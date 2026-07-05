extends State
@export var speed : float;
# 切换方向秒数
@export var frameCountmax: float;

var frameCount = 0.0;


func enter() -> void:
	character.velocity = character.located_direction * speed;
	frameCount = 0.0;
	var sprite: AnimatedSprite2D = character.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.play("冲刺")
		# 根据冲锋方向水平翻转图像
		sprite.flip_h = character.located_direction.x < 0
	
func exit() -> void:
	pass
	
	
func process_update(delta :float) -> void:
	pass
	
func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * delta
	character.move_and_slide();
	frameCount += delta;
	if frameCount > frameCountmax + 1e-7:
		character.anim_sprite.play("default")
		transition_requested.emit("Normal");
