extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

# Get the gravity from the project settings.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D
@onready var interaction_ray = $Camera3D/RayCast3D

func _ready():
	# Ascunde și blochează mouse-ul în centrul ecranului la pornire
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Asigură-te că raza e mereu pornită și bate 10 metri în față (pe axa Z negativă)
	interaction_ray.enabled = true
	interaction_ray.target_position = Vector3(0, 0, -10)
	interaction_ray.collide_with_areas = true # <--- Asta ne lasă să lovim și Area3D!
	interaction_ray.add_exception(self) # Ignoră propriul corp ca să nu se lovească de sine

	# Creează un mic punct alb pe centrul ecranului (ținta) ca să știi unde te uiți
	var crosshair = ColorRect.new()
	crosshair.custom_minimum_size = Vector2(4, 4)
	crosshair.color = Color.WHITE
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.add_child(crosshair)
	add_child(center)

func _unhandled_input(event):
	# Mișcarea camerei din mouse
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		# Blocăm camera să nu se dea peste cap
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	# Dacă apeși ESC, eliberezi mouse-ul ca să poți închide jocul
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	# Gravitația
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Săritura
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Mișcarea (WASD)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# Logica ta de Puzzle (Member 2): Interacțiunea cu obiectele (ex: E pe tastatură)
	if Input.is_action_just_pressed("interact"):
		check_interaction()

func check_interaction():
	interaction_ray.force_raycast_update()
	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()
		print("Raza a lovit: ", target.name)
		
		# Verificăm dacă obiectul cu care ne uităm are o funcție de interact() atașată
		if target.has_method("interact"):
			target.interact()
			print("Ai dat click pe: ", target.name)
	else:
		print("Raza (de 10m) nu a lovit nimic! Verifică Debug -> Visible Collision Shapes.")
