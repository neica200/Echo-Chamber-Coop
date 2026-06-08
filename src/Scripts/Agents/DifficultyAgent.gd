extends Node

# =============================================================
# DIFFICULTY AGENT - LLM Difficulty Director
# =============================================================

@export var ollama_url: String = "http://127.0.0.1:11434/api/generate"
@export var model_name: String = "llama3:8b"

var game_start_time: float = 0.0
var http_request: HTTPRequest
var _is_waiting_for_ollama: bool = false

var game_events = null
var hint_agent = null
var saboteur_agent = null

func _ready():
	game_start_time = Time.get_unix_time_from_system()
	
	http_request = HTTPRequest.new()
	http_request.name = "OllamaHTTP_Difficulty"
	add_child(http_request)
	http_request.request_completed.connect(_on_ollama_response)
	
	await get_tree().create_timer(0.5).timeout
	game_events = get_node_or_null("/root/GameEvents")
	hint_agent = get_node_or_null("/root/HintAgent")
	saboteur_agent = get_node_or_null("/root/SaboteurAgent")
	
	if game_events:
		game_events.stage_changed.connect(_on_stage_changed)
	
	print("[DifficultyAgent] ✅ Agentul Dificultate inițializat | Model: ", model_name)

func _on_stage_changed(new_stage: int):
	# Evaluam inainte de puzzle-ul de culori (Faza 2)
	if new_stage == 2:
		_evaluate_difficulty(2)
	# Evaluam inainte de afisarea parolei de seif pe monitor (Faza 3)
	elif new_stage == 3:
		_evaluate_difficulty(3)

func _get_total_mistakes() -> int:
	var total = 0
	if hint_agent and "wrong_attempts" in hint_agent:
		for k in hint_agent.wrong_attempts:
			total += hint_agent.wrong_attempts[k]
	return total

func _evaluate_difficulty(target_stage: int):
	var time_elapsed = Time.get_unix_time_from_system() - game_start_time
	var mistakes = _get_total_mistakes()
	
	print("[DifficultyAgent] 📊 Evaluare Faza ", target_stage, " | Timp scurs: ", int(time_elapsed), "s | Greșeli: ", mistakes)
	
	# Coordonare: asteptam daca alti agenti folosesc LLM-ul
	while (hint_agent and hint_agent._is_waiting_for_ollama) or (saboteur_agent and saboteur_agent._is_waiting_for_ollama):
		print("[DifficultyAgent] ⏳ LLM ocupat de alt agent. Asteptam 1 secunda...")
		await get_tree().create_timer(1.0).timeout
	
	var puzzle_name = "Color Sequence (Faza 2)" if target_stage == 2 else "Final Numpad (Faza 4)"
	
	var prompt = """You are the AI Difficulty Director for a cooperative escape room game.
The players are about to face the next puzzle: {puzzle}.
Time elapsed so far: {time} seconds.
Total mistakes made so far: {mistakes}.

Your task is to choose the difficulty for the upcoming puzzle.
Choose "SCALE_UP" if they are fast (< 120s) and made few mistakes (< 2).
Choose "SCALE_DOWN" if they are slow (> 300s) or made many mistakes (> 5).
Choose "KEEP_STANDARD" otherwise.

Respond EXCLUSIVELY with a valid JSON object. No extra text or markdown.
Structure:
{{
  "thought": "your short reasoning based on time and mistakes",
  "action": "SCALE_UP, SCALE_DOWN, or KEEP_STANDARD",
  "target_stage": {stage}
}}
"""
	
	prompt = prompt.format({
		"puzzle": puzzle_name,
		"time": int(time_elapsed),
		"mistakes": mistakes,
		"stage": target_stage
	})
	
	var body = JSON.stringify({
		"model": model_name,
		"prompt": prompt,
		"stream": false,
		"format": "json",
		"options": {
			"temperature": 0.1, # Vrem raspunsuri predictibile/logice pentru dificultate
			"num_predict": 100
		}
	})
	
	var headers = ["Content-Type: application/json"]
	var error = http_request.request(ollama_url, headers, HTTPClient.METHOD_POST, body)
	
	if error == OK:
		_is_waiting_for_ollama = true
		print("[DifficultyAgent] 🤖 Cerere evaluare trimisă către Ollama...")
	else:
		print("[DifficultyAgent] ⚠️ Eroare HTTP la trimiterea cererii: ", error)

func _on_ollama_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	_is_waiting_for_ollama = false
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[DifficultyAgent] ⚠️ Ollama a răspuns cu eroare (HTTP ", response_code, ").")
		return
		
	var response_text = body.get_string_from_utf8()
	var outer_json = JSON.parse_string(response_text)
	if not outer_json or not outer_json.has("response"):
		return
		
	var inner_text = outer_json["response"].strip_edges()
	print("[DifficultyAgent] 🤖 Răspuns LLM: ", inner_text)
	
	var parsed = JSON.parse_string(inner_text)
	if not parsed or not parsed.has("action") or not parsed.has("target_stage"):
		return
		
	var action = parsed["action"]
	var stage = parsed["target_stage"]
	
	print("[DifficultyAgent] 🧠 Decizie: ", action, " pentru faza ", stage)
	_apply_difficulty(int(stage), action)

func _apply_difficulty(stage: int, decision: String):
	if decision == "KEEP_STANDARD":
		print("[DifficultyAgent] Dificultate menținută standard.")
		return
		
	if stage == 2:
		# Modificam puzzle_gen -> color_sequence
		var colors = ["Rosu", "Albastru", "Verde", "Galben"]
		var current_sol = PuzzleGen.active_puzzles["color_sequence"]["solution"]
		if decision == "SCALE_UP":
			# Din 4, se fac 6 culori
			current_sol.append(colors[randi() % colors.size()])
			current_sol.append(colors[randi() % colors.size()])
			print("[DifficultyAgent] 🔥 Culori modificate la 6 elemente: ", current_sol)
		elif decision == "SCALE_DOWN":
			# Din 4, se face 3 culori
			if current_sol.size() > 3:
				current_sol.pop_back()
			print("[DifficultyAgent] 💤 Culori reduse la 3 elemente: ", current_sol)
			
	elif stage == 3:
		# Modificam puzzle_gen -> numpad_puzzle
		var current_sol = PuzzleGen.active_puzzles["numpad_puzzle"]["solution"]
		var new_sol = current_sol
		
		if decision == "SCALE_UP":
			# Din 4 cifre, se fac 6 cifre
			new_sol = "%06d" % (randi() % 1000000)
			print("[DifficultyAgent] 🔥 PIN modificat la 6 cifre: ", new_sol)
		elif decision == "SCALE_DOWN":
			# Din 4 cifre, se fac 3 cifre
			new_sol = "%03d" % (randi() % 1000)
			print("[DifficultyAgent] 💤 PIN redus la 3 cifre: ", new_sol)
			
		PuzzleGen.active_puzzles["numpad_puzzle"]["solution"] = new_sol
