extends Node

var click_player: AudioStreamPlayer
var error_player: AudioStreamPlayer
var success_player: AudioStreamPlayer
var bg_player: AudioStreamPlayer

var footstep_wood_player: AudioStreamPlayer
var footstep_carpet_player: AudioStreamPlayer

func _ready():
	# Creăm nodurile de Audio dinamic și le atașăm la Singleton
	click_player = AudioStreamPlayer.new()
	error_player = AudioStreamPlayer.new()
	success_player = AudioStreamPlayer.new()
	bg_player = AudioStreamPlayer.new()
	footstep_wood_player = AudioStreamPlayer.new()
	footstep_carpet_player = AudioStreamPlayer.new()
	
	add_child(click_player)
	add_child(error_player)
	add_child(success_player)
	add_child(bg_player)
	add_child(footstep_wood_player)
	add_child(footstep_carpet_player)
	
	# Încărcăm fișierele tale din folderul sounds
	if FileAccess.file_exists("res://sounds/click.mp3"):
		click_player.stream = load("res://sounds/click.mp3")
	if FileAccess.file_exists("res://sounds/fail.mp3"):
		error_player.stream = load("res://sounds/fail.mp3")
	if FileAccess.file_exists("res://sounds/correct.mp3"):
		success_player.stream = load("res://sounds/correct.mp3")
		
	if FileAccess.file_exists("res://sounds/178990__jmdh__footsteps.wav"):
		footstep_wood_player.stream = load("res://sounds/178990__jmdh__footsteps.wav")
		footstep_wood_player.volume_db = -15.0 # Mult mai încet (lemn)
		
	if FileAccess.file_exists("res://sounds/732573__lewisemmott5__footsteps-carpet.wav"):
		footstep_carpet_player.stream = load("res://sounds/732573__lewisemmott5__footsteps-carpet.wav")
		footstep_carpet_player.volume_db = -5.0 # Ajustare volum pentru noul fișier
		
	# Muzica de fundal
	if FileAccess.file_exists("res://sounds/background.mp3"):
		var bg_stream = load("res://sounds/background.mp3")
		if bg_stream is AudioStreamMP3:
			bg_stream.loop = true
		bg_player.stream = bg_stream
		bg_player.volume_db = -10.0 # O dăm mai încet să nu acopere tot
		bg_player.play()

func play_click():
	if click_player.stream:
		click_player.play()

func play_error(volume: float = 0.0):
	if error_player.stream:
		error_player.volume_db = volume
		error_player.play()

func play_success():
	if success_player.stream:
		success_player.play()

var footstep_wood_offsets = [0.168, 0.934, 1.6, 2.425, 3.104, 3.85, 4.516, 5.612, 6.588, 7.304, 7.895, 8.519, 9.211, 9.957, 10.473, 11.232, 11.75, 12.411, 13.158, 15.286, 15.831, 16.583, 17.447, 18.252, 19.182, 19.723, 20.34, 21.533, 22.282, 23.1, 25.525, 26.131, 26.746, 27.318]
var footstep_carpet_offsets = [1.846, 2.389, 2.871, 3.383, 3.848, 4.477, 5.009, 5.546, 6.003, 6.569, 7.09, 7.619, 8.143, 8.65, 9.183, 9.694, 10.232, 10.718, 11.291, 11.799, 12.309, 12.826, 13.358, 13.803, 14.322, 14.887, 15.332, 15.925, 16.301, 16.959, 17.623, 17.923, 19.409, 20.077, 21.401, 23.315, 25.163, 27.092, 28.888, 30.724]

func play_footstep(is_on_rug: bool):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var random_offset = 0.0
	
	if is_on_rug:
		if footstep_carpet_player.stream:
			footstep_carpet_player.pitch_scale = rng.randf_range(0.95, 1.05)
			random_offset = footstep_carpet_offsets[rng.randi() % footstep_carpet_offsets.size()]
			footstep_carpet_player.play(random_offset)
			
			# Oprim sunetul direct pe player-ul permanent ca să evităm micro-stutter (delay cauzat de crearea unui nou nod)
			get_tree().create_timer(0.4).timeout.connect(func(): footstep_carpet_player.stop())
	else:
		if footstep_wood_player.stream:
			footstep_wood_player.pitch_scale = rng.randf_range(0.95, 1.05)
			random_offset = footstep_wood_offsets[rng.randi() % footstep_wood_offsets.size()]
			footstep_wood_player.play(random_offset)
			
			get_tree().create_timer(0.4).timeout.connect(func(): footstep_wood_player.stop())
