extends State

# 从项目设置里获取全局重力，这样代码更具移植性
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func enter() -> void:
	print("进入死亡状态")
	character.velocity = Vector2.ZERO
	character.anim_sprite.play("die")
	
func exit() -> void:
	print("离开死亡状态")

func process_update(delta :float) -> void:
	pass
		
func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	character.move_and_slide()
