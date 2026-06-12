extends StaticBody3D

var fuse_parent = null
var grid_index = 0

func interact():
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		rpc("sync_interact")
	else:
		sync_interact()

@rpc("any_peer", "call_local")
func sync_interact():
	if fuse_parent:
		animate_press()
		fuse_parent.toggle_fuse(grid_index, self)

func animate_press():
	var tween = create_tween()
	# Apăsare pe axa Z
	var original_pos = position
	tween.tween_property(self, "position:z", position.z - 0.03, 0.1)
	tween.tween_property(self, "position:z", original_pos.z, 0.1)
