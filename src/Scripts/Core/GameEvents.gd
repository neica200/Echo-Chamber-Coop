extends Node

# --- SEMNALE GLOBALE ---
# Orice obiect din joc poate asculta (connect) sau striga (emit) aceste semnale

signal stage_changed(new_stage: int)
signal puzzle_solved(puzzle_id: String)
signal room_lights_toggled(room_id: String, state: bool)
signal safe_opened(room_id: String)
signal escape_door_opened()
signal drawer_opened()

# --- STATE MACHINE ---
var current_stage = 1

func _ready():
	# Când începe jocul, suntem la Faza 1
	current_stage = 1

func advance_stage():
	current_stage += 1
	print(">>> PROGRESIE: Jocul a trecut la Faza ", current_stage, " <<<")
	emit_signal("stage_changed", current_stage)
