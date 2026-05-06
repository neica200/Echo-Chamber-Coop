extends GutTest

# Încărcăm scriptul agentului, nu Autoload-ul global (pentru a-l testa izolat)
var HintAgentScript = preload("res://Scripts/Agents/HintAgent.gd")

func test_telemetry_increment():
	# TEST 1: Verificăm dacă funcția _process adaugă corect timpul la telemetrie
	var agent = autofree(HintAgentScript.new())
	
	# Setăm threshold-ul mai mare doar pentru siguranță și inițializăm timpul
	agent.HINT_THRESHOLD = 60.0
	agent.time_since_last_progress = 0.0
	agent.is_generating = true # Oprim HTTP request-ul forțat ca să nu încerce să sune la Ollama în timpul testului
	
	# Simulăm trecerea a 0.5 secunde (un frame de joc de jumătate de secundă)
	agent._process(0.5)
	
	# Verificăm dacă timerul a crescut la exact 0.5 secunde
	assert_eq(agent.time_since_last_progress, 0.5, "Timerul de telemetrie trebuie să crească exact cu valoarea delta a frame-ului.")

func test_telemetry_reset():
	# TEST 2: Verificăm dacă progresul jucătorului (reset_telemetry) readuce timer-ul la zero absolut
	var agent = autofree(HintAgentScript.new())
	
	# Simulăm că jucătorii sunt blocați de 45 de secunde
	agent.time_since_last_progress = 45.0
	
	# Jucătorii rezolvă un puzzle și cheamă reset
	agent.reset_telemetry()
	
	# Ne așteptăm ca timer-ul să fie din nou 0.0, oferindu-le alte 60 secunde liniște
	assert_eq(agent.time_since_last_progress, 0.0, "Apelarea funcției reset_telemetry() trebuie să șteargă complet timpul scurs (0.0).")
