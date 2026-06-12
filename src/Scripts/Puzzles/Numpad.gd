extends Node3D

var current_input = ""
var target_code = ""

func _ready():
	# Așteptăm o fracțiune de secundă pentru a ne asigura că PuzzleGen a generat parolele
	await get_tree().create_timer(0.1).timeout
	
	# Preluăm parola (Lock-ul din Camera B)
	var data = PuzzleGen.get_puzzle_data("numpad_puzzle")
	if data.has("solution"):
		target_code = data["solution"]
		
	# Aici e partea MAGICĂ (Varianta A)
	# Pentru a nu te pune să legi 10 scripturi manual pe cele 10 butoane făcute de colegul tău,
	# le injectăm dinamic! Luăm scriptul de Buton...
	var button_script = preload("res://Scripts/Puzzles/NumpadButton.gd")
	
	# Trecem prin butoanele de la 0 la 9
	for i in range(10):
		var btn = get_node_or_null("Button_" + str(i))
		if btn:
			# Adăugăm scriptul pe buton în timp ce rulează jocul
			btn.set_script(button_script)
			# Îi spunem butonului pe ce cifră stă și cine e "Tatăl" (numpad-ul mare)
			btn.numpad_parent = self
			btn.digit_value = str(i)

# Această funcție e chemată de Buton când e lovit cu raza laser a jucătorului
func button_pressed(digit: String):
	# if GameEvents.current_stage < 4:
	# 	print("🔒 [Sistem] Trebuie să obții codul final din Terminal (Faza 3) mai întâi!")
	# 	return
		
	current_input += digit
	AudioManager.play_click()
	
	# Fetch dynamic în caz că DifficultyAgent a modificat lungimea (Faza 3)
	var data = PuzzleGen.get_puzzle_data("numpad_puzzle")
	if data.has("solution"):
		target_code = str(data["solution"])
		
	print("[Numpad] Ai tastat până acum: ", current_input)
	
	# Verificăm dacă jucătorul a băgat toate cele 4 cifre
	if current_input.length() == target_code.length():
		if current_input == target_code:
			AudioManager.play_success()
			print("✅ [SUCCESS] SEIFUL A FOST DESCHIS! Ai salvat situația!")
			
			# --- CROSS-ROOM EFFECT ---
			GameEvents.trigger_escape_door_opened()
		else:
			AudioManager.play_error()
			if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
				GameEvents.rpc("sync_numpad_mistake")
			else:
				GameEvents.sync_numpad_mistake()
			print("❌ [ERROR] Parolă greșită! S-a resetat.")
			if has_node("/root/HintAgent"):
				get_node("/root/HintAgent").register_wrong_attempt("numpad_puzzle")
			if has_node("/root/SaboteurAgent"):
				get_node("/root/SaboteurAgent").register_wrong_attempt("numpad_puzzle", "Player2")
			current_input = "" # Ștergem inputul ca să poată încerca iar
