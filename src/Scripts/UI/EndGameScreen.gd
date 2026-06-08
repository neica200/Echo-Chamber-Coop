extends Control
# ============================================================
# EndGameScreen.gd
# Path: res://Scripts/UI/EndGameScreen.gd
#
# SETUP:
#   1. Pune EndGame.tscn în res://Scenes/
#   2. Adaugă scriptul la path-ul de mai sus
#   3. În testLevel.tscn (sau scena principală de joc),
#      instanțiază EndGame.tscn ca nod copil
#   4. Conectarea la GameEvents.escape_door_opened se face automat
#      în _ready() de mai jos — nu mai trebuie nimic extra.
#
# INTEGRARE cu GameStats.gd existent:
#   În Numpad.gd, la greșeală adaugă o linie:
#       GameStats.add_numpad_mistake()
#   La success nu mai trebuie nimic — GameEvents.escape_door_opened
#   este deja emis în Numpad.gd și GameStats îl ascultă.
# ============================================================

@onready var rank_label    : Label  = $CenterContainer/Card/VBox/RankContainer/RankLabel
@onready var rank_title    : Label  = $CenterContainer/Card/VBox/RankTitle
@onready var value_time    : Label  = $CenterContainer/Card/VBox/StatsGrid/ValueTime
@onready var value_errors  : Label  = $CenterContainer/Card/VBox/StatsGrid/ValueErrors
@onready var value_score   : Label  = $CenterContainer/Card/VBox/StatsGrid/ValueScore
@onready var feedback_label: Label  = $CenterContainer/Card/VBox/FeedbackLabel
@onready var replay_btn    : Button = $CenterContainer/Card/VBox/Buttons/ReplayBtn
@onready var menu_btn      : Button = $CenterContainer/Card/VBox/Buttons/MenuBtn

const RANK_DATA = {
	"S": {
		"color":    Color(1.0,  0.84, 0.0,  1.0),
		"title":    "PERFECT ESCAPE",
		"feedback": "Nicio greșeală. Sincronizare perfectă. Legendă."
	},
	"A": {
		"color":    Color(0.4,  0.85, 0.4,  1.0),
		"title":    "SHARP MINDS",
		"feedback": "Rapizi și precisi. Puțin loc de îmbunătățit."
	},
	"B": {
		"color":    Color(0.35, 0.70, 1.0,  1.0),
		"title":    "SOLID TEAMWORK",
		"feedback": "Câteva erori v-au costat timp, dar ați scăpat."
	},
	"C": {
		"color":    Color(1.0,  0.60, 0.15, 1.0),
		"title":    "CLOSE CALL",
		"feedback": "La limită. Data viitoare comunicați mai mult."
	},
	"D": {
		"color":    Color(0.85, 0.20, 0.20, 1.0),
		"title":    "BARELY SURVIVED",
		"feedback": "Camera v-a lăsat să plecați... din milă."
	},
}

func _ready() -> void:
	visible = false
	GameEvents.escape_door_opened.connect(_on_escape_door_opened)
	

func _on_escape_door_opened() -> void:
	# Delay scurt ca să se vadă animația ușii
	await get_tree().create_timer(1.5).timeout
	show_results()

# ── AFIȘARE ────────────────────────────────────────────────
func show_results() -> void:
	var stats = GameStats.get_stats()
	var rank  = stats["rank"]
	var rd    = RANK_DATA[rank]

	rank_label.text = rank
	rank_label.add_theme_color_override("font_color", rd["color"])
	rank_title.text = rd["title"]
	rank_title.add_theme_color_override("font_color", rd["color"])

	value_time.text   = _format_time(stats["time"])
	value_errors.text = str(stats["numpad_mistakes"])
	value_score.text  = "%d / 100" % _calculate_score(stats["time"], stats["numpad_mistakes"])

	feedback_label.text = rd["feedback"]

	# Fade-in panel
	visible = true
	modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.6) \
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Bounce pe rank
	rank_label.scale = Vector2(0.4, 0.4)
	tween.parallel().tween_property(rank_label, "scale", Vector2(1.0, 1.0), 0.55) \
		 .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# ── SCOR 0–100 ─────────────────────────────────────────────
func _calculate_score(time_sec: float, errors: int) -> int:
	var time_pts: float
	if time_sec <= 180.0:
		time_pts = 50.0
	elif time_sec >= 600.0:
		time_pts = 0.0
	else:
		time_pts = 50.0 * (1.0 - (time_sec - 180.0) / 420.0)
	var error_pts = clamp(50.0 - errors * 10.0, 0.0, 50.0)
	return int(round(time_pts + error_pts))

func _format_time(seconds: float) -> String:
	var m = int(seconds) / 60
	var s = int(seconds) % 60
	return "%02d:%02d" % [m, s]

# ── BUTOANE ────────────────────────────────────────────────
func _on_replay_pressed() -> void:
	GameStats.numpad_mistakes = 0
	GameStats.start_time      = Time.get_unix_time_from_system()
	GameStats.total_time      = 0.0
	GameStats.puzzles_solved  = 0
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	GameStats.numpad_mistakes = 0
	GameStats.total_time      = 0.0
	GameStats.puzzles_solved  = 0
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn.tscn")


func _on_replay_btn_pressed() -> void:
	_on_replay_pressed()

func _on_menu_btn_pressed() -> void:
	_on_menu_pressed()
