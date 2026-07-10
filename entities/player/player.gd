extends CharacterBody2D

@export var move_speed: float = 400
@export var gravity: float = 1600
@export_group("Jump")
@export var jump_height: float = 192
@export var min_jump_height: float = 64
@export var grounded_rays: Node2D
@export var coyote_time: float = 0.1
@export_subgroup("Wall Jump")
@export var right_ray: RayCast2D
@export var left_ray: RayCast2D
@export_range(-180, 180) var wall_jump_angle: float = 30
@export var identical_jump_velocity: bool = true
@export var wall_jump_velocity: float
@export var wall_jump_uses: int = 5
@export var wall_jump_cooldown: float = 0.5
@export var sliding_gravity_cap: float = 200
@export_group("Grounded Physics")
@export var acceleration: float = 3200
@export var friction_scale: float = 0.2
@export_subgroup("Dash")
@export var dash_speed: float = 2400
@export var dash_damping_scale: float = 0.25
@export var dash_uses: int = 2
@export var dash_cooldown: float = 1.0
@export var require_ground_to_get_dash: bool = false
@export_group("Floating Physics")
@export var air_acceleration: float = 1600
@export var air_resistance_scale: float = 10

var _jump_velocity: float = 0
var _min_jump_velocity: float = 0
var _last_grounded: float
var _last_dashed: float
var _last_wall_jumped: float
var _dash_uses_left: int
var _wall_jump_uses_left: int
var _right_wall_jump_direction: Vector2
var _left_wall_jump_direction: Vector2

func _ready() -> void:
	# IF yk Jump Height
	# To calculate intial v to have jump height
	# vf^2=vi^2+2ax
	# 0=vi^2+2ax
	# sqrt(-2ax) but a isn't negative so sqrt(2ax)
	_jump_velocity = -sqrt(2 * jump_height * gravity)
	_min_jump_velocity = -sqrt(2 * min_jump_height * gravity)
	_last_grounded = coyote_time + 1 # Make sure that the game doesn't let you jump midair just because of loading time
	_dash_uses_left = dash_uses
	_right_wall_jump_direction = Vector2.UP.rotated(deg_to_rad(wall_jump_angle))
	_left_wall_jump_direction = Vector2.UP.rotated(deg_to_rad(-wall_jump_angle))
	print(_right_wall_jump_direction)
	if identical_jump_velocity: 
		wall_jump_velocity = abs(_jump_velocity)



func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	
	var grounded: bool = false
	
	for ray in grounded_rays.get_children(): 
		if ray.is_colliding(): 
			grounded = true
	
	var x_input: int = (1 if Input.is_action_pressed("right") else 0) - (1 if Input.is_action_pressed("left") else 0)
	
	if x_input != 0: 
		if Input.is_action_just_pressed("dash") and _dash_uses_left > 0: 
			velocity.x = x_input * dash_speed
			_dash_uses_left -= 1
		velocity.x = move_toward(velocity.x, x_input * move_speed, (acceleration if is_on_floor() else air_acceleration) * delta)
	else: 
		velocity.x = lerp(velocity.x, 0.0, 1.0 - exp(-delta / (friction_scale if is_on_floor() else air_resistance_scale)))
	
	_last_dashed += delta * (1 if (grounded or not require_ground_to_get_dash) else 0)
	_last_wall_jumped += delta
	
	if _last_dashed >= dash_cooldown: 
		_last_dashed = 0
		_dash_uses_left = min(_dash_uses_left + 1, dash_uses)
	
	if abs(velocity.x) > move_speed: 
		velocity.x = lerp(velocity.x, move_speed, 1.0 - exp(-delta / dash_damping_scale))
	
	_last_grounded = 0 if grounded else _last_grounded + delta # Start ticking timer up when the rays stop colliding
	
	if _wall_jump_uses_left > 0 and _last_wall_jumped > wall_jump_cooldown: 
		if Input.is_action_just_pressed("up") and x_input == -1 and left_ray.is_colliding(): 
			velocity = _right_wall_jump_direction * wall_jump_velocity
			_wall_jump_uses_left -= 1
			_last_wall_jumped = 0
		
		if Input.is_action_just_pressed("up") and x_input == 1 and right_ray.is_colliding(): 
			velocity = _left_wall_jump_direction * wall_jump_velocity
			_wall_jump_uses_left -= 1
			_last_wall_jumped = 0
	
	if (x_input == -1 and left_ray.is_colliding()) or (x_input == 1 and right_ray.is_colliding()): 
		velocity.y = min(velocity.y, sliding_gravity_cap)
	
	if grounded: 
		_wall_jump_uses_left = wall_jump_uses
		_last_wall_jumped = 0
	
	if Input.is_action_just_pressed("up") and _last_grounded < coyote_time: 
		velocity.y = _jump_velocity
	
	if Input.is_action_just_released("up") and velocity.y < _min_jump_velocity: 
		velocity.y = _min_jump_velocity
	
	move_and_slide()
