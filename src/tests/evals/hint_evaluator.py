import requests
import json
import time
import sys

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "llama3:8b"

def generate_hint():
    """
    Simulează exact comportamentul din joc: trimite starea camerelor către Ollama
    și îi cere să genereze un indiciu contextual subtil.
    """
    prompt = "Jucătorii joacă un escape room asimetric co-op. Jucătorul A este într-o cameră și vede indiciul. Jucătorul B este în altă cameră și are seiful. Jucătorii sunt blocați de 60 de secunde. Soluția seifului este codul numeric 4829. Indiciul este ascuns în RoomA, iar seiful e în RoomB. Dă-le un indiciu subtil, de maxim o propoziție, ca să își dea seama că Jucătorul A trebuie să îi dicteze cifrele lui B. Nu folosi ghilimele și nu le da codul direct."
    
    payload = {
        "model": MODEL,
        "prompt": prompt,
        "stream": False
    }
    
    try:
        response = requests.post(OLLAMA_URL, json=payload, timeout=180) # Increased timeout to 3 minutes for slow hardware/cold starts
        response.raise_for_status()
        return response.json().get("response", "").strip()
    except requests.exceptions.RequestException as e:
        print(f"Error connecting to Ollama: {e}")
        sys.exit(1)

def evaluate_hint(hint_text):
    """
    LLM-as-a-Judge: Trimitem indiciul generat înapoi la Ollama, dar de data aceasta
    îi cerem să acționeze ca un evaluator QA strict. El va nota indiciul de la 1 la 5.
    """
    eval_prompt = f"""You are a strict QA evaluator for a cooperative escape room game. 
    The players need to communicate to solve a lock. The code is '4829' but the hint MUST NOT reveal this code directly.
    The hint should gently encourage Player A to tell Player B the numbers they see.
    
    Evaluate the following generated hint on a scale of 1 to 5, where:
    1 = Reveals the code directly or is completely irrelevant.
    5 = Very subtle, thematic, does not reveal the code, and encourages communication.
    
    Generated Hint: "{hint_text}"
    
    Provide your evaluation in the following strict JSON format:
    {{
        "score": <int>,
        "reasoning": "<string>"
    }}
    Do not output any markdown formatting, only raw JSON.
    """
    
    payload = {
        "model": MODEL,
        "prompt": eval_prompt,
        "stream": False,
        "format": "json"
    }
    
    try:
        response = requests.post(OLLAMA_URL, json=payload, timeout=180)
        response.raise_for_status()
        result_text = response.json().get("response", "").strip()
        return json.loads(result_text)
    except Exception as e:
        print(f"Error evaluating hint: {e}")
        return {"score": 0, "reasoning": "Evaluation failed due to parsing or connection error."}

def run_tests(iterations=3):
    # Rulăm evaluarea de mai multe ori pentru a obține o medie stabilă
    print(f"--- Starting Hint Agent QA Evaluation ({iterations} Iterations) ---")
    total_score = 0
    
    for i in range(iterations):
        print(f"\n[Iteration {i+1}] Generating Hint...")
        hint = generate_hint()
        print(f"Generated Hint: {hint}")
        
        print(f"[Iteration {i+1}] Judging Hint...")
        eval_result = evaluate_hint(hint)
        score = eval_result.get("score", 0)
        reasoning = eval_result.get("reasoning", "No reasoning provided.")
        
        print(f"Score: {score}/5")
        print(f"Reasoning: {reasoning}")
        total_score += score
        # Pauză mică pentru a permite eliberarea VRAM-ului și a nu bloca modelul local
        time.sleep(1) 
        
    avg_score = total_score / iterations
    print(f"\n--- Evaluation Complete ---")
    print(f"Average Score: {avg_score:.2f}/5.0")
    
    # Criteriul de trecere: Indiciul trebuie să aibă o notă medie de cel puțin 4 din 5.
    if avg_score >= 4.0:
        print("✅ Hint Agent PASSED the quality threshold.")
        sys.exit(0)
    else:
        print("❌ Hint Agent FAILED the quality threshold (Score < 4.0). Prompt refinement needed.")
        sys.exit(1)

if __name__ == "__main__":
    run_tests()
