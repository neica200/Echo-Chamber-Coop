extends SceneTree

var tests_passed = 0
var tests_failed = 0

func _init():
	print("\n=======================================================")
	print("🚀 STARTING AUTOMATED TESTS: Game Stats & Analytics")
	print("=======================================================\n")
	
	test_rank_s_perfect_game()
	test_rank_c_average_game()
	test_rank_d_worst_game()
	
	print("\n=======================================================")
	if tests_failed == 0:
		print("✅ TOATE TESTELE AU TRECUT! (", tests_passed, "/", tests_passed, ")")
	else:
		print("❌ TESTE PICATE: ", tests_failed, " | TRECUTE: ", tests_passed)
	print("=======================================================\n")
	
	if tests_failed > 0:
		quit(1)
	else:
		quit(0)

# --- TEST 1: Scor Perfect (Rank S) ---
func test_rank_s_perfect_game():
	print("Running: test_rank_s_perfect_game...")
	var stats = preload("res://Scripts/Core/GameStats.gd").new()
	
	# Simulam o evadare in 2 minute cu 0 greseli -> scor = 120 (S: scor < 300)
	stats.total_time = 120.0
	stats.numpad_mistakes = 0
	
	var rank = stats.get_rank()
	if rank == "S":
		print("  ✅ PASS: Rank S returnat corect (scor < 300).")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Rank asteptat S, primit: ", rank)
		tests_failed += 1
	stats.free()

# --- TEST 2: Scor Mediu (Rank C) ---
func test_rank_c_average_game():
	print("Running: test_rank_c_average_game...")
	var stats = preload("res://Scripts/Core/GameStats.gd").new()
	
	# Simulam evadare la limita (15 minute = 900s) + 2 greseli (60 puncte extra) -> scor 960 (C: intre 900 si 1200)
	stats.total_time = 900.0
	stats.numpad_mistakes = 2
	
	var rank = stats.get_rank()
	if rank == "C":
		print("  ✅ PASS: Rank C returnat corect (scor 960).")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Rank asteptat C, primit: ", rank)
		tests_failed += 1
	stats.free()

# --- TEST 3: Cel mai slab Scor (Rank D) ---
func test_rank_d_worst_game():
	print("Running: test_rank_d_worst_game...")
	var stats = preload("res://Scripts/Core/GameStats.gd").new()
	
	# Simulam evadare intarziata (20 min = 1200s) + 10 greseli -> scor foarte mare (D: scor >= 1200)
	stats.total_time = 1200.0
	stats.numpad_mistakes = 10
	
	var rank = stats.get_rank()
	if rank == "D":
		print("  ✅ PASS: Rank D returnat corect pentru penalizari mari.")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Rank asteptat D, primit: ", rank)
		tests_failed += 1
	stats.free()
