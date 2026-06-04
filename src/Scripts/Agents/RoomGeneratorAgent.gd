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

# Elemente pentru puzzle-uri
@export var numpad_scene: PackedScene
@export var terminal_scene: PackedScene
@export var note_scene: PackedScene
@export var color_hint_scene: PackedScene
@export var color_btn_scene: PackedScene
@export var matrix_monitor_scene: PackedScene
@export var fuse_box_scene: PackedScene
@export var book_scene: PackedScene
@export var mug_scene: PackedScene

# Proprietățile camerei
@export var room_size: Vector2 = Vector2(12, 12)
@export var room_b_offset: Vector3 = Vector3(100, 0, 0)

var room_a_spawn: Marker3D
var room_b_spawn: Marker3D

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	if not wall_scene:
		push_error("Scena pentru perete (wall_scene) nu este atribuită în RoomGeneratorAgent.")
		return
		
	# --- ENVIRONMENT ÎNTUNECAT ---
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.05) # Foarte întunecat
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.05, 0.05, 0.05)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	# Dacă există soarele default, îl oprim complet
	var sun = get_parent().get_node_or_null("DirectionalLight3D")
	if sun:
		sun.light_energy = 0.02
		
	# Inițializăm cu un seed fix pentru testare. Pe viitor, acesta va fi primit de la NetworkManager.
	generate_rooms(12345)

var player1: Node3D
var player2: Node3D
var current_player = 1

func _input(event):
	# Apasă TAB pentru a schimba corpul!
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
		if current_player == 1 and player2:
			if player1.is_focused: player1.exit_focus()
			current_player = 2
			player1.is_active = false
			player2.is_active = true
			player2.camera.make_current()
			print("--- Ești Jucătorul 2 (Camera B) ---")
		elif current_player == 2 and player1:
			if player2.is_focused: player2.exit_focus()
			current_player = 1
			player2.is_active = false
			player1.is_active = true
			player1.camera.make_current()
			print("--- Ești Jucătorul 1 (Camera A) ---")

func generate_rooms(seed_value: int) -> void:
	rng.seed = seed_value
	print("[RoomGen] Se generează camerele procedural folosind seed-ul: ", seed_value)
	
	generate_room_a()
	generate_room_b()
	
	# --- LOCAL TEST MANAGER INJECTAT ---
	# Spawnăm jucătorii automat
	var player_scene = preload("res://Scenes/player.tscn")
	if player_scene:
		player1 = player_scene.instantiate()
		player1.name = "Player1"
		add_child(player1)
		player1.global_position = room_a_spawn.global_position
		player1.is_active = true

		player2 = player_scene.instantiate()
		player2.name = "Player2"
		add_child(player2)
		player2.global_position = room_b_spawn.global_position
		player2.is_active = false
		
		# Setam camera abia dupa ce amandoi au fost spawnati, ca sa evitam
		# situatia in care Player2 ii fura focusul lui Player1 cand e creat.
		current_player = 1
		player1.get_node("Camera3D").make_current()

# Returnează un array de poziții Vector3 sigure, care nu se suprapun, pentru obiectele de pe podea
func get_available_grid_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	# Folosim o grilă de 2x2, de la x=2 la x=10 și z=2 la z=10
	for x in range(2, int(room_size.x) - 1, 2):
		for z in range(2, int(room_size.y) - 1, 2):
			positions.append(Vector3(x, 0, z))
	return positions

