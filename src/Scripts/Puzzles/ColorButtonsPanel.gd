extends Node3D

var target_sequence = []
var current_input = []

# Ordinea fizică a butoanelor pe panou (de la stânga la dreapta)
var button_colors = ["Rosu", "Albastru", "Verde", "Galben"]

func _ready():
	await get_tree().create_timer(0.1).timeout
	var data = PuzzleGen.get_puzzle_data("color_sequence")
	if data.has("solution"):
		target_sequence = data["solution"]
		
	var btn_script = preload("res://Scripts/Puzzles/ColorButton.gd")
	
	# Parcurgem cele 4 butoane
	for i in range(4):
		var btn = get_node_or_null("ColorBtn_" + str(i + 1))
		if btn:
			btn.set_script(btn_script)
			btn.panel_parent = self
			btn.color_name = button_colors[i]
			
			# Colorăm vizual butonul pentru jucător
			var mesh = btn.get_node("MeshInstance3D")
			var mat = StandardMaterial3D.new()
			if button_colors[i] == "Rosu": mat.albedo_color = Color.RED
			elif button_colors[i] == "Albastru": mat.albedo_color = Color.BLUE
			elif button_colors[i] == "Verde": mat.albedo_color = Color.GREEN
			elif button_colors[i] == "Galben": mat.albedo_color = Color.YELLOW
			mesh.set_surface_override_material(0, mat)

func button_pressed(color: String):
	current_input.append(color)
	print("[Culori] Ai apăsat: ", color, " | Secvență curentă: ", current_input)
	
	# Verificăm dacă a greșit undeva
	var is_correct = true
	for i in range(current_input.size()):
		if current_input[i] != target_sequence[i]:
			is_correct = false
			break
			
	if not is_correct:
		print("❌ [ERROR] Culoare greșită! Secvența s-a resetat.")
		current_input.clear()
	elif current_input.size() == target_sequence.size():
		print("✅ [SUCCESS] AI FINALIZAT PUZZLE-UL CULORILOR!")
