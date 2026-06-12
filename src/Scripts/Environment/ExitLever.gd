extends StaticBody3D

@export var lever_id: int = 1
var pulled = false

func interact():
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		rpc("sync_interact")
	else:
		sync_interact()

@rpc("any_peer", "call_local")
func sync_interact():
	if pulled: return
	
	GameEvents.pull_exit_lever(lever_id)
	pulled = true
	
	# Visual feedback: apasă butonul
	var tween = create_tween()
	var handle = $Handle
	if handle:
		tween.tween_property(handle, "position:z", 0.05, 0.1)
		tween.tween_property(handle, "position:z", 0.1, 0.2).set_delay(2.0)
	
	AudioManager.play_click()
	
	# Reset after 2 seconds (the window to pull the other lever)
	await get_tree().create_timer(2.0).timeout
	pulled = false