# Returnează un array de dicționare cu transformări (poziție, rotație) pentru plasarea pe pereți
# Formatul returnat: {"pos": Vector3, "rot": Vector3}
func get_available_wall_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var spacing = 2.0
	var inset = 0.26 # Half wall thickness + small margin
	
	# Wall z=0 (North)
	for x in range(2, int(room_size.x) - 1, int(spacing)):
		slots.append({"pos": Vector3(x, 1.5, inset), "rot": Vector3(0, 0, 0)})
	# Wall z=room_size.y (South)
	for x in range(2, int(room_size.x) - 1, int(spacing)):
		slots.append({"pos": Vector3(x, 1.5, room_size.y - inset), "rot": Vector3(0, 180, 0)})
	# Wall x=0 (West)
	for z in range(2, int(room_size.y) - 1, int(spacing)):
		slots.append({"pos": Vector3(inset, 1.5, z), "rot": Vector3(0, 90, 0)})
	# Wall x=room_size.x (East)
	for z in range(2, int(room_size.y) - 1, int(spacing)):
		slots.append({"pos": Vector3(room_size.x - inset, 1.5, z), "rot": Vector3(0, -90, 0)})
		
	return slots

# Funcție utilitară pentru a plasa un obiect pe un slot de perete
func place_on_wall(scene: PackedScene, slots: Array[Dictionary], remove_slot: bool = true) -> Node3D:
	if not scene or slots.is_empty(): return null
	
	var slot_index = rng.randi_range(0, slots.size() - 1)
	var slot = slots[slot_index]
	if remove_slot:
		slots.remove_at(slot_index)
		
	var instance = scene.instantiate()
	instance.position = slot["pos"]
	instance.rotation_degrees = slot["rot"]
	return instance

# Funcție utilitară pentru a plasa un obiect pe grila podelei
func place_on_floor(scene: PackedScene, positions: Array[Vector3], remove_pos: bool = true) -> Node3D:
	if not scene or positions.is_empty(): return null
	
	var pos_index = rng.randi_range(0, positions.size() - 1)
	var pos = positions[pos_index]
	if remove_pos:
		positions.remove_at(pos_index)
		
	var instance = scene.instantiate()
	instance.position = pos
	
	# Rotim aleatoriu pe axa Y pentru varietate (în pași de 90 de grade)
	instance.rotation_degrees.y = rng.randi_range(0, 3) * 90.0
	
	return instance

# Plasează setul de mobilă (Birou) cu toate obiectele atașate
func place_table_set(parent: Node3D, grid: Array[Vector3]) -> void:
	if not table_scene or grid.is_empty(): return
	
	var pos_index = rng.randi_range(0, grid.size() - 1)
	var table_pos = grid[pos_index]
	grid.remove_at(pos_index)
	
	var table = table_scene.instantiate()
	parent.add_child(table)
	table.position = table_pos
	
	var table_rot = rng.randi_range(0, 3) * 90.0
	table.rotation_degrees.y = table_rot
	
	# Plasăm scaunul relativ față de birou
	if chair_scene:
		var chair = chair_scene.instantiate()
		parent.add_child(chair)
		var offset = Vector3(0, 0, 1.2).rotated(Vector3.UP, deg_to_rad(table_rot))
		chair.position = table_pos + offset
		chair.rotation_degrees.y = table_rot - 180 # Scaunul privește spre birou
		
	# Adăugăm obiectele de puzzle ca noduri copil ale biroului (Sistem de Socket)
	if terminal_scene:
		var terminal = terminal_scene.instantiate()
		terminal.set_script(preload("res://Scripts/Puzzles/Terminal.gd"))
		table.add_child(terminal)
		terminal.position = Vector3(-0.4, 1.0, 0)
		
		# [RUSTY LAKE FOCUS POINT PENTRU TERMINAL]
		var focus_term = Marker3D.new()
		focus_term.name = "FocusPoint"
		focus_term.position = Vector3(0, 0.4, 0.8) # În fața ecranului
		terminal.add_child(focus_term)
		
	if matrix_monitor_scene:
		var monitor = matrix_monitor_scene.instantiate()
		monitor.set_script(preload("res://Scripts/Puzzles/MatrixMonitor.gd"))
		table.add_child(monitor)
		monitor.position = Vector3(0.6, 1.25, -0.2)
		
	# --- EPIC 1: INVENTORY & DRAWER ---
	# Atașăm logica de sertar încuiat direct pe birou, dar chemam _ready manual pentru ca a fost deja atasat
	table.set_script(preload("res://Scripts/Environment/LockedDrawer.gd"))
	if table.has_method("_ready"): table._ready()
	
	if note_scene:
		var note = note_scene.instantiate()
		note.set_script(preload("res://Scripts/Puzzles/Note.gd"))
		table.add_child(note)
		note.position = Vector3(0.3, 1.01, 0.2)
		note.name = "Note"
		note.visible = false # Ascuns până când descuie masa
		
		# [RUSTY LAKE FOCUS POINT PENTRU FOAIE]
		var focus_note = Marker3D.new()
		focus_note.name = "FocusPoint"
		focus_note.position = Vector3(0, 0.5, 0.3)
		focus_note.rotation_degrees.x = -45
		note.add_child(focus_note)
		
	if mug_scene:
		var mug = mug_scene.instantiate()
		table.add_child(mug)
		mug.position = Vector3(-0.8, 1.075, 0.3)
		
	if book_scene:
		var book = book_scene.instantiate()
		table.add_child(book)
		book.position = Vector3(-0.3, 1.025, 0.3)
		book.rotation_degrees.y = rng.randf_range(-30, 30)

