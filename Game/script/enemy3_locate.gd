extends State


func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
	
func process_update(delta :float) -> void:
	character.located_direction = Vector2(character.get_parent().player.position.x - character.position.x,character.get_parent().player.position.y - character.position.y).normalized()
	self.transition_requested.emit("Rush");
	
func physics_update(delta: float) -> void:
	pass
