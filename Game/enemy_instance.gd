extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -400.0


var direction = Vector2(0.0,0.0);
var count = 0;

func random_direction() -> Vector2:
	return Vector2((randi() % 3) * 1.0 - 1.0,0.0);
	

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if randi() % 100 == 0 and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if(count == 0 || direction.length() < 1e-7):
		direction = random_direction();
		count = 0;
	
	if direction && abs(velocity.x) < 1e-7:
		velocity.x = self.direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	count += 1;
	
	if count >= 12:
		count = 0;
	move_and_slide()
