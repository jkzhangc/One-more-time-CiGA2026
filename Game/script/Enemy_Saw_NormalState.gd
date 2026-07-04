extends State

enum Axis { HORIZONTAL, VERTICAL }

@export var move_axis: int = Axis.HORIZONTAL
@export var positive_direction: bool = true
@export var max_distance: float = 200.0
@export_range(0.0, 1.0) var initial_percent: float = 0.0
@export var speed: float = 100.0

var start_pos: Vector2
var direction: int
var _initialized: bool = false


func enter() -> void:
	var sprite: AnimatedSprite2D = character.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("default")
	character.velocity = Vector2.ZERO


func physics_update(_delta: float) -> void:
	if not _initialized:
		_initialized = true
		start_pos = character.global_position
		direction = 1 if positive_direction else -1
		var offset: float = max_distance * clamp(initial_percent, 0.0, 1.0)
		var axis_vec: Vector2 = Vector2.RIGHT if move_axis == Axis.HORIZONTAL else Vector2.DOWN
		character.global_position = start_pos + axis_vec * offset

	var axis_vec: Vector2 = Vector2.RIGHT if move_axis == Axis.HORIZONTAL else Vector2.DOWN
	character.velocity = axis_vec * direction * speed
	character.move_and_slide()

	var pos_along: float = (character.global_position - start_pos).dot(axis_vec)
	if direction > 0 and pos_along >= max_distance:
		character.global_position = start_pos + axis_vec * max_distance
		direction = -1
	elif direction < 0 and pos_along <= 0.0:
		character.global_position = start_pos
		direction = 1
