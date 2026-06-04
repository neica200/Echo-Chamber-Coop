extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

# Get the gravity from the project settings.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var is_active: bool = true
var is_focused: bool = false
var original_camera_transform: Transform3D
var original_camera_parent: Node3D

@onready var camera = $Camera3D
@onready var interaction_ray = $Camera3D/RayCast3D

# --- INVENTORY SYSTEM ---
var inventory: Array[String] = []
var inventory_label: Label

func _ready():
	if is_active:
		camera.make_current()
		
	# --- Setup Inventory UI ---
	var canvas = CanvasLayer.new()
	inventory_label = Label.new()
	inventory_label.text = "Inventar: Gol"
	inventory_label.position = Vector2(20, 20)
	# Styling rapid pentru a se vedea textul
	inventory_label.add_theme_font_size_override("font_size", 24)
	inventory_label.add_theme_color_override("font_color", Color.YELLOW)
	canvas.add_child(inventory_label)
	add_child(canvas)
		
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
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE # CA SĂ NU BLOCHEZE MOUSE-UL!
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE # CA SĂ NU BLOCHEZE MOUSE-UL!
	
	center.add_child(crosshair)
	add_child(center)

func _unhandled_input(event):
	if not is_active: return
	
	# Dacă suntem în modul ZOOM (Focus), nu lăsăm mișcarea camerei din mouse
	if is_focused:
		# Ieșire din Focus cu Click Dreapta sau ESC
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed) or event.is_action_pressed("ui_cancel"):
			exit_focus()
		
		# Când suntem focusați, vrem să dăm click pe butoane folosind un raycast care pleacă din poziția cursorului 2D!
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			handle_focus_click()
		return
		
	# Dacă nu suntem focusați, recapturăm mouse-ul și interacționăm cu lumea de la distanță
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			check_interaction() # Noul buton de interacțiune este Click Stânga!
		
	# Mișcarea camerei din mouse are loc doar dacă mouse-ul e capturat (ascuns)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		# Blocăm camera să nu se dea peste cap
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	
	# Dacă apeși ESC, eliberezi mouse-ul ca să poți închide jocul sau da click pe altceva
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	if not is_active: return
	
	# Adăugăm gravitația
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Săritura
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Mișcarea (WASD și Săgeți)
	var input_dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"): input_dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"): input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"): input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"): input_dir.x += 1
	input_dir = input_dir.normalized()
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	# Am mutat interacțiunea în _unhandled_input (pe Click Stânga)
	# Dar lăsăm și E funcțional în caz că userul îl apasă din obișnuință
	if Input.is_action_just_pressed("interact") and not is_focused:
		check_interaction()

func check_interaction():
	interaction_ray.force_raycast_update()
	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()
		print("DEBUG RAYCAST: Am lovit obiectul = ", target.name, " (Clasa: ", target.get_class(), ")")
		if target:
			if target.has_method("pick_up"):
				target.pick_up(self)
			else:
				var focus_target = find_focus_point(target)
				print("DEBUG FOCUS: find_focus_point a returnat = ", focus_target)
				if focus_target:
					enter_focus(focus_target)
				elif target.has_method("interact"):
					target.interact()
	else:
		print("DEBUG RAYCAST: Nu lovesc absolut nimic la distanța asta.")

func find_focus_point(node: Node) -> Node:
	var current = node
	print("DEBUG FOCUS HIERARCHY for ", node.name, ":")
	while current and current != get_tree().root:
		print(" - Checking ancestor: ", current.name)
		if current.has_node("FocusPoint"):
			print("   -> GĂSIT FocusPoint în ", current.name)
			return current
		current = current.get_parent()
	print("   -> NU am găsit FocusPoint nicăieri în sus!")
	return null

# --- RUSTY LAKE FOCUS SYSTEM ---
func enter_focus(target_puzzle: Node3D):
	if is_focused: return
	is_focused = true
	
	print("🔍 [FOCUS] Am dat zoom pe: ", target_puzzle.name)
	original_camera_transform = camera.global_transform
	original_camera_parent = camera.get_parent()
	
	# Decuplăm camera din jucător ca să o putem mișca liber
	var current_global = camera.global_transform
	camera.get_parent().remove_child(camera)
	get_tree().root.add_child(camera)
	camera.global_transform = current_global
	
	var focus_point = target_puzzle.get_node("FocusPoint")
	var target_transform = focus_point.global_transform
	
	# Tween animat
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_transform:origin", target_transform.origin, 0.5)
	
	# Ca să ne uităm exact la puzzle, folosim slerp sau ne uităm la target
	# O metodă ușoară e să copiem rotația FocusPoint-ului
	tween.tween_property(camera, "global_transform:basis", target_transform.basis, 0.5)
	
	# Facem mouse-ul vizibil ca jucătorul să dea click-uri
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func exit_focus():
	if not is_focused: return
	is_focused = false
	print("🔙 [FOCUS] Am ieșit din zoom.")
	
	# Punem mouse-ul la loc
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_transform", original_camera_transform, 0.4)
	
	# După animație, reparentăm camera
	tween.chain().tween_callback(func():
		camera.get_parent().remove_child(camera)
		original_camera_parent.add_child(camera)
		camera.transform = Transform3D(Basis(), Vector3(0, 1.5, 0))
	)

func handle_focus_click():
	# Aruncăm o rază din mouse în lumea 3D
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_dir * 5.0)
	query.collide_with_areas = true
	var result = space.intersect_ray(query)
	
	if result and result.collider:
		if result.collider.has_method("receive_3d_click"):
			result.collider.receive_3d_click(result.position)
		elif result.collider.has_method("interact"):
			result.collider.interact()

# --- INVENTORY FUNCTIONS ---
func add_to_inventory(item_name: String):
	inventory.append(item_name)
	update_inventory_ui()
	print("🎒 Ai ridicat: ", item_name)

func has_item(item_name: String) -> bool:
	return inventory.has(item_name)

func remove_item(item_name: String):
	if has_item(item_name):
		inventory.erase(item_name)
		update_inventory_ui()

func update_inventory_ui():
	if inventory.is_empty():
		inventory_label.text = "Inventar: Gol"
	else:
		inventory_label.text = "Inventar:\n- " + "\n- ".join(inventory)
