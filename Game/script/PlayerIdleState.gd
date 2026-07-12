extends State

# 从项目设置中获取全局重力
@export var gravity: float = ProjectSettings.get_setting(
	"physics/2d/default_gravity"
)

# 下落时的重力倍率
@export var fall_gravity_multiplier: float = 1.8


func enter() -> void:
	print(character.name)
	print("进入idle状态")

	# 只清除水平速度，不要清除纵向速度
	# 否则玩家在空中进入 Idle 时，下落速度会被重置为 0
	character.velocity.x = 0.0


func exit() -> void:
	print("离开idle状态")


func process_update(_delta: float) -> void:
	character.anim_sprite.play("idle")

	# 左右移动
	if Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		transition_requested.emit("Walk")
		return

	# 跳跃
	if Input.is_action_just_pressed("jump") and character.is_on_floor():
		transition_requested.emit("Jump")
		return


func physics_update(delta: float) -> void:
	# 玩家不在地面时，继续进行快速下落
	if not character.is_on_floor():
		character.velocity.y += gravity * fall_gravity_multiplier * delta

	character.move_and_slide()
