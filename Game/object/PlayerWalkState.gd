extends State

@export var speed: float = 150.0
var input_axis: float = 0.0

func enter() -> void:
	print("进入walk状态，播放动画")
	
func process_update(delta :float) -> void:
	input_axis = Input.get_axis("ui_left","ui_right")
	
	if is_zero_approx(input_axis):
		transition_requested.emit("Idle")
	
	if Input.is_action_just_pressed("ui_up"):
		transition_requested.emit("Jump")
		
func physics_update(delta: float) -> void:
	# 执行移动
	character.velocity.x = input_axis * speed
	character.move_and_slide()

func exit() -> void:
	print("离开idle状态")
