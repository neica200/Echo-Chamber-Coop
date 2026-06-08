extends Node

# ==============================================================================
# SABOTEUR AGENT - LLM Atmospheric Director / Paranoia System
# Roluri:
#   1. Monitorizează telemetria jucătorilor (poziție, timp blocat, nivel de panică)
#   2. Interogheaza Ollama LLM pentru a decide actiunea de sperietoare potrivita
#   3. Coordoneaza cu HintAgent pentru a evita cereri concurente catre Ollama
#   4. Executa actuatorii fizici: pasi, bufnitura usa, intuneric, izolare, indici falsi
# ==============================================================================

# --- CONFIGURARE ---
@export var ollama_url: String = "http://127.0.0.1:11434/api/generate"
@export var model_name: String = "llama3:8b"
@export var base_cooldown: float = 45.0       # Secunde intre doua sperieturi
@export var idle_threshold: float = 20.0      # Secunde fara miscare pana cand creste tensiunea

# --- STATE INTERN ---
var _is_waiting_for_ollama: bool = false
var _cooldown_timer: Timer
var _http_request: HTTPRequest
var _tension: float = 0.0                     # 0.0 → 1.0  (creste in timp)
var _player1_panic: float = 0.0              # Nivel de panica individual
var _player2_panic: float = 0.0

# --- TRACKING POZITII (detectare inactivitate) ---
var _last_player1_pos: Vector3 = Vector3.ZERO
var _last_player2_pos: Vector3 = Vector3.ZERO
var _player1_idle_time: float = 0.0
var _player2_idle_time: float = 0.0

# --- HUD / UI izolare activa ---
var _isolation_overlay: CanvasLayer = null
var _active_fake_notes: Array = []            # Referinte la notitele false spawned
var game_events = null
var audio_manager = null
var hint_agent = null

# --- FALLBACK STATIC (cand Ollama nu e disponibil) ---
const FALLBACK_ACTIONS = {
	1: { "action": "DOOR_SLAM", "glitch_text": "They hear your thoughts.", "target_player": "Both" },
	2: { "action": "LIGHT_BLACKOUT", "glitch_text": "The system sees you.", "target_player": "Both" },
	3: { "action": "PLAYER_ISOLATION", "glitch_text": "Trust no one.", "target_player": "Player1" },
	4: { "action": "SPAWN_FAKE_CLUE",
		 "glitch_text": "Wrong path.",
		 "fake_clue_content": "OVERRIDE CODE:\n7-7-7-7",
		 "target_player": "Player2" }
}

# Indicii false hardcodate per stadiu (folosite ca fallback pentru SPAWN_FAKE_CLUE)
const FALLBACK_FAKE_CLUES = {
	1.0: "GRID PATTERN:\nX _ X\n_ X _\nX _ X\n(Wrong pattern!)",
	2.0: "COLOR ORDER:\nRed → Blue → Red → Green\n(Wrong order!)",
	3.0: "TERMINAL SEQUENCE:\nACCESS CORE → BYPASS → DECRYPT\n(Wrong sequence!)",
	4.0: "EXIT CODE:\n0 0 0 0\n(Wrong code!)"
}

# ==============================================================================
# READY
# ==============================================================================

func _ready():
	# --- Timer pentru cooldown intre sperieturi ---
	_cooldown_timer = Timer.new()
	_cooldown_timer.name = "SaboteurCooldown"
	_cooldown_timer.one_shot = true
	_cooldown_timer.wait_time = base_cooldown
	add_child(_cooldown_timer)
	_cooldown_timer.timeout.connect(_on_cooldown_expired)

	# --- HTTP Request pentru Ollama ---
	_http_request = HTTPRequest.new()
	_http_request.name = "SaboteurHTTP"
	add_child(_http_request)
	_http_request.request_completed.connect(_on_ollama_response)

	if not game_events:
		game_events = get_node_or_null("/root/GameEvents")
	if not audio_manager:
		audio_manager = get_node_or_null("/root/AudioManager")
	if not hint_agent:
		hint_agent = get_node_or_null("/root/HintAgent")

	# --- Ascultam semnalele globale pentru a reseta tensiunea la progres ---
	if game_events:
		game_events.stage_changed.connect(_on_stage_changed)
		game_events.puzzle_solved.connect(_on_puzzle_solved)

	# Pornim cu un delay aleator ca sa nu fie sincron cu HintAgent
	var startup_delay = randf_range(8.0, 15.0)
	await get_tree().create_timer(startup_delay).timeout
	_cooldown_timer.start()

	print("[SaboteurAgent] 😈 Agentul Saboteur s-a initializat. Cooldown: %.0fs | Model: %s" % [base_cooldown, model_name])

