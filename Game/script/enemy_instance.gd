extends CharacterBody2D

@onready var anim_sprite: Node = get_node_or_null("AnimatedSprite2D")
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


# 尖刺柱的 Area2D 刺碰撞体检测到玩家时调用
func _on_spike_area_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return
	# 刺中玩家（冻结在 Spike 状态时刺碰撞体保持开启，依然会受伤）
	body.take_damage(1)
	# 把玩家弹起来（站在刺上的效果）
	if body is CharacterBody2D:
		body.velocity.y = -400.0		
