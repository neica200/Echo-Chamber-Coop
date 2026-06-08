extends Node

# --- SEMNALE GLOBALE ---
# Orice obiect din joc poate asculta (connect) sau striga (emit) aceste semnale

signal stage_changed(new_stage: int)
signal puzzle_solved(puzzle_id: String)
signal room_lights_toggled(room_id: String, state: bool)
signal safe_opened(room_id: String)
signal escape_door_opened()
signal drawer_opened()
signal final_exit_opened()

# --- STATE MACHINE ---
var current_stage = 1

func _ready():
	# Când începe jocul, suntem la Faza 1
	current_stage = 1

func advance_stage():
	current_stage += 1
	print(">>> PROGRESIE: Jocul a trecut la Faza ", current_stage, " <<<")
	emit_signal("stage_changed", current_stage)

# --- SIMULTANEOUS EXIT LEVERS ---
var lever_1_pulled = false
var lever_2_pulled = false
var lever_timer = 0.0

func _process(delta):
	if lever_timer > 0:
		lever_timer -= delta
		if lever_timer <= 0:
			# Reset levers if time runs out
			lever_1_pulled = false
			lever_2_pulled = false
			print("[GameEvents] Timpul pentru a trage a doua manivelă a expirat!")

func pull_exit_lever(id: int):
	if id == 1:
		lever_1_pulled = true
	elif id == 2:
		lever_2_pulled = true
		
	if lever_1_pulled and lever_2_pulled:
		print("[GameEvents] Ambele manivele trase! Deschid ușa finală!")
		emit_signal("final_exit_opened")
		lever_1_pulled = false
		lever_2_pulled = false
		lever_timer = 0.0
	else:
		# Porniți cronometrul pentru cealaltă manivelă
		lever_timer = 2.0

