extends Node

# =============================================================
# HINT AGENT - LLM Director AI
# Pasul 4: Integrare Ollama API + Prompt JSON + Fallback local
# Pasul 5: Actuatori fizici (lumini, sunet, shake, text cu sange)
# =============================================================

# --- CONFIGURARE ---
@export var stuck_time_limit: float = 10.0
@export var ollama_url: String = "http://127.0.0.1:11434/api/generate"
@export var model_name: String = "llama3:8b"

# --- STATE INTERN ---
var is_drawer_opened: bool = false
var active_blood_label: Label3D = null
var stuck_timer: Timer
var http_request: HTTPRequest
var _is_waiting_for_ollama: bool = false
var hints_given_this_stage: int = 0

# --- TELEMETRIE ---
var wrong_attempts: Dictionary = {
	"fuse_puzzle": 0,
	"drawer_puzzle": 0,
	"color_sequence": 0,
	"terminal_hack": 0,
	"numpad_puzzle": 0
}
var hint_history: Array[String] = []

# --- DETALII STAGII ---
const STAGE_DETAILS = {
	1.0: {
		"script": "FuseBox3x3.gd",
		"name": "Tablou Electric (Sigurante)",
		"room": "RoomB",
		"solution_info": "Un grid de 3x3 butoane (sigurante) in RoomB. Jucatorul din RoomA vede pe monitorul verde modelul corect (exact care celule sunt verzi si care sunt gri). Scopul este ca jucatorul din RoomB sa reproduca exact acest model pe panou."
	},
	1.5: {
		"script": "LockedDrawer.gd",
		"name": "Sertar Incuiat (Birou)",
		"room": "RoomA",
		"solution_info": "Sertarul are nevoie de 'Cheie de Birou'. Cheia este ascunsa in Camera B (RoomB), pe una dintre mese sau dulapuri. Jucatorul din RoomB trebuie sa o gaseasca si sa o transmita verbal celuilalt jucator din RoomA."
	},
	2.0: {
		"script": "ColorButtonsPanel.gd",
		"name": "Panou Butoane Colorate",
		"room": "RoomB",
		"solution_info": "Secventa corecta de culori este scrisa pe biletul gasit in sertarul din Camera A (RoomA). Jucatorul din RoomA citeste secventa, iar jucatorul din RoomB apasa butoanele in ordinea corecta."
	},
	3.0: {
		"script": "Terminal.gd",
		"name": "Terminalul de Control",
		"room": "RoomA",
		"solution_info": "Terminalul are 3 optiuni. Ordinea corecta este: BYPASS FIREWALL, DECRYPT PROTOCOL, ACCESS CORE. Jucatorul din RoomA apasa butoanele, jucatorul din RoomB confirma efectele pe monitorul mare."
	},
	4.0: {
		"script": "Numpad.gd",
		"name": "Tastatura Finala (Usa de Iesire)",
		"room": "RoomB",
		"solution_info": "Codul numeric din 4 cifre a fost afisat pe ecranul terminalului dupa hackuire reusita. Jucatorul din RoomA transmite verbal codul, jucatorul din RoomB il introduce la tastatura de langa usa de iesire."
	}
}

# --- FALLBACK LOCAL (cand Ollama nu e disponibil) ---
const FALLBACK_HINTS = {
	1.0: {
		"action": "FLICKER_LIGHTS",
		"hint_text": "Copy the green screen pattern."
	},
	1.5: {
		"action": "SHAKE_OBJECT",
		"hint_text": "Key is in the other room."
	},
	2.0: {
		"action": "SPAWN_BLOOD_TEXT",
		"hint_text": "Read the drawer note order."
	},
	3.0: {
		"action": "FLICKER_LIGHTS",
		"hint_text": "Bypass, decrypt, then access core."
	},
	4.0: {
		"action": "SHAKE_OBJECT",
		"hint_text": "The terminal holds the exit PIN."
	}
}

# =============================================================
# READY
# =============================================================

func _ready():
	stuck_timer = Timer.new()
	stuck_timer.name = "StuckTimer"
	stuck_timer.one_shot = true
	stuck_timer.wait_time = stuck_time_limit
	add_child(stuck_timer)
	stuck_timer.timeout.connect(_on_stuck_timeout)

	# Nod HTTP pentru apelul catre Ollama
	http_request = HTTPRequest.new()
	http_request.name = "OllamaHTTP"
	add_child(http_request)
	http_request.request_completed.connect(_on_ollama_response)

	GameEvents.stage_changed.connect(_on_stage_changed)
	GameEvents.drawer_opened.connect(_on_drawer_opened)
	stuck_timer.start()

	print("[HintAgent] ✅ Directorul AI initializat. Stuck limit: ", stuck_time_limit, "s | Model: ", model_name)