# ==============================================================================
# PROCESS — Actualizare tensiune si detectare inactivitate
# ==============================================================================

func _process(delta: float):
	_update_player_idle_tracking(delta)
	_update_tension(delta)

func _update_player_idle_tracking(delta: float):
	var player1 = get_tree().root.find_child("Player1", true, false)
	var player2 = get_tree().root.find_child("Player2", true, false)

	if player1 and is_instance_valid(player1) and "global_position" in player1:
		var dist = player1.global_position.distance_to(_last_player1_pos)
		if dist < 0.3:
			_player1_idle_time += delta
		else:
			_player1_idle_time = 0.0
			_last_player1_pos = player1.global_position
			# Miscare reduce panica usor
			_player1_panic = max(0.0, _player1_panic - delta * 0.05)

	if player2 and is_instance_valid(player2) and "global_position" in player2:
		var dist = player2.global_position.distance_to(_last_player2_pos)
		if dist < 0.3:
			_player2_idle_time += delta
		else:
			_player2_idle_time = 0.0
			_last_player2_pos = player2.global_position
			_player2_panic = max(0.0, _player2_panic - delta * 0.05)

func _update_tension(delta: float):
	# Tensiunea creste mai repede daca ambii jucatori sunt nemiscati
	var idle_multiplier = 1.0
	if _player1_idle_time > idle_threshold and _player2_idle_time > idle_threshold:
		idle_multiplier = 2.5
	elif _player1_idle_time > idle_threshold or _player2_idle_time > idle_threshold:
		idle_multiplier = 1.5

	_tension = min(1.0, _tension + delta * 0.015 * idle_multiplier)

# ==============================================================================
# HANDLERS SEMNALE
# ==============================================================================

func _on_stage_changed(_new_stage: int):
	# Progresul in joc reduce tensiunea
	_tension = max(0.0, _tension - 0.4)
	_player1_panic = max(0.0, _player1_panic - 0.2)
	_player2_panic = max(0.0, _player2_panic - 0.2)
	print("[SaboteurAgent] ✅ Progres detectat. Tensiune: %.2f" % _tension)

func _on_puzzle_solved(_puzzle_id: String):
	_tension = max(0.0, _tension - 0.2)

# ==============================================================================
# API PUBLIC — apelat de scripturile de puzzle la fiecare greseala
# (La fel ca HintAgent.register_wrong_attempt, dar pentru panica/tensiune)
# ==============================================================================

func register_wrong_attempt(puzzle_type: String, player_name: String = "Both"):
	print("[SaboteurAgent] 💢 Greseala la: %s (jucator: %s)" % [puzzle_type, player_name])

	# Crestem tensiunea si panica imediat
	_tension = min(1.0, _tension + 0.12)
	if player_name == "Player1" or player_name == "Both":
		_player1_panic = min(1.0, _player1_panic + 0.15)
	if player_name == "Player2" or player_name == "Both":
		_player2_panic = min(1.0, _player2_panic + 0.15)

	# Daca tensiunea a sarit de 0.5, scurtam cooldown-ul la 10 secunde
	if _tension > 0.5 and not _cooldown_timer.is_stopped():
		var remaining = _cooldown_timer.time_left
		if remaining > 10.0:
			_cooldown_timer.stop()
			_cooldown_timer.start(10.0)
			print("[SaboteurAgent] ⚡ Cooldown redus la 10s din cauza greselilor repetate!")

# ==============================================================================
# COOLDOWN EXPIRAT — Decidem daca actionam
# ==============================================================================

