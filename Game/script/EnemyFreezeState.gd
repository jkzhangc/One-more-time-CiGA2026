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
		print(character.name,"被冻结了")
		if character.get_parent().name == "形态类怪物":
			if character.get_node("StateMachine").last_state.name == "Normal":
				sprite.play("收缩形态冻结")
			if character.get_node("StateMachine").last_state.name == "MiddleJump":
				sprite.play("中形态冻结")
			if character.get_node("StateMachine").last_state.name == "HighJump":
				sprite.play("高形态冻结")
		else:
			sprite.play("冻结")

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
