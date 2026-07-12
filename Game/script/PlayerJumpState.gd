extends State

# 跳跃初速度
@export var jump_velocity: float = -450.0
# 空中移动速度
@export var jump_move_velocity: float = 150.0
# 基础重力
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
# 下落重力倍率
@export var fall_gravity_multiplier: float = 1.8


func enter() -> void:
	print("进入jump状态，播放动画")
	character.anim_sprite.play("jump")
	character.velocity.y = jump_velocity


func physics_update(delta: float) -> void:
	# velocity.y < 0：正在上升
	# velocity.y > 0：正在下落
	if character.velocity.y > 0.0:
		character.velocity.y += gravity * fall_gravity_multiplier * delta
	else:
		character.velocity.y += gravity * delta

	var input_axis := Input.get_axis("left", "right")
	character.velocity.x = input_axis * jump_move_velocity

	character.move_and_slide()

	if character.is_on_floor():
		character._play_jump_sound()

		if not is_zero_approx(character.velocity.x):
			transition_requested.emit("Walk")
		else:
			transition_requested.emit("Idle")


func exit() -> void:
	print("离开jump状态")
