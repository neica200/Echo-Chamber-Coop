extends Control

const SERVER_URL = "http://localhost:3000/api"

@onready var username_field = $VBoxContainer/LineEdit
@onready var password_field = $VBoxContainer/LineEdit2
@onready var http_request = HTTPRequest.new()

func _ready():
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func _on_login_pressed():
	var body = JSON.stringify({"username": username_field.text, "password": password_field.text})
	http_request.request(SERVER_URL + "/login", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_register_pressed():
	var body = JSON.stringify({"username": username_field.text, "password": password_field.text})
	http_request.request(SERVER_URL + "/register", ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)

func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		if json.has("token"):
			print("Login reusit! Token: ", json["token"])
		else:
			print("Inregistrare reusita!")
	else:
		print("Eroare: ", json)
