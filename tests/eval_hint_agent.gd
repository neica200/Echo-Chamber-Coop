extends SceneTree

# ==============================================================================
# AUTOMATED TESTS & AGENT EVALS
# Acest script ruleaza in mod headless si valideaza logica agentului AI (HintAgent)
# ==============================================================================

var tests_passed = 0
var tests_failed = 0

func _init():
	print("\n=======================================================")
	print("🚀 STARTING AUTOMATED TESTS & AGENT EVALS")
	print("=======================================================\n")
	
	test_hint_agent_prompt_generation()
	test_hint_agent_fallback_logic()
	test_telemetry_state_tracking()
	
	print("\n=======================================================")
	if tests_failed == 0:
		print("✅ TOATE TESTELE AU TRECUT! (", tests_passed, "/", tests_passed, ")")
	else:
		print("❌ TESTE PICATE: ", tests_failed, " | TRECUTE: ", tests_passed)
	print("=======================================================\n")
	
	# Iesire cu cod corect pentru CI/CD
	if tests_failed > 0:
		quit(1)
	else:
		quit(0)

# --- TEST 1: Generarea corectă a Prompt-urilor (LLM Eval) ---
func test_hint_agent_prompt_generation():
	print("Running: test_hint_agent_prompt_generation...")
	var agent = preload("res://Scripts/Agents/HintAgent.gd").new()
	
	# Mock data pentru stadiul 2 (Panou Culori) cu 2 greșeli
	var mock_tel = {
		"current_stage": 2.0,
		"target_puzzle": "Panou Butoane Colorate",
		"room_id": "RoomB",
		"player1_pos": "(1.0, 0.0, 1.0)",
		"player2_pos": "(105.0, 0.0, 2.0)",
		"player1_distance_to_target": 100.0,
		"player2_distance_to_target": 1.5,
		"wrong_attempts": {"color_sequence": 2},
		"solution_info": "Secventa corecta de culori este scrisa pe biletul gasit in sertar.",
		"hint_history": ["Read the note."]
	}
	
	var prompt = agent._build_prompt(mock_tel)
	
	var passed = true
	if not "Stage: 2" in prompt: passed = false
	if not "color_sequence: 2 mistakes" in prompt: passed = false
	if not "Read the note." in prompt: passed = false
	
	if passed:
		print("  ✅ PASS: Prompt-ul LLM contine contextul corect, greselile anterioare si istoricul de hint-uri.")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Prompt-ul LLM nu a asamblat corect telemetria!")
		print(prompt)
		tests_failed += 1
		
	agent.free()

# --- TEST 2: Sistemul de Fallback (Fara conexiune la Ollama) ---
func test_hint_agent_fallback_logic():
	print("Running: test_hint_agent_fallback_logic...")
	var agent = preload("res://Scripts/Agents/HintAgent.gd").new()
	
	# Simulam Stage 3.0 (Terminal) in GameEvents global
	var GameEventsClass = preload("res://Scripts/Core/GameEvents.gd").new()
	GameEventsClass.current_stage = 3
	
	# Ne uitam la dictionarul de fallback
	var fallback_data = agent.FALLBACK_HINTS[3.0]
	
	if fallback_data["action"] == "FLICKER_LIGHTS" and "Bypass" in fallback_data["hint_text"]:
		print("  ✅ PASS: Agentul are fallback preconfigurat corect pentru Faza 3.")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Dictionarul de fallback este incomplet sau gresit.")
		tests_failed += 1
		
	GameEventsClass.free()
	agent.free()

# --- TEST 3: Trackuirea Greselilor ---
func test_telemetry_state_tracking():
	print("Running: test_telemetry_state_tracking...")
	var agent = preload("res://Scripts/Agents/HintAgent.gd").new()
	
	# Agentul inregistreaza o greseala la terminal
	agent.register_wrong_attempt("terminal_hack")
	agent.register_wrong_attempt("terminal_hack")
	
	if agent.wrong_attempts["terminal_hack"] == 2:
		print("  ✅ PASS: Telemetria agentului inregistreaza greselile corect.")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Numaratoarea greselilor nu s-a actualizat.")
		tests_failed += 1
		
	agent.free()