# Plasează setul de mobilă (Piedestal) cu toate obiectele atașate
func place_pedestal_set(parent: Node3D, grid: Array[Vector3]) -> void:
	if not pedestal_scene or grid.is_empty(): return
	
	var pos_index = rng.randi_range(0, grid.size() - 1)
	var ped_pos = grid[pos_index]
	grid.remove_at(pos_index)
	
	var pedestal = pedestal_scene.instantiate()
	parent.add_child(pedestal)
	pedestal.position = ped_pos
	
	# Adăugăm biletul pe piedestal
	if note_scene:
		var note = note_scene.instantiate()
		pedestal.add_child(note)
		note.position = Vector3(0, 1.01, 0)
		
		var focus_note = Marker3D.new()
		focus_note.name = "FocusPoint"
		focus_note.position = Vector3(0, 0.5, 0.3)
		focus_note.rotation_degrees.x = -45
		note.add_child(focus_note)
		
	# Împrăștiem cărți în jurul piedestalului
	if book_scene:
		for i in range(2):
			var book = book_scene.instantiate()
			pedestal.add_child(book)
			book.position = Vector3(rng.randf_range(-1.0, 1.0), 0.025, rng.randf_range(-1.0, 1.0))
			book.rotation_degrees.y = rng.randf_range(0, 360)

func generate_room_a() -> void:
	var room_a_root = Node3D.new()
	room_a_root.name = "RoomA"
	add_child(room_a_root)
	
	build_walls_and_floor(room_a_root)
	
	var grid = get_available_grid_positions()
	var wall_slots = get_available_wall_slots()
	
	# Punctul de spawn pentru Jucătorul 1
	room_a_spawn = Marker3D.new()
	room_a_spawn.name = "SpawnPlayer1"
	room_a_spawn.position = Vector3(room_size.x / 2.0, 1.0, room_size.y / 2.0)
	room_a_root.add_child(room_a_spawn)
	
	if ceiling_light_scene:
		var light = ceiling_light_scene.instantiate()
		light.set_script(preload("res://Scripts/Environment/CeilingLightLogic.gd"))
		room_a_root.add_child(light)
		light.position = Vector3(room_size.x / 2.0, 3.0, room_size.y / 2.0)
		
	# Plasăm biroul, scaunul și obiectele direct conectate
	place_table_set(room_a_root, grid)
	
	var color_hint = place_on_wall(color_hint_scene, wall_slots)
	if color_hint: 
		color_hint.set_script(preload("res://Scripts/Puzzles/ColorHintBoard.gd"))
		room_a_root.add_child(color_hint)

	# --- EPIC 1: INVENTORY KEY ---
	# Spawnăm cheia magică pe un grid liber din Camera A
	if mug_scene and grid.size() > 0:
		var key = mug_scene.instantiate() # Folosim cana pe post de cheie temporară
		room_a_root.add_child(key)
		key.position = grid[0]
		
		# O adăugăm într-un body ca să o luăm cu raza
		var key_body = StaticBody3D.new()
		var key_col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(0.2, 0.2, 0.2)
		key_col.shape = box
		key_body.add_child(key_col)
		key.add_child(key_body)
		
		key_body.set_script(preload("res://Scripts/Environment/PickupItem.gd"))
		key_body.set("item_name", "Cheie de Birou")
		# Ca să dispară tot obiectul când îl luăm, nu doar corpul de fizică
		key_body.set("owner", key)
