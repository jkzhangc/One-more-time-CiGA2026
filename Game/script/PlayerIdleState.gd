extends State

# 从项目设置里获取全局重力，这样代码更具移植性
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func enter() -> void:
	character.velocity = Vector2.ZERO
	print("进入idle状态")
	
func exit() -> void:
	print("离开idle状态")

func process_update(delta :float) -> void:
	if Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right"):
		transition_requested.emit("Walk")
		return
	if Input.is_action_just_pressed("jump"):
		transition_requested.emit("Jump")
		
func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y += gravity * delta
	character.move_and_slide()
