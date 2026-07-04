extends Node2D

@export_enum("水平", "垂直") var move_axis: int = 0
@export var positive_direction: bool = true
@export var max_distance: float = 200.0
@export_range(0.0, 1.0) var initial_percent: float = 0.0
@export var speed: float = 100.0
@export_enum("全部", "上", "下", "左", "右") var contact_direction: int = 0


func _ready() -> void:
	var instance: Node2D = get_child(0)
	var machine: StateMachine = null
	var normal: Node = null
	for child in instance.get_children():
		if child is StateMachine:
			machine = child
	if machine:
		for child in machine.get_children():
			if child.name == "Normal":
				normal = child
				break
	if normal:
		normal.move_axis = move_axis
		normal.positive_direction = positive_direction
		normal.max_distance = max_distance
		normal.initial_percent = initial_percent
		normal.speed = speed

	_apply_contact_shape(instance)


func _apply_contact_shape(instance: Node2D) -> void:
	var cs: CollisionShape2D = instance.get_node_or_null("CollisionShape2D")
	if not cs:
		return
	var original: RectangleShape2D = cs.shape as RectangleShape2D
	if not original:
		return
	var full_size: Vector2 = original.size
	var new_shape := RectangleShape2D.new()
	var new_pos: Vector2 = Vector2.ZERO
	match contact_direction:
		1: # 上：高度减半，向上偏移
			new_shape.size = Vector2(full_size.x, full_size.y / 2.0)
			new_pos = Vector2(0, -full_size.y / 4.0)
		2: # 下
			new_shape.size = Vector2(full_size.x, full_size.y / 2.0)
			new_pos = Vector2(0, full_size.y / 4.0)
		3: # 左
			new_shape.size = Vector2(full_size.x / 2.0, full_size.y)
			new_pos = Vector2(-full_size.x / 4.0, 0)
		4: # 右
			new_shape.size = Vector2(full_size.x / 2.0, full_size.y)
			new_pos = Vector2(full_size.x / 4.0, 0)
		_: # 全部
			new_shape.size = full_size
			new_pos = Vector2.ZERO
	cs.shape = new_shape
	cs.position = new_pos
