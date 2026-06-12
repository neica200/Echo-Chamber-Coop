extends StaticBody3D

var is_open = false

func _ready():
	GameEvents.final_exit_opened.connect(_on_exit_door_open)

func _on_exit_door_open():
	if is_open: return
	is_open = true
	
	var tween = create_tween()
	tween.tween_property(self, "position:y", 3.0, 3.0)
	AudioManager.play_success()
	print("🚪 UȘA FINALĂ S-A DESCHIS! AI SCĂPAT!")
	
	# După ce se deschide (3-4 secunde), trecem la End Game Screen
	await get_tree().create_timer(4.0).timeout
	get_tree().change_scene_to_file("res://Scenes/EndGame.tscn")