func _on_cooldown_expired():
	# ======================================================================
	# COORDONARE CU HINTAGENT — evitam cereri concurente catre Ollama
	# ======================================================================
	if hint_agent and hint_agent._is_waiting_for_ollama:
		print("[SaboteurAgent] ⏳ HintAgent foloseste Ollama. Astept 6 secunde...")
		await get_tree().create_timer(6.0).timeout
		# Daca inca asteapta, folosim fallback direct
		if hint_agent and hint_agent._is_waiting_for_ollama:
			print("[SaboteurAgent] ⚡ Ollama inca ocupat. Activez fallback.")
			_use_fallback()
			return

	if _is_waiting_for_ollama:
		print("[SaboteurAgent] ⚠️ Inca astept propria cerere Ollama.")
		_cooldown_timer.start(base_cooldown)
		return

	# Construim si trimitem promptul
	var tel = _build_telemetry()
	var prompt = _build_prompt(tel)
	_call_ollama(prompt)

# ==============================================================================
# TELEMETRIE
# ==============================================================================

func _build_telemetry() -> Dictionary:
	var player1 = get_tree().root.find_child("Player1", true, false)
	var player2 = get_tree().root.find_child("Player2", true, false)
	var stage = float(game_events.current_stage if game_events else 1.0)

	return {
		"stage": stage,
		"tension": _tension,
		"player1_panic": _player1_panic,
		"player2_panic": _player2_panic,
		"player1_idle_seconds": _player1_idle_time,
		"player2_idle_seconds": _player2_idle_time,
		"player1_pos": ("(%.1f,%.1f,%.1f)" % [player1.global_position.x, player1.global_position.y, player1.global_position.z]) if (player1 and is_instance_valid(player1) and "global_position" in player1) else "N/A",
		"player2_pos": ("(%.1f,%.1f,%.1f)" % [player2.global_position.x, player2.global_position.y, player2.global_position.z]) if (player2 and is_instance_valid(player2) and "global_position" in player2) else "N/A"
	}

# ==============================================================================
# LLM PROMPT
# ==============================================================================

func _build_prompt(tel: Dictionary) -> String:
	var stage_context = _get_stage_context(tel["stage"])
	var prompt = """You are the SABOTEUR ENTITY controlling an escape room horror game in Godot 4.
Your purpose is to increase paranoia and terror among the players.

=== CURRENT GAME STATE ===
Stage: {stage}
Stage Context: {stage_ctx}
Overall Tension Level: {tension} (0.0 = calm, 1.0 = maximum terror)
Player 1 Panic: {p1_panic} | Idle for: {p1_idle}s | Position: {p1_pos}
Player 2 Panic: {p2_panic} | Idle for: {p2_idle}s | Position: {p2_pos}

=== YOUR MISSION ===
Choose ONE scare action to execute RIGHT NOW.
Respond ONLY with a valid JSON object. No extra text, no markdown.

MANDATORY Structure:
{{
  "thought": "brief internal reasoning (max 20 words)",
  "action": "DOOR_SLAM or LIGHT_BLACKOUT or PLAYER_ISOLATION or SPAWN_FAKE_CLUE",
  "glitch_text": "creepy message shown on screen, maximum 5 words",
  "fake_clue_content": "ONLY if action is SPAWN_FAKE_CLUE: the wrong puzzle instruction to display on the fake note. Otherwise leave empty string.",
  "target_player": "Player1 or Player2 or Both"
}}

=== ACTIONS EXPLAINED ===
- DOOR_SLAM: heavy distant thud sound from outside walls
- LIGHT_BLACKOUT: lights turn off briefly (5-8 seconds) then return
- PLAYER_ISOLATION: movement and interaction locked for 6 seconds with glitch overlay
- SPAWN_FAKE_CLUE: spawn a physical note with wrong puzzle instructions in target_player's room

IMPORTANT:
1. Choose one of the 4 actions completely at random to keep the experience unpredictable. Do NOT base your choice on tension or panic levels.
2. glitch_text MUST be in English and maximum 5 words."""

	prompt = prompt.format({
		"stage": str(tel["stage"]),
		"stage_ctx": stage_context,
		"tension": "%.2f" % tel["tension"],
		"p1_panic": "%.2f" % tel["player1_panic"],
		"p1_idle": "%.0f" % tel["player1_idle_seconds"],
		"p1_pos": tel["player1_pos"],
		"p2_panic": "%.2f" % tel["player2_panic"],
		"p2_idle": "%.0f" % tel["player2_idle_seconds"],
		"p2_pos": tel["player2_pos"]
	})
	return prompt