# =============================================================
# HANDLERS SEMNALE
# =============================================================

func _on_stage_changed(_new_stage: int):
	hints_given_this_stage = 0
	_clear_active_blood_label()
	_restart_stuck_timer()
	_is_waiting_for_ollama = false
	print("[HintAgent] 🔄 Etapa noua. Timer resetat.")

func _on_drawer_opened():
	hints_given_this_stage = 0
	is_drawer_opened = true
	_clear_active_blood_label()
	_restart_stuck_timer()
	print("[HintAgent] 🗝️ Sertar deschis. Timer resetat.")

# =============================================================
# TELEMETRIE (Pasul 2)
# =============================================================

func find_node_by_script_name(script_basename: String) -> Node:
	return _find_node_recursive(get_tree().root, script_basename)

func _find_node_recursive(node: Node, script_basename: String) -> Node:
	if not node:
		return null
	var script = node.get_script()
	if script and script.resource_path.get_file() == script_basename:
		return node
	for child in node.get_children():
		var found = _find_node_recursive(child, script_basename)
		if found:
			return found
	return null

func get_telemetry() -> Dictionary:
	var stage = _get_current_stage_key()
	var details = STAGE_DETAILS.get(stage, {})

	var telemetry = {
		"current_stage": stage,
		"target_puzzle": details.get("name", "Necunoscut"),
		"room_id": details.get("room", "Necunoscuta"),
		"player1_pos": "N/A",
		"player2_pos": "N/A",
		"player1_distance_to_target": -1.0,
		"player2_distance_to_target": -1.0,
		"wrong_attempts": wrong_attempts.duplicate(),
		"solution_info": details.get("solution_info", ""),
		"hint_history": hint_history.duplicate()
	}

	var player1 = get_tree().root.find_child("Player1", true, false)
	var player2 = get_tree().root.find_child("Player2", true, false)
	var target_node: Node = null
	var target_script = details.get("script", "")
	if target_script != "":
		target_node = find_node_by_script_name(target_script)

	if player1 and is_instance_valid(player1) and "global_position" in player1:
		var p = player1.global_position
		telemetry["player1_pos"] = "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]
		if target_node and is_instance_valid(target_node) and "global_position" in target_node:
			telemetry["player1_distance_to_target"] = p.distance_to(target_node.global_position)

	if player2 and is_instance_valid(player2) and "global_position" in player2:
		var p = player2.global_position
		telemetry["player2_pos"] = "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]
		if target_node and is_instance_valid(target_node) and "global_position" in target_node:
			telemetry["player2_distance_to_target"] = p.distance_to(target_node.global_position)

	return telemetry

# =============================================================
# GRESELI (Pasul 3)
# =============================================================

func register_wrong_attempt(puzzle_type: String):
	if wrong_attempts.has(puzzle_type):
		wrong_attempts[puzzle_type] += 1
		print("[HintAgent] ❌ Greseala: ", puzzle_type, " (Total: ", wrong_attempts[puzzle_type], ")")
		if stuck_timer and not stuck_timer.is_stopped():
			var remaining = stuck_timer.time_left
			var new_remaining = max(1.0, remaining * 0.5)
			stuck_timer.stop()
			stuck_timer.wait_time = new_remaining
			stuck_timer.start()
			print("[HintAgent] ⏱️ Timer: ", "%.1f" % remaining, "s -> ", "%.1f" % new_remaining, "s")

# =============================================================
# PASUL 4: APEL OLLAMA + PROMPT
# =============================================================

func _on_stuck_timeout():
	if _is_waiting_for_ollama:
		print("[HintAgent] ⚠️ Inca astept raspunsul Ollama. Sar peste aceasta iteratie.")
		stuck_timer.start()
		return

	var stage = _get_current_stage_key()
	var tel = get_telemetry()

	print("[HintAgent] ⏰ Jucatorii blocati la Faza ", stage, ". Construiesc prompt-ul...")
	print("  Player1: ", tel["player1_pos"], " dist=", "%.1f" % tel["player1_distance_to_target"], "m")
	print("  Player2: ", tel["player2_pos"], " dist=", "%.1f" % tel["player2_distance_to_target"], "m")

	var prompt = _build_prompt(tel)
	_call_ollama(prompt)

