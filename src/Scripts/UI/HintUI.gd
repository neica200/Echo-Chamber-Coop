extends CanvasLayer

@onready var label: RichTextLabel = $HintLabel

func _ready() -> void:
	# Ascundem labelul la început
	label.visible = false
	label.modulate = Color(1, 1, 1, 0)

func _on_hint_received(text: String) -> void:
	label.text = "[center][b]INDICIU:[/b] " + text + "[/center]"
	_show_hint()

func _on_hint_failed(error_msg: String) -> void:
	label.text = "[center][color=red]Eroare Indiciu:[/color] " + error_msg + "[/center]"
	_show_hint()

func _show_hint() -> void:
	label.visible = true
	# Fade in scurt
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 0.5)
	
	# Așteptăm 8 secunde
	tween.tween_interval(8.0)
	
	# Fade out
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func(): label.visible = false)
