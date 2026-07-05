extends State

const JUMP_VELOCITY = -400.0

@export var speed : float;
@export var distRange: float;
@export var y_tolerance: float = 60.0  # 玩家与怪物Y轴差距小于此值才视为同一水平线
@export var reverse_interval: float = 3.0  # 反转方向的间隔秒数


var direction = Vector2(1.0, 0.0);
var count = 0;

var frameCount = 0.0;
var _reverse_timer: float = 0.0


func random_direction() -> Vector2:
	return Vector2((randi() % 3) * 1.0 - 1.0,0.0);


func enter() -> void:
	character.velocity = direction * speed;
	_reverse_timer = 0.0
	_update_sprite_flip()


func _update_sprite_flip() -> void:
	var sprite: AnimatedSprite2D = character.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.flip_h = direction.x < 0


func process_update(delta: float) -> void:
	pass

func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	character.move_and_slide()

	# 每 reverse_interval 秒反转移动方向
	_reverse_timer += delta
	if _reverse_timer >= reverse_interval:
		_reverse_timer = 0.0
		direction.x = -direction.x
		character.velocity = direction * speed
		_update_sprite_flip()

	var player: Node2D = _get_player()
	if not player:
		return
	var d: Vector2 = player.global_position - character.global_position
	var dist: float = d.length()

	# 必须在同一水平线（Y 轴差距小于阈值）且在距离范围内才会冲锋
	var on_same_level: bool = abs(d.y) < y_tolerance
	if dist < distRange + 1e-7 and on_same_level:
		if character.anim_sprite:
			character.anim_sprite.play("冲刺预备")
			await character.anim_sprite.animation_finished
			character.anim_sprite.play("冲刺")
		transition_requested.emit("Locate");
