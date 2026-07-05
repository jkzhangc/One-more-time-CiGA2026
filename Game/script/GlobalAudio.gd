extends Node

## GlobalAudio — 全局背景音乐播放器（autoload 单例）
## 随游戏启动自动播放，场景切换时音乐不间断。

@export var music_stream: AudioStream  # 在编辑器中设置要播放的音乐

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "BGMusic"
	_player.bus = "Master"
	_player.finished.connect(_on_player_finished)
	add_child(_player)
	if music_stream:
		play_music(music_stream)


func play_music(stream: AudioStream) -> void:
	if not stream:
		return
	if _player.playing and _player.stream == stream:
		return
	_player.stream = stream
	_player.play()


func stop_music() -> void:
	_player.stop()


func _on_player_finished() -> void:
	_player.play()


func set_volume_db(db: float) -> void:
	_player.volume_db = db


func fade_to(stream: AudioStream, duration: float = 1.0) -> void:
	"""渐变切换到新音乐"""
	if not stream or _player.stream == stream:
		return
	var tween := create_tween()
	tween.tween_property(_player, "volume_db", -40.0, duration * 0.5)
	tween.tween_callback(func():
		_player.stream = stream
		_player.play()
	)
	tween.tween_property(_player, "volume_db", 0.0, duration * 0.5)
