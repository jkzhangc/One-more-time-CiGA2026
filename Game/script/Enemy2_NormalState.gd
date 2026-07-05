extends State

const JUMP_VELOCITY = -400.0

@export var speed : float;


var direction = Vector2(0.0,0.0);
var count = 0;

var frameCount = 0.0;

func random_direction() -> Vector2:
	return Vector2((randi() % 3) * 1.0 - 1.0,0.0);
	

func enter() -> void:
	pass
	

func process_update(delta: float) -> void:
	pass
	
func physics_update(delta: float) -> void:
	# Add the gravity.
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	character.move_and_slide()
	frameCount += delta

	if frameCount > 1.0:
		frameCount -= 1.0;
		character.anim_sprite.play("中形态切换动画")
		await character.anim_sprite.animation_finished
		character.anim_sprite.play("中形态")
		transition_requested.emit("MiddleJump")
	
