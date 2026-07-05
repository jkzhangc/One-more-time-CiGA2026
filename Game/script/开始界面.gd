extends Node2D

## 开始界面 / 主菜单脚本
## 背景使用 art/开始界面背景.png，包含开始游戏、制作人员、退出游戏三个按钮。

@export var first_level: PackedScene  # 开始游戏时进入的关卡（可在编辑器中设置）
@export var bg_texture: Texture2D    # 背景图片

var _credits_panel: CanvasLayer = null


func _ready() -> void:
	# 设置背景
	if bg_texture:
		$Background.texture = bg_texture

	# 将场景中的 AudioStreamPlayer 交给全局 GlobalAudio 播放（场景切换不断）
	var scene_player: AudioStreamPlayer = $AudioStreamPlayer
	if scene_player and scene_player.stream:
		GlobalAudio.play_music(scene_player.stream)
		scene_player.stop()

	# 连接按钮信号
	$UI/Panel/VBoxContainer/StartButton.pressed.connect(_on_start_game)
	$UI/Panel/VBoxContainer/CreditsButton.pressed.connect(_on_show_credits)
	$UI/Panel/VBoxContainer/QuitButton.pressed.connect(_on_quit_game)


func _on_start_game() -> void:
	if not first_level:
		print("错误：未设置 first_level 关卡场景！")
		return
	print("开始游戏 → 进入关卡")
	get_tree().change_scene_to_packed(first_level)


func _on_show_credits() -> void:
	if _credits_panel:
		return  # 已经在显示中

	_credits_panel = CanvasLayer.new()
	_credits_panel.layer = 200
	_credits_panel.name = "CreditsPanel"
	add_child(_credits_panel)

	# 半透明黑色遮罩
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_credits_panel.add_child(overlay)

	# 中间面板
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(360, 200)
	panel.position = Vector2(-180, -100)
	_credits_panel.add_child(panel)

	# 标题
	var title = Label.new()
	title.text = "制作人员名单"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 1))  # 暖金色
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(-140, -125)
	title.size = Vector2(280, 40)
	panel.add_child(title)

	# 分隔线
	var sep = HSeparator.new()
	sep.position = Vector2(20, -80)
	sep.size = Vector2(320, 4)
	panel.add_child(sep)

	# 制作人员名单内容
	var credits_text = Label.new()
	credits_text.text = "策划：橙籽狸 / 昀墨魇莲离 / mash1ro\n程序：剑客 / Ricky / OTT \n美术：繁星点点\n音效&音乐：来自网络"
	credits_text.add_theme_font_size_override("font_size", 18)
	credits_text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	credits_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_text.position = Vector2(40, 20)
	credits_text.size = Vector2(280, 120)
	panel.add_child(credits_text)

	# 返回按钮
	var back_btn = Button.new()
	back_btn.text = "返回"
	back_btn.position = Vector2(140, 210)
	back_btn.size = Vector2(80, 36)
	back_btn.pressed.connect(_on_close_credits)
	panel.add_child(back_btn)


func _on_close_credits() -> void:
	if _credits_panel:
		_credits_panel.queue_free()
		_credits_panel = null


func _on_quit_game() -> void:
	print("退出游戏")
	get_tree().quit()
