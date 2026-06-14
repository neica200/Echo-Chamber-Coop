# Raport privind Utilizarea Instrumentelor de Inteligență Artificială în Dezvoltarea Software

**Proiect:** Echo Chamber Co-op

---

## 1. Introducere Generală (Echipa)
În cadrul dezvoltării proiectului "Echo Chamber Co-op", instrumentele de Inteligență Artificială (AI) au jucat un rol central în eficientizarea procesului de lucru, reducerea timpului alocat depanării și îmbunătățirea arhitecturii generale. Am adoptat un model de dezvoltare hibrid ("AI-assisted development"), în care tool-urile AI nu au fost folosite doar pentru generare de cod boilerplate, ci și ca parteneri de *pair-programming* pentru rezolvarea problemelor de logică complexă, design de sistem și automatizare (DevOps).

Printre instrumentele utilizate se numără asistenți AI avansați, cu capabilități "agentice" (capabili să citească fișiere din proiect, să analizeze mediul de lucru și să execute scripturi), precum și modele Large Language Models (LLM) tradiționale pentru brainstorming de idei, generare de asset-uri (ex. date pentru puzzle-uri) și configurarea de pipeline-uri CI/CD. Utilizarea acestora ne-a permis să ne concentrăm pe viziunea creativă și pe designul nivelurilor, delegând sarcinile repetitive sau erorile matematice către inteligența artificială.

---

## 2. Contribuții Individuale în utilizarea AI

### Mario (Dezvoltare Core, Mecanici 3D și CI/CD)
În rolul meu de dezvoltator pentru engine-ul de joc (Godot 4), am folosit instrumente AI avansate ca un asistent de tip *pair-programmer* autonom. Utilizarea AI s-a concentrat pe următoarele arii critice:
- **Arhitectură și Progresie (State Machine):** Am folosit AI-ul pentru a refactoriza un sistem haotic de interacțiuni într-un flux liniar bazat pe semnale (`GameEvents.gd`), conectând puzzle-urile între ele (ex. *deschiderea sertarului declanșează aprinderea panoului de culori*).
- **Depanare Matematică Complexă (Raycasting & Viewports):** Pentru "Focus Mode-ul" terminalului PC, am întâmpinat probleme legate de coordonatele locale și transpunerea UV a unei plase 3D (`PlaneMesh`) rotite la 90 de grade. AI-ul m-a ajutat să identific inversarea axei Z locale și să formulez ecuația corectă (`v = (local_hit.z + height/2)/height`), o problemă care manual mi-ar fi consumat ore întregi de testare.
- **Automatizare și DevOps:** Am delegat AI-ului redactarea și repararea pipeline-ului CI/CD prin GitHub Actions (`ci.yml`), inclusiv înlocuirea unor acțiuni GitHub third-party învechite cu scripturi oficiale prin Python (`gdtoolkit`), asigurând astfel un pipeline robust.
- **Generare de Documentație:** Diagramele arhitecturale și de workflow complexe (secvențele Raycast) au fost generate și formatate folosind standardul `Mermaid` prin prompting direct din descrierea codului.

### Alexia (Sisteme AI, Integrare LLM si Dificultate Dinamica)
Pentru partea mea din proiect, m-am ocupat de "creierul" jocului, mai exact de implementarea celor 3 agenti inteligenti: **HintAgent**, **SaboteurAgent** si **DifficultyAgent**. Pentru ca a fost destul de mult cod de scris si logica de integrat cu modelul local de limbaj, m-am bazat destul de mult pe asistentii AI ca sa grabesc procesul, desi a trebuit sa fac foarte mult debugging manual.

