extends State

const JUMP_VELOCITY = -400.0

@export var speed : float;


var direction = Vector2(0.0,0.0);
var count = 0;

var frameCount = 0.0;

func random_direction() -> Vector2:
	return Vector2((randi() % 3) * 1.0 - 1.0,0.0);


func enter() -> void:
	var area2D = null
	for child in character.get_children():
		if child is Area2D:
			area2D = child
	if area2D:
		area2D.get_children()[0].set_deferred("disabled", false)

func exit() -> void:
	# 不在 exit 关闭刺碰撞体——
	# 如果是 Spike→Freeze，刺应保持开启（冻结在刺出状态仍会伤到玩家）
	# Normal.enter() 会负责关闭
	pass

func process_update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	# Add the gravity.
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	character.move_and_slide()
	frameCount += delta

	if frameCount > 5.0:
		frameCount -= 5.0;
		character.anim_sprite.play("default")
		transition_requested.emit("Normal")