func generate_room_b() -> void:
	var room_b_root = Node3D.new()
	room_b_root.name = "RoomB"
	room_b_root.position = room_b_offset
	add_child(room_b_root)
	
	build_walls_and_floor(room_b_root)
	
	var grid = get_available_grid_positions()
	var wall_slots = get_available_wall_slots()
	
	# Punctul de spawn pentru Jucătorul 2
	room_b_spawn = Marker3D.new()
	room_b_spawn.name = "SpawnPlayer2"
	room_b_spawn.position = Vector3(room_size.x / 2.0, 1.0, room_size.y / 2.0)
	room_b_root.add_child(room_b_spawn)
	
	if ceiling_light_scene:
		var light = ceiling_light_scene.instantiate()
		light.set_script(preload("res://Scripts/Environment/CeilingLightLogic.gd"))
		room_b_root.add_child(light)
		light.position = Vector3(room_size.x / 2.0, 3.0, room_size.y / 2.0)
		
	# Plasăm piedestalul și obiectele sale
	place_pedestal_set(room_b_root, grid)
	
	# Plasăm seiful pe un loc liber de pe podea
	var safe = place_on_floor(safe_scene, grid)
	if safe: 
		safe.set_script(preload("res://Scripts/Environment/DoorLogic.gd"))
		room_b_root.add_child(safe)
	
	# Plasăm mecanismele de puzzle pe pereți
	var numpad = place_on_wall(numpad_scene, wall_slots)
	if numpad: 
		numpad.set_script(preload("res://Scripts/Puzzles/Numpad.gd"))
		room_b_root.add_child(numpad)
		var f1 = Marker3D.new()
		f1.name = "FocusPoint"
		f1.position = Vector3(0, 0, 0.6)
		numpad.add_child(f1)
	
	var fusebox = place_on_wall(fuse_box_scene, wall_slots)
	if fusebox: 
		fusebox.set_script(preload("res://Scripts/Puzzles/FuseBox3x3.gd"))
		room_b_root.add_child(fusebox)
		var f2 = Marker3D.new()
		f2.name = "FocusPoint"
		f2.position = Vector3(0, 0, 1.0)
		fusebox.add_child(f2)
	
	var colorbtn = place_on_wall(color_btn_scene, wall_slots)
	if colorbtn: 
		colorbtn.set_script(preload("res://Scripts/Puzzles/ColorButtonsPanel.gd"))
		room_b_root.add_child(colorbtn)
		var f3 = Marker3D.new()
		f3.name = "FocusPoint"
		f3.position = Vector3(0, 0, 1.2)
		colorbtn.add_child(f3)
	
	# Cazul special pentru ușă: se plasează la nivelul solului (y=0) dar pe un slot de perete
	if door_scene and wall_slots.size() > 0:
		var slot_index = rng.randi_range(0, wall_slots.size() - 1)
		var slot = wall_slots[slot_index]
		wall_slots.remove_at(slot_index)
		
		var door = door_scene.instantiate()
		door.set_script(preload("res://Scripts/Environment/DoorLogic.gd"))
		room_b_root.add_child(door)
		door.position = Vector3(round(slot["pos"].x), 0, round(slot["pos"].z))
		door.rotation_degrees = slot["rot"]

# Construiește podeaua și cei 4 pereți pentru o cameră dată
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
