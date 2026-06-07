extends Node3D

@onready var omni_light = $OmniLight3D
@onready var spot_light = $SpotLight3D
@onready var fixture = $FixtureMesh

var default_omni_energy = 1.0
var default_spot_energy = 2.0
var room_type: String = "Corridor"

func setup(type: String):
	room_type = type
	if room_type == "RoomA":
		set_light_state(false) # RoomA incepe in bezna
	else:
		set_light_state(true)  # Celelalte camere incep luminate

func _ready():
	# Forțează materialul emisiv cu o intensitate potrivită, nu "ca soarele"
	if fixture:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1, 1)
		mat.emission_enabled = true
		mat.emission = Color(1, 1, 0.9, 1)
		mat.emission_energy_multiplier = 2.0 # Mai puțin orbitor
		fixture.set_surface_override_material(0, mat)

	# Amplifică lumina de bounce a OmniLight-ului existent moderat
	if omni_light: 
		omni_light.light_energy = 1.0
		omni_light.omni_range = 12.0
		omni_light.shadow_enabled = false
		omni_light.position.y = 0.1
		default_omni_energy = omni_light.light_energy

	# Adaugă SpotLight-ul programmatic cu intensitate mai caldă
	if not spot_light:
		spot_light = SpotLight3D.new()
		add_child(spot_light)
		spot_light.position.y = -0.2
		spot_light.rotation_degrees.x = -90
		spot_light.light_color = Color(1.0, 0.95, 0.8)
		spot_light.light_energy = 2.0
		spot_light.light_volumetric_fog_energy = 2.0
		spot_light.spot_range = 25.0
		spot_light.spot_angle = 85.0
		spot_light.shadow_enabled = true
	
	if spot_light: default_spot_energy = spot_light.light_energy
		
	GameEvents.room_lights_toggled.connect(_on_lights_toggled)

func set_light_state(state: bool):
	if omni_light: omni_light.visible = state
	if spot_light: spot_light.visible = state
	
	# Stingem și emisia materialului vizual! Astfel nu mai avem o aură în beznă.
	if fixture:
		var mat = fixture.get_surface_override_material(0)
		if mat:
			mat.emission_energy_multiplier = 2.0 if state else 0.0

func _on_lights_toggled(target_room_id: String, state: bool):
	if room_type == target_room_id:
		set_light_state(state)
		if state:
			print("💡 Lumina s-a aprins în ", room_type, "!")
		else:
			print("🌑 O pană de curent a lovit ", room_type, "!")

func flicker_sequence():
	var orig_state = omni_light.visible if omni_light else false
	
	for i in range(6):
		set_light_state(!orig_state)
		orig_state = !orig_state
		await get_tree().create_timer(0.15).timeout
		
	set_light_state(true)
	print("💡 [CeilingLight] Palpaiere completata in ", room_type)
