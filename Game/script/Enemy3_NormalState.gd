extends State

const JUMP_VELOCITY = -400.0

@export var speed : float;
@export var distRange: float;


var direction = Vector2(0.0,0.0);
var count = 0;

var frameCount = 0.0;

func random_direction() -> Vector2:
	return Vector2((randi() % 3) * 1.0 - 1.0,0.0);
	

func enter() -> void:
	character.velocity = Vector2(1.0, 0.0) * speed;
	pass
	

func process_update(delta: float) -> void:
	pass
	
func physics_update(delta: float) -> void:
	
	var d = Vector2(character.get_parent().player.position.x - character.position.x,character.get_parent().player.position.y - character.position.y);
	var dist = sqrt(d.dot(d));

	if dist < distRange + 1e-7:
		character.anim_sprite.play("冲刺预备")
		await character.anim_sprite.animation_finished
		character.anim_sprite.play("冲刺")
		transition_requested.emit("Locate");
