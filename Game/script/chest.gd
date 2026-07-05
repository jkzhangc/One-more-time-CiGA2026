extends Node2D

@export var is_opened: bool = false
@export var mode: String = "内容1"

var player_in_range: bool = false
var prompt_label: Label = null
var anim_sprite: AnimatedSprite2D = null


func _ready() -> void:
	set_process_input(true)

	anim_sprite = $StaticBody2D/AnimatedSprite2D as AnimatedSprite2D

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

	# 创建炸弹可视化容器
	var bomb_visual = Node2D.new()
	bomb_visual.name = "BombVisual"
	bomb_visual.position = global_position
	bomb_visual.z_index = 100  # 确保在背景之上显示
	get_tree().current_scene.add_child(bomb_visual)

	# 危险区域圆圈（地面上的红色范围指示）
	var circle_sprite = Sprite2D.new()
	circle_sprite.name = "DangerCircle"
	circle_sprite.texture = _create_circle_texture(
		BOMB_RADIUS,
		Color(1.0, 0.12, 0.08, 0.25),   # 内部填充：半透明红色
		Color(1.0, 0.25, 0.1, 0.9),       # 边框：明显红色
		3.0                                  # 边框宽度
	)
	circle_sprite.centered = true
	bomb_visual.add_child(circle_sprite)

	# 中央炸弹图标
	var bomb_icon = Label.new()
	bomb_icon.name = "BombIcon"
	bomb_icon.text = "💣"
	bomb_icon.add_theme_font_size_override("font_size", 24)
	bomb_icon.position = Vector2(-12, -12)
	bomb_icon.z_index = 1  # 相对父节点偏移
	bomb_visual.add_child(bomb_icon)

	# 播放炸弹音效
	_play_bomb_sound()

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
	bomb_area.add_child(collision_shape)

	get_tree().current_scene.add_child(bomb_area)

	# 闪烁警告效果（圆圈 + 图标一起闪）
	var flash_count = 0
	while flash_count < int(BOMB_DELAY / 0.15):
		circle_sprite.visible = not circle_sprite.visible
		bomb_icon.visible = not bomb_icon.visible
		await get_tree().create_timer(0.15).timeout
		flash_count += 1
	# 最后保持可见
	circle_sprite.visible = true
	bomb_icon.visible = true

	# 爆炸前圆圈变红（短暂预警）
	circle_sprite.modulate = Color(1.0, 0.15, 0.05, 1.0)
	await get_tree().create_timer(0.1).timeout

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
	bomb_visual.queue_free()


func _create_circle_texture(radius: float, fill_color: Color, border_color: Color, border_width: float = 3.0) -> ImageTexture:
	var size: int = int(radius * 2 + border_width * 2 + 4)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var center := Vector2(size / 2.0, size / 2.0)
	for x in range(size):
		for y in range(size):
			var dist := Vector2(x - center.x, y - center.y).length()
			if dist <= radius + border_width:
				if dist >= radius - border_width:
					# 边框像素
					image.set_pixel(x, y, border_color)
				elif dist <= radius:
					# 内部填充
					image.set_pixel(x, y, fill_color)

	return ImageTexture.create_from_image(image)


func _play_bomb_sound() -> void:
	var audio := AudioStreamPlayer.new()
	audio.name = "BombSound"
	audio.stream = load("res://sound/炸弹.mp3")
	audio.autoplay = false
	audio.finished.connect(audio.queue_free)
	get_tree().current_scene.add_child(audio)
	audio.play()


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
