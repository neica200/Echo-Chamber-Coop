# 📄 CONTEXT_MANIFEST: Echo Chamber

## 1. Project Essence
**Echo Chamber** is a multi-agent procedural escape room game where two players are trapped in isolated rooms and must cooperate asymmetrically to solve interconnected puzzles, akin to the "We Were Here" series. Players rely entirely on external voice chat (like Discord) for communication, as they cannot see each other's environments but hold the keys to each other's progress. A robust system of four distinct AI agents dynamically generates room layouts, puzzle dependencies, hints, and saboteur events to ensure every playthrough is a unique and unpredictable experience.

## 2. Architecture Map

### Core Systems & Script Mapping
*   **Backend Authentication API (New):** A separate Node.js/Express application handling user registration and login via JWT.
    *   *Path:* `backend/server.js`, `backend/auth/auth.js`
*   **Frontend Authentication UI (New):** Godot Control node interfacing with the backend REST API.
    *   *Script:* `src/Scripts/AuthUI.gd`
*   **Automated Testing Suite (New):** Comprehensive QA architecture including GUT unit/stress tests for game logic and Python scripts for LLM-as-a-Judge evaluations and Backend integration.
    *   *Path:* `src/tests/`
*   **Room Generation System:** Procedurally builds the physical space of Room A and Room B, placing modular assets.
    *   *Script:* `src/Scripts/Agents/RoomGeneratorAgent.gd`
*   **Puzzle Generation System:** The logic engine that creates the dependency graph for puzzles and ensures solvable combinations across rooms.
    *   *Script:* `src/Scripts/Agents/PuzzleGeneratorAgent.gd`
*   **Player Controller & Interaction:** Standard FPS controller managing movement and raycast-based interactions with the environment.
    *   *Script:* `src/Scripts/Player/PlayerController.gd`
*   **Puzzle Elements & Interactions:** Manages local logic for specific interactable objects.
    *   *Scripts:* `src/Scripts/Puzzles/*.gd` (e.g., `Numpad.gd`, `Note.gd`, `FuseBox3x3.gd`, `ColorButtonsPanel.gd`)

### Networking Approach
The game utilizes a **Peer-to-Peer** architecture via Godot’s `MultiplayerPeer`. Crucially, player movement (X, Y, Z coordinates) is **NOT** synchronized. To reduce network overhead by 80%, the game only synchronizes **Puzzle States** (e.g., `is_safe_open = true`, or a button being pressed).

## 3. Agent Logic Breakdown
1.  **Room Generator Agent:** Architect of the physical space. It procedurally generates a grid-based floor plan and available wall slots to dynamically place furniture and puzzles without overlap. It uses a relative "Socket System" to perfectly parent desk props (monitors, notes, keypads) to specific furniture sets (like the Table in Room A or Pedestal in Room B), ensuring precise and clipping-free layouts driven by a deterministic seed.
2.  **Puzzle Generator Agent (Asymmetric Logic):** The logic engine. It generates an `active_puzzles` dictionary using a random seed. Each puzzle definition assigns a `clue_room` (where the solution is displayed) and a `lock_room` (where the solution is input).
3.  **Hint Agent:** The observer. *[Implemented]* Connects to a local Ollama instance (`llama3:8b`) via HTTP. Automatically tracks player idle time (`time_since_last_progress`) and triggers dynamically after 60 seconds of inactivity, generating contextual hints based on the `PuzzleGeneratorAgent` state. Includes an asynchronous UI fade system.
4.  **Saboteur Agent:** The tension builder. *[Pending Implementation]* Dynamically triggers glitches like flickering lights or fake clues based on game difficulty to stall progress and build atmosphere.

## 4. Current State of Development

*   **🟢 Done:**
    *   FPS Player Controller (`PlayerController.gd`) with WASD movement, jumping, and a RayCast3D interaction system.
    *   Foundational `PuzzleGeneratorAgent` that successfully creates the asymmetric data graph (e.g., Numeric codes, Color Sequences, Math Puzzles).
    *   Individual puzzle interaction scripts (Numpad input collection, Note text updating from the generator).
    *   `RoomGeneratorAgent`: Procedurally spawns two distinct rooms using a grid system, dynamic wall slots, and a socket-based relative placement system for furniture.
    *   **Hint Agent:** Fully automated telemetry triggering, dynamic context prompts, and integrated UI.
    *   **Automated Testing & CI/CD:** GUT framework implemented for logic stress tests, Python scripts for LLM evaluation and backend API integration, and Github Actions pipeline configured.
*   **🟡 In Progress / Skeleton:**
    *   Puzzle Dependency System: Puzzles read from the generator locally, but network synchronization across clients is missing.
    *   Network & Accounts: Created a basic Express.js backend with JWT authentication (`backend/`) and connected it to Godot via `AuthUI.gd`.
*   **🔴 Missing / Placeholder:**
    *   Network Manager / Lobby System (Host/Join multiplayer sync).
    *   Saboteur Agent.
    *   AI Image Generation Pipeline Integration.
    *   Statistics & Scoring UI.
    *   Audio/Visual Glitch Effects.

## 5. The Next Steps (Priority Roadmap)
Based on the execution roadmap and current codebase gaps, the next immediate technical tasks are:

1.  **Network Manager (Host/Join Lobby):** Expand the existing Auth UI into a proper lobby system. Implement Godot's `MultiplayerPeer` to establish a reliable connection between two clients.
2.  **The Synchronization Test (RPC Validation):** Implement a simple network test where Player A clicks a button and Player B sees a light turn on, confirming the peer-to-peer event flow.
3.  **Puzzle State Network Sync:** Refactor existing puzzle scripts (like `Numpad.gd`) to use RPC calls to synchronize their state variables and success/failure conditions across both clients.
4.  **Saboteur Agent Implementation:** Create the base node structure for the Saboteur agent to dynamically mess with the players (flickering lights, locking doors).
5.  **Backend Persistence:** Migrate the in-memory array in the Node.js backend to a real database (e.g., SQLite/PostgreSQL) for user persistence.

## 6. Dependency Graph (Cross-Linking Logic)
Camera A and Camera B share data seamlessly through a centralized logic graph managed by the `PuzzleGeneratorAgent`. 

When the game initializes, the agent generates puzzle objects (e.g., `numpad_puzzle`) containing a `clue_room` and a `lock_room`. For instance, it generates a random 4-digit code. The `Note.gd` script in Camera A queries this agent, receives the code, and renders it on a physical note. Simultaneously, the `Numpad.gd` script in Camera B queries the exact same agent to set its `target_code`. 

Because only the abstract solution is shared via this graph—and not physical positions or player locations—a clue discovered in one isolated environment perfectly maps to a locking mechanism in the other, enforcing verbal collaboration.
