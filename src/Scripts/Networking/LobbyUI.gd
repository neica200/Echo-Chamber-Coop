extends Control

const PORT = 7777
const MAX_PLAYERS = 2

@onready var ip_field = $CenterContainer/VBoxContainer/HBoxContainer/IP
@onready var status_label = $CenterContainer/VBoxContainer/Stare
@onready var host_button = $CenterContainer/VBoxContainer/Host
@onready var join_button = $CenterContainer/VBoxContainer/HBoxContainer/Join

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_host_pressed():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		status_label.text = "Eroare la Host!"
		return
	multiplayer.multiplayer_peer = peer
	status_label.text = "Hosting... Așteptând jucător 2"
	host_button.disabled = true
	join_button.disabled = true

func _on_join_pressed():
	var ip = ip_field.text.strip_edges()
	if ip == "":
		status_label.text = "Introdu un IP valid!"
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	status_label.text = "Se conectează la " + ip + "..."

func _on_player_connected(id):
	status_label.text = "Jucător conectat! ID: " + str(id)

func _on_player_disconnected(id):
	status_label.text = "Jucător deconectat!"

func _on_connected_to_server():
	status_label.text = "Conectat la server!"

func _on_connection_failed():
	status_label.text = "Conexiune eșuată!"
