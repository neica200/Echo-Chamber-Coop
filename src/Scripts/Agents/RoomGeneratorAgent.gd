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

# Grid Layout variables
const GRID_W = 3
const GRID_H = 3
var grid_cells = [] # Array de dicționare pentru fiecare celulă: { "x", "y", "type": "A" / "B" / "C", "connected": false }
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var room_a_spawn: Marker3D
var room_b_spawn: Marker3D

var player1: Node3D
var player2: Node3D
var current_player = 1

func _ready() -> void:
	rng.seed = hash("echo_chamber_decor_v2") # Seed fix pentru generare deterministă

	if not wall_scene:
		push_error("Scena pentru perete (wall_scene) nu este atribuită în RoomGeneratorAgent.")
		return
	call_deferred("generate_rooms")

	# --- ENVIRONMENT ÎNTUNECAT & POST PROCESSING ---
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.02) # Beznă
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.02, 0.02, 0.03) # Lumină f slabă
	env.tonemap_mode = Environment.TONE_MAPPER_ACES # Cinematic
	
	# VFX: Volumetrics
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.015
	env.volumetric_fog_albedo = Color(0.6, 0.7, 0.8)
	
	# VFX: Post Processing
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 2.0
	env.glow_enabled = true
	env.glow_bloom = 0.3
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.adjustment_enabled = true
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	# Film Grain CanvasLayer
	_setup_film_grain()
	
	# Dacă există soarele default, îl oprim complet
	var sun = get_parent().get_node_or_null("DirectionalLight3D")
	if sun:
		sun.light_energy = 0.01
		
	# Inițializăm cu un seed fix pentru testare
	generate_rooms(12345)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		GameEvents.room_lights_toggled.emit("RoomA", true)

