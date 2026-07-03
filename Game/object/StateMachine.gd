class_name StateMachine extends Node

@export var initial_state: State

var states: Dictionary = {}
var current_state: State
var character: CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	character = get_parent() as CharacterBody2D
	
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.transition_requested.connect(_on_transition_requested);
			child.character = character;
	if initial_state:
		initial_state.enter();
		current_state = initial_state;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_state:
		current_state.process_update(delta);

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta);

func _on_transition_requested(nxtState : String) -> void:
	if not states.has(nxtState) or current_state.name == nxtState:
		return
	
	if current_state:
		current_state.exit();
		
	current_state = states[nxtState]
	if current_state:
		current_state.enter()
