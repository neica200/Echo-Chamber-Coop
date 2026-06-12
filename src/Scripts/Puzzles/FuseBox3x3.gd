extends Node3D

var target_grid = []
var current_grid = [false, false, false, false, false, false, false, false, false]
var moves_made = 0

func _ready():
	await get_tree().create_timer(0.1).timeout
	var data = PuzzleGen.get_puzzle_data("grid_puzzle")
	if data.has("solution"):
		target_grid = data["solution"]
		
	var fuse_script = preload("res://Scripts/Puzzles/FuseButton.gd")
	var index = 0
	
	# Parcurgem siguranțele și le atașăm logica de click
	for y in range(3):
		for x in range(3):
			var fuse = get_node_or_null("Fuse_" + str(x) + "_" + str(y))
			if fuse:
				fuse.set_script(fuse_script)
				fuse.fuse_parent = self
				fuse.grid_index = index
			index += 1

func toggle_fuse(index: int, fuse_node: Node3D):
	# Inversăm starea (dacă e true devine false, și invers)
	current_grid[index] = not current_grid[index]
	
	AudioManager.play_click()
	print("[FuseBox] Toggled fuse index: ", index, " | State: ", current_grid[index])
	
	# Oferim feedback vizual
	var mesh = fuse_node.get_node("MeshInstance3D")
	var mat = StandardMaterial3D.new()
	if current_grid[index]:
		mat.albedo_color = Color(0.0, 0.8, 0.0) # Verde = Aprins
		mat.emission_enabled = true
		mat.emission = Color(0.0, 1.0, 0.0)
	else:
		mat.albedo_color = Color(0.3, 0.3, 0.3) # Gri = Stins
		mat.emission_enabled = false
		mat.emission = Color(0.0, 0.0, 0.0)
		
	mesh.set_surface_override_material(0, mat)
	
	check_solution()

func check_solution():
	var is_correct = true
	print("[FuseBox] Current Grid: ", current_grid)
	print("[FuseBox] Target Grid:  ", target_grid)
	
	# Verificăm dacă grila jucătorului e IDENTICĂ cu soluția
	for i in range(9):
		if current_grid[i] != target_grid[i]:
			is_correct = false
			break
			
	if is_correct:
		AudioManager.play_success()
		print("✅ [SUCCESS] MATRICEA A FOST REZOLVATĂ! Siguranțele au căzut pe verde perfect.")
		
		# --- CROSS-ROOM EFFECT ---
		GameEvents.advance_stage()
		GameEvents.trigger_room_lights_toggled("RoomA", true)
		GameEvents.trigger_room_lights_toggled("RoomB", true)
		print("[FuseBox] Panoul reparat! Am aprins lumina in A si B!")
	else:
		moves_made += 1
		if moves_made % 8 == 0:
			if has_node("/root/HintAgent"):
				get_node("/root/HintAgent").register_wrong_attempt("fuse_puzzle")
			if has_node("/root/SaboteurAgent"):
				get_node("/root/SaboteurAgent").register_wrong_attempt("fuse_puzzle", "Player2")
			if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
				GameEvents.rpc("sync_mistake")
			else:
				GameEvents.sync_mistake()
