extends Node3D

@export var item_name: String = "Cheie"

# Called by PlayerController when interacting with this object
func pick_up(player):
	player.add_to_inventory(item_name)
	
	# Oferim feedback vizual și distrugem obiectul vizual complet
	print("✨ Ai ridicat obiectul: ", item_name)
	if owner:
		owner.queue_free()
	else:
		get_parent().queue_free() if get_parent() is Node3D else queue_free()
