extends State

const JUMP_VELOCITY = -400.0

@export var speed : float;
# 尖刺出现随机时长 x=最小随机数,y=最大随机数
@export var spike_show_rate: Vector2 = Vector2(0.0,10.0);

var direction = Vector2(0.0,0.0);
var count = 0;
var random_float = 0.0;
var frameCount = 0.0;

func random_direction() -> Vector2:
	return Vector2((randi() % 3) * 1.0 - 1.0,0.0);
	

func enter() -> void:
	var area2D = null
	for child in character.get_children():
		if child is Area2D:
			area2D = child
	if area2D:
		area2D.get_children()[0].set_deferred("disabled", true)
	random_float = randf_range(spike_show_rate.x, spike_show_rate.y)
	

func process_update(delta: float) -> void:
	pass
	
func physics_update(delta: float) -> void:
	# Add the gravity.
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	character.move_and_slide()
	frameCount += delta;
	
	if frameCount > random_float:
		frameCount -= random_float;
		character.anim_sprite.play("尖刺状态")
		transition_requested.emit("Spike")
	
