extends StaticBody3D

var panel_parent = null
var color_name = ""

# Interacțiunea generată de laserul jucătorului
func receive_3d_click(hit_pos: Vector3):
	if GameEvents.current_stage < 2:
		print("🔒 [Sistem] Trebuie să rezolvi panoul electric (Faza 1) mai întâi!")
		return
	if panel_parent and panel_parent.has_method("button_pressed"):
		animate_press()
		panel_parent.button_pressed(color_name)

func animate_press():
	var tween = create_tween()
	# Afundăm butonul. Să presupunem că Z e adâncimea.
	var original_pos = position
	tween.tween_property(self, "position:z", position.z - 0.05, 0.1)
	tween.tween_property(self, "position:z", original_pos.z, 0.1)