func _build_prompt(tel: Dictionary) -> String:
	var history_str = "No previous hints."
	if tel["hint_history"].size() > 0:
		history_str = "- " + "\n- ".join(tel["hint_history"])

	var p1_info = "Position: %s, distance to puzzle: %.1fm" % [tel["player1_pos"], tel["player1_distance_to_target"]]
	var p2_info = "Position: %s, distance to puzzle: %.1fm" % [tel["player2_pos"], tel["player2_distance_to_target"]]

	var wrong_str = ""
	for key in tel["wrong_attempts"]:
		if tel["wrong_attempts"][key] > 0:
			wrong_str += "  - %s: %d mistakes\n" % [key, tel["wrong_attempts"][key]]
	if wrong_str == "":
		wrong_str = "  - No mistakes registered yet."

	var prompt = """You are an AI Director for a cooperative horror escape room game in Godot 4.
The players are stuck, and your job is to give them a SUBTLE HINT, stylized as a creepy message left by a previous victim.

=== CURRENT GAME STATE ===
Stage: {stage} | Active Puzzle: {puzzle}
Puzzle Info: {info}

Player 1 (Room A): {p1}
Player 2 (Room B): {p2}

Previous Mistakes:
{wrong}

Previous Hints Given (DO NOT repeat these):
{history}

=== STRICT INSTRUCTIONS ===
Respond EXCLUSIVELY with a valid JSON object. No extra text, no markdown, no explanations.
MANDATORY Structure:
{{
  "thought": "your short internal reasoning about why they are stuck and which action you choose",
  "action": "FLICKER_LIGHTS or SHAKE_OBJECT or SPAWN_BLOOD_TEXT",
  "hint_text": "the hint in ENGLISH, maximum 6 to 8 words, very short and creepy (like a message left by a victim), referencing the active puzzle ({puzzle}) or its room context."
}}

Choose the most appropriate action:
- FLICKER_LIGHTS: to draw attention or create atmosphere (the main lights in both rooms are already fully turned on and functional starting from Stage 1.5+)
- SHAKE_OBJECT: to draw attention directly to the active puzzle node
- SPAWN_BLOOD_TEXT: for cryptic messages spawned on the wall

IMPORTANT:
1. The hint text MUST be in ENGLISH and MUST be extremely short (maximum 6 to 8 words).
2. The hint can be mysterious or abstract (horror/victim style), but it MUST reference the current active puzzle ({puzzle}), its room, or the required action (e.g. searching for a key on tables/shelves, using colors from the note, entering the code at the door). DO NOT use metaphors completely unrelated to the game elements (such as birds flying, etc.).
3. Starting from Stage 1.5, the lights are already fully turned on and functioning normally. DO NOT suggest turning on or fixing the lights!"""

	prompt = prompt.format({
		"stage": str(tel["current_stage"]),
		"puzzle": tel["target_puzzle"],
		"info": tel["solution_info"],
		"p1": p1_info,
		"p2": p2_info,
		"wrong": wrong_str,
		"history": history_str
	})

	return prompt

func _call_ollama(prompt: String):
	var body = JSON.stringify({
		"model": model_name,
		"prompt": prompt,
		"stream": false,
		"format": "json",
		"options": {
			"temperature": 0.3,
			"num_predict": 100
		}
	})

	var headers = ["Content-Type: application/json"]
	var error = http_request.request(ollama_url, headers, HTTPClient.METHOD_POST, body)

	if error == OK:
		_is_waiting_for_ollama = true
		print("[HintAgent] 🤖 Cerere trimisa catre Ollama (", model_name, ")...")
	else:
		print("[HintAgent] ⚠️ Eroare la trimiterea cererii HTTP: ", error, ". Folosesc fallback.")
		_use_fallback()

func _on_ollama_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	_is_waiting_for_ollama = false

	# Reporneste timer-ul indiferent de rezultat
	_restart_stuck_timer()

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[HintAgent] ⚠️ Ollama a raspuns cu eroare (HTTP ", response_code, "). Fallback.")
		_use_fallback()
		return

	var response_text = body.get_string_from_utf8()
	var outer_json = JSON.parse_string(response_text)
	if not outer_json or not outer_json.has("response"):
		print("[HintAgent] ⚠️ JSON invalid de la Ollama. Fallback.")
		_use_fallback()
		return

	# Ollama returneaza raspunsul LLM in campul "response"
	var inner_text = outer_json["response"].strip_edges()
	print("[HintAgent] 🤖 Raspuns brut Ollama: ", inner_text)

	var parsed = JSON.parse_string(inner_text)
	if not parsed or not parsed.has("hint_text"):
		print("[HintAgent] ⚠️ LLM nu a returnat JSON valid. Fallback.")
		_use_fallback()
		return

	var action = parsed.get("action", "SPAWN_BLOOD_TEXT")
	var hint_text = parsed.get("hint_text", "")
	var thought = parsed.get("thought", "")

	print("[HintAgent] 🧠 Thought: ", thought)
	print("[HintAgent] 💬 Hint: ", hint_text)
	print("[HintAgent] 🎬 Actiune: ", action)

	_execute_hint(action, hint_text)

