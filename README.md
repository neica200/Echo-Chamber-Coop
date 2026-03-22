# 🎭 Echo Chamber - Co-op AI Escape Room

## 🚀 Proiect Overview
**Echo Chamber** este o experiență horror cooperativă de tip escape room, dezvoltată ca un serviciu (SaaS). Jocul utilizează un sistem complex de **4 Agenți AI** pentru a genera o experiență unică la fiecare sesiune, forțând jucătorii să colaboreze prin comunicare asimetrică și coordonare în timp real.

### 💡 Elementul de Inovare (AI Agents)
1. **Room Generator Agent:** Creează layout-ul camerei procedural.
2. **Asymmetric Puzzle Agent:** Împarte indiciile între jucători (Player A vede soluția, Player B are mecanismul).
3. **Saboteur Agent:** Monitorizează echipa și intervine pentru a crește tensiunea (izolare, sabotaj lumini).
4. **Hint Agent:** Oferă asistență contextuală bazată pe telemetria jucătorilor.

---

## 👥 Echipa
-Neica Mario - 234
-Șeitan Alexia - 234 
-Sali Melysa - 24
-Popa Andreea -24


---

## 📋 Product Backlog (Fixed: March 22, 2026)

| US ID | Epic | User Story (EN) | Role | SP | Priority | MoSCoW | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **US1** | Exploration | Explore the room to discover hidden clues. | Player | 3 | High | Must | 🔴 To Do |
| **US2** | Networking | Join a lobby via unique code for co-op play. | Player | 5 | High | Must | 🔴 To Do |
| **US3** | Mechanics | Asymmetric clues: one sees it, one uses it. | Player | 8 | High | Must | 🔴 To Do |
| **US4** | Mechanics | Coordinated actions (sync levers/buttons). | Player | 5 | Medium | Should | 🔴 To Do |
| **US5** | Mechanics | Item transfer system between players. | Player | 3 | Medium | Should | 🔴 To Do |
| **US6** | UI/UX | 3D Ping system to highlight objects for partner. | Player | 2 | Low | Could | 🔴 To Do |
| **US7** | AI Agents | Procedural room layouts based on network seed. | Player | 8 | High | Must | 🔴 To Do |
| **US8** | AI Agents | Saboteur event: temporary player isolation. | Player | 5 | Medium | Should | 🔴 To Do |
| **US9** | AI Agents | Hint Agent: Adaptive help when stuck. | Player | 5 | Low | Could | 🔴 To Do |
| **US10** | SaaS/Cloud | Cloud Auth: Save progress and escape times. | User | 5 | High | Must | 🔴 To Do |
| **US11** | SaaS/Cloud | Team Dashboard: Performance & analytics. | User | 3 | Medium | Could | 🔴 To Do |
| **US12** | Audio | Proximity-based 3D Voice Chat. | Player | 5 | Medium | Should | 🔴 To Do |
| **US13** | Mechanics | Shared Failure State: Global Game Over. | Team | 3 | High | Must | 🔴 To Do |

---

## 📂 Project Structure

```text
Echo-Chamber-SaaS/
├── src/                # Game Source Code (Unity/Unreal)
│   ├── Scripts/
│   │   ├── AI/         # RoomGen, Saboteur, Hint Logic
│   │   ├── Networking/ # Sincronizare & Lobby System
│   │   ├── Player/     # Interaction & Inventory
│   │   └── UI/         # Dashboards & HUD
│   └── Assets/         # 3D Models, Prefabs, Audio
├── backend/            # SaaS Infrastructure (Node.js)
│   ├── auth/           # Firebase/Auth0 Integration
│   └── api/            # Telemetry & Leaderboard API
├── docs/               # Technical Documentation & Diagrams
└── .github/            # CI/CD Workflows
