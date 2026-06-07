extends Node3D

@export var required_item: String = "Cheie de Birou" # Cerem cheia din nou
@export var contains_note: bool = true

var is_open = false

func interact():
	var player = get_viewport().get_camera_3d().get_parent()
	
	if is_open:
		print("Sertarul este deja deschis.")
		return
		
	if player.has_method("has_item") and player.has_item(required_item):
		print("🔓 Ai descuiat sertarul folosind: ", required_item)
		is_open = true
		AudioManager.play_success()
		player.remove_item(required_item)
		GameEvents.emit_signal("drawer_opened")
		open_animation()
	else:
		AudioManager.play_error(-15.0) # Mai încet!
		print("🔒 E încuiat. Ai nevoie de: ", required_item)
		show_locked_message()

func show_locked_message():
	var label = Label3D.new()
	label.text = "Blocat! Ai nevoie de cheie."
	label.position = Vector3(0, 1.6, 0.8) # Mai aproape de jucător (în fața obiectelor)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1, 0.2, 0.2) # Roșu
	label.font_size = 48
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(label.queue_free)

func open_animation():
	if contains_note:
		var note = get_node_or_null("Note")
		if note:
			note.visible = true
			var tween = create_tween()
			var initial_pos = note.position
			note.position = initial_pos + Vector3(0, 0, -0.2)
			tween.tween_property(note, "position", initial_pos, 0.4).set_ease(Tween.EASE_OUT)