func _use_fallback():
	var stage = _get_current_stage_key()
	var fallback = FALLBACK_HINTS.get(stage, {
		"action": "SPAWN_BLOOD_TEXT",
		"hint_text": "...continua sa cauti... raspunsul este chiar in fata ta..."
	})
	print("[HintAgent] 🔁 Fallback activ: ", fallback["hint_text"])
	_execute_hint(fallback["action"], fallback["hint_text"])

	# Reporneste timer-ul
	_restart_stuck_timer()

# =============================================================
# PASUL 5: ACTUATORI FIZICI
# =============================================================

func _execute_hint(action: String, hint_text: String):
	hints_given_this_stage += 1
	
	# Salvam in history (max 3 elemente)
	hint_history.append(hint_text)
	if hint_history.size() > 3:
		hint_history.pop_front()

	var stage = _get_current_stage_key()
	var details = STAGE_DETAILS.get(stage, {})
	var target_script = details.get("script", "")
	var target_node: Node = null
	if target_script != "":
		target_node = find_node_by_script_name(target_script)

	match action:
		"FLICKER_LIGHTS":
			_do_flicker_lights(details.get("room", "RoomA"))
		"SHAKE_OBJECT":
			if target_node:
				_do_shake_object(target_node)
			else:
				_do_flicker_lights(details.get("room", "RoomA"))
		"SPAWN_BLOOD_TEXT":
			pass  # mereu spawnam text mai jos
		_:
			print("[HintAgent] Actiune necunoscuta: ", action)

	# Intotdeauna spawn text cu sange (indiferent de actiune, ca backup vizual)
	if hint_text != "":
		var spawn_pos = Vector3(6, 1.5, 0.1)  # default langa peretele din RoomA
		if target_node and is_instance_valid(target_node) and "global_position" in target_node:
			spawn_pos = _get_wall_position_near(target_node.global_position)
		_spawn_blood_text(hint_text, spawn_pos)

# --- Actuator 1: Palpairea luminilor ---
func _do_flicker_lights(room_id: String):
	print("[HintAgent] 💡 Declanseaza palpaiere in ", room_id)
	# Gasim lumina din camera tinta prin script
	var lights = _find_all_nodes_by_script("CeilingLightLogic.gd")
	for light_node in lights:
		var parent_name = light_node.get_parent().name if light_node.get_parent() else ""
		if parent_name == room_id:
			if light_node.has_method("flicker_sequence"):
				light_node.flicker_sequence()
			return
	# Daca nu gasim dupa camera, facem prima lumina gasita sa palpaie
	if lights.size() > 0 and lights[0].has_method("flicker_sequence"):
		lights[0].flicker_sequence()

func _find_all_nodes_by_script(script_basename: String) -> Array:
	var results: Array = []
	_find_all_recursive(get_tree().root, script_basename, results)
	return results

func _find_all_recursive(node: Node, script_basename: String, results: Array):
	if not node:
		return
	var script = node.get_script()
	if script and script.resource_path.get_file() == script_basename:
		results.append(node)
	for child in node.get_children():
		_find_all_recursive(child, script_basename, results)

# --- Actuator 2: Shake pe obiectul puzzle ---
func _do_shake_object(target_node: Node):
	if not ("position" in target_node):
		return
	print("[HintAgent] 📳 Shake pe: ", target_node.name)
	var orig_pos = target_node.position
	var tween = create_tween()
	tween.set_loops(4)
	tween.tween_property(target_node, "position", orig_pos + Vector3(0.05, 0, 0), 0.06)
	tween.tween_property(target_node, "position", orig_pos + Vector3(-0.05, 0, 0), 0.06)
	tween.tween_property(target_node, "position", orig_pos + Vector3(0, 0, 0.05), 0.06)
	tween.tween_property(target_node, "position", orig_pos, 0.06)

