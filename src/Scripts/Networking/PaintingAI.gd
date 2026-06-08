extends MeshInstance3D
# ============================================================
# PaintingAI.gd
# Atașează-l pe nodul MeshInstance3D al tabloului din scenă.
#
# CE FACE:
#   La start, trimite un request HTTP la API-ul tău de imagini
#   (implicit: Pollinations.ai — GRATUIT, fără cheie API).
#   Când imaginea sosește, o aplică ca textură pe tablou.
#
# CUM SE INTEGREAZĂ:
#   1. Pune scriptul pe nodul "Painting" (MeshInstance3D) din scenă.
#   2. Dacă vrei DALL-E (OpenAI), schimbă USE_DALLE = true și
#      setează api_key din Project Settings sau din export var.
#   3. Asigură-te că în Project Settings → Network → SSL e activat.
# ============================================================

## Setează true dacă vrei să folosești DALL-E (necesită API key OpenAI)
@export var USE_DALLE: bool = false
@export var openai_api_key: String = ""  # Pune cheia aici sau din inspector

## Suprafața materialului pe care se aplică textura (0 = prima suprafață)
@export var surface_index: int = 0

# Prompt-uri randomizate — la fiecare sesiune se alege unul diferit
const PROMPTS = [
	"a cryptic symbol painted in oil on old canvas, dark horror atmosphere",
	"an ancient eye symbol with roman numerals, mysterious and eerie painting",
	"a clock melting on a dark wall, surreal escape room clue",
	"a constellation map with a hidden number, vintage illustration style",
	"a cracked mirror reflecting a distorted room, horror art",
	"a torn page with a 4-digit code written in blood-red ink",
	"a haunted house blueprint with a marked room, aged paper style",
]

var http_request: HTTPRequest
var chosen_prompt: String

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	# Doar host-ul alege promptul și îl sincronizează
	if multiplayer.is_server():
		seed(Time.get_unix_time_from_system())
		chosen_prompt = PROMPTS[randi() % PROMPTS.size()]
		print("[PaintingAI] Generez tabloul cu promptul: ", chosen_prompt)
		sync_prompt.rpc(chosen_prompt)

@rpc("authority", "call_local")
func sync_prompt(prompt: String) -> void:
	chosen_prompt = prompt
	print("[PaintingAI] Prompt sincronizat: ", chosen_prompt)
	if USE_DALLE:
		_request_dalle()
	else:
		_request_pollinations()

# ── OPȚIUNEA 1: Pollinations.ai (gratuit, fără cheie) ──────────────────────
func _request_pollinations() -> void:
	var encoded = chosen_prompt.uri_encode()
	# width/height opționale — 512x512 e suficient pentru o textură de tablou
	var url = "https://image.pollinations.ai/prompt/%s?width=512&height=512&nologo=true" % encoded
	var err = http_request.request(url)
	if err != OK:
		print("[PaintingAI] Eroare la request Pollinations: ", err)

# ── OPȚIUNEA 2: DALL-E (OpenAI) ────────────────────────────────────────────
func _request_dalle() -> void:
	if openai_api_key.is_empty():
		push_error("[PaintingAI] USE_DALLE=true dar openai_api_key e gol!")
		return

	var url = "https://api.openai.com/v1/images/generations"
	var headers = [
		"Authorization: Bearer " + openai_api_key,
		"Content-Type: application/json"
	]
	var body = JSON.stringify({
		"model": "dall-e-3",
		"prompt": chosen_prompt,
		"n": 1,
		"size": "1024x1024",
		"response_format": "url"
	})

	var err = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("[PaintingAI] Eroare la request DALL-E: ", err)

# ── HANDLER COMUN ──────────────────────────────────────────────────────────
func _on_request_completed(result: int, response_code: int,
		_headers: PackedStringArray, body: PackedByteArray) -> void:

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[PaintingAI] Request eșuat. Cod: ", response_code)
		return

	if USE_DALLE:
		_apply_dalle_response(body)
	else:
		_apply_image_bytes(body)

func _apply_dalle_response(body: PackedByteArray) -> void:
	# DALL-E returnează un JSON cu URL-ul imaginii — trebuie un al doilea request
	var json = JSON.new()
	var err = json.parse(body.get_string_from_utf8())
	if err != OK:
		print("[PaintingAI] Eroare parse JSON DALL-E")
		return

	var image_url = json.data["data"][0]["url"]
	print("[PaintingAI] URL imagine DALL-E primit, descarc...")

	# Al doilea HTTPRequest pentru imaginea în sine
	var http2 = HTTPRequest.new()
	add_child(http2)
	http2.request_completed.connect(func(res, code, _h, img_body):
		if res == HTTPRequest.RESULT_SUCCESS and code == 200:
			_apply_image_bytes(img_body)
		else:
			print("[PaintingAI] Eroare la descărcarea imaginii DALL-E: ", code)
		http2.queue_free()
	)
	http2.request(image_url)

func _apply_image_bytes(bytes: PackedByteArray) -> void:
	var img = Image.new()
	# Încearcă PNG, apoi JPG
	var load_err = img.load_png_from_buffer(bytes)
	if load_err != OK:
		load_err = img.load_jpg_from_buffer(bytes)
	if load_err != OK:
		print("[PaintingAI] Nu pot încărca imaginea (nu e PNG/JPG valid)")
		return

	var texture = ImageTexture.create_from_image(img)
	_apply_texture_to_mesh(texture)
	print("[PaintingAI] ✅ Tabloul a fost actualizat cu indiciul vizual unic!")

func _apply_texture_to_mesh(texture: ImageTexture) -> void:
	# Self e MeshInstance3D — luăm materialul suprafeței și schimbăm albedo
	if not self is MeshInstance3D:
		push_error("[PaintingAI] Scriptul trebuie pus pe un MeshInstance3D!")
		return

	var mat = (self as MeshInstance3D).get_active_material(surface_index)
	if mat == null:
		# Creăm un material nou dacă nu există
		mat = StandardMaterial3D.new()
		(self as MeshInstance3D).set_surface_override_material(surface_index, mat)

	# Clonăm materialul ca să nu afectăm alte instanțe
	mat = mat.duplicate()
	(self as MeshInstance3D).set_surface_override_material(surface_index, mat)

	if mat is StandardMaterial3D:
		(mat as StandardMaterial3D).albedo_texture = texture
	elif mat is ORMMaterial3D:
		(mat as ORMMaterial3D).albedo_texture = texture
	else:
		push_warning("[PaintingAI] Material necunoscut: ", mat.get_class())
