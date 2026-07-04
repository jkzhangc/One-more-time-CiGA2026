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

func _get_state_machine() -> StateMachine:
	for child in get_children():
		if child is StateMachine:
			return child
	return null

func apply_anchor_state(duration: float) -> void:
	var sm := _get_state_machine()
	if not sm:
		return
	var freeze_state: State = sm.states.get("Freeze", null)
	if not freeze_state:
		return
	if sm.current_state and sm.current_state.name == "Freeze":
		freeze_state.framePassed = maxf(freeze_state.framePassed, duration)
		freeze_state.consistenceFrame = maxf(freeze_state.consistenceFrame, duration)
		return
	freeze_state.consistenceFrame = duration
	sm._on_transition_requested("Freeze")

func apply_gray_state(duration: float) -> void:
	apply_anchor_state(duration)
