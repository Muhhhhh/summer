extends CharacterBody2D
class_name Player

@export_group("Combat")
@export var max_hp: float = 3
@export var weapon: Weapon
@export_group("Aerial Physics")
@export var gravity: float = 6400
@export_subgroup("Jump")
@export var jump_height: float = 768
@export var min_jump_height: float = 256
@export var grounded_rays: Node2D
@export var coyote_time: float = 0.1
@export_subgroup("Wall Jump")
@export var right_rays: Node2D
@export var left_rays: Node2D
@export_range(-180, 180) var wall_jump_angle: float = 30
@export var identical_jump_velocity: bool = true
@export var wall_jump_velocity: float
@export var wall_jump_uses: int = 5
@export var wall_jump_cooldown: float = 0.5
@export var sliding_gravity_cap: float = 800
@export_group("Grounded Physics")
@export var move_speed: float = 1600
@export var acceleration: float = 12800
@export var friction_scale: float = 0.2
@export_subgroup("Dash")
@export var dash_speed: float = 9600
@export var dash_damping_scale: float = 0.25
@export var dash_uses: int = 2
@export var dash_cooldown: float = 1.0
@export var require_ground_to_get_dash: bool = false
@export_group("Floating Physics")
@export var air_acceleration: float = 6400
@export var air_resistance_scale: float = 10

@onready var hp: float = max_hp

var _jump_velocity: float = 0
var _min_jump_velocity: float = 0
var _last_grounded: float
var _last_dashed: float
var _last_wall_jumped: float
var _dash_uses_left: int
var _wall_jump_uses_left: int
var _right_wall_jump_direction: Vector2
var _left_wall_jump_direction: Vector2

var grounded: bool = false
var left_colliding: bool = false
var right_colliding: bool = false

func _ready() -> void:
	Globals.player = self
	_jump_velocity = -sqrt(2 * jump_height * gravity)
	_min_jump_velocity = -sqrt(2 * min_jump_height * gravity)
	_last_grounded = coyote_time + 1 # Make sure that the game doesn't let you jump midair just because of loading time
	_dash_uses_left = dash_uses
	_right_wall_jump_direction = Vector2.UP.rotated(deg_to_rad(wall_jump_angle))
	_left_wall_jump_direction = Vector2.UP.rotated(deg_to_rad(-wall_jump_angle))
	if identical_jump_velocity: 
		wall_jump_velocity = abs(_jump_velocity)

var right_particles_timer: float = 0.0
var left_particles_timer: float = 0.0

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	_check_rays()
	
	# left input is -1, right input is 1, and no input/both left and right is 0
	var x_input: int = (1 if Input.is_action_pressed("right") else 0) - (1 if Input.is_action_pressed("left") else 0)
	
	_handle_run(x_input, delta)
	_handle_timers(delta)
	_handle_wall_jump(x_input)
	_handle_jump()

	# delete this when you have actual animations
	$Polygon2D.rotation_degrees = clamp(velocity.x / move_speed * 10, -20, 20)
	$GroundParticles.emitting = grounded and abs(velocity.x) >= move_speed * 0.5
	$"Dash Trail".emitting = abs(velocity.x) > move_speed * 2
	if $RightParticles.emitting: 
		right_particles_timer += delta
		if right_particles_timer >= 0.1: 
			$RightParticles.emitting = false
			right_particles_timer = 0.0
	if $LeftParticles.emitting:
		left_particles_timer += delta
		if left_particles_timer >= 0.1: 
			$LeftParticles.emitting = false
			left_particles_timer = 0.0

	move_and_slide()


func _handle_jump() -> void: 
	# Jump if you are within coyote time and the jump button is pressed
	if Input.is_action_just_pressed("up") and _last_grounded < coyote_time: 
		velocity.y = _jump_velocity
	
	# If you release the jump button while going up, set the velocity to the minimum jump velocity to allow for variable jump height
	if Input.is_action_just_released("up") and velocity.y < _min_jump_velocity: 
		velocity.y = _min_jump_velocity


func _handle_wall_jump(x_input: int) -> void: 
	# Wall jump if you have uses left and the cooldown has passed
	if _wall_jump_uses_left > 0 and _last_wall_jumped > wall_jump_cooldown: 
		if Input.is_action_just_pressed("up") and x_input == -1 and left_colliding: 
			velocity = _right_wall_jump_direction * wall_jump_velocity
			_wall_jump_uses_left -= 1
			_last_wall_jumped = 0
			$LeftParticles.emitting = true
		
		if Input.is_action_just_pressed("up") and x_input == 1 and right_colliding: 
			velocity = _left_wall_jump_direction * wall_jump_velocity
			_wall_jump_uses_left -= 1
			_last_wall_jumped = 0
			$RightParticles.emitting = true
	
	# Slide on walls if you're "moving" into them
	if (x_input == -1 and left_colliding) or (x_input == 1 and right_colliding): 
		velocity.y = min(velocity.y, sliding_gravity_cap)
	
	# Reset wall jump uses if grounded
	if grounded: 
		_wall_jump_uses_left = wall_jump_uses
		_last_wall_jumped = 0


func _handle_run(x_input: int, delta: float) -> void: 
	if x_input != 0: 
		if Input.is_action_just_pressed("dash") and _dash_uses_left > 0: # Set the velocity to the dash speed if the player presses the dash button and has uses left
			velocity.x = x_input * dash_speed
			_dash_uses_left -= 1
		elif abs(velocity.x) < move_speed or velocity.x * x_input < 0: # If the player is moving slower than the max speed, accelerate them towards the input direction
			velocity.x = move_toward(velocity.x, x_input * move_speed, (acceleration if is_on_floor() else air_acceleration) * delta)
	else: # If the player isn't pressing any input, dampen the horizontal velocity to simulate friction or air resistance
		velocity.x = lerp(velocity.x, 0.0, 1.0 - exp(-delta / (friction_scale if is_on_floor() else air_resistance_scale)))
	
	# Dampen the horizontal velocity if it exceeds the move speed (to limit dash time)
	if abs(velocity.x) > move_speed: 
		velocity.x = lerp(velocity.x, move_speed, 1.0 - exp(-delta / dash_damping_scale))


func _handle_timers(delta: float) -> void: 
	# Only count down the dash cooldown if the player is grounded or if the player doesn't need to be grounded to get dash uses back
	if grounded or not require_ground_to_get_dash:
		_last_dashed += delta
	
	# Increment the wall jump and grounded timers
	_last_wall_jumped += delta
	_last_grounded += delta
	
	if _last_dashed >= dash_cooldown: 
		_last_dashed = 0
		_dash_uses_left = min(_dash_uses_left + 1, dash_uses)
	
	
	if grounded: 
		_last_grounded = 0	


func _check_rays() -> void: 
	# Iterate through all the rays and set the grounded, left_colliding, and right_colliding variables based on whether any ray is colliding
	grounded = false
	
	for ray in grounded_rays.get_children(): 
		if ray.is_colliding(): 
			grounded = true
	
	left_colliding = false
	right_colliding = false

	for ray in left_rays.get_children(): 
		if ray.is_colliding(): 
			left_colliding = true

	for ray in right_rays.get_children(): 
		if ray.is_colliding(): 
			right_colliding = true


func damaged(amount: float) -> void: 
	hp -= amount
	if hp <= 0: 
		print("Player has died!") # TODO: Add death logic
