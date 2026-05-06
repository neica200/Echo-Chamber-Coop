extends GutTest

var RoomGenAgent = preload("res://Scripts/Agents/RoomGeneratorAgent.gd")

func test_grid_positions_unique():
	# TEST 1: Verificăm grila de spawn a obiectelor pe podea (ex: seif, piedestal)
	# Instanțiem agentul generator de camere și ne asigurăm că va fi eliberat din memorie automat (autofree)
	var room_gen = autofree(RoomGenAgent.new())
	var positions = room_gen.get_available_grid_positions()
	
	# Ne asigurăm că funcția chiar generează puncte (lista nu e goală)
	assert_gt(positions.size(), 0, "Ar trebui să se genereze cel puțin o poziție de grilă pe podea.")
	
	# Parcurgem toate pozițiile generate pentru a garanta că NU există duplicate
	# Dacă ar exista duplicate, două obiecte diferite ar fi spawnate în exact același loc, clip-uind prin ele.
	var seen = {}
	for pos in positions:
		assert_false(seen.has(pos), "Am găsit o poziție duplicată pe podea (obiectele s-ar suprapune): " + str(pos))
		seen[pos] = true

func test_wall_slots_unique():
	# TEST 2: Verificăm sloturile de montare pe pereți (ex: tablouri de siguranțe, tastaturi numerice)
	var room_gen = autofree(RoomGenAgent.new())
	var slots = room_gen.get_available_wall_slots()
	
	# Ne asigurăm că există locuri disponibile pe pereți
	assert_gt(slots.size(), 0, "Ar trebui să se genereze cel puțin un slot de montare pe perete.")
	
	# Parcurgem sloturile pentru a ne asigura că sunt unice spațial.
	# Fiecare slot are un dicționar cu o "pos" (poziție globală) și un "rot" (rotația necesară pentru a sta plat pe perete).
	var seen = {}
	for slot in slots:
		assert_false(seen.has(slot["pos"]), "Am găsit un slot de perete duplicat (mecanismele s-ar suprapune): " + str(slot["pos"]))
		seen[slot["pos"]] = true
