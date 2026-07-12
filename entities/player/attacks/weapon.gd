extends Node2D
class_name Weapon

@export_group("Weapon Stats")
@export var damage: float = 4.0
@export var animation_player: AnimationPlayer
@export_group("Hitboxes")
@export var damage_hitbox: Area2D
@export var parry_hitbox: Area2D
@export_group("Player")
@export var use_parent: bool = true
@export var player: Node2D
@export var ignore_group: String = "player"
@export_group("Input")
@export var attack_input: String = "attack"
@export_group("Animation Names")
@export var side_attack: String = "side_attack"
@export var up_attack: String = "up_attack"
@export var down_attack: String = "down_attack"
@export var neutral_attack: String = "neutral_attack"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	damage_hitbox.area_entered.connect(_damage_hit)
	if use_parent:
		player = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("attack"):
		return
	
	var x_input: int = (1 if Input.is_action_pressed("right") else 0) - (1 if Input.is_action_pressed("left") else 0)
	var y_input: int = (1 if Input.is_action_pressed("down") else 0) - (1 if Input.is_action_pressed("up") else 0)

	if x_input != 0:
		scale.x = 1 if x_input > 0 else -1
		scale.y = 1
	
	if x_input != 0: 
		animation_player.play(side_attack)
	elif y_input == 1: 
		animation_player.play(down_attack)
	elif y_input == -1: 
		animation_player.play(up_attack)


func _damage_hit(area: Area2D) -> void: 
	if not area.is_in_group(ignore_group): 
		area.body.damaged(damage)
