extends Node3D

@export var item_name: String = "Cheie"

# Called by PlayerController when interacting with this object
func pick_up(player):
	player.add_to_inventory(item_name)
	print("✨ Ai ridicat obiectul: ", item_name)
	
	# Oferim feedback vizual și distrugem obiectul vizual complet pe TOATE calculatoarele
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		rpc("sync_delete_item")
	else:
		sync_delete_item()

@rpc("any_peer", "call_local")
func sync_delete_item():
	if owner:
		owner.queue_free()
	else:
		get_parent().queue_free() if get_parent() is Node3D else queue_free()
