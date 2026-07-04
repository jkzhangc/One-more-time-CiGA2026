extends State

@export var speed : float;
# 切换方向秒数
@export var frameCountmax: float;

var direction = Vector2(0.0,0.0);
var count = 0;

var frameCount = 0.0;


func enter() -> void:
	character.velocity = Vector2(0.0, 1.0) * speed;
	pass
	

func process_update(delta: float) -> void:
	pass
	
func physics_update(delta: float) -> void:

	frameCount += delta
	
	if frameCount > frameCountmax:
		frameCount -= frameCountmax;
		character.velocity.y *= -1.0;
	
	character.move_and_slide()
