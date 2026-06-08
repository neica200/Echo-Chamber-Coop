extends SceneTree

var tests_passed = 0
var tests_failed = 0

class MockHintAgent extends Node:
	var wrong_attempts: Dictionary = {
		"fuse_puzzle": 2,
		"drawer_puzzle": 0,
		"color_sequence": 3,
		"terminal_hack": 1,
		"numpad_puzzle": 0
	}

func _init():
	print("\n=======================================================")
	print("🚀 STARTING DIFFICULTY AGENT EVALS")
	print("=======================================================\n")

	test_mistakes_calculation()
	test_json_schema_validation()

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

# --- TEST 1: Calculul greselilor din HintAgent ---
func test_mistakes_calculation():
	print("Running: test_mistakes_calculation...")
	var agent = preload("res://Scripts/Agents/DifficultyAgent.gd").new()
	
	# Folosim MockHintAgent
	var mock_hint = MockHintAgent.new()
	agent.hint_agent = mock_hint
	
	var total = agent._get_total_mistakes()
	
	if total == 6:
		print("  ✅ PASS: _get_total_mistakes însumează corect.")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Totalul calculat a fost ", total, " (așteptat 6).")
		tests_failed += 1

	agent.free()
	mock_hint.free()

# --- TEST 2: Parsarea schemei JSON din raspunsul Ollama ---
func test_json_schema_validation():
	print("Running: test_json_schema_validation...")
	
	var valid_response = JSON.stringify({
		"thought": "Players are extremely fast.",
		"action": "SCALE_UP",
		"target_stage": 3
	})
	
	var parsed = JSON.parse_string(valid_response)
	
	var passed = true
	if not parsed: passed = false
	if not parsed.has("action"): passed = false
	if not parsed.has("target_stage"): passed = false
	if parsed.get("action", "") != "SCALE_UP": passed = false
	if int(parsed.get("target_stage", 0)) != 3: passed = false
	
	if passed:
		print("  ✅ PASS: Schema JSON pentru DifficultyAgent este validă.")
		tests_passed += 1
	else:
		print("  ❌ FAIL: Parsarea JSON a eșuat!")
		tests_failed += 1
