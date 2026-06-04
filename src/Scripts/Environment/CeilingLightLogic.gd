extends Node3D

@onready var light = $OmniLight3D

func _ready():
	# Lumina e stinsă la începutul nivelului (Stage 1)
	light.visible = false
	
	GameEvents.room_lights_toggled.connect(_on_lights_toggled)

func _on_lights_toggled(room_id: String, state: bool):
	# Verificăm din ce cameră facem parte
	var current_room = get_parent().name
	if current_room == room_id:
		light.visible = state
		if state:
			print("💡 Lumina s-a aprins în ", current_room, "!")
		else:
			print("🌑 O pană de curent a lovit ", current_room, "!")
