extends Node

# ── STATISTICI ────────────────────────────────────────────
var start_time: float = 0.0
var end_time: float = 0.0
var puzzles_solved: int = 0
var total_mistakes: int = 0
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

func start_timer() -> void:
	start_time = Time.get_unix_time_from_system()
	total_time = 0.0
	numpad_mistakes = 0
	puzzles_solved = 0
	print("[GameStats] Timer reset and started la: ", start_time)

func add_mistake() -> void:
	total_mistakes += 1
	print("[GameStats] Greșeală! Total: ", total_mistakes)

func _on_game_finished() -> void:
	if total_time > 0.0: return # Prevent double call
	end_time = Time.get_unix_time_from_system()
	total_time = end_time - start_time
	print("[GameStats] Joc terminat! Timp: ", total_time, "s | Greșeli: ", total_mistakes)

func get_rank() -> String:
	# Rank bazat pe timp și greșeli. O greșeală e penalizată cu 60 secunde.
	var score = total_time + (total_mistakes * 60)
	if total_mistakes == 0 and score < 300:
		return "S"
	elif score < 400:
		return "A"
	elif score < 600:
		return "B"
	elif score < 900:
		return "C"
	else:
		return "D"

func get_stats() -> Dictionary:
	return {
		"time": total_time,
		"puzzles_solved": puzzles_solved,
		"total_mistakes": total_mistakes,
		"rank": get_rank()
	}
