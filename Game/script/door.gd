extends Node2D

## 门 —— 支持"未开启"和"开启"两个状态
## 可通过压力板信号、或玩家走进 Area2D 来触发打开
##
## 连接方式：在编辑器中把压力板的 pressed 信号连接到门的 open() 方法

signal door_opened
signal door_closed

@export var is_open: bool = false        # 初始是否已开启
@export var is_victory_door: bool = false  # 是否为通关终点门

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _blocker: StaticBody2D = $StaticBody2D


func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	if is_open:
		_apply_open_state()
	else:
		_apply_closed_state()


## 开门（供外部信号连接）
func open() -> void:
	if is_open:
		return
	is_open = true
	_apply_open_state()
	door_opened.emit()
	print("门已开启")


## 关门（供外部信号连接）
func close() -> void:
	if not is_open:
		return
	is_open = false
	_apply_closed_state()
	door_closed.emit()
	print("门已关闭")


func _apply_open_state() -> void:
	if anim:
		anim.play("open")
	if _blocker:
		_blocker.collision_layer = 0  # 禁用碰撞，玩家可通过


func _apply_closed_state() -> void:
	if anim:
		anim.play("default")
	if _blocker:
		_blocker.collision_layer = 8  # 恢复碰撞（杂项层，阻挡玩家）


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return

	# 如果是通关终点门且已开启 → 显示胜利 UI
	if is_victory_door and is_open:
		print("玩家通过终点门！恭喜通关！")
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


func _on_board_pressed() -> void:
	print("开启门")
	open()


func _on_board_released() -> void:
	close()