func _get_stage_context(stage: float) -> String:
	match stage:
		1.0: return "Players must solve 3x3 grid fuse puzzle in Room B to turn on lights."
		2.0: return "Player A needs the color hint from the drawer. Player B must input the correct color sequence."
		3.0: return "Player A hacks the terminal (Bypass→Decrypt→Access Core) to reveal the PIN."
		4.0: return "Player B inputs the PIN on the numpad at the exit door."
		_: return  "Unknown stage."

# ==============================================================================
# OLLAMA HTTP
# ==============================================================================

func _call_ollama(prompt: String):
	var body = JSON.stringify({
		"model": model_name,
		"prompt": prompt,
		"stream": false,
		"format": "json",
		"options": {
			"temperature": 0.9,
			"num_predict": 150
		}
	})
	var headers = ["Content-Type: application/json"]
	var error = _http_request.request(ollama_url, headers, HTTPClient.METHOD_POST, body)

	if error == OK:
		_is_waiting_for_ollama = true
		print("[SaboteurAgent] 🤖 Cerere trimisa catre Ollama...")
	else:
		print("[SaboteurAgent] ⚠️ Eroare HTTP: %d. Folosesc fallback." % error)
		_use_fallback()

func _on_ollama_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	_is_waiting_for_ollama = false
	_cooldown_timer.start(base_cooldown)

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[SaboteurAgent] ⚠️ Ollama eroare HTTP %d. Fallback." % response_code)
		_use_fallback()
		return

	var response_text = body.get_string_from_utf8()
	var outer_json = JSON.parse_string(response_text)
	if not outer_json or not outer_json.has("response"):
		print("[SaboteurAgent] ⚠️ JSON invalid de la Ollama. Fallback.")
		_use_fallback()
		return

	var inner_text = outer_json["response"].strip_edges()
	print("[SaboteurAgent] 🎭 Raspuns brut: ", inner_text.left(120), "...")

	var parsed = JSON.parse_string(inner_text)
	if not parsed or not parsed.has("action"):
		print("[SaboteurAgent] ⚠️ LLM nu a returnat JSON valid. Fallback.")
		_use_fallback()
		return

	var action      = parsed.get("action", "NONE")
	var glitch_text = parsed.get("glitch_text", "")
	var fake_clue   = parsed.get("fake_clue_content", "")
	var target      = parsed.get("target_player", "Both")
	var thought     = parsed.get("thought", "")

	print("[SaboteurAgent] 🧠 Thought: ", thought)
	print("[SaboteurAgent] 🎬 Action: %s | Target: %s" % [action, target])
	print("[SaboteurAgent] 👻 Glitch text: ", glitch_text)

	_execute_action(action, glitch_text, fake_clue, target)

func _use_fallback():
	var actions = ["DOOR_SLAM", "LIGHT_BLACKOUT", "PLAYER_ISOLATION", "SPAWN_FAKE_CLUE"]
	var chosen_action = actions[randi() % actions.size()]
	
	var glitch_texts = [
		"They hear your thoughts.",
		"The system sees you.",
		"Trust no one.",
		"Wrong path.",
		"Run away.",
		"No escape.",
		"Behind you."
	]
	var glitch_text = glitch_texts[randi() % glitch_texts.size()]
	
	var target = "Player1" if randf() < 0.5 else "Player2"
	if chosen_action == "LIGHT_BLACKOUT" and randf() < 0.3:
		target = "Both"
	
	var fake_clue = ""
	if chosen_action == "SPAWN_FAKE_CLUE":
		var stage_key = float(game_events.current_stage if game_events else 1.0)
		fake_clue = FALLBACK_FAKE_CLUES.get(stage_key, "ERROR:\nData corrupted.\n(Ignore this note.)")
		
	print("[SaboteurAgent] 🔁 Fallback random choice: ", chosen_action)
	_execute_action(chosen_action, glitch_text, fake_clue, target)
	_cooldown_timer.start(base_cooldown)

