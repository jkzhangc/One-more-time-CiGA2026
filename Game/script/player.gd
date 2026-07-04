extends CharacterBody2D

@onready var anim_sprite = $AnimatedSprite2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const MAX_HP = 3
const INVULNERABLE_TIME = 1.5  # 受伤后无敌时间（秒）

signal hit
signal hp_changed(current_hp: int, max_hp: int)
signal died

var current_hp: int = MAX_HP
var is_invulnerable: bool = false
var _dying: bool = false  # 防止重复死亡
var _frozen_overlap: Dictionary = {}  # 玩家正在重叠的已冻结敌人 body → true
var _hp_label: Label = null


func _ready() -> void:
	$Area2D.body_exited.connect(_on_area_2d_body_exited)
	_create_hp_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()


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
	if is_invulnerable or _dying:
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
	if _dying:
		return
	_dying = true
	print("玩家死亡！")

	# 1. 隐藏玩家 + 禁用碰撞
	hide()
	$CollisionShape2D.set_deferred("disabled", true)

	# 2. 生成死亡粒子
	_spawn_death_particles()

	# 3. 画面渐黑过渡
	await _fade_to_black(0.6)

	# 4. 重载场景（自动重置所有状态）
	get_tree().reload_current_scene()


func _spawn_death_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.position = global_position
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 24
	particles.lifetime = 0.6
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 4.0
	particles.direction = Vector2(0, -1)
	particles.spread = 150.0
	particles.gravity = Vector2(0, 150)
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 180.0
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.5
	particles.scale_amount_curve = _make_fade_out_curve()
	particles.color = Color(0.239, 0.184, 0.0, 0.9)  # 橙红色
	particles.color_ramp = _make_color_ramp()
	particles.finished.connect(particles.queue_free)

	get_tree().current_scene.add_child(particles)
	particles.emitting = true


func _make_fade_out_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))    # 开始：正常大小
	curve.add_point(Vector2(0.3, 1))  # 保持
	curve.add_point(Vector2(1, 0))    # 结束：缩小消失
	return curve


func _make_color_ramp() -> Gradient:
	var grad = Gradient.new()
	grad.add_point(0.0, Color(1.0, 0.6, 0.2, 1.0))   # 亮橙
	grad.add_point(0.5, Color(1.0, 0.2, 0.1, 0.7))    # 红
	grad.add_point(1.0, Color(0.3, 0.05, 0.05, 0.0))  # 暗红 → 透明
	return grad


func _fade_to_black(duration: float) -> void:
	if not is_inside_tree():
		return

	var canvas = CanvasLayer.new()
	canvas.layer = 128  # 最顶层

	var color_rect = ColorRect.new()
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	canvas.add_child(color_rect)
	get_tree().root.add_child(canvas)

	var tween = create_tween()
	tween.tween_property(color_rect, "color", Color(0, 0, 0, 1), duration)
	await tween.finished

	# 重载场景前必须清理 root 上的 overlay，否则黑屏会残留
	canvas.queue_free()


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

	# 移动方向翻转 AnimatedSprite2D
	var input_dir = Input.get_axis("left", "right")
	if input_dir < 0:
		$AnimatedSprite2D.flip_h = true
	elif input_dir > 0:
		$AnimatedSprite2D.flip_h = false


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

		"尖刺柱":
			_handle_spike_pillar_collision(body, enemyStateMachine)
			return

		"电锯":
			_handle_saw_collision(body, enemyStateMachine)
			return

		_:
			_handle_default_collision(body, enemyStateMachine)


# --- 尖刺柱 ---
# 伤害由尖刺柱自己的 Area2D（刺碰撞体）在 Spike 状态时触发
# 玩家 Area2D 碰到 EnemyInstance 本体不造成伤害
# 碰到冻结的尖刺柱柱子本体 → 追踪解冻伤害

func _handle_spike_pillar_collision(body: Node2D, sm: StateMachine) -> void:
	var current_name = sm.current_state.name

	if current_name == "Freeze":
		print("尖刺柱已冻结，玩家安全通过")
		if not _frozen_overlap.has(body):
			_frozen_overlap[body] = true
		return

	# Normal / Spike 状态碰到柱子本体 → 无伤害（伤害在刺 Area2D）
	print("尖刺柱本体触碰，无伤害 (state=%s)" % current_name)


# --- 锯齿陷阱 ---
# 无论是否冻结，触碰锯齿都会掉血

func _handle_saw_collision(body: Node2D, _sm: StateMachine) -> void:
	print("玩家触碰电锯，受到伤害！")
	take_damage(1)


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
		if last_name in "MiddleJump":
			velocity.y = -300.0
		elif last_name in "HighJump":
			velocity.y = -600.0

	else:
		print("形态类怪物已冻结（普通态），玩家安全通过")


# --- 默认碰撞（未知敌人类型兜底）---

func _handle_default_collision(body: Node2D, sm: StateMachine) -> void:
	if sm.character.get_parent().name == "Board":
		return
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
