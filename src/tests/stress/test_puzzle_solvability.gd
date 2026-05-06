extends GutTest

var PuzzleGenAgent = preload("res://Scripts/Agents/PuzzleGeneratorAgent.gd")

func test_puzzle_solvability_stress():
	# Acest test verifică robustețea generatorului procedural de logică a puzzle-urilor
	# Folosim `autofree` pentru a nu bloca runner-ul GUT la final
	var agent = autofree(PuzzleGenAgent.new())
	
	# STRESS TEST: Rulăm generatorul de 100 de ori folosind 100 de seed-uri (semințe) unice.
	# Aceasta garantează că, indiferent cum se amestecă randomizarea, graful de dependențe funcționează perfect.
	for seed_val in range(100):
		agent.generate_puzzles(seed_val)
		
		# TEST 1 (Completitudine): Verificăm dacă TOATE cele 4 puzzle-uri de bază sunt generate pentru acest seed.
		assert_true(agent.active_puzzles.has("numpad_puzzle"), "Lipsește numpad la seed " + str(seed_val))
		assert_true(agent.active_puzzles.has("color_sequence"), "Lipsește secvența de culori la seed " + str(seed_val))
		assert_true(agent.active_puzzles.has("grid_puzzle"), "Lipsește matricea la seed " + str(seed_val))
		assert_true(agent.active_puzzles.has("math_puzzle"), "Lipsește puzzle-ul de matematică la seed " + str(seed_val))
		
		# Parcurgem fiecare puzzle activ generat în tura curentă
		for p_name in agent.active_puzzles:
			var p_data = agent.active_puzzles[p_name]
			
			# TEST 2 (Asimetrie Strictă): Cel mai critic test al jocului!
			# Ne asigurăm ABSOLUT că indiciul (clue_room) NU pică niciodată în aceeași cameră cu mecanismul (lock_room).
			# Dacă ar pica în aceeași cameră, jucătorii nu ar mai fi obligați să comunice!
			assert_ne(p_data["clue_room"], p_data["lock_room"], "EROARE CRITICĂ: Clue și Lock în aceeași cameră pentru " + p_name + " la seed " + str(seed_val))
			
			# TEST 3 (Integritatea Soluției): Verificăm dacă s-a generat un șir valid de caractere/valori pentru rezolvare
			assert_not_null(p_data.get("solution"), "Lipsește soluția generată pentru " + p_name + " la seed " + str(seed_val))
