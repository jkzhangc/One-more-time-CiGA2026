extends State

# 从项目设置里获取全局重力，这样代码更具移植性
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func enter() -> void:
	print(character.name)
	print("进入idle状态")
	character.velocity = Vector2.ZERO
	
	
func exit() -> void:
	print("离开idle状态")

func process_update(delta :float) -> void:
	character.anim_sprite.play("idle")
	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		transition_requested.emit("Walk")
		return
	if Input.is_action_pressed("jump"):
		transition_requested.emit("Jump")
		
func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	character.move_and_slide()
