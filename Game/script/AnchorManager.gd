extends Node2D
@export var mask_duration: float = 3.0
@export var mouse_mask_radius: float = 40.0
@export var fixed_mask_radius: float = 75.0
@export_range(0.1, 2.0) var indicator_scale_factor: float = 1.9
@export var mask_expand_duration: float = 0.2
@export var mask_strobe_duration: float = 0.5
@export var mask_shrink_duration: float = 0.2
@export var strobe_interval: float = 0.08
@export var max_anchors: int = 3

signal anchor_count_changed(current: int, max_count: int)

@onready var button: Button = $UI/Button
@onready var color_rect: ColorRect = $GrayEffectLayer/ColorRect
@onready var indicator: Sprite2D = $GrayEffectLayer/Indicator

var is_active: bool = false
var fixed_masks: Array[Dictionary] = []
var _anchor_label: Label = null
var _placed_count: int = 0  # 本次已放置的锚点数


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	color_rect.material.set_shader_parameter("is_active", false)
	color_rect.material.set_shader_parameter("mouse_radius", mouse_mask_radius)
	color_rect.material.set_shader_parameter("fixed_radius", fixed_mask_radius)
	# 初始化指示器
	indicator.visible = false
	indicator.centered = true
	if indicator.texture:
		var texture_radius = indicator.texture.get_width() / 2.0
		if texture_radius > 0:
			indicator.scale = Vector2.ONE * (mouse_mask_radius / texture_radius) * indicator_scale_factor
	_update_fixed_masks()
	_create_anchor_count_ui()
	_notify_anchor_count()


func _create_anchor_count_ui() -> void:
	_anchor_label = Label.new()
	_anchor_label.name = "AnchorCountLabel"
	_anchor_label.add_theme_font_size_override("font_size", 16)
	_anchor_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0, 1))  # 冰蓝色
	# 跟 Button 一样锚定在右下角，放在按钮上方
	_anchor_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_anchor_label.offset_left = -120
	_anchor_label.offset_top = -70
	_anchor_label.offset_right = -8
	_anchor_label.offset_bottom = -20
	_anchor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.get_parent().add_child(_anchor_label)


func _notify_anchor_count() -> void:
	var remaining: int = max_anchors - _placed_count
	anchor_count_changed.emit(remaining, max_anchors)
	if _anchor_label:
		_anchor_label.text = "锚点: %d/%d" % [remaining, max_anchors]


func add_anchor_count(amount: int) -> void:
	max_anchors += amount
	_notify_anchor_count()
	print("锚点上限增加 %d，当前上限: %d" % [amount, max_anchors])


func _on_button_pressed() -> void:
	print("点击锚点图标")
	toggle_indicator()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_Q and event.pressed and not event.echo:
		toggle_indicator()
	elif is_active and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos = get_global_mouse_position()
		create_fixed_mask(world_pos)

func toggle_indicator() -> void:
	is_active = not is_active
	indicator.visible = is_active
	button.modulate = Color.LIME_GREEN if is_active else Color.WHITE
	color_rect.material.set_shader_parameter("is_active", is_active)
	if is_active:
		_update_indicator_pos()

func _process(_delta: float) -> void:
	_update_fixed_masks()
	_detect_masks()
	if is_active:
		_update_indicator_pos()
		_update_mouse_shader_pos()

func _update_indicator_pos() -> void:
	indicator.position = get_viewport().get_mouse_position()

func _update_mouse_shader_pos() -> void:
	color_rect.material.set_shader_parameter("mouse_pos", get_viewport().get_mouse_position())

func create_fixed_mask(world_pos: Vector2) -> void:
	if _placed_count >= max_anchors:
		return
	var mask: Dictionary = {
		"world_pos": world_pos,
		"radius_scale": 0.0,
		"tween": null,
		"start_time": Time.get_ticks_msec() / 1000.0,
		"total_duration": mask_duration,
		"triggered": [],
	}
	fixed_masks.append(mask)
	_placed_count += 1
	_update_fixed_masks()
	_notify_anchor_count()

	var steady: float = maxf(mask_duration - mask_expand_duration - mask_strobe_duration - mask_shrink_duration, 0.0)
	var tween: Tween = create_tween()
	mask["tween"] = tween

	tween.tween_method(_apply_scale.bind(mask), 0.0, 1.0, mask_expand_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if steady > 0.0:
		tween.tween_interval(steady)
	var flashes: int = int(mask_strobe_duration / (strobe_interval * 2.0))
	for i in range(flashes):
		tween.tween_callback(_apply_scale.bind(0.0, mask))
		tween.tween_interval(strobe_interval)
		tween.tween_callback(_apply_scale.bind(1.0, mask))
		tween.tween_interval(strobe_interval)
	tween.tween_callback(_apply_scale.bind(1.0, mask))
	tween.tween_method(_apply_scale.bind(mask), 1.0, 0.0, mask_shrink_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_remove_mask.bind(mask))

func _apply_scale(value: float, mask: Dictionary) -> void:
	mask["radius_scale"] = value
	_update_fixed_masks()

func _remove_mask(mask: Dictionary) -> void:
	for i in range(fixed_masks.size()):
		if is_same(fixed_masks[i], mask):
			fixed_masks.remove_at(i)
			_placed_count -= 1
			_notify_anchor_count()
			break
	_update_fixed_masks()

func _update_fixed_masks() -> void:
	var default_pos := Vector2(-10000, -10000)
	var positions: Array[Vector2] = [default_pos, default_pos, default_pos]
	var scales: Array[float] = [0.0, 0.0, 0.0]
	var canvas_xf: Transform2D = get_viewport().get_canvas_transform()
	var zoom_scale: float = canvas_xf.get_scale().x
	for i in range(min(fixed_masks.size(), 3)):
		positions[i] = canvas_xf * fixed_masks[i]["world_pos"]
		scales[i] = fixed_masks[i]["radius_scale"]
	var mat: ShaderMaterial = color_rect.material
	mat.set_shader_parameter("fixed_pos_1", positions[0])
	mat.set_shader_parameter("fixed_pos_2", positions[1])
	mat.set_shader_parameter("fixed_pos_3", positions[2])
	mat.set_shader_parameter("fixed_scale_1", scales[0])
	mat.set_shader_parameter("fixed_scale_2", scales[1])
	mat.set_shader_parameter("fixed_scale_3", scales[2])
	mat.set_shader_parameter("fixed_radius", fixed_mask_radius * zoom_scale)

func _detect_masks() -> void:
	var space_state = get_world_2d().direct_space_state
	var now: float = Time.get_ticks_msec() / 1000.0
	for mask in fixed_masks:
		var eff_radius: float = fixed_mask_radius * mask.radius_scale
		if eff_radius <= 0.001:
			continue
		var remaining: float = mask.total_duration - (now - mask.start_time)
		if remaining <= 0.0:
			continue
		var query := PhysicsShapeQueryParameters2D.new()
		var circle_shape := CircleShape2D.new()
		circle_shape.radius = eff_radius
		query.shape = circle_shape
		query.transform = Transform2D(0, mask.world_pos)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		var results = space_state.intersect_shape(query)
		var triggered: Array = mask.triggered
		for result in results:
			var collider: Node = result.collider
			if triggered.has(collider):
				continue
			if collider.has_method("apply_anchor_state"):
				collider.apply_anchor_state(remaining)
				triggered.append(collider)
