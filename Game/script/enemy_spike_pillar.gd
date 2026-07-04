extends Node2D
# 尖刺出现随机时长 x=最小随机数,y=最大随机数
@export var spike_show_rate: Vector2 = Vector2(0.0,10.0);
# 尖刺消失随机时长 x=最小随机数,y=最大随机数
@export var spike_hied_rate: Vector2 = Vector2(0.0,10.0);


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 将上面的数值传给状态
	var machine = null
	var instance = get_children()[0]
	print(instance)
	for child in instance.get_children():
		if child is StateMachine:
			machine = child
	if machine:
		for child in machine.get_children():
			if child.name == "Normal":
				child.spike_show_rate = spike_show_rate
			if child.name == "Spike":
				child.spike_hied_rate = spike_hied_rate


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
