extends Node
# ============================================================
# WalkieTalkie.gd  — Singleton (Autoload)
# ============================================================
# SETUP în Godot:
#   1. Project → Project Settings → Autoload → Adaugă scriptul
#      cu numele "WalkieTalkie"
#   2. În Project Settings → Audio → activează "Enable Audio Input"
#   3. Asigură-te că în export settings ai permisiunile de microfon
#      (pe Android/iOS e necesar explicit)
#
# FUNCȚIONARE:
#   - Hold T (sau butonul din UI) = transmiți vocea
#   - Vocea ta e capturată cu AudioStreamMicrophone
#   - Trece prin un bus audio "Radio" cu efecte: BandPassFilter +
#     AudioEffectDistortion + AudioEffectReverb (ușor)
#   - Ceilalți jucători aud vocea ta via MultiplayerPeer (RPC)
#     transmisă ca PackedByteArray de audio samples
#
# NOTĂ IMPORTANTĂ despre transmisia audio în Godot 4 multiplayer:
#   Godot NU are un sistem nativ de voice-streaming via RPC.
#   Această implementare capturează chunks de la microfon și le
#   trimite periodic prin RPC — simplu și funcțional pentru LAN/internet
#   cu latență acceptabilă (~100–200ms).
# ============================================================

const CHUNK_DURATION = 0.1     # secunde per chunk RPC
var sample_rate: float = 44100.0
var decimated_rate: float = 11025.0
var samples_per_chunk: int = 1102

var is_transmitting: bool = false
var mic_capture: AudioStreamMicrophone
var playback: AudioStreamGeneratorPlayback
var receive_buffer: PackedFloat32Array = PackedFloat32Array()

# Nodul de playback pentru vocea primită
var _voice_player: AudioStreamPlayer
var _mic_player: AudioStreamPlayer
var _capture_effect: AudioEffectCapture

# Acumulăm mostre înainte de a trimite RPC
var _sample_accumulator: PackedFloat32Array

## Efect Radio ──────────────────────────────────────────────
# Creăm bus-ul "Radio" cu 3 efecte în lanț

func _ready() -> void:
	sample_rate = AudioServer.get_mix_rate()
	decimated_rate = sample_rate / 4.0
	samples_per_chunk = int(decimated_rate * CHUNK_DURATION)
	_setup_radio_bus()
	_setup_mic_capture()
	_setup_voice_player()
	print("[WalkieTalkie] Sistem inițializat. Rate: ", sample_rate, " Ține T pentru a transmite.")

# ── 1. BUS AUDIO "Radio" cu efecte distorsion ──────────────
func _setup_radio_bus() -> void:
	# Verificăm dacă bus-ul există deja (nu vrem duplicate)
	if AudioServer.get_bus_index("Radio") != -1:
		return

	AudioServer.add_bus()
	var bus_idx = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_idx, "Radio")
	AudioServer.set_bus_send(bus_idx, "Master")

	# Efect 1: EQ6 (Tăiem bașii și înaltele pentru efectul de difuzor mic)
	var eq = AudioEffectEQ6.new()
	eq.set_band_gain_db(0, -24.0) # 32 Hz
	eq.set_band_gain_db(1, -12.0) # 100 Hz
	eq.set_band_gain_db(2, 6.0)   # 320 Hz
	eq.set_band_gain_db(3, 12.0)  # 1 kHz
	eq.set_band_gain_db(4, 6.0)   # 3.2 kHz
	eq.set_band_gain_db(5, -24.0) # 10 kHz
	AudioServer.add_bus_effect(bus_idx, eq)
	AudioServer.add_bus_effect(bus_idx, eq)

	# Efect 2: Distorsion ușoară (caracteristic radio/walkie-talkie)
	var distort = AudioEffectDistortion.new()
	distort.mode = AudioEffectDistortion.MODE_CLIP
	distort.pre_gain = 18.0    # amplificăm înainte de clip
	distort.drive = 0.3        # cât de tare distorsionăm
	distort.post_gain = -6.0   # dăm înapoi gain-ul
	AudioServer.add_bus_effect(bus_idx, distort)

	# Efect 3: Reverb minim (simulează cutia metalică a stației)
	var reverb = AudioEffectReverb.new()
	reverb.room_size = 0.15
	reverb.damping  = 0.8
	reverb.wet      = 0.2
	reverb.dry      = 0.8
	AudioServer.add_bus_effect(bus_idx, reverb)

	# Efect 4: Compressor — egalizează volumul vocii
	var comp = AudioEffectCompressor.new()
	comp.threshold = -20.0
	comp.ratio     = 4.0
	comp.attack_us = 5.0
	comp.release_ms = 100.0
	AudioServer.add_bus_effect(bus_idx, comp)

	print("[WalkieTalkie] Bus 'Radio' creat cu efecte.")

