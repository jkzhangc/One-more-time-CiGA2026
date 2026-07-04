extends State

@export var consistenceFrame: float;

var framePassed: float = 0.0;
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	
func enter() -> void:
	framePassed = consistenceFrame;
	pass
	
func exit() -> void:
	pass


func process_update(delta: float) -> void:
	if framePassed > 1e-7:
		framePassed -= delta;
	else:
		transition_requested.emit(last_state); # 回到之前的状态
		
		
func physics_update(delta: float) -> void:
	pass
