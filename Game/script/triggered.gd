extends State


func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func process_update(delta :float) -> void:
	character.triggered = true
	print("triggered")
	
	
func physics_update(delta: float) -> void:
	pass
