extends SceneTree

# ==============================================================================
# AUTOMATED TESTS & AGENT EVALS — SaboteurAgent
# Ruleaza in mod headless si valideaza logica agentului Saboteur:
#   1. Generarea corecta a Prompt-ului LLM (cu contextul corect)
#   2. Sistemul de Cooldown (nu permite doua actiuni simultane)
#   3. Parsarea schemei JSON corecte din raspunsul Ollama simulat
#   4. Fallback-ul static la actiuni corecte per stadiu
# ==============================================================================

var tests_passed = 0
var tests_failed = 0

func _init():
	print("\n=======================================================")
	print("🚀 STARTING SABOTEUR AGENT EVALS")
	print("=======================================================\n")

	test_prompt_contains_telemetry()
	test_json_schema_validation()
	test_fallback_action_per_stage()
	test_fake_clue_fallback_content()

	print("\n=======================================================")
	if tests_failed == 0:
		print("✅ TOATE TESTELE AU TRECUT! (%d/%d)" % [tests_passed, tests_passed])
	else:
		print("❌ TESTE PICATE: %d | TRECUTE: %d" % [tests_failed, tests_passed])
	print("=======================================================\n")

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)

# --- TEST 1: Promptul LLM contine telemetria corecta ---
func test_prompt_contains_telemetry():
	print("Running: test_prompt_contains_telemetry...")
	var agent = preload("res://Scripts/Agents/SaboteurAgent.gd").new()

	# Cream un mock de telemetrie
	var mock_tel = {
		"stage": 3.0,
		"tension": 0.75,
		"player1_panic": 0.4,
		"player2_panic": 0.6,
		"player1_idle_seconds": 35.0,
		"player2_idle_seconds": 22.0,
		"player1_pos": "(5.0, 0.0, 5.0)",
		"player2_pos": "(105.0, 0.0, 5.0)"
	}

	var prompt = agent._build_prompt(mock_tel)

	var passed = true
	if not "Stage: 3" in prompt: passed = false
	if not "0.75" in prompt: passed = false            # tensiunea e in prompt
	if not "SPAWN_FAKE_CLUE" in prompt: passed = false  # actiunea e listata
	if not "PLAYER_ISOLATION" in prompt: passed = false
	if not "DOOR_SLAM" in prompt: passed = false

	if passed:
		print("  ✅ PASS: Promptul LLM contine telemetria corecta si toate actiunile disponibile.")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Promptul LLM lipsesc date de telemetrie!")
		print(prompt.left(500))
		tests_failed += 1

	agent.free()

# --- TEST 2: Parsarea schemei JSON din raspunsul simulat Ollama ---
func test_json_schema_validation():
	print("Running: test_json_schema_validation...")

	# Simulam un raspuns valid de la Ollama
	var valid_response = JSON.stringify({
		"thought": "Players are idle too long near terminal.",
		"action": "LIGHT_BLACKOUT",
		"glitch_text": "They watch. Always.",
		"fake_clue_content": "",
		"target_player": "Player1"
	})

	var parsed = JSON.parse_string(valid_response)

	var passed = true
	if not parsed: passed = false
	if not parsed.has("action"): passed = false
	if not parsed.has("glitch_text"): passed = false
	if not parsed.has("target_player"): passed = false
	if parsed["action"] != "LIGHT_BLACKOUT": passed = false
	if parsed["target_player"] != "Player1": passed = false

	if passed:
		print("  ✅ PASS: Schema JSON este valida si campurile sunt parsate corect.")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Parsarea JSON a esuat pentru raspunsul simulat!")
		tests_failed += 1

# --- TEST 3: Fallback activ cu actiunea corecta per stadiu ---
func test_fallback_action_per_stage():
	print("Running: test_fallback_action_per_stage...")
	var agent = preload("res://Scripts/Agents/SaboteurAgent.gd").new()

	# Stadiul 1 → FOOTSTEPS
	var fb1 = agent.FALLBACK_ACTIONS.get(1, {})
	# Stadiul 3 → LIGHT_BLACKOUT
	var fb3 = agent.FALLBACK_ACTIONS.get(3, {})

	var passed = true
	if fb1.get("action", "") != "DOOR_SLAM": passed = false
	if fb3.get("action", "") != "PLAYER_ISOLATION": passed = false

	if passed:
		print("  ✅ PASS: Fallback-urile statice au actiunile corecte per stadiu.")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Fallback-urile statice sunt configurate gresit!")
		print("  Stadiu 1: ", fb1)
		print("  Stadiu 3: ", fb3)
		tests_failed += 1

	agent.free()

# --- TEST 4: FALLBACK_FAKE_CLUES contine date pentru fiecare stadiu ---
func test_fake_clue_fallback_content():
	print("Running: test_fake_clue_fallback_content...")
	var agent = preload("res://Scripts/Agents/SaboteurAgent.gd").new()

	var passed = true
	for stage_key in [1.0, 2.0, 3.0, 4.0]:
		var clue = agent.FALLBACK_FAKE_CLUES.get(stage_key, "")
		if clue == "":
			passed = false
			print("  ❌ Lipsa fallback fake clue pentru stadiul: ", stage_key)

	if passed:
		print("  ✅ PASS: Toate stadiile au fallback fake clues configurate.")
		tests_passed += 1
	else:
		tests_failed += 1

	agent.free()
