extends Node3D

@onready var label = $Label3D
var custom_text = ""

func _ready():
	if custom_text != "":
		label.text = custom_text
		return
		
	# Așteptăm o secundă ca PuzzleGen să aibă timp să genereze parolele
	await get_tree().create_timer(0.1).timeout
	
	# Luăm datele generate de Singleton-ul tău
	var puzzle_data = PuzzleGen.get_puzzle_data("numpad_puzzle")
	
	if puzzle_data.has("solution"):
		# Scriem parola pe bilet! (Asta va apărea în Room A)
		label.text = "COD SEIF:\n" + puzzle_data["solution"]
	else:
		label.text = "Eroare:\nNicio parolă."