# ==============================================================================
# EXECUTIE ACTIUNI
# ==============================================================================

func _execute_action(action: String, glitch_text: String, fake_clue: String, target: String):
	# Creste panica
	if target == "Player1" or target == "Both":
		_player1_panic = min(1.0, _player1_panic + 0.25)
	if target == "Player2" or target == "Both":
		_player2_panic = min(1.0, _player2_panic + 0.25)

	# Afisam glitch_text pentru TOATE actiunile (cu exceptia celor care il gestioneaza intern)
	if glitch_text != "" and action != "ASYMMETRIC_WHISPER" and action != "PLAYER_ISOLATION":
		_show_glitch_text(glitch_text)

	match action:
		"DOOR_SLAM":
			_do_door_slam(target)
		"FOOTSTEPS":
			_do_footsteps(target)
		"VENTILATION_SHUTDOWN":
			_do_ventilation_shutdown()
		"LIGHT_BLACKOUT":
			_do_light_blackout(target)
		"PLAYER_ISOLATION":
			_do_player_isolation(target, glitch_text)
		"ASYMMETRIC_WHISPER":
			_do_asymmetric_whisper(target, glitch_text)
		"SPAWN_FAKE_CLUE":
			_do_spawn_fake_clue(target, fake_clue)
		"NONE":
			print("[SaboteurAgent] 💤 Actiune NONE aleasa. Astept urmatorul ciclu.")
		_:
			print("[SaboteurAgent] ❓ Actiune necunoscuta: ", action)

# ==============================================================================
# AFISARE GLITCH TEXT (subtitlu creepy pentru orice actiune)
# ==============================================================================

func _show_glitch_text(text: String):
	var overlay = CanvasLayer.new()
	overlay.layer = 9
	get_tree().root.add_child(overlay)

	var label = Label.new()
	label.text = text.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.anchor_top = 0.80
	label.anchor_bottom = 0.90
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(0.85, 0.05, 0.05, 0.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)

	# Fade-in rapida, ramane 3s, fade-out
	var tween = create_tween()
	tween.tween_property(label, "theme_override_colors/font_color", Color(0.85, 0.05, 0.05, 1.0), 0.4)
	tween.tween_interval(3.0)
	tween.tween_property(label, "theme_override_colors/font_color", Color(0.85, 0.05, 0.05, 0.0), 1.0)
	tween.tween_callback(func(): if is_instance_valid(overlay): overlay.queue_free())

# ==============================================================================
# ACTUATOR 1: DOOR SLAM
# Thuds si camera shake de la usa de departare
# ==============================================================================

func _do_door_slam(target: String):
	print("[SaboteurAgent] 🚪 DOOR SLAM!")
	var player = _get_target_player(target)
	if not player:
		return

	_ensure_audio_listener(player)

	# Cream un AudioStreamPlayer3D temporar departe de jucator
	var audio = AudioStreamPlayer3D.new()
	audio.max_distance = 30.0
	audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	get_tree().root.add_child(audio)

	# Pozitionam sunetul departe de jucator (in spatele peretelui)
	var player_pos = player.global_position if "global_position" in player else Vector3.ZERO
	audio.global_position = player_pos + Vector3(randf_range(-8, 8), 0, -10)

	# Incarcam fail.mp3 pe care il tunam jos ca sa sune ca o bufnitura
	if FileAccess.file_exists("res://sounds/fail.mp3"):
		var stream = load("res://sounds/fail.mp3")
		audio.stream = stream
		audio.pitch_scale = 0.3   # Foarte jos = bufnitura profunda
		audio.volume_db = 8.0
		audio.play()

	# Camera shake
	_do_camera_shake(player, 0.3, 0.15)

	# Stergem nodul audio dupa 3 secunde
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(audio):
		audio.queue_free()

# ==============================================================================
# ACTUATOR 2: FOOTSTEPS
# Pasi spatiali care panoreaza in jurul jucatorului
# ==============================================================================