**Cum m-a ajutat AI-ul:**
- **Sistemul de Indicii (HintAgent):** Am folosit AI-ul pentru a genera logica prin care jocul "intelege" contextul. I-am cerut sa scrie un algoritm care sa urmareasca pozitia jucatorilor, stadiul curent si de cate ori au gresit la un anumit puzzle, pentru a compune un prompt clar catre LLM. Astfel, LLM-ul genereaza hint-uri utile si integrate in poveste, fara sa dea solutia mura-n gura.
- **Sistemul de Groaza (SaboteurAgent):** Pentru a crea atmosfera tensionata, am delegat AI-ului structurarea evenimentelor de groaza. Asistentul m-a ajutat sa generez scriptul care analizeaza cat timp au stat jucatorii pe loc si cat de mare e "tensiunea", cerand apoi LLM-ului sa decida dinamic ce efect sa declanseze (blackout, usi trantite, izolare sau mesaje criptice).
- **Dificultatea dinamica (DifficultyAgent):** I-am cerut AI-ului sa gandeasca un algoritm pentru `DifficultyAgent.gd` care sa faca puzzle-urile mai grele sau mai usoare (de ex. lungimea codului PIN) in functie de cat de bine se descurca jucatorii, actualizand valorile direct in `PuzzleGen`.
- **Infrastructura HTTP si Async:** Pentru toti cei 3 agenti, AI-ul m-a ajutat enorm la partea de request-uri HTTP catre serverul local de Ollama (`llama3:8b`) si la gestionarea asincrona (cu `await` si semafoare), ca sa nu se blocheze jocul cand se trimit mai multe interogari simultan. Tot cu el am rafinat prompt-urile pentru a forta Ollama sa raspunda strict in format JSON valid.
- **Refactorizare cod puzzle-uri:** M-am blocat la un moment dat pentru ca solutiile puzzle-urilor ramaneau blocate la valorile initiale din `_ready()`. AI-ul m-a ajutat sa rescriu metodele din `ColorButtonsPanel.gd` si `Numpad.gd` ca sa le citeasca dinamic la fiecare interactiune.
- **Teste automate si CI/CD:** Pentru ca trebuia sa testam agentii des, am pus AI-ul sa scrie testele unitare pentru toti trei (`eval_hint_agent.gd`, etc.) si sa le lege automat in pipeline-ul de GitHub Actions (`ci.yml`).

**Ce am facut manual (fara AI):**
- **Testarea efectiva in engine:** Am petrecut foarte mult timp testand "fizic" jocul. A trebuit sa reglez manual coordonatele ca textul cu sange de pe perete sa apara exact la nivelul ochilor, sa setez efectul de flicker la lumini si sa ajustez sunetele spatiale (usi trantite, pasi) ca sa sune cu adevarat infricosator.
- **Balansarea jocului si cooldown-uri:** Am modificat de zeci de ori timpii de cooldown. De exemplu, am pus un timer de 60 de secunde pe HintAgent ca sa nu dea indicii non-stop si am facut Saboteur-ul mai agresiv (cooldown redus la 10 secunde) daca jucatorii gresesc de mai multe ori la rand.
- **Sistemul de siguranta (Fallback-uri):** Pentru ca Ollama mai da si rateuri sau raspunde greu, am scris manual pentru toti agentii niste dictionare cu indicii si sperieturi statice (`FALLBACK_HINTS`, `FALLBACK_ACTIONS`) ca jocul sa mearga fluent oricum.
- **Tuning fin pe modelele LLM:** M-am jucat destul de mult cu temperatura din setarile HTTP. Am ajuns la concluzia ca merge cel mai bine cu 0.9 la Saboteur (sa fie mai imprevizibil), 0.3 la Hint (sa fie precis) si 0.1 la DifficultyAgent.
- **Curatarea JSON-urilor:** Am implementat manual filtre de protectie pe `JSON.parse_string()`. LLM-ul uneori mai adauga caractere aiurea sau ghilimele gresite si imi dadea crash tot jocul, asa ca a trebuit sa ma asigur ca parsez mereu o structura curata.

