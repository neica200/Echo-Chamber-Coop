extends StaticBody3D

func _ready():
	GameEvents.final_exit_opened.connect(_on_exit_door_open)

func _on_exit_door_open():
	var tween = create_tween()
	tween.tween_property(self, "position:y", 3.0, 3.0)
	AudioManager.play_success()
	print("🚪 UȘA FINALĂ S-A DESCHIS! AI SCĂPAT!")
