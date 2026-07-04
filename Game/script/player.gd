extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const MAX_HP = 3
const INVULNERABLE_TIME = 1.5  # 受伤后无敌时间（秒）

signal hit
signal hp_changed(current_hp: int, max_hp: int)
signal died

var current_hp: int = MAX_HP
var spawn_position: Vector2
var is_invulnerable: bool = false
var _frozen_overlap: Dictionary = {}  # 玩家正在重叠的已冻结敌人 body → true
var _hp_label: Label = null


func _ready() -> void:
	spawn_position = position
	$Area2D.body_exited.connect(_on_area_2d_body_exited)
	_create_hp_ui()


func _create_hp_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.name = "HpCanvas"

	var label = Label.new()
	label.name = "HpLabel"
	label.add_theme_font_size_override("font_size", 28)
	label.position = Vector2(12, 12)
	label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))  # 红色爱心

	canvas.add_child(label)
	add_child(canvas)

	_hp_label = label
	_update_hp_display()


func _update_hp_display() -> void:
	if not _hp_label:
		return
	var hearts = ""
	for i in range(MAX_HP):
		if i < current_hp:
			hearts += "♥ "
		else:
			hearts += "♡ "
	_hp_label.text = hearts


func _on_area_2d_body_exited(body: Node2D) -> void:
	if _frozen_overlap.has(body):
		_frozen_overlap.erase(body)


# --- HP 系统 ---

func take_damage(amount: int) -> void:
	if is_invulnerable:
		return
	current_hp -= amount
	current_hp = max(current_hp, 0)
	hp_changed.emit(current_hp, MAX_HP)
	_update_hp_display()

	if current_hp <= 0:
		die()
	else:
		_start_invulnerability()


func _start_invulnerability() -> void:
	is_invulnerable = true
	# 简单闪烁效果：反复显示/隐藏
	for _i in range(int(INVULNERABLE_TIME / 0.1)):
		visible = not visible
		await get_tree().create_timer(0.1).timeout
	visible = true
	is_invulnerable = false


func die() -> void:
	print("玩家死亡，重生中...")
	died.emit()
	_frozen_overlap.clear()
	is_invulnerable = false
	# 重置血量
	current_hp = MAX_HP
	hp_changed.emit(current_hp, MAX_HP)
	_update_hp_display()
	# 回到出生点
	position = spawn_position
	show()
	$CollisionShape2D.disabled = false
	$StateMachine._on_transition_requested("Idle")
	# TODO: 重置时停和所有怪物状态


func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, MAX_HP)
	hp_changed.emit(current_hp, MAX_HP)
	_update_hp_display()


# --- 物理帧：检测解冻掉血 ---

func _physics_process(delta: float) -> void:
	# 检查是否有冻结的敌人解冻了（玩家还站在上面 → 掉血）
	var to_remove = []
	for body in _frozen_overlap.keys():
		if not is_instance_valid(body):
			to_remove.append(body)
			continue
		var sm = _get_state_machine(body)
		if sm and sm.current_state.name != "Freeze":
			print("敌人解冻，玩家站在上面，扣 1 滴血")
			take_damage(1)
			to_remove.append(body)

	for body in to_remove:
		_frozen_overlap.erase(body)


# --- 辅助 ---

func _get_state_machine(body: Node2D) -> StateMachine:
	if body:
		for child in body.get_children():
			if child is StateMachine:
				return child
	return null


# --- 碰撞检测 ---

func collision_check(delta: float) -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("玩家触碰了 ", body)

	var enemyStateMachine := _get_state_machine(body)
	if not enemyStateMachine:
		return

	var enemy_state_name = enemyStateMachine.current_state.name
	print("敌人状态: ", enemy_state_name)

	var enemy_type: String = body.get("typename") if body.get("typename") else ""

	match enemy_type:
		"移动平台":
			# 移动平台：无论是否冻结，玩家都不受影响
			print("碰到移动平台，无反应")
			return

		"形态类怪物":
			_handle_morph_enemy_collision(body, enemyStateMachine)
			return

		_:
			_handle_default_collision(body, enemyStateMachine)


# --- 形态类怪物 ---

func _handle_morph_enemy_collision(body: Node2D, sm: StateMachine) -> void:
	var current_name = sm.current_state.name
	var last_name = sm.last_state.name if sm.last_state else ""

	# 未冻结 → 扣血
	if current_name != "Freeze":
		print("玩家被形态类怪物伤害！(state=%s)" % current_name)
		take_damage(1)
		return

	# 已冻结 → 追踪这个敌人，用于检测解冻伤害
	if not _frozen_overlap.has(body):
		_frozen_overlap[body] = true

	# 检查冻结前是否是跳跃状态
	var was_jump_state = (last_name in ["MiddleJump", "HighJump"])

	if was_jump_state:
		print("形态类怪物冻结在跳跃状态 (last=%s)，弹起！" % last_name)
		velocity.y = -500.0
	else:
		print("形态类怪物已冻结（普通态），玩家安全通过")


# --- 默认碰撞（未知敌人类型兜底）---

func _handle_default_collision(body: Node2D, sm: StateMachine) -> void:
	var current_name = sm.current_state.name

	if current_name == "Freeze":
		print(body.typename, " 已冻结，玩家安全通过")
		if not _frozen_overlap.has(body):
			_frozen_overlap[body] = true
		return

	# 区分"踩到"还是"碰到"
	var player_bottom = global_position.y + 25.0
	var enemy_top = body.global_position.y - 16.0
	var is_falling = velocity.y > 0.0
	var is_above_enemy = player_bottom < enemy_top + 12.0

	if is_falling and is_above_enemy:
		print("玩家踩到了 ", body.typename, "，弹起！")
		velocity.y = -500.0
	else:
		print("玩家被 ", body.typename, " 伤害！")
		take_damage(1)


# --- 重置 ---

func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false
	$StateMachine._on_transition_requested("Idle")
