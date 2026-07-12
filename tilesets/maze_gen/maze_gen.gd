@tool
extends TileMapLayer
class_name MazeGen


var starting_pos = Vector2i()
const main_layer = 0
# const normal_wall_atlas_coords = Vector2i(10, 1)
# const walkable_atlas_coords = Vector2i(9, 4)
const SOURCE_ID = 0
var spot_to_letter = {}
var spot_to_label = {}
var current_letter_num = 65
@export var grid_size: float = 32
@export var source: Vector2i = Vector2i(6, 1)

@export var y_dim: int = 35
@export var x_dim: int = 35
@export var starting_coords = Vector2i(0, 0)
@export var valve_percentage: float = 20
@export var pipes: Array[Vector2i]
@export var generate: bool = false: 
	set(_value): 
		clear()
		maze = []
		for y in range(y_dim + 1):
			maze.append([])
			for x in range(x_dim + 1):
				maze[y].append(0)
		place_border()
		dfs(starting_coords)
		generate_pipes()
		generate = false




var maze = []

var adj4 = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]


func generate_pipes(): 
	for y in range(y_dim + 1): 
		for x in range(x_dim + 1): 
			var cell: int = maze[y][x]
			if cell == 0: 
				var left_connection: bool = not (x == 0 or (x > 0 and maze[y][x - 1] == 1))
				var right_connection: bool = not (x == (x_dim) or (x < x_dim and maze[y][x + 1] == 1))
				var top_connection: bool = not (y == 0 or (y > 0 and maze[y - 1][x] == 1))
				var bottom_connection: bool = not (y == y_dim or (y < y_dim and maze[y + 1][x] == 1))

				# Single connections
				if left_connection and not (right_connection or top_connection or bottom_connection): 
					set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
				if right_connection and not (left_connection or top_connection or bottom_connection): 
					set_cell(Vector2i(x, y), 0, Vector2i(0, 1))
				if top_connection and not (left_connection or right_connection or bottom_connection): 
					set_cell(Vector2i(x, y), 0, Vector2i(1, 1))
				if bottom_connection and not (left_connection or right_connection or top_connection): 
					set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
				# Double connections (straight lines)
				if top_connection and bottom_connection and not (left_connection or right_connection): 
					if randf_range(0, 100) < valve_percentage: 
						set_cell(Vector2i(x, y), 0, Vector2i(0, 2))
					else: 
						set_cell(Vector2i(x, y), 0, Vector2i(5, 2))
				if right_connection and left_connection and not (top_connection or bottom_connection): 
					if randf_range(0, 100) < valve_percentage: 
						set_cell(Vector2i(x, y), 0, Vector2i(1, 2))
					else: 
						set_cell(Vector2i(x, y), 0, Vector2i(5, 0))
				# Double connections (corners)
				if right_connection and bottom_connection and not (left_connection or top_connection): 
					set_cell(Vector2i(x, y), 0, Vector2i(2, 0))
				if right_connection and top_connection and not (left_connection or bottom_connection): 
					set_cell(Vector2i(x, y), 0, Vector2i(2,2))
				if left_connection and bottom_connection and not (right_connection or top_connection): 
					set_cell(Vector2i(x, y), 0, Vector2i(4, 0))
				if left_connection and top_connection and not (right_connection or bottom_connection): 
					set_cell(Vector2i(x, y), 0, Vector2i(4,2))
				# Triple connections (T-junctions)
				if left_connection and right_connection and bottom_connection and not top_connection:
					set_cell(Vector2i(x, y), 0, Vector2i(3, 0))
				if left_connection and right_connection and top_connection and not bottom_connection:
					set_cell(Vector2i(x, y), 0, Vector2i(3, 2))
				if left_connection and top_connection and bottom_connection and not right_connection:
					set_cell(Vector2i(x, y), 0, Vector2i(4, 1))
				if right_connection and top_connection and bottom_connection and not left_connection:
					set_cell(Vector2i(x, y), 0, Vector2i(2, 1))
				# Quad connections (crossroads)
				if left_connection and right_connection and top_connection and bottom_connection:
					set_cell(Vector2i(x, y), 0, Vector2i(3, 1))
				


func _input(event: InputEvent) -> void:
	pass
#	if Input.is_action_just_pressed("reset"):
#		get_tree().reload_current_scene()
	
	
func place_border():
	for y in range(-1, y_dim):
		place_wall(Vector2(-1, y))
	for x in range(-1, x_dim):
		place_wall(Vector2(x, -1))
	for y in range(-1, y_dim + 1):
		place_wall(Vector2(x_dim, y))
	for x in range(-1, x_dim + 1):
		place_wall(Vector2(x, y_dim))


func delete_cell_at(pos: Vector2):
	maze[pos.y][pos.x] = 0
	# set_cell(pos, -1)
	
	
func place_wall(pos: Vector2):
	maze[pos.y][pos.x] = 1
	# set_cell(pos, SOURCE_ID, source)


func will_be_converted_to_wall(spot: Vector2i):
	return (spot.x % 2 == 1 and spot.y % 2 == 1)
	
	
func is_wall(pos):
	return get_cell_atlas_coords(pos) == Vector2i(0, 0);


func can_move_to(current: Vector2i):
	return (
			current.x >= 0 and current.y >= 0 and\
			current.x < x_dim and current.y < y_dim and\
			not is_wall(current)
	)


func dfs(start: Vector2i):
	var fringe: Array[Vector2i] = [start]
	var seen = {}
	while fringe.size() > 0:
		var current: Vector2i 
		current = fringe.pop_back() as Vector2
			
		seen[current] = true
		if current in spot_to_label:
			for node in spot_to_label[current]:
				node.queue_free()
##			var existing_letter = find_child(spot_to_letter[current])
#			if existing_letter != null:
#				existing_letter.queue_free()
		if current.x % 2 == 1 and current.y % 2 == 1:
			place_wall(current)
			continue
			
		set_cell(current, SOURCE_ID)
		
		var found_new_path = false
		adj4.shuffle()
		for pos in adj4:
			var new_pos = current + pos
			if new_pos not in seen and can_move_to(new_pos):
				var chance_of_no_loop = randi_range(1, 10)
				#if Globals.allow_loops:
				#	chance_of_no_loop = randi_range(1, 5)
				if will_be_converted_to_wall(new_pos) and chance_of_no_loop == 1:
					place_wall(new_pos)
				else:
					found_new_path = true
					fringe.append(new_pos)
					
		#if we hit a dead end or are at a cross section
		if not found_new_path:
			place_wall(current)