func _do_footsteps(target: String):
	print("[SaboteurAgent] 👣 FOOTSTEPS!")
	var player = _get_target_player(target)
	if not player or not "global_position" in player:
		print("[SaboteurAgent] ⚠️ Jucatorul tinta nu a fost gasit pentru FOOTSTEPS!")
		return

	_ensure_audio_listener(player)

	var player_pos = player.global_position

	for i in range(4):
		await get_tree().create_timer(0.5).timeout

		var audio = AudioStreamPlayer3D.new()
		audio.max_distance = 15.0
		get_tree().root.add_child(audio)

		# Pasi care se apropie progresiv de jucator
		var angle = randf_range(0, TAU)
		var dist = 6.0 - float(i) * 1.2
		audio.global_position = player_pos + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

		if FileAccess.file_exists("res://sounds/click.mp3"):
			audio.stream = load("res://sounds/click.mp3")
			audio.pitch_scale = randf_range(0.4, 0.6)
			audio.volume_db = 4.0 + float(i) * 2.0
			audio.play()
			print("[SaboteurAgent] 👣 Pas ", i+1, " la dist=", "%.1f" % dist, "m, unghi=", "%.0f" % rad_to_deg(angle), "deg")

		await get_tree().create_timer(0.8).timeout
		if is_instance_valid(audio):
			audio.queue_free()

# ==============================================================================
# ACTUATOR 3: VENTILATION SHUTDOWN
# Muzica de fundal se opreste treptat → tacere infioratoare
# ==============================================================================

func _do_ventilation_shutdown():
	print("[SaboteurAgent] 🔇 VENTILATION SHUTDOWN!")
	var bg_player = audio_manager.get_node_or_null("BGMusic") if (audio_manager and audio_manager.has_node("BGMusic")) else null

	# Reducere volum din AudioManager direct
	var tween = create_tween()
	tween.tween_method(func(vol: float):
		if audio_manager and audio_manager.has_method("set_bg_volume"):
			audio_manager.set_bg_volume(vol)
		elif audio_manager and "bg_player" in audio_manager and is_instance_valid(audio_manager.bg_player):
			audio_manager.bg_player.volume_db = vol
	, -10.0, -60.0, 3.0)

	# Dupa 10 secunde de liniste, redaream muzica
	await get_tree().create_timer(13.0).timeout
	var tween2 = create_tween()
	tween2.tween_method(func(vol: float):
		if audio_manager and "bg_player" in audio_manager and is_instance_valid(audio_manager.bg_player):
			audio_manager.bg_player.volume_db = vol
	, -60.0, -10.0, 4.0)

# ==============================================================================
# ACTUATOR 4: LIGHT BLACKOUT
# Stingem luminile in camera tintita
# ==============================================================================

func _do_light_blackout(target: String):
	print("[SaboteurAgent] 🌑 LIGHT BLACKOUT!")
	var room_id = "RoomA" if target == "Player1" else "RoomB"
	if target == "Both":
		room_id = "RoomA"  # Stingem pe rand

	# Stingem prin semnalul GameEvents
	if game_events:
		game_events.room_lights_toggled.emit(room_id, false)

	# Dupa 6 secunde reaprindem
	await get_tree().create_timer(6.0).timeout
	if game_events:
		game_events.room_lights_toggled.emit(room_id, true)

	# Daca e Both, stingem si RoomB cu un mic delay
	if target == "Both":
		if game_events:
			game_events.room_lights_toggled.emit("RoomB", false)
		await get_tree().create_timer(6.0).timeout
		if game_events:
			game_events.room_lights_toggled.emit("RoomB", true)

# ==============================================================================
# ACTUATOR 5: PLAYER ISOLATION
# Blocam miscarea, afisam overlay de interferenta, redaream zgomot static
# ==============================================================================

