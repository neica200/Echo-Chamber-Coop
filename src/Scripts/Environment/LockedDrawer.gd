extends Node3D

@export var required_item: String = "Cheie de Birou"
@export var contains_note: bool = true

var is_open = false

# Funcția obișnuită pe care o caută PlayerController
func interact():
	# Căutăm jucătorul care a interacționat (ne folosim de un mic trick cu get_tree().get_nodes_in_group dacă aveam grupuri,
	# dar cel mai simplu e să detectăm din raza lui PlayerController. 
	# Aici facem o verificare globală simplistă pentru single-player local:
	var player = get_viewport().get_camera_3d().get_parent()
	
	if is_open:
		print("Sertarul este deja deschis.")
		return
		
	if player.has_method("has_item") and player.has_item(required_item):
		print("🔓 Ai descuiat sertarul folosind: ", required_item)
		is_open = true
		AudioManager.play_success()
		player.remove_item(required_item) # Consumăm cheia
		GameEvents.emit_signal("drawer_opened")
		open_animation()
	else:
		AudioManager.play_error()
		print("🔒 E încuiat. Ai nevoie de: ", required_item)

func open_animation():
	var tween = create_tween()
	# Mutăm sertarul (sau masa) în față pentru a simula deschiderea. 
	# Presupunem că acest script stă pe un element ce glisează.
	tween.tween_property(self, "position:z", position.z + 0.3, 0.5)
	
	if contains_note:
		# Putem spawna biletul cu parola! 
		# În cazul nostru, biletul e deja pe masă, așa că îl facem vizibil:
		var note = get_node_or_null("Note")
		if note:
			note.visible = true
