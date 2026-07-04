extends Node2D

# 上下移动的切换方向秒数
@export var updownframeCountmax:float = 5.0
# 左右移动的切换方向秒数
@export var leftrightframeCountmax:float = 2.0
# 上下移动速度
@export var updownspeed:float = 50
# 左右移动速度
@export var leftrightspeed:float = 50

# 圆周移动半径大小
@export var circumferenceradius: float = 120.0
# 圆周移动速度
@export var circumferencespeed: float = 2.0
# 圆周移动中心位置
@export var circumferencecenter: Vector2 = Vector2.ZERO

#初始状态
@export var initial_state: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 将上面的数值传给状态
	var machine = null
	var instance = get_children()[0]
	print(instance)
	for child in instance.get_children():
		if child is StateMachine:
			machine = child
	if machine:
		machine._on_transition_requested(initial_state)
		for child in machine.get_children():
			if child.name == "Move_updown":
				child.speed = updownspeed
				child.frameCount = updownframeCountmax
			if child.name == "Move_leftright":
				child.speed = leftrightspeed
				child.frameCount = leftrightframeCountmax


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