# --- Actuator 3: Text cu sange pe perete ---
func _get_wall_position_near(puzzle_pos: Vector3) -> Vector3:
	# Gasim cel mai apropriat perete (marginile camerelor)
	# RoomA: X=[0,12], Z=[0,12] | RoomB: X=[100,112], Z=[0,12]
	var room_bounds: Array
	if puzzle_pos.x > 50:
		room_bounds = [100.0, 112.0, 0.0, 12.0]  # RoomB
	else:
		room_bounds = [0.0, 12.0, 0.0, 12.0]  # RoomA

	var min_x = room_bounds[0]
	var max_x = room_bounds[1]
	var min_z = room_bounds[2]
	var max_z = room_bounds[3]

	# Distanta pana la fiecare perete
	var dist_left   = puzzle_pos.x - min_x
	var dist_right  = max_x - puzzle_pos.x
	var dist_front  = puzzle_pos.z - min_z
	var dist_back   = max_z - puzzle_pos.z

	var min_dist = min(min(dist_left, dist_right), min(dist_front, dist_back))

	var wall_pos = puzzle_pos
	var wall_height = 1.6  # inaltimea la care apare textul (la nivelul ochilor)

	if min_dist == dist_left:
		wall_pos = Vector3(min_x + 0.05, wall_height, puzzle_pos.z)
	elif min_dist == dist_right:
		wall_pos = Vector3(max_x - 0.05, wall_height, puzzle_pos.z)
	elif min_dist == dist_front:
		wall_pos = Vector3(puzzle_pos.x, wall_height, min_z + 0.05)
	else:
		wall_pos = Vector3(puzzle_pos.x, wall_height, max_z - 0.05)

	return wall_pos

func _spawn_blood_text(text: String, wall_pos: Vector3):
	# Stergem textul vechi daca exista
	_clear_active_blood_label()

	print("[HintAgent] 🩸 Spawn text pe perete la: ", wall_pos)

	var label = Label3D.new()
	label.text = text
	label.font_size = 72
	label.outline_size = 20
	
	var custom_font = SystemFont.new()
	custom_font.font_names = ["Chiller", "Bloodthirsty", "Creepster", "Impact"]
	label.font = custom_font
	
	label.modulate = Color(1.0, 0.0, 0.0, 0.0)  # Rosu pur, transparent la inceput
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.width = 1000.0
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # Intotdeauna spre jucator
	label.no_depth_test = true  # Apare in fata geometriei (peretii intunecati)
	label.pixel_size = 0.006  # Dublu mai mare in lumea 3D
	label.shaded = false  # Self-illuminat, nu este afectat de lumina scenei

	# Pozitionam - cu BILLBOARD_ENABLED nu mai trebuie look_at
	# Ridicam textul putin pentru a fi la nivelul ochilor
	var elevated_pos = wall_pos + Vector3(0, 0.3, 0)
	
	get_tree().root.add_child(label)
	label.global_position = elevated_pos
	active_blood_label = label

	# Fade-in in 2 secunde (rosu pur, vizibil in intuneric)
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1.0, 0.0, 0.0, 1.0), 2.0)
	tween.parallel().tween_property(label, "outline_modulate", Color(0.0, 0.0, 0.0, 1.0), 2.0)
	
	# Auto-fade out dupa 60 secunde si stergere automata
	tween.tween_interval(60.0)
	tween.tween_property(label, "modulate:a", 0.0, 3.0)
	tween.parallel().tween_property(label, "outline_modulate:a", 0.0, 3.0)
	tween.tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
			if active_blood_label == label:
				active_blood_label = null
	)

# =============================================================
# HELPERS
# =============================================================

func _restart_stuck_timer():
	if stuck_timer:
		stuck_timer.stop()
		var current_limit = max(60.0, stuck_time_limit - (hints_given_this_stage * 120.0))
		stuck_timer.wait_time = current_limit
		stuck_timer.start()
		print("[HintAgent] ⏱️ Timer resetat la ", "%.1f" % current_limit, "s")

func _get_current_stage_key() -> float:
	if GameEvents.current_stage == 2 and not is_drawer_opened:
		return 1.5
	return float(GameEvents.current_stage)

func _clear_active_blood_label():
	if active_blood_label and is_instance_valid(active_blood_label):
		# Fade-out rapid inainte de stergere
		var tween = create_tween()
		tween.tween_property(active_blood_label, "modulate:a", 0.0, 0.5)
		await tween.finished
		if active_blood_label and is_instance_valid(active_blood_label):
			active_blood_label.queue_free()
		active_blood_label = null
		print("[HintAgent] 🧹 Indiciul vechi sters.")
