extends State

var direction = Vector2(0.0,0.0);
var count = 0;

var frameCount = 0.0;

@export var radius: float = 120.0
@export var speed: float = 2.0
@export var center: Vector2 = Vector2.ZERO

var angle: float = 0.0

func _process(delta: float) -> void:
	pass

func enter() -> void:
	#character.velocity = Vector2(1.0, 0.0) * speed;
	pass
	

func process_update(delta: float) -> void:
	pass

	#target.position = center + Vector2(x, y)
	
func physics_update(delta: float) -> void:

	angle += speed * delta

	var x := cos(angle) * radius
	var y := sin(angle) * radius
	character.velocity = center + Vector2(x, y)
	
	character.move_and_slide()
