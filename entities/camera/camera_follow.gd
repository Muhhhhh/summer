extends Camera2D

@export var target: Node2D
@export var box_size: Vector2 = Vector2(0, 0)
@export_enum("Linear", "Exponential") var follow_type: int = 1
@export_group("Linear")
@export var speed: float = 800
@export_group("Exponential")
@export var time_scale: float = 0.3

func _physics_process(delta: float) -> void:
	if abs(global_position.x - target.global_position.x) > box_size.x * 0.5: 
		global_position.x = lerp(global_position.x, target.global_position.x, 1 - exp(-delta / time_scale)) if follow_type == 1 else move_toward(global_position.x, target.global_position.x, speed * delta) 
	if abs(global_position.y - target.global_position.y) > box_size.y * 0.5: 
		global_position.y = lerp(global_position.y, target.global_position.y, 1 - exp(-delta / time_scale)) if follow_type == 1 else move_toward(global_position.y, target.global_position.y, speed * delta)
	
