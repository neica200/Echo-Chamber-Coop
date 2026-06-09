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
	var player = PLAYER_SCENE.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	get_tree().root.add_child(player)
	players[id] = player
	print("Spawned player: ", id)

func _on_all_players_ready() -> void:
	if multiplayer.is_server():
		print("[NetworkManager] Toți jucătorii conectați! Schimb scena...")
		change_scene.rpc()

@rpc("authority", "call_local")
func change_scene() -> void:
	get_tree().change_scene_to_file("res://Scenes/Rooms/TestRoomGeneration.tscn")

func host():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	spawn_player(multiplayer.get_unique_id())

func join(ip_string: String):
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
