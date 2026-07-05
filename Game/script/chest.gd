extends CharacterBody2D

@export var is_opened: bool = false
@export var mode: String = "内容1"

var player_in_range: bool = false
var prompt_label: Label = null
var anim_sprite: AnimatedSprite2D = null


func _ready() -> void:
	set_process_input(true)

	anim_sprite = $AnimatedSprite2D as AnimatedSprite2D

	# 创建提示文字
	prompt_label = Label.new()
	prompt_label.name = "PromptLabel"
	prompt_label.text = "按 E 打开"
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 1))  # 暖金色
	prompt_label.position = Vector2(-28, -55)
	prompt_label.visible = false
	add_child(prompt_label)

	# 连接 Area2D 信号
	var area_2d = $Area2D as Area2D
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)

	# 初始状态
	if is_opened:
		anim_sprite.play("开启状态")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):  # 判断是玩家
		player_in_range = true
		if not is_opened:
			prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.has_method("take_damage"):
		player_in_range = false
		prompt_label.visible = false


func _input(event: InputEvent) -> void:
	if not player_in_range or is_opened:
		return
	if event.is_action_pressed("act"):
		_open_chest()


func _open_chest() -> void:
	is_opened = true
	anim_sprite.play("开启状态")
	prompt_label.visible = false
	print("宝箱已打开！")

	match mode:
		"内容1":
			_reward_extra_anchor()
		"内容2":
			_trap_bomb()
		_:
			print("未知宝箱模式: %s" % mode)


# --- 内容1：奖励时间锚点次数+1 ---

func _reward_extra_anchor() -> void:
	print("奖励时间锚点次数+1")
	var root = get_tree().current_scene
	if root and root.has_method("add_anchor_count"):
		root.add_anchor_count(1)
	# 播放金色粒子
	_spawn_reward_particles()


func _spawn_reward_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.position = global_position + Vector2(0, -30)
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 16
	particles.lifetime = 0.8
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 8.0
	particles.direction = Vector2(0, -1)
	particles.spread = 90.0
	particles.gravity = Vector2(0, -80)  # 向上飘
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = Color(1.0, 0.85, 0.3, 0.9)  # 金色
	particles.finished.connect(particles.queue_free)

	get_tree().current_scene.add_child(particles)
	particles.emitting = true


# --- 内容2：触发炸弹，2秒后爆炸，2格范围内扣1血 ---

const BOMB_RADIUS: float = 64.0  # 2 格（32px/格）
const BOMB_DELAY: float = 2.0

func _trap_bomb() -> void:
	print("触发炸弹！2秒后爆炸！")

	# 创建炸弹检测区域
	var bomb_area = Area2D.new()
	bomb_area.name = "BombArea"
	bomb_area.position = global_position
	bomb_area.collision_layer = 0
	bomb_area.collision_mask = 2  # 检测玩家层

	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = BOMB_RADIUS
	collision_shape.shape = circle
	collision_shape.debug_color = Color(1, 0.2, 0.1, 0.4)
	bomb_area.add_child(collision_shape)

	get_tree().current_scene.add_child(bomb_area)

	# 闪烁警告效果
	var flash_count = 0
	while flash_count < int(BOMB_DELAY / 0.15):
		bomb_area.visible = not bomb_area.visible
		await get_tree().create_timer(0.15).timeout
		flash_count += 1
	bomb_area.visible = true

	# 爆炸：检测范围内的玩家
	var bodies = bomb_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			print("炸弹爆炸！玩家在范围内，扣 1 滴血")
			body.take_damage(1)

	# 爆炸粒子
	_spawn_explosion_particles()

	# 清理
	bomb_area.queue_free()


func _spawn_explosion_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.position = global_position
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 32
	particles.lifetime = 0.5
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 4.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 100)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 250.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color(1.0, 0.3, 0.1, 0.9)  # 橙红色爆炸
	var color_ramp = Gradient.new()
	color_ramp.add_point(0.0, Color(1.0, 0.6, 0.1, 1.0))
	color_ramp.add_point(0.4, Color(1.0, 0.2, 0.05, 0.8))
	color_ramp.add_point(1.0, Color(0.1, 0.05, 0.05, 0.0))
	particles.color_ramp = color_ramp
	particles.finished.connect(particles.queue_free)

	get_tree().current_scene.add_child(particles)
	particles.emitting = true
