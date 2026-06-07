extends Node

var click_player: AudioStreamPlayer
var error_player: AudioStreamPlayer
var success_player: AudioStreamPlayer
var bg_player: AudioStreamPlayer

func _ready():
	# Creăm nodurile de Audio dinamic și le atașăm la Singleton
	click_player = AudioStreamPlayer.new()
	error_player = AudioStreamPlayer.new()
	success_player = AudioStreamPlayer.new()
	bg_player = AudioStreamPlayer.new()
	
	add_child(click_player)
	add_child(error_player)
	add_child(success_player)
	add_child(bg_player)
	
	# Încărcăm fișierele tale din folderul sounds
	if FileAccess.file_exists("res://sounds/click.mp3"):
		click_player.stream = load("res://sounds/click.mp3")
		print("[AudioManager] Încărcat click.mp3: ", click_player.stream != null)
	else:
		print("[AudioManager] EROARE: click.mp3 nu a fost găsit pe disc!")
		
	if FileAccess.file_exists("res://sounds/fail.mp3"):
		error_player.stream = load("res://sounds/fail.mp3")
		print("[AudioManager] Încărcat fail.mp3: ", error_player.stream != null)
		
	if FileAccess.file_exists("res://sounds/correct.mp3"):
		success_player.stream = load("res://sounds/correct.mp3")
		print("[AudioManager] Încărcat correct.mp3: ", success_player.stream != null)
		
	# Muzica de fundal
	if FileAccess.file_exists("res://sounds/background.mp3"):
		bg_player.stream = load("res://sounds/background.mp3")
		print("[AudioManager] Încărcat background.mp3: ", bg_player.stream != null)
		bg_player.volume_db = -10.0 # O dăm mai încet să nu acopere tot
		bg_player.play()
	else:
		print("[AudioManager] EROARE: background.mp3 nu a fost găsit pe disc!")

func play_click():
	if click_player.stream:
		click_player.play()
	else:
		print("🔊 [AUDIO] CLICK!")

func play_error(volume: float = 0.0):
	if error_player.stream:
		error_player.volume_db = volume
		error_player.play()
	else:
		print("🔊 [AUDIO] ERROR / BUZZER! (vol: ", volume, ")")

func play_success():
	if success_player.stream:
		success_player.play()
	else:
		print("🔊 [AUDIO] SUCCESS CHIME!")
