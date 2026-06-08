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

func host():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	spawn_player(multiplayer.get_unique_id())

func join(ip: String):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
