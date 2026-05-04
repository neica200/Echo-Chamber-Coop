extends StaticBody3D

var panel_parent = null
var color_name = ""

# Interacțiunea generată de laserul jucătorului
func interact():
	if panel_parent:
		panel_parent.button_pressed(color_name)
