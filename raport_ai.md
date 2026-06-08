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

### Alex (Dezvoltare Agenti Inteligenti, Integrare LLM si Dificultate Dinamica)
In rolul meu de dezvoltator axat pe AI si designul dinamic al jocului, am utilizat asistentii AI pentru a scrie codul de baza si structura celor 3 agenti inteligenti: **HintAgent.gd**, **SaboteurAgent.gd** si **DifficultyAgent.gd**.

**Contributii cu asistenta AI:**
- **Scrierea Codului pentru Agentii LLM (`HintAgent.gd`, `SaboteurAgent.gd`, `DifficultyAgent.gd`):** Am generat in intregime structura si logica de baza a celor trei agenti prin intermediul asistentului AI. Acesta a scris logica de interogare HTTP catre instanta locala de Ollama (`llama3:8b`), gestionarea structurilor asincrone (folosind `await` si semafoare pentru prevenirea coliziunilor la interogari simultane) si configurarea prompt-urilor de sistem pentru a genera raspunsuri valide in format JSON.
- **Implementarea Dificultatii Dinamice:** Am folosit AI pentru a genera algoritmul din `DifficultyAgent.gd` care scaleaza lungimea puzzle-urilor in functie de performanta jucatorilor, adaptand automat solutiile in memoria singleton-ului `PuzzleGen`.
- **Refactorizarea Puzzles si Dynamic Fetching:** Asistentul AI a rescris metodele din `ColorButtonsPanel.gd` si `Numpad.gd` pentru a permite citirea dinamica a noilor solutii din `PuzzleGen` la fiecare interactiune, in loc sa le cache-uiasca in `_ready()`.
- **Generarea Testelor Unitare si Pipeline CI/CD:** Am delegat AI-ului scrierea testelor unitare automate (`eval_hint_agent.gd`, `eval_saboteur_agent.gd`, `eval_difficulty_agent.gd`) pentru fiecare agent si integrarea lor in fisierul `.github/workflows/ci.yml`.

**Activitate Manuala (Fara asistenta AI):**
- **Testare Manuala in Joc:** Am rulat repetat jocul local pentru a testa manual comportamentul fizic al actuatorilor agentilor (ex: pozitionarea textului de sange 3D pe perete la nivelul ochilor, modul in care se declanseaza flickering-ul pe CeilingLights sau cum se aude spatial audio-ul pentru pasi si usi trantite).
- **Calibrarea Timpilor de Cooldown si Echilibrare:** Am ajustat manual valorile de cooldown (ex: 60 secunde pentru HintAgent pentru a evita spamarea, logica de reducere a cooldown-ului Saboteur la 10 secunde in caz de greseli repetate) pentru a asigura o experienta de joc tensionata, dar corecta.
- **Configurarea Manuala a Fallback-urilor Statice:** Am creat manual toate dictionarele cu indicii statice si sperieturi de rezerva (`FALLBACK_HINTS`, `FALLBACK_ACTIONS`) folosite de joc in cazurile in care instanta locala de Ollama nu ruleaza sau raspunde prea greu.
- **Tuning-ul Parametrilor LLM:** Am testat si setat manual valorile de `temperature` din cererile HTTP (ex. 0.9 pentru Saboteur pentru variabilitate, 0.3 pentru Hint pentru precizie si 0.1 pentru DifficultyAgent pentru predictibilitate) pentru a obtine cel mai bun raport intre viteza si corectitudine.
- **Validarea si Parsarea Structurilor JSON:** Am scris manual mecanismele de siguranta pentru parsarea raspunsurilor brute de la LLM (`JSON.parse_string()`), asigurandu-ma ca jocul nu crasheaza daca LLM-ul intoarce din greseala caractere in plus sau formate incorecte.

### [Nume Membru 3] (Completare necesară)
*Descrie aici cum ai folosit tool-urile de AI. Exemple:*
- *Generarea de efecte sonore sau muzică ambientală folosind AI audio.*
- *Crearea design-ului interfețelor (UI/UX) cu asistenți de design.*
- *Testare și validare de cod.*

### [Nume Membru 4] (Dacă este cazul - Completare necesară)
*Descrie aici cum ai folosit tool-urile de AI.*

---

## 3. Concluzie
Integrarea asistenților AI în fluxul nostru de dezvoltare nu a înlocuit gândirea critică umană, ci a funcționat ca o extensie a echipei. Ne-a permis să depășim blocajele tehnice (mai ales în dezvoltarea 3D și gestionarea matricelor de coliziune) și să obținem o calitate a codului și a documentației superioară, respectând totodată standardele de versionare (Git) și testare continuă.
