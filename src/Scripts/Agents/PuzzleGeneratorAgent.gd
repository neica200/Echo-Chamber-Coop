extends Node

# Baza de date pentru puzzle-urile active (Graful de dependențe)
var active_puzzles = {}

func _ready():
	# Generăm un set de puzzle-uri imediat ce pornește jocul (doar pentru faza de test)
	test_generation()

# Inițializează și leagă indiciile de mecanisme pe baza unui "Seed" (sămânță)
func generate_puzzles(seed_value: int):
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	active_puzzles.clear()
	
	# --- 1. Puzzle-ul Cod Numeric ---
	# Generăm un număr la întâmplare între 1000 și 9999
	var numeric_code = str(rng.randi_range(1000, 9999))
	
	active_puzzles["numpad_puzzle"] = {
		"type": "numeric",
		"solution": numeric_code,
		"clue_room": "RoomA",
		"lock_room": "RoomB"
	}
	
	# --- 2. Puzzle-ul Secvență de Culori ---
	var colors = ["Rosu", "Albastru", "Verde", "Galben"]
	# Amestecăm culorile (un shuffle manual folosind rng)
	var shuffled_colors = []
	var available_colors = colors.duplicate()
	while available_colors.size() > 0:
		var index = rng.randi_range(0, available_colors.size() - 1)
		shuffled_colors.append(available_colors[index])
		available_colors.remove_at(index)
		
	active_puzzles["color_sequence"] = {
		"type": "color",
		"solution": shuffled_colors,
		"clue_room": "RoomB", # De data asta inversăm camerele!
		"lock_room": "RoomA"
	}

	# --- 3. Puzzle-ul Matrice 3x3 ---
	# Avem 9 pătrățele în total. Alegem 4 aleatoriu să fie aprinse.
	var grid_state = [false, false, false, false, false, false, false, false, false]
	var active_tiles = 0
	while active_tiles < 4:
		var idx = rng.randi_range(0, 8)
		if not grid_state[idx]:
			grid_state[idx] = true
			active_tiles += 1
			
	active_puzzles["grid_puzzle"] = {
		"type": "grid",
		"solution": grid_state,
		"clue_room": "RoomA",
		"lock_room": "RoomB"
	}
	
	# --- 4. Puzzle-ul de Matematică Vizuală ---
	# Jucătorul din camera clue va avea spawnat acest număr de cărți și scaune.
	var count_books = rng.randi_range(2, 6)
	var count_chairs = rng.randi_range(1, 4)
	
	active_puzzles["math_puzzle"] = {
		"type": "math",
		"clue_data": {"books": count_books, "chairs": count_chairs},
		"solution": str(count_books + count_chairs), # Soluția este suma lor
		"clue_room": "RoomB",
		"lock_room": "RoomA"
	}

# Funcție publică: Un seif sau un bilet o va chema ca să afle ce text să afișeze
func get_puzzle_data(puzzle_id: String) -> Dictionary:
	if active_puzzles.has(puzzle_id):
		return active_puzzles[puzzle_id]
	return {}

# Funcție pentru a vizualiza în consolă dacă merge corect sistemul
func test_generation():
	print("\n=== Începe Generarea Puzzle-urilor (Seed: 12345) ===")
	generate_puzzles(12345) # Seed fix ca să dea aceleași rezultate la teste
	
	for puzzle_id in active_puzzles:
		var data = active_puzzles[puzzle_id]
		print("[PuzzleGen] ID Puzzle: " + puzzle_id)
		print("  -> Soluție Generată: " + str(data["solution"]))
		print("  -> Indiciul (Afișajul) este ascuns în: " + data["clue_room"])
		print("  -> Mecanismul (Seiful) se află în: " + data["lock_room"])
	print("====================================================\n")
