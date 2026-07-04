extends State

enum Axis { HORIZONTAL, VERTICAL }

@export var move_axis: int = Axis.HORIZONTAL
@export var positive_direction: bool = true
@export var max_distance: float = 200.0
@export_range(0.0, 1.0) var initial_percent: float = 0.0
@export var speed: float = 100.0
@export var rotate_speed: float = 6.0  # 弧度/秒

var start_pos: Vector2
var direction: int
var _sprite: Sprite2D
var _mat: ShaderMaterial
var _angle: float = 0.0
var _initialized: bool = false


func enter() -> void:
	character.velocity = Vector2.ZERO


func physics_update(delta: float) -> void:
	if not _initialized:
		_initialized = true
		_sprite = character.get_node_or_null("Sprite2D")
		if _sprite and _sprite.material is ShaderMaterial:
			_mat = _sprite.material
		start_pos = character.global_position
		direction = 1 if positive_direction else -1
		var offset: float = max_distance * clamp(initial_percent, 0.0, 1.0)
		var axis_vec0: Vector2 = Vector2.RIGHT if move_axis == Axis.HORIZONTAL else Vector2.DOWN
		character.global_position = start_pos + axis_vec0 * offset

	var axis_vec: Vector2 = Vector2.RIGHT if move_axis == Axis.HORIZONTAL else Vector2.DOWN
	var step: float = speed * delta * direction
	var pos_along: float = (character.global_position - start_pos).dot(axis_vec)
	var next_along: float = pos_along + step

	# 到达端点：夹到端点并反向，避免超调造成物理碰撞偏移
	if direction > 0 and next_along >= max_distance:
		var cur: Vector2 = character.global_position
		character.global_position = start_pos + axis_vec * max_distance + (cur - start_pos - axis_vec * pos_along)
		direction = -1
		character.velocity = Vector2.ZERO
	elif direction < 0 and next_along <= 0.0:
		var cur: Vector2 = character.global_position
		character.global_position = start_pos + (cur - start_pos - axis_vec * pos_along)
		direction = 1
		character.velocity = Vector2.ZERO
	else:
		character.velocity = axis_vec * direction * speed
		character.move_and_slide()

	if _mat:
		_angle += rotate_speed * delta
		_mat.set_shader_parameter("rotation_angle", _angle)
