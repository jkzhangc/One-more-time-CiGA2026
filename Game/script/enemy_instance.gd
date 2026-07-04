extends CharacterBody2D

@onready var anim_sprite = $AnimatedSprite2D
@onready var mode: int = 0
@export var typename: String

var located_direction = Vector2(0.0,0.0)

func random_direction() -> Vector2:
	return Vector2((randi() % 3) * 1.0 - 1.0,0.0);
	
	
func _ready() -> void:
	self.position = get_parent().position
	get_parent().position = Vector2(0.0,0.0)
	print(anim_sprite)

func _physics_process(delta: float) -> void:
	pass;


func _on_body_entered(other : Node2D) -> void:
	if other.get_parent().name == "Player":
		pass
	
	if other.get_parent().name == "Board":
		other.transition("Triggered");
