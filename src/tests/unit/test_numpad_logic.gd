extends GutTest

var NumpadScene = preload("res://Scripts/Puzzles/Numpad.gd")

func test_numpad_input_accumulation():
	# TEST 1: Verificăm dacă butoanele adaugă corect cifrele în string-ul curent
	var numpad = autofree(NumpadScene.new())
	numpad.target_code = "1234" # Setăm un cod de test manual
	
	# Simulăm jucătorul apăsând butonul "1" apoi "2"
	numpad.button_pressed("1")
	numpad.button_pressed("2")
	
	# Ne așteptăm ca inputul acumulat să fie "12"
	assert_eq(numpad.current_input, "12", "Input-ul curent trebuie să concateneze cifrele apăsate succesiv.")

func test_numpad_failure_reset():
	# TEST 2: Verificăm dacă seiful se resetează când se introduce un cod greșit de 4 cifre
	var numpad = autofree(NumpadScene.new())
	numpad.target_code = "1234"
	
	# Jucătorul introduce un cod greșit de aceeași lungime (4 cifre)
	numpad.button_pressed("1")
	numpad.button_pressed("1")
	numpad.button_pressed("1")
	numpad.button_pressed("1") # Parola introdusă este "1111", care nu e "1234"
	
	# Deoarece a greșit la a 4-a cifră, sistemul ar trebui să șteargă automat inputul
	assert_eq(numpad.current_input, "", "Când se introduce o parolă greșită de 4 cifre, inputul curent trebuie să fie resetat la gol.")

func test_numpad_success_state():
	# TEST 3: Verificăm dacă introducerea codului corect menține succesul și nu resetează inputul
	var numpad = autofree(NumpadScene.new())
	numpad.target_code = "1234"
	
	# Jucătorul introduce codul corect
	numpad.button_pressed("1")
	numpad.button_pressed("2")
	numpad.button_pressed("3")
	numpad.button_pressed("4")
	
	# Deoarece codul a fost corect, nu se resetează ci rămâne pe ecran
	assert_eq(numpad.current_input, "1234", "Când se introduce parola corectă, inputul NU trebuie resetat, semnalând succesul.")
