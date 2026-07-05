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

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func physics_update(delta: float) -> void:
	var player: Node2D = _get_player()
	if not player:
		return
	var d: Vector2 = player.global_position - character.global_position
	var dist: float = d.length()

	if dist < distRange + 1e-7:
		if character.anim_sprite:
			character.anim_sprite.play("冲刺预备")
			await character.anim_sprite.animation_finished
			character.anim_sprite.play("冲刺")
		transition_requested.emit("Locate");
