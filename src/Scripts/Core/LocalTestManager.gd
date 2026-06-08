extends Node

# Așează acest script pe un Nod gol în scena ta de testare!
# Va spawna automat 2 jucători și te va lăsa să dai TAB între ei.

var player_scene = preload("res://Scenes/Rooms/player.tscn")

var player1: Node3D
var player2: Node3D
var current_player = 1

func _ready():
	# Așteptăm ca RoomGenerator să termine de făcut camerele
	await get_tree().process_frame
	
	# Spawn Player 1 în Room A
	player1 = player_scene.instantiate()
	player1.name = "Player1"
	add_child(player1)
	var spawn1 = get_node_or_null("../TestRoomGeneration/RoomA/SpawnPlayer1")
	if spawn1:
		player1.global_position = spawn1.global_position
	player1.is_active = true
	player1.get_node("Camera3D").make_current()

	# Spawn Player 2 în Room B
	player2 = player_scene.instantiate()
	player2.name = "Player2"
	add_child(player2)
	var spawn2 = get_node_or_null("../TestRoomGeneration/RoomB/SpawnPlayer2")
	if spawn2:
		player2.global_position = spawn2.global_position
	player2.is_active = false # Oprit inițial

func _unhandled_input(event):
	# Apasă TAB pentru a schimba corpul!
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed:
		if current_player == 1:
			current_player = 2
			player1.is_active = false
			player2.is_active = true
			player2.get_node("Camera3D").make_current()
			print("--- Ești Jucătorul 2 (Camera B) ---")
		else:
			current_player = 1
			player2.is_active = false
			player1.is_active = true
			player1.get_node("Camera3D").make_current()
			print("--- Ești Jucătorul 1 (Camera A) ---")
