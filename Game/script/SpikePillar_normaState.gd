extends State

@export var spike_show_time: float = 1.0;

var frameCount: float = 0.0;


func enter() -> void:
	var area2D: Area2D = null
	for child in character.get_children():
		if child is Area2D:
			area2D = child
			break
	if area2D and area2D.get_child_count() > 0:
		area2D.get_child(0).set_deferred("disabled", true)
	frameCount = 0.0
	if character.anim_sprite:
		character.anim_sprite.play("default")


func process_update(_delta: float) -> void:
	pass

func physics_update(delta: float) -> void:

	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	character.move_and_slide()
	frameCount += delta;

	if frameCount > spike_show_time:
		frameCount = 0.0
		if character.anim_sprite:
			character.anim_sprite.play("尖刺状态")
		transition_requested.emit("Spike")
