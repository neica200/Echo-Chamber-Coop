extends Node

# ── STATISTICI ────────────────────────────────────────────
var start_time: float = 0.0
var end_time: float = 0.0
var puzzles_solved: int = 0
var numpad_mistakes: int = 0
var total_time: float = 0.0

func _ready() -> void:
	# Conectăm la semnalele din GameEvents
	var game_events = get_node_or_null("/root/GameEvents")
	if game_events:
		game_events.puzzle_solved.connect(_on_puzzle_solved)
		game_events.final_exit_opened.connect(_on_game_finished)
	start_time = Time.get_unix_time_from_system()
	print("[GameStats] Tracking pornit!")

func _on_puzzle_solved(_puzzle_id: String) -> void:
	puzzles_solved += 1
	print("[GameStats] Puzzle rezolvat! Total: ", puzzles_solved)

func add_numpad_mistake() -> void:
	numpad_mistakes += 1
	print("[GameStats] Greșeală numpad! Total: ", numpad_mistakes)

func _on_game_finished() -> void:
	end_time = Time.get_unix_time_from_system()
	total_time = end_time - start_time
	print("[GameStats] Joc terminat! Timp: ", total_time, "s | Greșeli: ", numpad_mistakes)

func get_rank() -> String:
	# Rank bazat pe timp și greșeli
	var score = total_time + (numpad_mistakes * 30)
	if score < 300:
		return "S"
	elif score < 600:
		return "A"
	elif score < 900:
		return "B"
	elif score < 1200:
		return "C"
	else:
		return "D"

func get_stats() -> Dictionary:
	return {
		"time": total_time,
		"puzzles_solved": puzzles_solved,
		"numpad_mistakes": numpad_mistakes,
		"rank": get_rank()
	}
