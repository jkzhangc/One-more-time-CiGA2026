extends Node2D

@export var next_level: PackedScene  # 下一关的场景
@export var 初始是否隐藏: bool
@export var is_final_level: bool = false  # 是否为最终关
@export var main_menu_scene: PackedScene  # 主菜单场景（最终关返回用）

var _completed: bool = false
var _ui_canvas: CanvasLayer = null
signal open
signal close 

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	if 初始是否隐藏:
		$Area2D.monitoring = false
		hide()

func _open() -> void:
	$Area2D.monitoring = true
	show()

func _close() -> void:
	$Area2D.monitoring = false
	hide()
	
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
	panel.size = Vector2(280, 100)
	panel.position = Vector2(-140, 0)
	_ui_canvas.add_child(panel)

	# 标题
	var title = Label.new()
	if is_final_level:
		title.text = "恭喜你通关了游戏！"
	else:
		title.text = "恭喜你通过本关！"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 1))  # 暖金色
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(30, -70)
	title.size = Vector2(240, 40)
	panel.add_child(title)

	# 重来按钮
	var restart_btn = Button.new()
	restart_btn.text = "重来"
	restart_btn.position = Vector2(30, 30)
	restart_btn.size = Vector2(80, 36)
	restart_btn.pressed.connect(_on_restart_pressed)
	panel.add_child(restart_btn)

	if is_final_level:
		# 回到主菜单按钮（最终关）
		var menu_btn = Button.new()
		menu_btn.text = "回到主菜单"
		menu_btn.position = Vector2(140, 30)
		menu_btn.size = Vector2(110, 36)
		menu_btn.pressed.connect(_on_return_to_menu_pressed)
		panel.add_child(menu_btn)
	else:
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


func _on_return_to_menu_pressed() -> void:
	if not main_menu_scene:
		print("错误：未设置 main_menu_scene 主菜单场景！")
		return
	print("回到主菜单")
	get_tree().change_scene_to_packed(main_menu_scene)


func _on_door_door_opened() -> void:
	_open() # Replace with function body.


func _on_door_door_closed() -> void:
	_close() # Replace with function body.
