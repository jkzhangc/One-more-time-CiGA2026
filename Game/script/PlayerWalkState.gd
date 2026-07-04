extends State

@export var speed: float = 150.0
var input_axis: float = 0.0

func enter() -> void:
	print("进入walk状态，播放动画")
	character.anim_sprite.play("walk")
	
func process_update(delta :float) -> void:
	input_axis = Input.get_axis("left","right")
	
	if is_zero_approx(input_axis):
		transition_requested.emit("Idle")
	
	if Input.is_action_pressed("jump"):
		transition_requested.emit("Jump")
		
func physics_update(delta: float) -> void:
	# 执行移动
	character.velocity.x = input_axis * speed
	
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	
	character.move_and_slide()

func exit() -> void:
	print("离开idle状态")
