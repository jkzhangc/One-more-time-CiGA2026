extends State


func enter() -> void:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		character.located_direction = (player.global_position - character.global_position).normalized()
	transition_requested.emit("Rush")

func exit() -> void:
	pass


func process_update(_delta :float) -> void:
	pass

func physics_update(_delta: float) -> void:
	if not character.is_on_floor():
		character.velocity += character.get_gravity() * _delta
	character.move_and_slide()