### Andreea (Level Design, Generare Procedurală și Depanare UI/UX)
În cadrul dezvoltării, am utilizat asistentul AI agentic ca partener direct de codare (pair-programming) pentru a accelera implementarea mecanicilor complexe din Godot și pentru a finisa aspectul nivelurilor:
- **Proiectare Generare Procedurală (Core):** Am construit arhitectura de bază pentru generarea camerelor (`RoomGeneratorAgent.gd`), implementând definirea grid-ului și plasarea manuală a modelelor 3D fundamentale (precum biroul, scaunul și setup-ul inițial al calculatorului), creând un mediu solid pe care au fost construite ulterior restul mecanicilor.
- **Level Design și Integrare Puzzle-uri:** Am folosit AI-ul pentru a modifica arhitectura procedurală a nivelurilor, ajustând proporțiile camerelor (ex. îngustarea coridorului de trecere) și plasând exact elementele pentru puzzle-ul final (poziționarea manetelor sincronizate pentru `ExitDoor`).
- **Generare Procedurală (Wave Function Collapse):** Am dezvoltat, cu ajutorul asistentului, un algoritm *Wave Function Collapse* scris complet în GDScript de la zero (`WFCTextureGenerator.gd`). Acesta calculează entropia minimă și propagă stări pentru a genera o textură unică (tip "Dungeon Stone") la fiecare rulare a jocului, care este apoi aplicată dinamic pe tavan.
- **Depanare UI/UX (Overlap în Split-Screen):** AI-ul m-a ajutat să depistez un bug vizual subtil în care inventarele jucătorilor se suprapuneau din cauza creării multiple de noduri `CanvasLayer` în modul de testare locală. Am rezolvat problema adăugând un sistem de toggle vizual bazat pe parametrul `is_active`.
- **Refactoring:** Eliminarea prop-urilor statice (notițele scrise de mână) pentru a forța jucătorii să interacționeze direct cu mecanicile complexe (Terminalul PC și Seiful).

### Melysa (SaaS, Backend & UI/UX)
În rolul meu de dezvoltator SaaS, m-am ocupat de infrastructura de autentificare, sistemul de networking multiplayer și integrarea serviciilor externe în joc. Am folosit AI ca asistent tehnic de-a lungul întregului proces de dezvoltare.

**Cum m-a ajutat AI-ul:**
- **Arhitectura serverului Node.js:** Am folosit AI-ul pentru a structura rapid rutele REST (`/register`, `/login`) cu Express.js, inclusiv hasharea parolelor cu bcrypt și generarea token-urilor JWT. AI-ul m-a ghidat pas cu pas prin configurarea middleware-ului și testarea cu PowerShell când Postman nu funcționa pe localhost.
- **Sistemul de Lobby Multiplayer:** AI-ul m-a ajutat să înțeleg și să implementez `ENetMultiplayerPeer` în Godot 4, inclusiv logica de host/join și schimbarea automată a scenei când ambii jucători se conectează prin `NetworkManager.gd`.
- **State Replication:** Am folosit AI-ul pentru a integra `MultiplayerSynchronizer` pe scena playerului și pentru a adăuga verificarea `is_multiplayer_authority()` în `PlayerController.gd`, astfel încât fiecare jucător să controleze doar propriul personaj.
- **Walkie-Talkie Audio:** AI-ul m-a ajutat să construiesc un sistem de voice chat push-to-talk cu `AudioStreamMicrophone`, transmisie RPC în chunks de 100ms și un bus audio „Radio" cu efecte în lanț (EQ6 + Distortion + Reverb + Compressor) pentru a simula vocea printr-o stație radio.
- **Integrarea Login în Godot:** AI-ul m-a ghidat în crearea scenei `MainMenu.tscn` cu noduri UI (LineEdit, Button) și scriptul `AuthUI.gd` care trimite request-uri HTTP către serverul Node.js și procesează token-ul JWT primit.
- **EndGame Analytics Screen:** AI-ul m-a ajutat să construiesc ecranul de final cu sistem de rank S-D bazat pe timp și greșeli, calcul scor 0-100, animații Tween (fade-in panel + bounce pe litera de rank) și mesaje de feedback unice per rank. Ecranul se conectează automat la `GameEvents.escape_door_opened` și afișează statisticile finale ambilor jucători.
- **GameStats.gd:** Am integrat un sistem de tracking al statisticilor în timp real — timer pornit la începutul sesiunii, contorizarea greșelilor la numpad și a puzzle-urilor rezolvate, cu calculul automat al rank-ului la final prin funcția `get_stats()`.

---

## 3. Concluzie
Integrarea asistenților AI în fluxul nostru de dezvoltare nu a înlocuit gândirea critică umană, ci a funcționat ca o extensie a echipei. Ne-a permis să depășim blocajele tehnice (mai ales în dezvoltarea 3D și gestionarea matricelor de coliziune) și să obținem o calitate a codului și a documentației superioară, respectând totodată standardele de versionare (Git) și testare continuă.
