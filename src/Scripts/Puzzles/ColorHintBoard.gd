extends Node3D

func _ready():
	await get_tree().create_timer(0.1).timeout
	var data = PuzzleGen.get_puzzle_data("color_sequence")
	
	GameEvents.drawer_opened.connect(_on_drawer_opened)
	
	if data.has("solution"):
		var sequence = data["solution"]
		for i in range(4):
			# Găsim nodurile Bulb_1 până la Bulb_4
			var bulb = get_node_or_null("Bulb_" + str(i + 1))
			if bulb:
				var mat = StandardMaterial3D.new()
				var color_name = sequence[i]
				
				if color_name == "Rosu":
					mat.albedo_color = Color.RED
				elif color_name == "Albastru":
					mat.albedo_color = Color.BLUE
				elif color_name == "Verde":
					mat.albedo_color = Color.GREEN
				elif color_name == "Galben":
					mat.albedo_color = Color.YELLOW
					
					
				# Becurile sunt stinse inițial
				mat.emission_enabled = false
				mat.emission = mat.albedo_color
				# Oprim temporar și albedo-ul să pară complet gri stins (sau foarte închis)
				mat.albedo_color = Color(0.1, 0.1, 0.1)
				
				bulb.set_surface_override_material(0, mat)

func _on_drawer_opened():
	var data = PuzzleGen.get_puzzle_data("color_sequence")
	if data.has("solution"):
		var sequence = data["solution"]
		for i in range(4):
			var bulb = get_node_or_null("Bulb_" + str(i + 1))
			if bulb:
				var mat = bulb.get_surface_override_material(0)
				if mat:
					var color_name = sequence[i]
					if color_name == "Rosu":
						mat.albedo_color = Color.RED
					elif color_name == "Albastru":
						mat.albedo_color = Color.BLUE
					elif color_name == "Verde":
						mat.albedo_color = Color.GREEN
					elif color_name == "Galben":
						mat.albedo_color = Color.YELLOW
					
					mat.emission_enabled = true
					
	AudioManager.play_success()
	print("💡 Panoul de culori din Camera A s-a aprins!")
