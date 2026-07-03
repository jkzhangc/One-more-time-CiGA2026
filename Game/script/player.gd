extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

signal hit

func collision_check(delta :float) -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i);
		
		
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	collision_check(delta);
	move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	# 这里做玩家触碰的效果
	hit.emit() # 发送hit信号

# 重置玩家的状态
func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false
	$StateMachine._on_transition_requested("Idle")
