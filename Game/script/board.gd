extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var triggered = false;


func _physics_process(delta: float) -> void:
	pass


func transition(nxtState: String) -> void:
	$StateMachine._on_transition_requested(nxtState);
