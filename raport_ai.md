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

### [Nume Membru 2] (Completare necesară)
*Descrie aici cum ai folosit tool-urile de AI. Exemple:*
- *Generare sau ajustare de asset-uri 2D/3D folosind AI (Midjourney, DALL-E, etc.).*
- *Generarea puzzle-urilor sau crearea de backend logic.*
- *Brainstorming pentru designul camerei sau flow-ul jocului.*
- *Scrierea scripturilor de Backend (Node.js/Python).*

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