func _do_player_isolation(target: String, glitch_text: String):
	print("[SaboteurAgent] 🔒 PLAYER ISOLATION!")
	var player = _get_target_player(target)
	if not player or not player.has_method("exit_focus"):
		return

	# Iesim din focus mode mai intai
	if player.is_focused:
		player.exit_focus()

	# Blocam controlul jucatorului
	player.is_active = false

	# Spawnam overlay de interferenta
	var overlay = _spawn_isolation_overlay(glitch_text)

	# Redaream fail.mp3 pituit sus ca zgomot static
	var static_audio = AudioStreamPlayer.new()
	add_child(static_audio)
	if FileAccess.file_exists("res://sounds/fail.mp3"):
		static_audio.stream = load("res://sounds/fail.mp3")
		static_audio.pitch_scale = 3.5
		static_audio.volume_db = -5.0
		static_audio.play()

	# Dupa 6 secunde eliberam controlul
	await get_tree().create_timer(6.0).timeout

	player.is_active = true
	if overlay and is_instance_valid(overlay):
		overlay.queue_free()
		_isolation_overlay = null
	if is_instance_valid(static_audio):
		static_audio.queue_free()

	print("[SaboteurAgent] ✅ Izolarea s-a terminat. Jucatorul are din nou control.")

func _spawn_isolation_overlay(glitch_text: String) -> CanvasLayer:
	var overlay = CanvasLayer.new()
	overlay.layer = 10  # Deasupra oricarui HUD
	get_tree().root.add_child(overlay)
	_isolation_overlay = overlay

	# Fundal semi-transparent negru
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bg)

	# Text glitch
	var label = Label.new()
	label.text = "COMMUNICATION LOST\n\n" + glitch_text.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)

	# Animatie flickering pe text
	var tween = create_tween().set_loops(20)
	tween.tween_property(label, "modulate:a", 0.2, 0.15)
	tween.tween_property(label, "modulate:a", 1.0, 0.15)

	return overlay

# ==============================================================================
# ACTUATOR 6: ASYMMETRIC WHISPER
# Afisam un mesaj infiorator doar unuia dintre jucatori
# ==============================================================================

func _do_asymmetric_whisper(target: String, glitch_text: String):
	if glitch_text == "":
		glitch_text = "You cannot trust him."
	print("[SaboteurAgent] 💬 WHISPER pentru %s: %s" % [target, glitch_text])

	var player = _get_target_player(target)
	if not player:
		return

	# Cream un Label3D care apare doar langa acel jucator (perspectiva lui)
	# Deoarece nu avem split-screen, folosim un CanvasLayer local temporar
	var overlay = CanvasLayer.new()
	overlay.layer = 9
	get_tree().root.add_child(overlay)

	var label = Label.new()
	label.text = "« " + glitch_text + " »"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.anchor_top = 0.75
	label.anchor_bottom = 0.9
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0.8, 0.0, 0.0, 0.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)

	# Fade-in si fade-out
	var tween = create_tween()
	tween.tween_property(label, "theme_override_colors/font_color", Color(0.8, 0.0, 0.0, 1.0), 1.5)
	tween.tween_interval(4.0)
	tween.tween_property(label, "theme_override_colors/font_color", Color(0.8, 0.0, 0.0, 0.0), 2.0)
	tween.tween_callback(func(): if is_instance_valid(overlay): overlay.queue_free())

# ==============================================================================
# ACTUATOR 7: SPAWN FAKE CLUE
# Instantiem o notita cu instructiuni gresite specifice puzzle-ului curent
# ==============================================================================

func _do_spawn_fake_clue(target: String, fake_clue_content: String):
	print("[SaboteurAgent] 📝 SPAWN FAKE CLUE pentru: ", target)

	# Daca LLM-ul nu a dat continut, folosim fallback-ul static pentru stadiul curent
	var stage_key = float(game_events.current_stage if game_events else 1.0)
	if fake_clue_content == "" or fake_clue_content == null:
		fake_clue_content = FALLBACK_FAKE_CLUES.get(stage_key,
			"ERROR:\nData corrupted.\n(Ignore this note.)")

	# Determinam pozitia de spawn in camera corecta
	var spawn_pos = _get_fake_note_spawn_pos(target)

	# Incercam sa instantiem Note.tscn
	var note_scene = load("res://Scenes/Rooms/Note.tscn") if ResourceLoader.exists("res://Scenes/Rooms/Note.tscn") else null

	if note_scene:
		var note = note_scene.instantiate()

		# Setam scriptul si textul
		if ResourceLoader.exists("res://Scripts/Puzzles/Note.gd"):
			note.set_script(load("res://Scripts/Puzzles/Note.gd"))

		# Setam textul fals INAINTE de add_child pentru ca _ready sa il preia
		note.set("custom_text", "⚠️ SYSTEM NOTE:\n" + fake_clue_content)
		note.set("is_fake", true)  # flag optional pentru debug

		get_tree().root.add_child(note)
		note.global_position = spawn_pos
		_active_fake_notes.append(note)

		print("[SaboteurAgent] 📌 Notita falsa spawned la: ", spawn_pos)

		# Timer auto-stergere dupa 25 secunde cu efect de glitch
		await get_tree().create_timer(25.0).timeout
		_dissolve_fake_note(note)
	else:
		# Fallback: afisam mesajul pe ecran ca Label3D pe perete
		print("[SaboteurAgent] ⚠️ Note.tscn nu exista. Folosesc Label3D fallback.")
		_spawn_fake_clue_label(fake_clue_content, spawn_pos)

