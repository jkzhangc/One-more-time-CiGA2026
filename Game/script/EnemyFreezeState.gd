extends State

@export var consistenceFrame: float;

var framePassed: float = 0.0;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	
func enter() -> void:
	framePassed = consistenceFrame;
	var sprite: AnimatedSprite2D = character.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.speed_scale = 0.0

func exit() -> void:
	var sprite: AnimatedSprite2D = character.get_node_or_null("AnimatedSprite2D")
	if sprite:
		sprite.speed_scale = 1.0


func process_update(delta: float) -> void:
	if framePassed > 1e-7:
		framePassed -= delta;
	else:
		if last_state:
			transition_requested.emit(last_state.name); # 回到之前的状态
		
		
func physics_update(delta: float) -> void:
	pass