# ── 2. CAPTURA MICROFON ────────────────────────────────────
func _setup_mic_capture() -> void:
	if AudioServer.get_bus_index("MicCapture") == -1:
		# Create a destination bus that is muted so we don't hear ourselves
		AudioServer.add_bus()
		var mute_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(mute_idx, "MuteBus")
		AudioServer.set_bus_mute(mute_idx, true)

		# Create the capture bus
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "MicCapture")
		AudioServer.set_bus_send(idx, "MuteBus") # Trimitem spre bus-ul mut

	var cap_effect = AudioEffectCapture.new()
	cap_effect.buffer_length = 0.2
	AudioServer.add_bus_effect(AudioServer.get_bus_index("MicCapture"), cap_effect)
	_capture_effect = cap_effect

	_mic_player = AudioStreamPlayer.new()
	mic_capture = AudioStreamMicrophone.new()
	_mic_player.stream = mic_capture
	_mic_player.bus = "MicCapture"
	add_child(_mic_player)

# ── 3. PLAYER PENTRU VOCEA PRIMITĂ ────────────────────────
func _setup_voice_player() -> void:
	_voice_player = AudioStreamPlayer.new()
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = decimated_rate
	gen.buffer_length = 1.0
	_voice_player.stream = gen
	_voice_player.bus = "Radio"   # ← vocea primită trece prin efectele radio!
	_voice_player.volume_db = 6.0
	add_child(_voice_player)
	_voice_player.play()
	playback = _voice_player.get_stream_playback()

# ── INPUT: T = Push-to-Talk ────────────────────────────────
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("walkie_talk"):
		start_transmit()
	elif Input.is_action_just_released("walkie_talk"):
		stop_transmit()

	if is_transmitting:
		_capture_and_send()
		
	# --- JITTER BUFFER & PLAYBACK ---
	if receive_buffer.size() > 0:
		if not _voice_player.playing:
			_voice_player.play()
		if playback == null:
			playback = _voice_player.get_stream_playback()
			
		var frames_available = playback.get_frames_available()
		if frames_available > 0:
			var to_push = min(receive_buffer.size(), frames_available)
			for i in range(to_push):
				playback.push_frame(Vector2(receive_buffer[i], receive_buffer[i]))
			receive_buffer = receive_buffer.slice(to_push)

func start_transmit() -> void:
	if is_transmitting: return
	is_transmitting = true
	_mic_player.play()
	_sample_accumulator = PackedFloat32Array()
	print("[WalkieTalkie] 📡 TRANSMIT ON")

func stop_transmit() -> void:
	if not is_transmitting: return
	is_transmitting = false
	_mic_player.stop()
	# Trimite ultimele mostre rămase
	if _sample_accumulator.size() > 0:
		_send_chunk_rpc(_sample_accumulator)
		_sample_accumulator = PackedFloat32Array()
	print("[WalkieTalkie] 📡 TRANSMIT OFF")

# ── CAPTURĂ + TRIMITERE ────────────────────────────────────
func _capture_and_send() -> void:
	if _capture_effect == null: return
	var frames = _capture_effect.get_frames_available()
	if frames <= 0: return

	var data: PackedVector2Array = _capture_effect.get_buffer(frames)
	for i in range(data.size()):
		if i % 4 == 0:
			# Mono: media stânga + dreapta
			_sample_accumulator.append((data[i].x + data[i].y) * 0.5)

	if _sample_accumulator.size() >= samples_per_chunk:
		var chunk = _sample_accumulator.slice(0, samples_per_chunk)
		_sample_accumulator = _sample_accumulator.slice(samples_per_chunk)
		_send_chunk_rpc(chunk)

func _send_chunk_rpc(samples: PackedFloat32Array) -> void:
	if not multiplayer.has_multiplayer_peer(): return
	var bytes = samples.to_byte_array()
	# Trimitem explicit la toți peers
	for id in multiplayer.get_peers():
		receive_voice_chunk.rpc_id(id, bytes)

# ── PRIMIRE VOCE ────────────────────────────────────────────
@rpc("any_peer", "reliable", "call_remote", 2)
func receive_voice_chunk(bytes: PackedByteArray) -> void:
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		return
	var samples = bytes.to_float32_array()
	receive_buffer.append_array(samples)

# ── UTILITY pentru UI ──────────────────────────────────────
func get_transmit_state() -> bool:
	return is_transmitting
