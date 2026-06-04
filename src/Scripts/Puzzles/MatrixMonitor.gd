extends Node3D

func _ready():
	# Așteptăm puțin ca PuzzleGen să genereze datele
	await get_tree().create_timer(0.1).timeout
	
	# Monitorul merge pe baterii în Faza 1 ca să dea indiciul pentru pană!
	var data = PuzzleGen.get_puzzle_data("grid_puzzle")

	if data.has("solution"):
		var grid = data["solution"]
		var index = 0
		
		for y in range(3):
			for x in range(3):
				var node_name = "Grid_" + str(x) + "_" + str(y)
				var grid_mesh = get_node_or_null(node_name)
				
				if grid_mesh and grid[index] == true:
					var mat = StandardMaterial3D.new()
					mat.albedo_color = Color(0.0, 0.8, 0.0) # Verde luminos
					mat.emission_enabled = true
					mat.emission = Color(0.0, 1.0, 0.0)
					grid_mesh.set_surface_override_material(0, mat)
					
				index += 1
