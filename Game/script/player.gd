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
	print("玩家触碰了",body)
	
	# 获取敌人状态机
	var enemyStateMachine = null
	if body:
		for child in body.get_children():
			if child as StateMachine:
				enemyStateMachine = child;
	
	if enemyStateMachine:
		# 成功获取了敌人状态机
		print(enemyStateMachine.current_state,enemyStateMachine.current_state.name)
		if enemyStateMachine.current_state.name == "Freeze":
		# 如果敌人状态处于时停状态
			print("#{body.name}正在时停状态")
			if body.name == "平台类怪物":
				print("#{body.name}是平台类怪物")
			if body.name == "形态类怪物":
				print("#{body.name}是形态类怪物")
			if body.name == "冲锋类怪物":
				print("#{body.name}是冲锋类怪物")
		else:
		# 如果敌人状态不处于时停状态
			hit.emit() # 发送hit信号
			hide() # 隐藏玩家
			#$CollisionShape2D.set_deferred("disabled", true) # 取消碰撞体效果
		
		

# 重置玩家的状态
func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false
	$StateMachine._on_transition_requested("Idle")
