extends Node2D

@export var cooldown: float = 2
@export var player_detector: Area2D
@export var speed: float = 200
@export var knockback: float = 1600
@export var aerial_knockback: float = 800
@export var hp: float = 4
@export var damage: float = 1
@export var damage_hitbox: Area2D
@export var stop_distance: float = 8

var target: Player
var velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	damage_hitbox.area_entered.connect(_damage_hit)
	player_detector.body_entered.connect(_player_detected)


func _physics_process(delta: float) -> void:
	if not target: 
		return
	if target.global_position.distance_squared_to(global_position) >= stop_distance: 
		velocity = global_position.direction_to(target.global_position) * speed
		global_position += velocity * delta


func _player_detected(body: Node) -> void:
	target = body


func damaged(amount: float) -> void:
	hp -= amount
	if hp <= 0: 
		print("Bat has died!") # TODO: Add death logic
		queue_free()



func _damage_hit(area: Area2D) -> void:
	if area.is_in_group("player"):
		area.body.velocity = global_position.direction_to(area.body.global_position) * (knockback if target.grounded else aerial_knockback)
		area.body.damaged(damage)