func _get_fake_note_spawn_pos(target: String) -> Vector3:
	# RoomA: X≈[0,12], RoomB: X≈[100,112]
	if target == "Player2":
		return Vector3(104.0, 1.0, 6.0)   # Masa din RoomB
	else:
		return Vector3(6.0, 1.0, 6.0)     # Masa din RoomA

func _dissolve_fake_note(note: Node):
	if not is_instance_valid(note):
		_active_fake_notes.erase(note)
		return

	print("[SaboteurAgent] 💨 Notita falsa se dizolva...")
	# Flickering rapid inainte de disparitie
	var tween = create_tween()
	for i in range(6):
		tween.tween_property(note, "visible", false, 0.1)
		tween.tween_property(note, "visible", true, 0.1)
	tween.tween_callback(func():
		if is_instance_valid(note):
			note.queue_free()
		_active_fake_notes.erase(note)
	)

func _spawn_fake_clue_label(text: String, pos: Vector3):
	var label = Label3D.new()
	label.text = "⚠️ " + text
	label.font_size = 48
	label.pixel_size = 0.006
	label.modulate = Color(1.0, 0.8, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	get_tree().root.add_child(label)
	label.global_position = pos

	await get_tree().create_timer(25.0).timeout
	if is_instance_valid(label):
		label.queue_free()

# ==============================================================================
# CAMERA SHAKE (helper)
# ==============================================================================

func _do_camera_shake(player: Node, intensity: float, duration: float):
	if not player or not player.has_node("Camera3D"):
		return
	var camera = player.get_node("Camera3D")
	var orig = camera.position
	var tween = create_tween()
	tween.set_loops(int(duration / 0.05))
	tween.tween_property(camera, "position",
		orig + Vector3(randf_range(-intensity, intensity), randf_range(-intensity, intensity), 0), 0.05)
	tween.tween_property(camera, "position", orig, 0.05)
	await get_tree().create_timer(duration + 0.1).timeout
	if is_instance_valid(camera):
		camera.position = orig

# ==============================================================================
# HELPERS
# ==============================================================================

func _get_target_player(target: String) -> Node:
	if target == "Player1":
		return get_tree().root.find_child("Player1", true, false)
	elif target == "Player2":
		return get_tree().root.find_child("Player2", true, false)
	else:  # Both → returnam pe cel cu panica mai mare
		var p1 = get_tree().root.find_child("Player1", true, false)
		var p2 = get_tree().root.find_child("Player2", true, false)
		if _player1_panic >= _player2_panic:
			return p1
		return p2

# Expus pentru HintAgent sa verifice daca Saboteur e ocupat
func is_busy() -> bool:
	return _is_waiting_for_ollama

# Asigura ca AudioListener3D este prezent pe Camera3D a jucatorului
# (necesar pentru ca AudioStreamPlayer3D sa functioneze corect in Godot 4)
func _ensure_audio_listener(player: Node):
	if not player:
		return
	var camera = player.get_node_or_null("Camera3D")
	if not camera:
		return
	if not camera.has_node("AudioListener3D"):
		var listener = AudioListener3D.new()
		listener.name = "AudioListener3D"
		camera.add_child(listener)
		listener.make_current()
		print("[SaboteurAgent] 🔊 AudioListener3D adaugat pe camera jucatorului.")
