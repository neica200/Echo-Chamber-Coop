extends StaticBody3D

var numpad_parent = null
var digit_value = ""

# Funcția pe care PlayerController-ul tău (Jucătorul) o caută când apasă E cu laserul
func interact():
	if numpad_parent:
		# Trimitem apăsarea înapoi la panoul principal
		numpad_parent.button_pressed(digit_value)
