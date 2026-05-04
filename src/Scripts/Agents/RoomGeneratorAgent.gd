extends Node3D
class_name RoomGeneratorAgent

@export var wall_scene: PackedScene
@export var door_scene: PackedScene
@export var screen_scene: PackedScene
@export var safe_scene: PackedScene
@export var floor_scene: PackedScene
@export var table_scene: PackedScene
@export var chair_scene: PackedScene
@export var ceiling_light_scene: PackedScene
@export var pedestal_scene: PackedScene

# Puzzle Elements
@export var numpad_scene: PackedScene
@export var terminal_scene: PackedScene
@export var note_scene: PackedScene
@export var color_hint_scene: PackedScene
@export var color_btn_scene: PackedScene
@export var matrix_monitor_scene: PackedScene
@export var fuse_box_scene: PackedScene
@export var book_scene: PackedScene
@export var mug_scene: PackedScene

# Room properties
@export var room_size: Vector2 = Vector2(12, 12)
@export var room_b_offset: Vector3 = Vector3(100, 0, 0)

var room_a_spawn: Marker3D
var room_b_spawn: Marker3D

func _ready() -> void:
	if not wall_scene:
		push_error("Wall scene not assigned to RoomGeneratorAgent.")
		return
		
	generate_room_a()
	generate_room_b()

func generate_room_a() -> void:
	var room_a_root = Node3D.new()
	room_a_root.name = "RoomA"
	add_child(room_a_root)
	
	build_walls_and_floor(room_a_root)
	
	room_a_spawn = Marker3D.new()
	room_a_spawn.name = "SpawnPlayer1"
	room_a_spawn.position = Vector3(room_size.x / 2.0, 1.0, room_size.y / 2.0 + 3.0)
	room_a_root.add_child(room_a_spawn)
	
	if ceiling_light_scene:
		var light = ceiling_light_scene.instantiate()
		room_a_root.add_child(light)
		light.position = Vector3(room_size.x / 2.0, 3.0, room_size.y / 2.0)
		
	if table_scene:
		var table = table_scene.instantiate()
		room_a_root.add_child(table)
		table.position = Vector3(room_size.x / 2.0, 0, room_size.y / 2.0)
		
		# Terminal
		if terminal_scene:
			var terminal = terminal_scene.instantiate()
			room_a_root.add_child(terminal)
			terminal.position = Vector3(room_size.x / 2.0 - 0.5, 1.0, room_size.y / 2.0)
			
		# Note with Label
		if note_scene:
			var note = note_scene.instantiate()
			room_a_root.add_child(note)
			note.position = Vector3(room_size.x / 2.0 + 0.3, 1.01, room_size.y / 2.0 + 0.2)
			
		# Matrix Monitor
		if matrix_monitor_scene:
			var monitor = matrix_monitor_scene.instantiate()
			room_a_root.add_child(monitor)
			monitor.position = Vector3(room_size.x / 2.0 + 0.6, 1.25, room_size.y / 2.0 - 0.2)
			
		# Mugs & Books on table
		if mug_scene:
			var mug1 = mug_scene.instantiate()
			room_a_root.add_child(mug1)
			mug1.position = Vector3(room_size.x / 2.0 - 0.8, 1.075, room_size.y / 2.0 + 0.3)
		if book_scene:
			var book1 = book_scene.instantiate()
			room_a_root.add_child(book1)
			book1.position = Vector3(room_size.x / 2.0 - 0.4, 1.025, room_size.y / 2.0 + 0.3)
			book1.rotation_degrees = Vector3(0, 15, 0)
			var book2 = book_scene.instantiate()
			room_a_root.add_child(book2)
			book2.position = Vector3(room_size.x / 2.0 - 0.4, 1.075, room_size.y / 2.0 + 0.3)
			book2.rotation_degrees = Vector3(0, -5, 0)
		
	if chair_scene:
		var chair = chair_scene.instantiate()
		room_a_root.add_child(chair)
		chair.position = Vector3(room_size.x / 2.0, 0, room_size.y / 2.0 - 1.0)
	
	if color_hint_scene:
		var hint = color_hint_scene.instantiate()
		room_a_root.add_child(hint)
		hint.position = Vector3(0.5, 1.5, room_size.y / 2.0)
		hint.rotation_degrees = Vector3(0, 90, 0)

