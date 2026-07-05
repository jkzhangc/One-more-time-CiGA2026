extends CharacterBody2D

@export var typename: String = "压力板"
## 压力板 —— 玩家或敌人站在上面时触发机关
## 通过信号连接其他物体（如门），实现板子按下→门打开的效果

signal pressed    # 板子被压下（无物体 → 有物体）
signal released   # 板子弹起（有物体 → 无物体）

@export var stay_triggered: bool = false  # true 时按下后保持触发，不会弹起

var _bodies_count: int = 0
var is_pressed: bool = false

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	_bodies_count += 1
	print("压力板被按下")
	if body.name == "Player":
		return
	if not is_pressed:
		is_pressed = true
		pressed.emit()
		# 同时驱动自身的 StateMachine（保持兼容旧系统）
		if has_node("StateMachine"):
			$StateMachine._on_transition_requested("Triggered")


func _on_body_exited(body: Node2D) -> void:
	_bodies_count = max(0, _bodies_count - 1)
	if _bodies_count == 0 and not stay_triggered:
		is_pressed = false
		released.emit()
		if has_node("StateMachine"):
			$StateMachine._on_transition_requested("Normal")


func transition(nxtState: String) -> void:
	# 保留旧接口，供外部直接调用（如旧版敌人脚本）
	if has_node("StateMachine"):
		$StateMachine._on_transition_requested(nxtState)
