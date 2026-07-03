extends CharacterBody2D


func random_direction() -> Vector2:
	return Vector2((randi() % 3) * 1.0 - 1.0,0.0);
	
	
func _ready() -> void:
	pass;

func _physics_process(delta: float) -> void:
	pass;
