extends CharacterBody2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var mode: int = 0
@export var typename: String
func random_direction() -> Vector2:
	return Vector2((randi() % 3) * 1.0 - 1.0,0.0);
	
	
func _ready() -> void:
	print(anim_sprite)

func _physics_process(delta: float) -> void:
	pass;
