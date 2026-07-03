extends State

const SPEED = 200.0
const JUMP_VELOCITY = -400.0


var direction = Vector2(0.0,0.0);
var count = 0;

func random_direction() -> Vector2:
	return Vector2((randi() % 3) * 1.0 - 1.0,0.0);
	

func process_update(delta: float) -> void:
	pass
	
func physics_update(delta: float) -> void:
	# Add the gravity.
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta

	# Handle jump.
	if randi() % 100 == 0 and character.is_on_floor():
		character.velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if(count == 0 || direction.length() < 1e-7):
		direction = random_direction();
		count = 0;
	
	if direction && abs(character.velocity.x) < 1e-7:
		character.velocity.x = direction.x * SPEED
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, SPEED)

	count += 1;
	
	if count >= 12:
		count = 0;
	character.move_and_slide()
