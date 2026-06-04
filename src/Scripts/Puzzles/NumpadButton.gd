extends StaticBody3D

var numpad_parent = null
var digit_value = ""

# Funcția pe care PlayerController-ul tău (Jucătorul) o caută când apasă E cu laserul
func interact():
	if numpad_parent:
		animate_press()
		# Trimitem apăsarea înapoi la panoul principal
		numpad_parent.button_pressed(digit_value)

func animate_press():
	var tween = create_tween()
	# Afundăm butonul cu 0.02 pe axa Z
	var original_pos = position
	tween.tween_property(self, "position:z", position.z - 0.02, 0.1)
	tween.tween_property(self, "position:z", original_pos.z, 0.1)