func generate_room_b() -> void:
	var room_b_root = Node3D.new()
	room_b_root.name = "RoomB"
	room_b_root.position = room_b_offset
	add_child(room_b_root)
	
	build_walls_and_floor(room_b_root)
	
	room_b_spawn = Marker3D.new()
	room_b_spawn.name = "SpawnPlayer2"
	room_b_spawn.position = Vector3(room_size.x / 2.0, 1.0, room_size.y / 2.0 + 3.0)
	room_b_root.add_child(room_b_spawn)
	
	if ceiling_light_scene:
		var light = ceiling_light_scene.instantiate()
		room_b_root.add_child(light)
		light.position = Vector3(room_size.x / 2.0, 3.0, room_size.y / 2.0)
		
	if pedestal_scene:
		var pedestal = pedestal_scene.instantiate()
		room_b_root.add_child(pedestal)
		pedestal.position = Vector3(room_size.x / 2.0, 0, room_size.y / 2.0)
		
		# Put note on pedestal
		if note_scene:
			var note = note_scene.instantiate()
			room_b_root.add_child(note)
			note.position = Vector3(room_size.x / 2.0, 1.01, room_size.y / 2.0)
			
		# Scattered books on floor around pedestal
		if book_scene:
			var b1 = book_scene.instantiate()
			room_b_root.add_child(b1)
			b1.position = Vector3(room_size.x / 2.0 + 1.0, 0.025, room_size.y / 2.0)
			var b2 = book_scene.instantiate()
			room_b_root.add_child(b2)
			b2.position = Vector3(room_size.x / 2.0 - 0.8, 0.025, room_size.y / 2.0 + 0.5)
	
	if safe_scene:
		var safe = safe_scene.instantiate()
		room_b_root.add_child(safe)
		safe.position = Vector3(room_size.x / 2.0 + 2.0, 0, room_size.y - 1.5)
	
	if door_scene:
		var door = door_scene.instantiate()
		room_b_root.add_child(door)
		door.position = Vector3(room_size.x - 1.0, 0, room_size.y / 2.0)
		door.rotation_degrees = Vector3(0, 90, 0)
		
		# Place Numpad near door
		if numpad_scene:
			var numpad = numpad_scene.instantiate()
			room_b_root.add_child(numpad)
			numpad.position = Vector3(room_size.x - 0.5, 1.5, room_size.y / 2.0 - 1.5)
			numpad.rotation_degrees = Vector3(0, 90, 0)

	# Matrix Buttons Panel (FuseBox)
	if fuse_box_scene:
		var fusebox = fuse_box_scene.instantiate()
		room_b_root.add_child(fusebox)
		fusebox.position = Vector3(0.5, 1.5, room_size.y / 2.0 + 1.5)
		fusebox.rotation_degrees = Vector3(0, 90, 0)

	# Color Buttons Panel
	if color_btn_scene:
		var cbtn = color_btn_scene.instantiate()
		room_b_root.add_child(cbtn)
		cbtn.position = Vector3(0.5, 1.5, room_size.y / 2.0 - 1.5)
		cbtn.rotation_degrees = Vector3(0, 90, 0)

func build_walls_and_floor(parent: Node3D) -> void:
	if floor_scene:
		var floor_instance = floor_scene.instantiate()
		parent.add_child(floor_instance)
		floor_instance.position = Vector3(room_size.x / 2.0, -0.5, room_size.y / 2.0)
		floor_instance.scale = Vector3(room_size.x, 1, room_size.y)
	
	var wall_length = 4.0
	var x_pos = wall_length / 2.0
	while x_pos < room_size.x:
		var wall = wall_scene.instantiate()
		parent.add_child(wall)
		wall.position = Vector3(x_pos, 0, 0)
		x_pos += wall_length
		
	x_pos = wall_length / 2.0
	while x_pos < room_size.x:
		var wall = wall_scene.instantiate()
		parent.add_child(wall)
		wall.position = Vector3(x_pos, 0, room_size.y)
		x_pos += wall_length

	var z_pos = wall_length / 2.0
	while z_pos < room_size.y:
		var wall = wall_scene.instantiate()
		parent.add_child(wall)
		wall.position = Vector3(0, 0, z_pos)
		wall.rotation_degrees = Vector3(0, 90, 0)
		z_pos += wall_length
		
	z_pos = wall_length / 2.0
	while z_pos < room_size.y:
		var wall = wall_scene.instantiate()
		parent.add_child(wall)
		wall.position = Vector3(room_size.x, 0, z_pos)
		wall.rotation_degrees = Vector3(0, 90, 0)
		z_pos += wall_length
