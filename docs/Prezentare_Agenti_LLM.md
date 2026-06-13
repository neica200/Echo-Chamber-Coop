# 🧠 Ghid Complet pentru Prezentare: Sistemul de Agenți AI (Ollama LLM)

Proiectul folosește un sistem asincron de 3 agenți bazați pe un Large Language Model local (**LLaMA3:8b** rulat prin **Ollama**). Fiecare agent funcționează ca un "Director" invizibil care ia decizii bazate pe **telemetria în timp real** a jucătorilor.

---

## ⚙️ MECANISMUL DE BAZĂ (Cum comunică toți cu LLM-ul)

1. **Colectarea Telemetriei (Input):** Agenții extrag date din joc (poziții 3D, timp scurs, număr de greșeli, distanța până la obiectiv).
2. **Construirea Prompt-ului:** Datele sunt formatate într-un template de text prestabilit. Partea crucială este că **LLM-ului i se interzice să dea text liber**; i se impune să răspundă EXCLUSIV cu o structură JSON (ex: `{"action": "...", "hint_text": "..."}`).
3. **Apelul HTTP Asincron:** Godot folosește nodul `HTTPRequest` pentru a trimite un POST către `http://127.0.0.1:11434/api/generate` cu un payload care conține parametrul `"format": "json"`.
4. **Parsarea Răspunsului:** Când Ollama termină, trimite înapoi string-ul generat. Godot îl parsează cu `JSON.parse_string()`, extrăgând deciziile (ex: `action`).
5. **Coordonare (Semaphore):** Deoarece rulăm local pe Ollama, un singur request greu poate încetini jocul. Dacă HintAgent vede că SaboteurAgent face o cerere la LLM (sau invers), el pune propria cerere "on hold" sau folosește instant un **Fallback hardcodat** (valori prestabilite) pentru a nu bloca serverul.

---

## 1. 🆘 Hint Agent (`HintAgent.gd`) - Directorul de Ajutor
*Mod de operare:* **On-Demand** (Când jucătorul apasă tasta 'H'). Are un cooldown de protecție (60 sec).

* **Ce informații îi dăm (Prompt):**
  * Stadiul curent și puzzle-ul activ (ex: "Panou Butoane Colorate").
  * Mecanica exactă de rezolvare a acelui puzzle.
  * Pozițiile (X, Y, Z) ale ambilor jucători și distanța lor (în metri) față de terminal/mecanism.
  * *Wrong Attempts*: Câte greșeli s-au înregistrat exact la acel puzzle.
  * *Hint History*: Ultimele 3 indicii date, ca LLM-ul să nu se repete.
* **Ce ne răspunde LLM-ul (Structura JSON):**
  ```json
  {
    "thought": "Player 2 is far away from the fuse box and keeps failing. I need to shake it.",
    "action": "SHAKE_OBJECT",
    "hint_text": "Copy the green screen pattern."
  }
  ```
* **Cum aplicăm răspunsul (Actuatorii FIZICI):**
  * `FLICKER_LIGHTS`: Apelează metoda `flicker_sequence()` de pe becurile din camera jucătorului.
  * `SHAKE_OBJECT`: Folosește un *Tween* în Godot pentru a mișca violent stânga-dreapta nodul fizic al puzzle-ului ca să atragă atenția.
  * *Blood Text*: Indiferent de acțiunea fizică, generează "hint_text"-ul (care are limită strictă de 6-8 cuvinte creepy) direct pe cel mai apropiat perete. Agentul calculează marginile camerei (Bounding Box) și spawnează un `Label3D` cu font sângeros, perfect orientat spre jucător.

---

## 2. 😈 Saboteur Agent (`SaboteurAgent.gd`) - Directorul de Groază
*Mod de operare:* **Continuu** (Rulează mereu, calculează "Tensiunea" și lovește cu cooldown de ~45s).

* **Ce informații îi dăm (Prompt):**
  * *Tension*: O valoare de la 0.0 la 1.0. Aceasta crește constant dacă jucătorii stau pe loc (Idle Time peste 20s) sau greșesc, și scade masiv când rezolvă un puzzle.
  * *Panic Level per Player*: Un nivel individual calculat separat pentru Player 1 și Player 2.
  * Pozițiile amândurora.
* **Ce ne răspunde LLM-ul (Structura JSON):**
  ```json
  {
    "thought": "Player 1 has high panic and is isolated. Let's kill his lights.",
    "action": "LIGHT_BLACKOUT",
    "glitch_text": "The system sees you.",
    "fake_clue_content": "",
    "target_player": "Player1"
  }
  ```
* **Cum aplicăm răspunsul (Actuatorii de Teroare):**
  * `DOOR_SLAM`: Instanțiază un `AudioStreamPlayer3D` dinamic fix în spatele peretelui unde se află jucătorul cu un pitch (frecvență) foarte scăzut pentru a suna ca o bufneală grea. Aplică și un *Camera Shake*.
  * `FOOTSTEPS`: Generează 4 pași secvențiali (sunet 3D) pe un unghi matematic circular în jurul jucătorului, care se apropie.
  * `PLAYER_ISOLATION`: Oprește variabilele de mișcare ale jucătorului din controller, îi aruncă un CanvasLayer negru cu mesaje de "COMMUNICATION LOST" și bagă zgomot alb (static).
  * `SPAWN_FAKE_CLUE`: Face spawn fizic unui prefab `Note.tscn` exact pe masa din fața jucătorului vizat, care conține instrucțiuni GREȘITE pentru puzzle-ul curent (furnizate tot de LLM). Notița se "evaporă" (dispare prin fade out) după 25 de secunde.

---

## 3. ⚖️ Difficulty Agent (`DifficultyAgent.gd`) - Balansatorul
*Mod de operare:* **Eveniment (Tranzițional)** (Se apelează doar când se face tranziția spre Faza 2 sau Faza 3/4).

* **Ce informații îi dăm (Prompt):**
  * Numele puzzle-ului care urmează (ex: "Numpad Final" sau "Color Sequence").
  * Timpul total scurs de la startul sesiunii (în secunde).
  * Numărul TOTAL de greșeli de la absolut toate puzzle-urile anterioare adunate (date luate de la HintAgent).
* **Ce ne răspunde LLM-ul (Structura JSON):**
  ```json
  {
    "thought": "They are moving too fast (under 120s) and have 0 mistakes. Need to make it harder.",
    "action": "SCALE_UP",
    "target_stage": 2
  }
  ```
* **Cum aplicăm răspunsul (Modificarea codului):**
  * Apelează direct Singleton-ul `PuzzleGen` (care deține algoritmul core al camerelor).
  * La **SCALE_UP**: Adaugă 2 elemente suplimentare la puzzle-ul de culori (de la 4 devin 6 culori de reținut), sau modifică string-ul parolei PIN din 4 cifre într-un format de 6 cifre (ex: `158392`).
  * La **SCALE_DOWN**: Penalizează puzzle-ul prin reducerea cerințelor (doar 3 culori, sau PIN din 3 cifre), ideal pentru jucătorii înceți sau stresați de Saboteur.
  * La **KEEP_STANDARD**: Jocul ignoră și păstrează mecanica de bază.
