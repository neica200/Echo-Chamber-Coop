extends StaticBody3D

func _ready():
	set_process_unhandled_input(true)
	GameEvents.escape_door_opened.connect(_on_door_open)
	GameEvents.safe_opened.connect(_on_safe_open)

func _on_door_open():
	# Când câștigăm jocul
	if name.contains("Door"):
		var tween = create_tween()
		# O ușă blindată sci-fi se glisează în sus!
		tween.tween_property(self, "position:y", 3.0, 2.0)
		AudioManager.play_success()
		print("🚪 Ușa blindată a glisat în sus! AI CÂȘTIGAT!")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		print("[Debug] Apăsat P - forțăm deschiderea ușilor glisante!")
		_on_door_open()

func _on_safe_open(room_id: String):
	# Dacă acest obiect e un Safe și se află în camera corectă
	if name.contains("Safe"):
		# Verificăm din ce cameră facem parte uitându-ne în arbore
		var current_room = get_parent().name
		if current_room == room_id:
			var tween = create_tween()
			# Tragem seiful în față și îl rotim ușor pentru a arăta că s-a deschis
			tween.tween_property(self, "position:z", position.z + 0.5, 0.5)
			tween.tween_property(self, "rotation_degrees:y", rotation_degrees.y - 45.0, 0.5)
			
			# Când se termină animația, spawnăm biletul cu parola!
			await tween.finished
			var note_scene = preload("res://Scenes/Rooms/Note.tscn")
			if note_scene:
				var note = note_scene.instantiate()
				note.set_script(preload("res://Scripts/Puzzles/Note.gd"))
				note.set("custom_text", "HACKING PROTOCOL:\n1. FIREWALL\n2. DECRYPT\n3. CORE")
				add_child(note)
				note.position = Vector3(0, 1.1, 0)
				
				# Adăugăm un FocusPoint pentru bilet
				var f = Marker3D.new()
				f.name = "FocusPoint"
				f.position = Vector3(0, 0.5, 0.3)
				f.rotation_degrees.x = -45
				note.add_child(f)
			
			print("🧰 Seiful din ", current_room, " a fost deschis automat și biletul a apărut!")