func _setup_film_grain():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	var rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect)
	
	var mat = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
	uniform float grain_amount = 0.05;
	void fragment() {
		vec4 color = texture(screen_texture, SCREEN_UV);
		float noise = fract(sin(dot(UV + TIME, vec2(12.9898, 78.233))) * 43758.5453);
		COLOR = mix(color, vec4(0.0, 0.0, 0.0, 1.0), noise * grain_amount);
	}
	"""
	mat.shader = shader
	rect.material = mat

func _input(event):
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
	
	_generate_grid_layout()
	
	# Spawnăm jucătorii automat
	var player_scene = preload("res://Scenes/Rooms/player.tscn")
	if player_scene:
		if room_a_spawn:
			player1 = player_scene.instantiate()
			player1.name = "Player1"
			add_child(player1)
			player1.global_position = room_a_spawn.global_position
			player1.rotation_degrees = room_a_spawn.rotation_degrees
			player1.is_active = true

		if room_b_spawn:
			player2 = player_scene.instantiate()
			player2.name = "Player2"
			add_child(player2)
			player2.global_position = room_b_spawn.global_position
			player2.is_active = false
		
		current_player = 1
		player1.get_node("Camera3D").make_current()

func _generate_grid_layout():
	grid_cells.clear()
	# Inițializare grid
	for x in range(GRID_W):
		var col = []
		for y in range(GRID_H):
			col.append({ "type": "Empty", "visited": false, "doors": {"N": false, "S": false, "E": false, "W": false} })
		grid_cells.append(col)
	
	# Alegem random o celulă de start pentru Room A și una pentru Room B
	var a_pos = Vector2(rng.randi_range(0, GRID_W-1), rng.randi_range(0, GRID_H-1))
	var b_pos = Vector2(rng.randi_range(0, GRID_W-1), rng.randi_range(0, GRID_H-1))
	while b_pos == a_pos:
		b_pos = Vector2(rng.randi_range(0, GRID_W-1), rng.randi_range(0, GRID_H-1))
		
	grid_cells[a_pos.x][a_pos.y]["type"] = "RoomA"
	grid_cells[b_pos.x][b_pos.y]["type"] = "RoomB"
	
	# DFS pentru a genera un labirint (spanning tree perfect) între celule
	_carve_passages_from(int(a_pos.x), int(a_pos.y))
	
	# Acum construim geometria pentru fiecare celulă
	for x in range(GRID_W):
		for y in range(GRID_H):
			_build_cell(x, y)

func _carve_passages_from(cx: int, cy: int):
	grid_cells[cx][cy]["visited"] = true
	var dirs = [[0, -1, "N", "S"], [0, 1, "S", "N"], [1, 0, "E", "W"], [-1, 0, "W", "E"]]
	# Shuffle dirs cu rng
	for i in range(dirs.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = dirs[i]
		dirs[i] = dirs[j]
		dirs[j] = temp
		
	for d in dirs:
		var nx = cx + d[0]
		var ny = cy + d[1]
		if nx >= 0 and ny >= 0 and nx < GRID_W and ny < GRID_H:
			if not grid_cells[nx][ny]["visited"]:
				grid_cells[cx][cy]["doors"][d[2]] = true
				grid_cells[nx][ny]["doors"][d[3]] = true
				if grid_cells[nx][ny]["type"] == "Empty":
					grid_cells[nx][ny]["type"] = "Corridor"
				_carve_passages_from(nx, ny)

func _build_cell(x: int, y: int):
	var cell_data = grid_cells[x][y]
	var cell_root = Node3D.new()
	cell_root.name = "Cell_" + str(x) + "_" + str(y)
	cell_root.position = Vector3(x * room_size.x, 0, y * room_size.y)
	add_child(cell_root)
	
	# Probe de reflexie ca să nu mai fie obiectele metalice negre
	var probe = ReflectionProbe.new()
	probe.position = Vector3(room_size.x / 2.0, 1.5, room_size.y / 2.0)
	probe.size = Vector3(room_size.x, 4.0, room_size.y)
	probe.intensity = 0.8
	cell_root.add_child(probe)
	
	# Podeaua
	if floor_scene:
		var floor_instance = floor_scene.instantiate()
		cell_root.add_child(floor_instance)
		floor_instance.position = Vector3(room_size.x / 2.0, -0.5, room_size.y / 2.0)
		floor_instance.scale = Vector3(room_size.x, 1, room_size.y)
		PBRMaterialManager.apply_material_to_mesh(floor_instance, "wood_floor")
		
		# Tavanul
		var ceiling_instance = floor_scene.instantiate()
		cell_root.add_child(ceiling_instance)
		ceiling_instance.position = Vector3(room_size.x / 2.0, 5.0, room_size.y / 2.0)
		ceiling_instance.scale = Vector3(room_size.x, 1.0, room_size.y)
		PBRMaterialManager.apply_material_to_mesh(ceiling_instance, "ceiling")
		
	var wall_length = 4.0
	
	# Pereți și Uși
	# North (z=0)
	var x_pos = wall_length / 2.0
	while x_pos < room_size.x:
		if cell_data["doors"]["N"] and abs(x_pos - room_size.x/2.0) < 0.1:
			_place_door(cell_root, Vector3(x_pos, 0, 0), Vector3(0, 0, 0))
		else:
			_place_wall(cell_root, Vector3(x_pos, 0, 0), Vector3(0, 0, 0))
		x_pos += wall_length

	# South (z=room_size.y)
	x_pos = wall_length / 2.0
	while x_pos < room_size.x:
		if cell_data["doors"]["S"] and abs(x_pos - room_size.x/2.0) < 0.1:
			_place_door(cell_root, Vector3(x_pos, 0, room_size.y), Vector3(0, 180, 0))
		else:
			_place_wall(cell_root, Vector3(x_pos, 0, room_size.y), Vector3(0, 180, 0))
		x_pos += wall_length

	# West (x=0)
	var z_pos = wall_length / 2.0
	while z_pos < room_size.y:
		if cell_data["doors"]["W"] and abs(z_pos - room_size.y/2.0) < 0.1:
			_place_door(cell_root, Vector3(0, 0, z_pos), Vector3(0, 90, 0))
		else:
			_place_wall(cell_root, Vector3(0, 0, z_pos), Vector3(0, 90, 0))
		z_pos += wall_length

	# East (x=room_size.x)
	z_pos = wall_length / 2.0
	while z_pos < room_size.y:
		if cell_data["doors"]["E"] and abs(z_pos - room_size.y/2.0) < 0.1:
			_place_door(cell_root, Vector3(room_size.x, 0, z_pos), Vector3(0, -90, 0))
		else:
			_place_wall(cell_root, Vector3(room_size.x, 0, z_pos), Vector3(0, -90, 0))
		z_pos += wall_length
		
	# Lampa de tavan
	if ceiling_light_scene:
		var light = ceiling_light_scene.instantiate()
		light.set_script(preload("res://Scripts/Environment/CeilingLightLogic.gd"))
		cell_root.add_child(light)
		light.position = Vector3(room_size.x / 2.0, 4.4, room_size.y / 2.0)
		if light.has_method("setup"):
			light.setup(cell_data["type"])
		
	var grid_pos = get_available_grid_positions()
	var wall_slots = get_available_wall_slots()
	
	if cell_data["type"] == "RoomA":
		room_a_spawn = Marker3D.new()
		room_a_spawn.name = "SpawnPlayer1"
		room_a_spawn.position = Vector3(room_size.x / 2.0, 1.0, 3.5) # Mutat mai spre perete ca să lase mijlocul liber
		room_a_spawn.rotation_degrees.y = 180 # Orientat spre biroul de la Z=11.0
		cell_root.add_child(room_a_spawn)
		
		var custom_table_grid: Array[Vector3] = [Vector3(6.0, 0, 11.0)] # Lipit de peretele din față
		place_table_set(cell_root, custom_table_grid, 180.0)
		
		var color_hint = place_on_wall(color_hint_scene, wall_slots)
		if color_hint: 
			color_hint.set_script(preload("res://Scripts/Puzzles/ColorHintBoard.gd"))
			cell_root.add_child(color_hint)

		# Cheia a fost mutată pe masa cu radioul în _decorate_manual()

	elif cell_data["type"] == "RoomB":
		room_b_spawn = Marker3D.new()
		room_b_spawn.name = "SpawnPlayer2"
		room_b_spawn.position = Vector3(room_size.x / 2.0, 1.0, room_size.y / 2.0)
		cell_root.add_child(room_b_spawn)
		
		place_pedestal_set(cell_root, grid_pos)
		
		var safe = safe_scene.instantiate()
		if safe: 
			cell_root.add_child(safe)
			safe.position = Vector3(2.0, 0.0, 2.0) # Colțul stânga-sus
			safe.rotation_degrees.y = 45 # Orientat cu ușa spre interiorul camerei
			safe.set_script(preload("res://Scripts/Environment/DoorLogic.gd"))
			PBRMaterialManager.apply_material_to_mesh(safe, "safe")
		
		var numpad = place_on_wall(numpad_scene, wall_slots)
		if numpad: 
			numpad.set_script(preload("res://Scripts/Puzzles/Numpad.gd"))
			cell_root.add_child(numpad)
			PBRMaterialManager.apply_material_to_mesh(numpad, "plastic")
			var f1 = Marker3D.new()
			f1.name = "FocusPoint"
			f1.position = Vector3(0, 0, 0.6)
			numpad.add_child(f1)
		
		var fusebox = place_on_wall(fuse_box_scene, wall_slots)
		if fusebox: 
			fusebox.set_script(preload("res://Scripts/Puzzles/FuseBox3x3.gd"))
			cell_root.add_child(fusebox)
			PBRMaterialManager.apply_material_to_mesh(fusebox, "plastic")
			var f2 = Marker3D.new()
			f2.name = "FocusPoint"
			f2.position = Vector3(0, 0, 1.0)
			fusebox.add_child(f2)
		
		var colorbtn = place_on_wall(color_btn_scene, wall_slots)
		if colorbtn: 
			colorbtn.set_script(preload("res://Scripts/Puzzles/ColorButtonsPanel.gd"))
			cell_root.add_child(colorbtn)
			var f3 = Marker3D.new()
			f3.name = "FocusPoint"
			f3.position = Vector3(0, 0, 1.2)
			colorbtn.add_child(f3)

	_decorate_manual(cell_root, cell_data["type"])

func _decorate_manual(parent: Node3D, room_type: String):
	var desk_scene = load("res://Scripts/Props/Desk.glb")
	var bookcase_scene = load("res://Scripts/Props/Bookcase with Books.glb")
	var closet_scene = load("res://Scripts/Props/Closet.glb")
	var boxes_scene = load("res://Scripts/Props/Cardboard Boxes.glb")
	var radio_scene = load("res://Scripts/Props/Radio.glb")
	var rug_scene = load("res://Scripts/Props/Rug.glb")
	var papers_scene = load("res://Scripts/Props/Debris Papers.glb")
	var candles_scene = load("res://Scripts/Props/Candles.glb")
	
	if room_type == "RoomA":
		# Biblioteca în colțul dreapta-jos (X=11.2, Z=10.0)
		var bookcase = bookcase_scene.instantiate()
		parent.add_child(bookcase)
		bookcase.position = Vector3(11.2, 0, 10.0)
		bookcase.rotation_degrees.y = -90
		_auto_generate_collision(bookcase)
		
		# Covorul rotund în centrul camerei
		if rug_scene:
			var rug = rug_scene.instantiate()
			parent.add_child(rug)
			rug.position = Vector3(6.0, 0.01, 6.0)
			rug.rotation_degrees.y = rng.randf_range(0, 360)
			rug.scale = Vector3(2.5, 2.5, 2.5) # Covor mărit
			
		# Hârtii aruncate pe jos (2 seturi, unul în stânga camerei, unul în dreapta)
		if papers_scene:
			var p1 = papers_scene.instantiate()
			parent.add_child(p1)
			p1.position = Vector3(rng.randf_range(1.5, 4.5), 0.02, rng.randf_range(2.0, 10.0))
			p1.rotation_degrees.y = rng.randf_range(0, 360)
			p1.scale = Vector3(1.5, 1.5, 1.5)
			
			var p2 = papers_scene.instantiate()
			parent.add_child(p2)
			p2.position = Vector3(rng.randf_range(7.5, 10.5), 0.02, rng.randf_range(2.0, 10.0))
			p2.rotation_degrees.y = rng.randf_range(0, 360)
			p2.scale = Vector3(1.5, 1.5, 1.5)
				
		# Lumânări cu efect de flacără în colțul opus biroului (peretele din față, stânga)
		if candles_scene:
			var candles = candles_scene.instantiate()
			parent.add_child(candles)
			candles.position = Vector3(1.5, 0.0, 1.5)
			candles.scale = Vector3(1, 1, 1)
			
			var flame = OmniLight3D.new()
			flame.light_color = Color(1.0, 0.6, 0.2) # Portocaliu de flacără
			flame.light_energy = 1.5
			flame.omni_range = 4.0
			flame.shadow_enabled = true
			flame.position = Vector3(0, 0.4, 0)
			candles.add_child(flame)
		
		# Primul dulap (Closet) între bibliotecă și masă (Z=8.0)
		var closet1 = closet_scene.instantiate()
		parent.add_child(closet1)
		closet1.position = Vector3(11.2, 0, 8.0)
		closet1.rotation_degrees.y = -90
		_auto_generate_collision(closet1)
		
		# A doua bibliotecă în colțul dreapta-sus (X=11.2, Z=2.0)
		var bookcase2 = bookcase_scene.instantiate()
		parent.add_child(bookcase2)
		bookcase2.position = Vector3(11.2, 0, 2.0)
		bookcase2.rotation_degrees.y = -90
		_auto_generate_collision(bookcase2)
		
		# Al doilea dulap (Closet) între bibliotecă și masă (Z=4.0)
		var closet2 = closet_scene.instantiate()
		parent.add_child(closet2)
		closet2.position = Vector3(11.2, 0, 4.0)
		closet2.rotation_degrees.y = -90
		_auto_generate_collision(closet2)
		
		# Masa cu radioul lipită de peretele din dreapta, lângă bibliotecă
		var desk = desk_scene.instantiate()
		parent.add_child(desk)
		desk.position = Vector3(11.2, 0, 6.0)
		desk.rotation_degrees.y = -90 
		desk.scale = Vector3(1.2, 1.2, 1.2) # Masa un pic mai mare
		_auto_generate_collision(desk)
		
		# Radioul pe birou (făcut și mai mic)
		var radio = radio_scene.instantiate()
		desk.add_child(radio)
		radio.position = Vector3(0, 0.9, 0) # Ajustăm înălțimea relativă dacă e cazul
		radio.scale = Vector3(0.3, 0.3, 0.3) # Radio foarte mic
		_auto_generate_collision(radio)
		
		# Cheia pusă direct pe biroul cu radio!
		var key_scene = preload("res://Scripts/Props/Key.glb")
		var key = key_scene.instantiate()
		desk.add_child(key)
		key.scale = Vector3(1.0, 1.0, 1.0) # Reset
		
		var aabb = AABB()
		var has_aabb = false
		for child in key.find_children("*", "MeshInstance3D"):
			var t_aabb = child.transform * child.get_aabb()
			if not has_aabb:
				aabb = t_aabb
				has_aabb = true
			else:
				aabb = aabb.merge(t_aabb)
		if has_aabb:
			var center_offset = aabb.get_center()
			for child in key.get_children():
				if child is Node3D:
					child.position -= center_offset
					
		key.scale = Vector3(0.2, 0.2, 0.2) # Mai mică
		key.position = Vector3(-0.5, 1.0, 0.1) # Mai sus (1.15) ca să iasă din masă
		
		var key_body = StaticBody3D.new()
		var key_col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(0.8, 0.8, 0.8) # Hitbox IMENS ca să fie super ușor de luat
		key_col.shape = box
		key_body.add_child(key_col)
		key.add_child(key_body)
		key_body.set_script(preload("res://Scripts/Environment/PickupItem.gd"))
		key_body.set("item_name", "Cheie de Birou")
		key_body.set("owner", key)
		
	elif room_type == "RoomB":
		# Covorul pe centru
		var rug = rug_scene.instantiate()
		parent.add_child(rug)
		rug.position = Vector3(6.0, 0.01, 6.0) # 1cm deasupra podelei
		rug.rotation_degrees.y = rng.randf_range(0, 360)
		rug.scale = Vector3(2.5, 2.5, 2.5) # Facem covorul mult mai mare!
		
		# 3 Cutii aruncate în colțul dreapta-sus
		for i in range(3):
			var box = boxes_scene.instantiate()
			parent.add_child(box)
			box.position = Vector3(10.0 + rng.randf_range(-1.0, 1.0), 0, 2.0 + rng.randf_range(-1.0, 1.0))
			box.rotation_degrees.y = rng.randf_range(0, 360)
			_auto_generate_collision(box)

func _auto_generate_collision(node: Node3D):
	var has_collision = false
	for child in node.get_children():
		if child is CollisionObject3D:
			has_collision = true
			break
			
	if not has_collision:
		var static_body = StaticBody3D.new()
		node.add_child(static_body)
		
		var aabb = AABB()
		var first = true
		for child in node.find_children("*", "VisualInstance3D", true, false):
			if child is MeshInstance3D and child.mesh:
				var mesh_aabb = child.get_aabb()
				mesh_aabb.position += child.position 
				
				if first:
					aabb = mesh_aabb
					first = false
				else:
					aabb = aabb.merge(mesh_aabb)
					
		if not first:
			var shape = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = aabb.size
			shape.shape = box
			shape.position = aabb.position + aabb.size / 2.0
			static_body.add_child(shape)

func _place_wall(parent: Node3D, pos: Vector3, rot: Vector3):
	var wall = wall_scene.instantiate()
	parent.add_child(wall)
	wall.position = pos
	wall.rotation_degrees = rot
	# Înălțimea nativă a peretelui este 3.0m. Vrem să ajungă la 5.0m. Deci Y scale = 5.0 / 3.0
	wall.scale = Vector3(1.0, 5.0 / 3.0, 1.0)
	PBRMaterialManager.apply_material_to_mesh(wall, "wall")

func _place_door(parent: Node3D, pos: Vector3, rot: Vector3):
	if door_scene:
		var door = door_scene.instantiate()
		parent.add_child(door)
		door.position = pos
		door.rotation_degrees = rot
		door.set_script(preload("res://Scripts/Environment/DoorLogic.gd"))
		PBRMaterialManager.apply_material_to_mesh(door, "door")
		
		# Ușa (ArmoredDoor) are 2.2m lățime totală și 3.2m înălțime totală!
		# Pereții laterali trebuie să aibă 0.9m fiecare (4.0 - 2.2 = 1.8 -> 0.9)
		var w1 = wall_scene.instantiate()
		parent.add_child(w1)
		w1.position = pos + Vector3(1.55, 0, 0).rotated(Vector3.UP, deg_to_rad(rot.y))
		w1.rotation_degrees = rot
		w1.scale = Vector3(0.9 / 4.0, 5.0 / 3.0, 1)
		PBRMaterialManager.apply_material_to_mesh(w1, "wall")
		
		var w2 = wall_scene.instantiate()
		parent.add_child(w2)
		w2.position = pos + Vector3(-1.55, 0, 0).rotated(Vector3.UP, deg_to_rad(rot.y))
		w2.rotation_degrees = rot
		w2.scale = Vector3(0.9 / 4.0, 5.0 / 3.0, 1)
		PBRMaterialManager.apply_material_to_mesh(w2, "wall")

		# Punem un perete și deasupra ușii ca să nu rămână gaură
		var w3 = wall_scene.instantiate()
		parent.add_child(w3)
		# Ușa se termină la y=3.2. Vrem peretele de la 3.2 la 5.0 (înălțime 1.8)
		w3.position = pos + Vector3(0, 3.2, 0)
		w3.rotation_degrees = rot
		# Lățime 2.2m / nativ 4.0m. Înălțime 1.8m / nativ 3.0m.
		w3.scale = Vector3(2.2 / 4.0, 1.8 / 3.0, 1)
		PBRMaterialManager.apply_material_to_mesh(w3, "wall")
	else:
		pass # Open corridor

func get_available_grid_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for x in range(2, int(room_size.x) - 1, 2):
		for z in range(2, int(room_size.y) - 1, 2):
			# Interzicem centrul exact (evităm blocarea jucătorului la spawn)
			if x == 6 and z == 6: continue
			# Interzicem colțul stânga-jos (noul loc al biroului din Room A)
			if x <= 4 and z >= 8: continue
			# Interzicem colțul dreapta-jos (noul loc al bibliotecii din Room A)
			if x >= 8 and z >= 8: continue
			# Interzicem colțul dreapta-sus (cutiile din Room B)
			if x >= 8 and z <= 4: continue
			# Interzicem colțul stânga-sus (seiful din Room B)
			if x <= 4 and z <= 4: continue
			
			positions.append(Vector3(x, 0, z))
	return positions

func get_available_wall_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var spacing = 2.0
	var inset = 0.26 
	
	for x in range(2, int(room_size.x) - 1, int(spacing)):
		slots.append({"pos": Vector3(x, 1.5, inset), "rot": Vector3(0, 0, 0)})
	for x in range(2, int(room_size.x) - 1, int(spacing)):
		slots.append({"pos": Vector3(x, 1.5, room_size.y - inset), "rot": Vector3(0, 180, 0)})
	for z in range(2, int(room_size.y) - 1, int(spacing)):
		slots.append({"pos": Vector3(inset, 1.5, z), "rot": Vector3(0, 90, 0)})
	for z in range(2, int(room_size.y) - 1, int(spacing)):
		slots.append({"pos": Vector3(room_size.x - inset, 1.5, z), "rot": Vector3(0, -90, 0)})
		
	return slots

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

func place_on_floor(scene: PackedScene, positions: Array[Vector3], remove_pos: bool = true) -> Node3D:
	if not scene or positions.is_empty(): return null
	var pos_index = rng.randi_range(0, positions.size() - 1)
	var pos = positions[pos_index]
	if remove_pos:
		positions.remove_at(pos_index)
	var instance = scene.instantiate()
	instance.position = pos
	instance.rotation_degrees.y = rng.randi_range(0, 3) * 90.0
	return instance

func place_table_set(parent: Node3D, grid: Array[Vector3], fixed_rot: float = -1.0) -> void:
	if grid.is_empty(): return
	var pos_index = rng.randi_range(0, grid.size() - 1)
	var table_pos = grid[pos_index]
	grid.remove_at(pos_index)
	
	# Încărcăm noile elemente 3D direct
	var new_desk_scene = load("res://Scripts/Props/Computer Deskglb.glb")
	var new_chair_scene = load("res://Scripts/Props/Chair.glb")
	var new_computer_scene = load("res://Scripts/Props/Desktop computer.glb")
	
	var table = Node3D.new()
	table.name = "TableAnchor"
	parent.add_child(table)
	table.position = table_pos
	
	var table_rot = rng.randi_range(0, 3) * 90.0 if fixed_rot < 0.0 else fixed_rot
	table.rotation_degrees.y = table_rot
	
	var table_visual = new_desk_scene.instantiate()
	table.add_child(table_visual)
	table_visual.scale = Vector3(0.04, 0.04, 0.04)
	
	# Forțăm centrarea biroului (dacă modelul descărcat de pe net este descentrat)
	var aabb = AABB()
	var has_aabb = false
	for child in table_visual.find_children("*", "MeshInstance3D"):
		var t_aabb = child.transform * child.get_aabb()
		if not has_aabb:
			aabb = t_aabb
			has_aabb = true
		else:
			aabb = aabb.merge(t_aabb)
			
	if has_aabb:
		var center_offset = aabb.get_center()
		center_offset.y = 0 # Nu modificăm înălțimea bazei
		for child in table_visual.get_children():
			if child is Node3D:
				child.position -= center_offset
				
	_auto_generate_collision(table_visual)
	
	if new_chair_scene:
		var chair_anchor = Node3D.new()
		parent.add_child(chair_anchor)
		var offset = Vector3(0, 0, 1.2).rotated(Vector3.UP, deg_to_rad(table_rot))
		chair_anchor.position = table_pos + offset
		chair_anchor.rotation_degrees.y = table_rot - 180 
		
		var chair_visual = new_chair_scene.instantiate()
		chair_anchor.add_child(chair_visual)
		chair_visual.scale = Vector3(0.13, 0.13, 0.13)
		_auto_generate_collision(chair_visual)
		
	if new_computer_scene:
		var computer_body = StaticBody3D.new()
		computer_body.name = "ComputerTerminal"
		table.add_child(computer_body)
		computer_body.position = Vector3(0.4, 1.30, 0.0) # Înapoi la 1.30 unde stătea bine
		
		# Atașăm logica de puzzle
		computer_body.set_script(preload("res://Scripts/Puzzles/Terminal.gd"))
		
		# Adăugăm vizualul 3D (noul calculator) foarte micșorat
		var computer = new_computer_scene.instantiate()
		computer_body.add_child(computer)
		computer.scale = Vector3(0.13, 0.13, 0.13)
		
		# Creăm ierarhia falsă pentru a împiedica crash-ul scriptului Terminal.gd
		var monitor_mesh = Node3D.new()
		monitor_mesh.name = "MonitorMesh"
		computer_body.add_child(monitor_mesh)
		
		var screen_mesh = MeshInstance3D.new()
		screen_mesh.name = "ScreenMesh"
		monitor_mesh.add_child(screen_mesh)
		
		var focus_term = Marker3D.new()
		focus_term.name = "FocusPoint"
		focus_term.position = Vector3(0, 0.4, 0.8) 
		computer_body.add_child(focus_term)
		
		# Creăm hitbox-ul (înlocuiește auto_generate_collision pe computer_body)
		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(0.8, 0.8, 0.8)
		shape.shape = box
		shape.position = Vector3(0, 0.4, 0)
		computer_body.add_child(shape)
		
		# Efectul de soft glow adăugat la noul calculator
		var term_glow = OmniLight3D.new()
		term_glow.light_color = Color(0.7, 0.9, 1.0) # Albăstrui
		term_glow.light_energy = 0.3 # Foarte subtil
		term_glow.omni_range = 3.0
		term_glow.shadow_enabled = true
		term_glow.position = Vector3(0, 0.3, 0.3)
		computer_body.add_child(term_glow)
		
	if matrix_monitor_scene:
		var monitor = matrix_monitor_scene.instantiate()
		monitor.set_script(preload("res://Scripts/Puzzles/MatrixMonitor.gd"))
		table.add_child(monitor)
		monitor.position = Vector3(-0.8, 1.45, -0.1) # Mai la stânga (-0.8) și mai jos (1.45)
		
		var screen_glow = OmniLight3D.new()
		screen_glow.light_color = Color(0.2, 0.9, 0.3)
		screen_glow.light_energy = 0.4
		screen_glow.omni_range = 3.5
		screen_glow.shadow_enabled = true
		screen_glow.position = Vector3(0, 0, 0.3)
		monitor.add_child(screen_glow)
		
	table.set_script(preload("res://Scripts/Environment/LockedDrawer.gd"))
	if table.has_method("_ready"): table._ready()
	
	if note_scene:
		var note = note_scene.instantiate()
		note.set_script(preload("res://Scripts/Puzzles/Note.gd"))
		table.add_child(note)
		note.position = Vector3(-0.6, 1.2, 0.2) # Coborâtă la 1.28
		note.name = "Note"
		note.visible = false 
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

func place_pedestal_set(parent: Node3D, grid: Array[Vector3]) -> void:
	if not pedestal_scene or grid.is_empty(): return
	var pos_index = rng.randi_range(0, grid.size() - 1)
	var ped_pos = grid[pos_index]
	grid.remove_at(pos_index)
	
	var pedestal = pedestal_scene.instantiate()
	parent.add_child(pedestal)
	pedestal.position = ped_pos
	
	if note_scene:
		var note = note_scene.instantiate()
		pedestal.add_child(note)
		note.position = Vector3(0, 1.01, 0)
		var focus_note = Marker3D.new()
		focus_note.name = "FocusPoint"
		focus_note.position = Vector3(0, 0.5, 0.3)
		focus_note.rotation_degrees.x = -45
		note.add_child(focus_note)
		
	if book_scene:
		for i in range(2):
			var book = book_scene.instantiate()
			pedestal.add_child(book)
			book.position = Vector3(rng.randf_range(-1.0, 1.0), 0.025, rng.randf_range(-1.0, 1.0))
			book.rotation_degrees.y = rng.randf_range(0, 360)
