extends Node2D

var _triggered: bool = false
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not body.has_method("take_damage"):
		return

	_triggered = true
	print("玩家进入门！恭喜通关！")

	# 切换门动画
	if anim:
		anim.play("open")

	# 稍作停顿后显示通关 UI
	await get_tree().create_timer(0.5).timeout
	_show_victory_ui()


func _show_victory_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	canvas.name = "VictoryUI"
	add_child(canvas)

	# 遮罩 — 从透明渐变到半黑
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(overlay)

	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0.6), 0.8)

	# 标题
	var title = Label.new()
	title.text = "恭喜你通关了！"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.4, 1))  # 金色
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-150, -60)
	title.size = Vector2(300, 50)
	canvas.add_child(title)

	# 重来按钮
	var restart_btn = Button.new()
	restart_btn.text = "重新开始"
	restart_btn.size = Vector2(120, 40)
	restart_btn.set_anchors_preset(Control.PRESET_CENTER)
	restart_btn.position = Vector2(-60, 20)
	restart_btn.pressed.connect(_on_restart_pressed)
	canvas.add_child(restart_btn)


func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()
