extends StaticBody3D

var panel_parent = null
var color_name = ""

func receive_3d_click(hit_pos: Vector3):
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().size() > 0:
		GameEvents.rpc("sync_color_button_pressed", get_path())
	else:
		GameEvents.sync_color_button_pressed(get_path())

func animate_press():
	var tween = create_tween()
	var original_pos = position
	tween.tween_property(self, "position:z", position.z - 0.05, 0.1)
	tween.tween_property(self, "position:z", original_pos.z, 0.1)
