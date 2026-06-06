extends StaticBody3D

var viewport: SubViewport
var screen_mesh: MeshInstance3D

var is_hacked = false
var current_sequence = []
var target_sequence = ["FIREWALL", "DECRYPT", "CORE"]

func _ready():
	# 1. Cream SubViewport-ul
	viewport = SubViewport.new()
	viewport.size = Vector2i(800, 600)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	add_child(viewport)
	
	# 2. Construim UI-ul
	var ui_root = Control.new()
	ui_root.size = Vector2(800, 600)
	viewport.add_child(ui_root)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 1) # Negru
	ui_root.add_child(bg)
	
	var title = Label.new()
	title.text = "=== ECHO CHAMBER MAINFRAME ==="
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0, 1, 0)) # Verde
	title.position = Vector2(0, 50)
	title.size = Vector2(800, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_root.add_child(title)
	
	var btn_firewall = Button.new()
	btn_firewall.text = "> 1. BYPASS FIREWALL <"
	btn_firewall.add_theme_font_size_override("font_size", 24)
	btn_firewall.add_theme_color_override("font_color", Color(0, 1, 0))
	btn_firewall.position = Vector2(200, 200)
	btn_firewall.size = Vector2(400, 50)
	btn_firewall.pressed.connect(_on_btn_pressed.bind("FIREWALL"))
	ui_root.add_child(btn_firewall)
	
	var btn_decrypt = Button.new()
	btn_decrypt.text = "> 2. DECRYPT PROTOCOL <"
	btn_decrypt.add_theme_font_size_override("font_size", 24)
	btn_decrypt.add_theme_color_override("font_color", Color(0, 1, 0))
	btn_decrypt.position = Vector2(200, 300)
	btn_decrypt.size = Vector2(400, 50)
	btn_decrypt.pressed.connect(_on_btn_pressed.bind("DECRYPT"))
	ui_root.add_child(btn_decrypt)
	
	var btn_core = Button.new()
	btn_core.text = "> 3. ACCESS CORE <"
	btn_core.add_theme_font_size_override("font_size", 24)
	btn_core.add_theme_color_override("font_color", Color(0, 1, 0))
	btn_core.position = Vector2(200, 400)
	btn_core.size = Vector2(400, 50)
	btn_core.pressed.connect(_on_btn_pressed.bind("CORE"))
	ui_root.add_child(btn_core)
	
	# 3. Aplicăm textura la Mesh
	screen_mesh = $MonitorMesh/ScreenMesh
	
	var plane = PlaneMesh.new()
	plane.size = Vector2(0.8, 0.6) # Ecran mai mare
	screen_mesh.mesh = plane
	screen_mesh.rotation_degrees.x = 90
	screen_mesh.position.z = 0.21
	
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_mesh.set_surface_override_material(0, mat)
	
	# Ecranul stă stins până ajungem la Faza 3 (după deschiderea seifului)
	screen_mesh.visible = false
	GameEvents.stage_changed.connect(_on_stage_changed)

func _on_stage_changed(new_stage: int):
	if new_stage == 3:
		screen_mesh.visible = true
		AudioManager.play_success()
		print("💻 [Terminal] Sistemul s-a aprins!")

func interact():
	pass

func receive_3d_click(hit_position: Vector3):
	if is_hacked: return
	
	if GameEvents.current_stage < 3:
		print("🔒 [Sistem] Trebuie să deblochezi seiful (Faza 2) mai întâi pentru a obține protocolul de hacking!")
		return
	
	AudioManager.play_click()
	
	if GameEvents.current_stage < 3 or not screen_mesh.visible:
		print("🔒 [Terminal] Este complet oprit. Trebuie pornit mai întâi.")
		return
		
	# Transformăm poziția globală în coordonate locale față de ecran
	var local_hit = screen_mesh.to_local(hit_position)
	
	# Mărimea PlaneMesh-ului
	var screen_width = 0.8
	var screen_height = 0.6
	
	# PlaneMesh e pe planul XZ, rotit cu 90 grade pe X ca sa stea in picioare.
	# Coordonata locala X pe PlaneMesh mapeaza spre axa X.
	# Coordonata locala Z pe PlaneMesh mapeaza pe inaltime (deoarece l-am rotit pe X).
	var u = (local_hit.x + (screen_width / 2.0)) / screen_width
	var v = (local_hit.z + (screen_height / 2.0)) / screen_height
	
	# Dacă click-ul e în afara ecranului (pe ramă), ignorăm
	if u < 0 or u > 1 or v < 0 or v > 1:
		print("⚠️ [Terminal] Click ignorat! UV out of bounds: (", u, ", ", v, ")")
		return
		
	# Transformăm UV în coordonate de pixeli pe Viewport
	var pixel_pos = Vector2(u * viewport.size.x, v * viewport.size.y)
	
	print("🖱️ [Terminal] Trimit click fals la coordonatele 2D: ", pixel_pos)
	
	# Trimitem o mișcare de mouse mai întâi (UI-ul din Godot are nevoie de asta pentru Hover)
	var motion = InputEventMouseMotion.new()
	motion.position = pixel_pos
	viewport.push_input(motion)
	
	# Așteptăm un frame pentru a lăsa UI-ul să proceseze hover-ul
	await get_tree().process_frame
	
	# Creăm un eveniment fals de mouse pentru a păcăli UI-ul
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pixel_pos
	viewport.push_input(event)
	
	# Trimitem și eventul de release pentru buton
	var release_event = event.duplicate()
	release_event.pressed = false
	viewport.push_input(release_event)



func _on_btn_pressed(btn_id: String):
	if is_hacked: return
	
	current_sequence.append(btn_id)
	print("💻 [Terminal] Apăsat: ", btn_id, " | Secvență curentă: ", current_sequence)
	AudioManager.play_click()
	
	# Verificăm dacă secvența introdusă e corectă până acum
	for i in range(current_sequence.size()):
		if current_sequence[i] != target_sequence[i]:
			# A greșit ordinea!
			print("❌ [Terminal] Secvență greșită! Resetare.")
			AudioManager.play_error()
			if has_node("/root/HintAgent"):
				get_node("/root/HintAgent").register_wrong_attempt("terminal_hack")
			current_sequence.clear()
			return
			
	# A introdus-o complet corect!
	if current_sequence.size() == target_sequence.size():
		_hack_successful()

func _hack_successful():
	print("💻 [Terminal] HACK REUȘIT!")
	AudioManager.play_success()
	is_hacked = true
	GameEvents.advance_stage()
	
	var ui_root = viewport.get_child(0)
	
	for child in ui_root.get_children():
		child.queue_free()
		
	var puzzle_data = PuzzleGen.get_puzzle_data("numpad_puzzle")
	var code = "ERROR"
	if puzzle_data.has("solution"):
		code = str(puzzle_data["solution"])
		
	var success_lbl = Label.new()
	success_lbl.text = "ACCESS GRANTED\nESCAPE DOOR PIN:\n" + code
	success_lbl.add_theme_font_size_override("font_size", 40)
	success_lbl.add_theme_color_override("font_color", Color(0, 1, 0))
	success_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	success_lbl.position = Vector2(0, 200)
	success_lbl.size = Vector2(800, 200)
	ui_root.add_child(success_lbl)
