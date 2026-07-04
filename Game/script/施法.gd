extends State

# 从项目设置里获取全局重力，这样代码更具移植性
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func enter() -> void:
	print("进入施法状态")
	character.velocity = Vector2.ZERO
	
	
func exit() -> void:
	print("离开施法状态")

func process_update(delta :float) -> void:
	character.anim_sprite.play("施法")
	await character.anim_sprite.animation_finished
	transition_requested.emit("Idle")
		
func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	character.move_and_slide()
