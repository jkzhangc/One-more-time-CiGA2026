extends Node2D
@export var mask_duration: float = 3.0
@export var mouse_mask_radius: float = 40.0
@export var fixed_mask_radius: float = 75.0
@export_range(0.1, 2.0) var indicator_scale_factor: float = 1.9
@onready var button: Button = $UI/Button
@onready var color_rect: ColorRect = $GrayEffectLayer/ColorRect
@onready var indicator: Sprite2D = $GrayEffectLayer/Indicator
var is_active: bool = false
var fixed_masks: Array[Vector2] = []
func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	color_rect.material.set_shader_parameter("is_active", false)
	color_rect.material.set_shader_parameter("mouse_radius", mouse_mask_radius)
	color_rect.material.set_shader_parameter("fixed_radius", fixed_mask_radius)
	# 初始化指示器
	indicator.visible = false
	indicator.centered = true # 强制图片中心点居中，防止偏移到左上角
	# 动态计算缩放，使Sprite2D的视觉半径与 mouse_radius 一致
	if indicator.texture:
		var texture_radius = indicator.texture.get_width() / 2.0
		if texture_radius > 0:
			indicator.scale = Vector2.ONE * (mouse_mask_radius / texture_radius) * indicator_scale_factor
	_update_fixed_masks()
func _on_button_pressed() -> void:
	print("点击锚点图标")
	toggle_indicator()
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed and not event.echo:
		toggle_indicator()
	elif is_active and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var screen_pos = event.position 
		var world_pos = get_global_mouse_position()
		create_fixed_mask(world_pos, screen_pos)
func toggle_indicator() -> void:
	is_active = not is_active
	indicator.visible = is_active
	button.modulate = Color.LIME_GREEN if is_active else Color.WHITE
	color_rect.material.set_shader_parameter("is_active", is_active)
	if is_active:
		_update_indicator_pos()
func _process(_delta: float) -> void:
	if is_active:
		_update_indicator_pos()
		_update_mouse_shader_pos()
# 更新指示器位置（使用屏幕坐标）
func _update_indicator_pos() -> void:
	indicator.position = get_viewport().get_mouse_position()
# 更新着色器鼠标位置（使用屏幕坐标）
func _update_mouse_shader_pos() -> void:
	color_rect.material.set_shader_parameter("mouse_pos", get_viewport().get_mouse_position())
func create_fixed_mask(world_pos: Vector2, screen_pos: Vector2) -> void:
	if fixed_masks.size() < 3:
		fixed_masks.append(screen_pos)
		_update_fixed_masks()
		_detect_and_modify_state(world_pos, fixed_mask_radius, mask_duration)
		await get_tree().create_timer(mask_duration).timeout
		fixed_masks.erase(screen_pos)
		_update_fixed_masks()
func _update_fixed_masks() -> void:
	var default_pos = Vector2(-10000, -10000)
	var p1 = default_pos
	var p2 = default_pos
	var p3 = default_pos
	if fixed_masks.size() > 0: p1 = fixed_masks[0]
	if fixed_masks.size() > 1: p2 = fixed_masks[1]
	if fixed_masks.size() > 2: p3 = fixed_masks[2]
	color_rect.material.set_shader_parameter("fixed_pos_1", p1)
	color_rect.material.set_shader_parameter("fixed_pos_2", p2)
	color_rect.material.set_shader_parameter("fixed_pos_3", p3)
func _detect_and_modify_state(center_pos: Vector2, radius: float, duration: float) -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	query.shape = circle_shape
	query.transform = Transform2D(0, center_pos)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider.has_method("apply_anchor_state"):
			collider.apply_gray_state(duration)
