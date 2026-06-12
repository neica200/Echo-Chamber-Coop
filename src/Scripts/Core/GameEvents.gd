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

func trigger_final_exit_opened():
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		rpc("broadcast_final_exit_opened")
	else:
		broadcast_final_exit_opened()

@rpc("any_peer", "call_local")
func broadcast_final_exit_opened():
	emit_signal("final_exit_opened")

# --- HELPERE MULTIPLAYER ---
func trigger_room_lights_toggled(room_id: String, state: bool):
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		rpc("broadcast_room_lights_toggled", room_id, state)
	else:
		broadcast_room_lights_toggled(room_id, state)

@rpc("any_peer", "call_local")
func broadcast_room_lights_toggled(room_id: String, state: bool):
	emit_signal("room_lights_toggled", room_id, state)

func trigger_escape_door_opened():
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		rpc("broadcast_escape_door_opened")
	else:
		broadcast_escape_door_opened()

@rpc("any_peer", "call_local")
func broadcast_escape_door_opened():
	emit_signal("escape_door_opened")

func trigger_safe_opened(room_id: String):
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		rpc("broadcast_safe_opened", room_id)
	else:
		broadcast_safe_opened(room_id)

@rpc("any_peer", "call_local")
func broadcast_safe_opened(room_id: String):
	emit_signal("safe_opened", room_id)

@rpc("any_peer", "call_local")
func sync_color_button_pressed(color_name: String):
	if current_stage < 2:
		print("🔒 [Sistem] Trebuie să rezolvi panoul electric (Faza 1) mai întâi!")
		return
	var panel = get_tree().root.find_child("ColorButtonsPanel", true, false)
	if panel and panel.has_method("button_pressed"):
		for btn in panel.get_children():
			if "color_name" in btn and btn.color_name == color_name:
				if btn.has_method("animate_press"):
					btn.animate_press()
				break
		panel.button_pressed(color_name)

func trigger_drawer_opened():
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		rpc("broadcast_drawer_opened")
	else:
		broadcast_drawer_opened()

@rpc("any_peer", "call_local")
func broadcast_drawer_opened():
	emit_signal("drawer_opened")

# --- STATE MACHINE ---
var current_stage = 1

func _ready():
	# Când începe jocul, suntem la Faza 1
	current_stage = 1

func advance_stage():
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		rpc("broadcast_stage_changed", current_stage + 1)
	else:
		broadcast_stage_changed(current_stage + 1)

@rpc("any_peer", "call_local")
func broadcast_stage_changed(new_stage: int):
	current_stage = new_stage
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
		trigger_final_exit_opened()
		lever_1_pulled = false
		lever_2_pulled = false
		lever_timer = 0.0
	else:
		# Porniți cronometrul pentru cealaltă manivelă
		lever_timer = 5.0
