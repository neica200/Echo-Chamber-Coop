extends Node3D

@onready var light = $OmniLight3D
var default_energy = 1.0

func _ready():
	default_energy = light.light_energy
	var current_room = get_parent().name
	
	if current_room == "RoomB":
		# In RoomB punem putina lumina la inceput ca sa se vada obiectele
		light.visible = true
		light.light_energy = 1.0
	else:
		# In RoomA lumina e complet stinsa
		light.visible = false
	
	GameEvents.room_lights_toggled.connect(_on_lights_toggled)

func _on_lights_toggled(room_id: String, state: bool):
	# Verificăm din ce cameră facem parte
	var current_room = get_parent().name
	if current_room == room_id:
		light.visible = state
		if state:
			light.light_energy = default_energy
			print("💡 Lumina s-a aprins în ", current_room, "!")
		else:
			print("🌑 O pană de curent a lovit ", current_room, "!")

# Apelata de HintAgent pentru efectul de palpaiere (hint vizual)
func flicker_sequence():
	var orig_visible = light.visible
	var orig_energy = light.light_energy
	
	for i in range(6):
		if light.visible:
			light.visible = false
		else:
			light.visible = true
			light.light_energy = default_energy # Palpaie la putere maxima pentru dramatisn
			
		await get_tree().create_timer(0.15).timeout
		
	light.visible = orig_visible
	light.light_energy = orig_energy
	print("💡 [CeilingLight] Palpaiere completata in ", get_parent().name)
