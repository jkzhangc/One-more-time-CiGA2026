extends Node2D

@export var is_opened: bool = false

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
	# TODO: 生成奖励物品
