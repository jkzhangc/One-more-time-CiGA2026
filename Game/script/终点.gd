extends Node2D

@export var next_level: PackedScene  # 下一关的场景

var _completed: bool = false
var _ui_canvas: CanvasLayer = null


func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _completed:
		return
	# 判断是玩家
	if not body.has_method("take_damage"):
		return

	_completed = true
	print("玩家到达终点！")
	_show_completion_ui()


func _show_completion_ui() -> void:
	_ui_canvas = CanvasLayer.new()
	_ui_canvas.layer = 200  # 最顶层
	_ui_canvas.name = "CompletionUI"
	add_child(_ui_canvas)

	# 半透明黑色遮罩
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_canvas.add_child(overlay)

	# 中间面板
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(280, 200)
	panel.position = Vector2(-140, -100)
	_ui_canvas.add_child(panel)

	# 标题
	var title = Label.new()
	title.text = "恭喜你通过本关！"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 1))  # 暖金色
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(-120, -70)
	title.size = Vector2(240, 40)
	panel.add_child(title)

	# 重来按钮
	var restart_btn = Button.new()
	restart_btn.text = "重来"
	restart_btn.position = Vector2(30, 30)
	restart_btn.size = Vector2(80, 36)
	restart_btn.pressed.connect(_on_restart_pressed)
	panel.add_child(restart_btn)

	# 下一关按钮
	var next_btn = Button.new()
	next_btn.text = "下一关"
	next_btn.position = Vector2(170, 30)
	next_btn.size = Vector2(80, 36)
	next_btn.pressed.connect(_on_next_level_pressed)
	if not next_level:
		next_btn.disabled = true
		next_btn.text = "无下一关"
	panel.add_child(next_btn)


func _on_restart_pressed() -> void:
	print("重来本关")
	get_tree().reload_current_scene()


func _on_next_level_pressed() -> void:
	if not next_level:
		return
	print("进入下一关")
	get_tree().change_scene_to_packed(next_level)
