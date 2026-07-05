extends State

@export var spike_hide_time: float = 1.0;


var frameCount = 0.0;


func enter() -> void:
	var area2D: Area2D = null
	for child in character.get_children():
		if child is Area2D:
			area2D = child
			break
	if area2D and area2D.get_child_count() > 0:
		area2D.get_child(0).set_deferred("disabled", false)

	frameCount = 0.0
	if character.anim_sprite:
		character.anim_sprite.play("尖刺状态")
		

func exit() -> void:
	# 不在 exit 关闭刺碰撞体——
	# 如果是 Spike→Freeze，刺应保持开启（冻结在刺出状态仍会伤到玩家）
	# Normal.enter() 会负责关闭
	pass

func process_update(_delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	#if not character.is_on_floor():
		#character.velocity += character.get_gravity() * delta
	#character.move_and_slide()
	frameCount += delta

	if frameCount > spike_hide_time:
		frameCount = 0.0
		if character.anim_sprite:
			character.anim_sprite.play("default")
		transition_requested.emit("Normal")
