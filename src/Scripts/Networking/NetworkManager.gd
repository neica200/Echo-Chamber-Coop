extends Node

const PLAYER_SCENE = preload("res://Scenes/Rooms/player.tscn")
const PORT = 7777
const MAX_PLAYERS = 2

var players = {}

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int):
	print("Player connected: ", id)
	spawn_player(id)
	if players.size() >= MAX_PLAYERS:
		_on_all_players_ready()

func _on_peer_disconnected(id: int):
	print("Player disconnected: ", id)
	if players.has(id):
		players[id].queue_free()
		players.erase(id)

func spawn_player(id: int):
	# Curățăm orice jucător vechi rămas din greșeală
	if players.has(id):
		if is_instance_valid(players[id]):
			players[id].queue_free()
		players.erase(id)
		
	var old_node = get_tree().root.get_node_or_null(str(id))
	if old_node:
		old_node.name = old_node.name + "_deleted"
		old_node.queue_free()

	var player = PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	player.get_node("MultiplayerSynchronizer").set_multiplayer_authority(id)
	
	if id == 1:
		player.position = Vector3(2, 1, 2)
	else:
		player.position = Vector3(10, 1, 10)
		
	get_tree().root.add_child(player)
	players[id] = player
	print("Spawned player: ", id)

func _on_all_players_ready() -> void:
	if multiplayer.is_server():
		print("[NetworkManager] Toți jucătorii conectați! Schimb scena...")
		change_scene.rpc()

@rpc("authority", "call_local")
func change_scene() -> void:
	if GameStats.has_method("start_timer"):
		GameStats.start_timer()
	get_tree().change_scene_to_file("res://Scenes/Rooms/TestRoomGeneration.tscn")

func cleanup_state():
	for p in players.values():
		if is_instance_valid(p):
			p.queue_free()
	players.clear()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

func host():
	cleanup_state()
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		print("Failed to host: ", err)
		return
	multiplayer.multiplayer_peer = peer
	spawn_player(multiplayer.get_unique_id())

func join(ip_string: String):
	cleanup_state()
	var peer = ENetMultiplayerPeer.new()
	var join_ip = ip_string
	var join_port = PORT
	
	if ip_string.find(":") != -1:
		var parts = ip_string.split(":")
		join_ip = parts[0]
		join_port = parts[1].to_int()
		
	peer.create_client(join_ip, join_port)
	multiplayer.multiplayer_peer = peer
	# Clientul își spawn-uiește playerul când se conectează
	await multiplayer.connected_to_server
	spawn_player(multiplayer.get_unique_id())
