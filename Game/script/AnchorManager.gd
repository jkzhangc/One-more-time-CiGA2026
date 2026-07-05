extends Node2D
@export var mask_duration: float = 3.0
@export var mouse_mask_radius: float = 45.0
@export var fixed_mask_radius: float = 75.0
@export_range(0.1, 2.0) var indicator_scale_factor: float = 1
@export var mask_expand_duration: float = 0.2
@export var mask_strobe_duration: float = 0.5
@export var mask_shrink_duration: float = 0.2
@export var strobe_interval: float = 0.08
@export var max_anchors: int = 3  # 锚点使用次数上限（初始次数 / 上限）

signal anchor_count_changed(current: int, max_count: int)

@onready var button: Button = $UI/Button
@onready var color_rect: ColorRect = $GrayEffectLayer/ColorRect
@onready var indicator: Sprite2D = $GrayEffectLayer/Indicator

var is_active: bool = false
var fixed_masks: Array[Dictionary] = []
var _anchor_label: Label = null
var _uses_remaining: int = 0  # 剩余可用次数，不随锚点消失自动恢复
var _no_uses_flash_tween: Tween = null  # 防止频闪动画叠加
const ANCHOR_LABEL_NORMAL_COLOR: Color = Color(0.6, 0.9, 1.0, 1.0)
const ANCHOR_LABEL_WARN_COLOR: Color = Color(1.0, 0.3, 0.25, 1.0)


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	color_rect.scale = Vector2.ONE
	color_rect.material.set_shader_parameter("is_active", false)
	color_rect.material.set_shader_parameter("mouse_pos", Vector2(-10000, -10000))
	color_rect.material.set_shader_parameter("mouse_radius", mouse_mask_radius)
	color_rect.material.set_shader_parameter("fixed_radius", fixed_mask_radius)
	# 初始化指示器
	indicator.visible = false
	indicator.centered = true
	if indicator.texture:
		var texture_radius = indicator.texture.get_width() / 2.0
		if texture_radius > 0:
			indicator.scale = Vector2.ONE * (mouse_mask_radius / texture_radius) * indicator_scale_factor
	_uses_remaining = max_anchors
	_update_fixed_masks()
	_create_anchor_count_ui()
	_notify_anchor_count()


func _create_anchor_count_ui() -> void:
	_anchor_label = Label.new()
	_anchor_label.name = "AnchorCountLabel"
	_anchor_label.add_theme_font_size_override("font_size", 16)
	_anchor_label.add_theme_color_override("font_color", ANCHOR_LABEL_NORMAL_COLOR)
	# 跟 Button 一样锚定在右下角，放在按钮上方
	_anchor_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_anchor_label.offset_left = -120
	_anchor_label.offset_top = -70
	_anchor_label.offset_right = -8
	_anchor_label.offset_bottom = -20
	_anchor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.get_parent().add_child(_anchor_label)


func _notify_anchor_count() -> void:
	anchor_count_changed.emit(_uses_remaining, max_anchors)
	if _anchor_label:
		_anchor_label.text = "锚点: %d/%d" % [_uses_remaining, max_anchors]


func add_anchor_count(amount: int) -> void:
	_uses_remaining += amount
	if _uses_remaining > max_anchors:
		_uses_remaining = max_anchors
	# 恢复次数时，停止可能正在播放的"无次数"频闪并还原颜色
	if _no_uses_flash_tween and _no_uses_flash_tween.is_valid():
		_no_uses_flash_tween.kill()
	_set_anchor_label_color(ANCHOR_LABEL_NORMAL_COLOR)
	_notify_anchor_count()
	print("锚点次数恢复 %d，剩余次数: %d/%d" % [amount, _uses_remaining, max_anchors])


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
	# 无剩余次数时，拒绝开启瞄准模式，播放 UI 频闪提示
	if not is_active and _uses_remaining <= 0:
		_flash_no_uses_ui()
		return
	is_active = not is_active
	indicator.visible = is_active
	button.modulate = Color.LIME_GREEN if is_active else Color.WHITE
	if is_active:
		_update_indicator_pos()
	else:
		# 退出瞄准模式时把鼠标圈推到屏幕外，避免残留
		color_rect.material.set_shader_parameter("mouse_pos", Vector2(-10000, -10000))


func _flash_no_uses_ui() -> void:
	# 如果已有频闪动画在播，先 kill 防止叠加
	if _no_uses_flash_tween and _no_uses_flash_tween.is_valid():
		_no_uses_flash_tween.kill()
	_no_uses_flash_tween = create_tween()
	const FLASH_INTERVAL: float = 0.08
	const FLASH_COUNT: int = 6  # 6 次明暗交替 ≈ 0.48s
	for _i in range(FLASH_COUNT):
		_no_uses_flash_tween.tween_callback(_set_anchor_label_color.bind(ANCHOR_LABEL_WARN_COLOR))
		_no_uses_flash_tween.tween_interval(FLASH_INTERVAL)
		_no_uses_flash_tween.tween_callback(_set_anchor_label_color.bind(ANCHOR_LABEL_NORMAL_COLOR))
		_no_uses_flash_tween.tween_interval(FLASH_INTERVAL)
	_no_uses_flash_tween.tween_callback(_set_anchor_label_color.bind(ANCHOR_LABEL_NORMAL_COLOR))


func _set_anchor_label_color(c: Color) -> void:
	if _anchor_label:
		_anchor_label.add_theme_color_override("font_color", c)

func _process(_delta: float) -> void:
	# shader 激活条件：瞄准中 或 场上有未消失的固定锚点
	var shader_active: bool = is_active or not fixed_masks.is_empty()
	color_rect.material.set_shader_parameter("is_active", shader_active)
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
	# 没有剩余次数 或 场上还有未消失的锚点，则不能释放
	if _uses_remaining <= 0 or not fixed_masks.is_empty():
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
	_uses_remaining -= 1
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
	for child in get_children():
		if child.name == "Player":
			#print(child,child.get_children())
			child.get_children()[3]._on_transition_requested("施法")

	# 释放后立即关闭瞄准模式（取消 indicator 和按钮高亮）
	if is_active:
		toggle_indicator()

func _apply_scale(value: float, mask: Dictionary) -> void:
	mask["radius_scale"] = value
	_update_fixed_masks()

func _remove_mask(mask: Dictionary) -> void:
	for i in range(fixed_masks.size()):
		if is_same(fixed_masks[i], mask):
			fixed_masks.remove_at(i)
			# 注意：锚点消失不恢复使用次数（必须通过宝箱恢复）
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


# 死亡区域回调（关卡底部 Area2D 连接到此方法）
func _on_death_zone_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		print("玩家掉入死亡区域！")
		get_tree().reload_current_scene()
