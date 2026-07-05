extends State
# 跳跃起速度
@export var jump_velocity: float = -450.0
# 空中移动速度
@export var jump_move_velocity: float = 150.0
# 重力
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# 从项目设置里获取全局重力，这样代码更具移植性
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func enter() -> void:
	print("进入jump状态，播放动画")
	character.anim_sprite.play("jump")
	character.velocity.y = jump_velocity
		
func physics_update(delta: float) -> void:
	character.velocity.y += gravity * delta
	
	var input_axis = Input.get_axis("left","right")
	character.velocity.x = input_axis * jump_move_velocity
	
	character.move_and_slide()
	
	if character.is_on_floor():
		if not is_zero_approx(character.velocity.x):
			character._play_jump_sound()
			transition_requested.emit("Walk")
		else:
			character._play_jump_sound()
			transition_requested.emit("Idle")


func exit() -> void:
	print("离开idle状态")
