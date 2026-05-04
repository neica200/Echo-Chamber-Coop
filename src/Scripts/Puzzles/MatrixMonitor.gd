extends Node3D

func _ready():
	await get_tree().create_timer(0.1).timeout
	var data = PuzzleGen.get_puzzle_data("grid_puzzle")
	
	if data.has("solution"):
		var grid = data["solution"]
		var index = 0
		
		# Trecem prin axele matricei, la fel cum au fost numite nodurile de colegul tău (Grid_X_Y)
		for y in range(3):
			for x in range(3):
				var node_name = "Grid_" + str(x) + "_" + str(y)
				var grid_mesh = get_node_or_null(node_name)
				
				# Dacă în soluție acest pătrat e "true", îl aprindem verde!
				if grid_mesh and grid[index] == true:
					var mat = StandardMaterial3D.new()
					mat.albedo_color = Color(0.0, 0.8, 0.0) # Verde
					mat.emission_enabled = true
					mat.emission = Color(0.0, 1.0, 0.0)
					grid_mesh.set_surface_override_material(0, mat)
					
				index += 1
