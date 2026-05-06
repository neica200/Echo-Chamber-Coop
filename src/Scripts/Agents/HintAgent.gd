extends Node

# Emis atunci când LLM-ul răspunde cu succes
signal hint_received(text: String)
# Emis dacă apare o eroare de conexiune cu Ollama
signal hint_failed(error_msg: String)

@onready var http_request: HTTPRequest = HTTPRequest.new()

# Setările pentru Ollama
var ollama_url: String = "http://localhost:11434/api/generate"
var ai_model: String = "llama3:8b" # Acesta este modelul pe care îl vom descărca
var is_generating: bool = false
var time_since_last_progress: float = 0.0
var HINT_THRESHOLD: float = 60.0 # 60 seconds

var hint_ui_scene = preload("res://Scenes/UI/HintUI.tscn")

func _ready() -> void:
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	print("[HintAgent] Agentul a fost inițializat. Așteaptă cereri către Ollama (", ai_model, ").")
	
	var ui = hint_ui_scene.instantiate()
	add_child(ui)
	hint_received.connect(ui._on_hint_received)
	hint_failed.connect(ui._on_hint_failed)

func _process(delta: float) -> void:
	time_since_last_progress += delta
	
	if time_since_last_progress >= HINT_THRESHOLD and not is_generating:
		print("[HintAgent] Timp expirat! Generăm un indiciu automat...")
		generate_dynamic_hint()
		time_since_last_progress = 0.0
		
	# Sistem de test: Apasă H pentru a forța un indiciu
	if Input.is_action_just_pressed("ui_home") or Input.is_physical_key_pressed(KEY_H):
		if not is_generating:
			print("[HintAgent] S-a cerut un indiciu manual (Tasta H)...")
			generate_dynamic_hint()
			time_since_last_progress = 0.0

func reset_telemetry() -> void:
	print("[HintAgent] Progres detectat! Resetăm timerul.")
	time_since_last_progress = 0.0

func generate_dynamic_hint() -> void:
	# Pentru prototip cerem statusul la numpad, dar aici poți lua orice puzzle nerezolvat
	var numpad_data = PuzzleGen.get_puzzle_data("numpad_puzzle")
	var prompt = ""
	
	if numpad_data.has("solution"):
		prompt = "Jucătorii joacă un escape room asimetric co-op. Jucătorul A este într-o cameră și vede indiciul. Jucătorul B este în altă cameră și are seiful. Jucătorii sunt blocați de 60 de secunde. Soluția seifului este codul numeric %s. Indiciul este ascuns în %s, iar seiful e în %s. Dă-le un indiciu subtil, de maxim o propoziție, ca să își dea seama că Jucătorul A trebuie să îi dicteze cifrele lui B. Nu folosi ghilimele și nu le da codul direct." % [numpad_data["solution"], numpad_data["clue_room"], numpad_data["lock_room"]]
	else:
		prompt = "Jucătorii sunt blocați într-un escape room asimetric. Dă-le un indiciu scurt, misterios și general să comunice mai bine verbal, de maxim o propoziție."
		
	request_hint(prompt)

func request_hint(context_prompt: String) -> void:
	if is_generating:
		push_warning("[HintAgent] O generare este deja în curs...")
		return
		
	is_generating = true
	print("[HintAgent] Trimitem prompt-ul către Ollama...")
	
	var body = JSON.stringify({
		"model": ai_model,
		"prompt": context_prompt,
		"stream": false
	})
	
	var headers = ["Content-Type: application/json"]
	
	var error = http_request.request(ollama_url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		is_generating = false
		hint_failed.emit("A apărut o eroare la crearea request-ului HTTP.")
		push_error("[HintAgent] Eroare la HTTPRequest: ", error)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	is_generating = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		hint_failed.emit("Eroare de conexiune. Verifică dacă Ollama rulează pe fundal!")
		push_error("[HintAgent] Ollama nu răspunde. Ai pornit aplicația?")
		return
		
	if response_code != 200:
		hint_failed.emit("Ollama a returnat o eroare: " + str(response_code))
		return
		
	var response_text = body.get_string_from_utf8()
	var json = JSON.new()
	var error = json.parse(response_text)
	
	if error == OK:
		var response_data = json.data
		if response_data.has("response"):
			var generated_hint = response_data["response"].strip_edges()
			print("[HintAgent] Răspuns primit: ", generated_hint)
			hint_received.emit(generated_hint)
		else:
			hint_failed.emit("Răspunsul JSON nu conține cheia 'response'.")
	else:
		hint_failed.emit("A eșuat parsarea răspunsului JSON de la Ollama.")
