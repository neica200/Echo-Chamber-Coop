# Architecture and Workflow Diagrams - Echo Chamber Co-op

## 1. Component Architecture (UML Class Diagram)

```mermaid
classDiagram
    class GameEvents {
        <<Autoload Singleton>>
        +int current_stage
        +bool lever_1_pulled
        +bool lever_2_pulled
        +advance_stage()
        +pull_exit_lever(id)
        +trigger_room_lights_toggled(room_id, state)
        +trigger_final_exit_opened()
        +signal stage_changed
        +signal puzzle_solved
        +signal room_lights_toggled
        +signal drawer_opened
        +signal escape_door_opened
        +signal final_exit_opened
    }

    class PuzzleGen {
        <<Autoload Singleton>>
        +Dictionary active_puzzles
        +generate_puzzles(seed)
        +get_puzzle_data(puzzle_id)
    }

    class GameStats {
        <<Autoload Singleton>>
        +float total_time
        +int total_mistakes
        +int puzzles_solved
        +add_mistake()
        +get_rank() String
        +get_stats() Dictionary
    }

    class AudioManager {
        <<Autoload Singleton>>
        +play_click()
        +play_error(volume)
        +play_success()
        +play_footstep(is_on_rug)
    }

    class PBRMaterialManager {
        <<Autoload Singleton>>
        +apply_material_to_mesh(node, type)
    }

    class NetworkManager {
        <<Autoload Singleton>>
        +Dictionary players
        +host()
        +join(ip)
        +spawn_player(id)
    }

    class WalkieTalkie {
        <<Autoload Singleton>>
        +bool is_transmitting
        +start_transmit()
        +stop_transmit()
        +receive_voice_chunk(bytes)
    }

    class HintAgent {
        <<Autoload Singleton>>
        +float hint_cooldown
        +Dictionary wrong_attempts
        +register_wrong_attempt(puzzle_type)
    }

    class SaboteurAgent {
        <<Autoload Singleton>>
        +float base_cooldown
        +register_wrong_attempt(puzzle_type, player)
    }

    class DifficultyAgent {
        <<Autoload Singleton>>
    }

    class RoomGeneratorAgent {
        <<Node3D in Scene>>
        +generate_rooms(seed)
    }

    class PaintingAI {
        <<MeshInstance3D in Scene>>
        +bool USE_DALLE
        +sync_prompt(prompt)
    }

    class PlayerController {
        <<CharacterBody3D>>
        +bool is_active
        +bool is_focused
        +Array inventory
        +enter_focus(target)
        +exit_focus()
        +check_interaction()
        +sync_movement(pos, rot)
    }

    class BackendServer {
        <<Express.js Port 3000>>
        +POST /api/register
        +POST /api/login
    }

    class AuthUI {
        <<Control>>
    }

    class EndGameScreen {
        <<Control>>
        +show_results()
    }

    HintAgent --> GameEvents : listens stage_changed, drawer_opened
    SaboteurAgent --> GameEvents : listens stage_changed, puzzle_solved
    SaboteurAgent --> HintAgent : checks _is_waiting_for_ollama
    DifficultyAgent --> GameEvents : listens stage_changed
    DifficultyAgent --> HintAgent : checks _is_waiting_for_ollama
    DifficultyAgent --> SaboteurAgent : checks _is_waiting_for_ollama
    DifficultyAgent --> PuzzleGen : modifies active_puzzles
    PlayerController --> AudioManager : play_footstep
    PlayerController --> WalkieTalkie : reads transmit state for UI
    RoomGeneratorAgent --> NetworkManager : reads players for spawn positions
    RoomGeneratorAgent --> PBRMaterialManager : applies materials
    RoomGeneratorAgent --> GameEvents : trigger_room_lights_toggled
    PaintingAI --> NetworkManager : RPC sync_prompt (server-only)
    GameStats --> GameEvents : listens puzzle_solved, final_exit_opened
    EndGameScreen --> GameStats : get_stats()
    AuthUI --> BackendServer : HTTP POST login/register
```

## 2. Game Flow (State Diagram)

```mermaid
stateDiagram-v2
    [*] --> MainMenu

    MainMenu --> AuthScreen : Login / Register
    AuthScreen --> Lobby : Auth Success (JWT token)
    MainMenu --> Lobby : Skip Auth (local)

    Lobby --> RoomGeneration : Host or Join (NetworkManager ENet P2P)

    state RoomGeneration {
        [*] --> ProceduralGen : RoomGeneratorAgent.generate_rooms(seed)
        ProceduralGen --> PuzzleGeneration : PuzzleGen.generate_puzzles(seed)
        PuzzleGeneration --> SpawnPlayers : P1 in RoomA, P2 in RoomB
        SpawnPlayers --> PaintingGeneration : PaintingAI requests image (host only)
    }

    RoomGeneration --> Stage1 : RoomA starts DARK, RoomB/Corridor lit

    state Stage1 {
        [*] --> FuseBox3x3 : P2 solves 3x3 grid in RoomB
        FuseBox3x3 --> LightsOn : P1 sees pattern on MatrixMonitor in RoomA
    }
    Stage1 --> Stage1_5 : advance_stage() -> stage 2

    state Stage1_5 {
        [*] --> FindKey : P1 finds Desk Key in RoomA
        FindKey --> OpenDrawer : LockedDrawer opens, reveals color Note
    }
    Stage1_5 --> Stage2 : drawer_opened signal

    state Stage2 {
        [*] --> ColorSequence : P2 inputs colors on ColorButtonsPanel
        ColorSequence --> SafeOpens : DifficultyAgent may SCALE_UP/DOWN
    }
    Stage2 --> Stage3 : advance_stage() -> stage 3

    state Stage3 {
        [*] --> TerminalHack : P1 inputs FIREWALL, DECRYPT, CORE
        TerminalHack --> PINRevealed : Terminal shows numpad PIN
    }
    Stage3 --> Stage4 : advance_stage() -> stage 4

    state Stage4 {
        [*] --> NumpadEntry : P2 enters PIN on Numpad (DifficultyAgent may adjust)
        NumpadEntry --> EscapeDoor : escape_door_opened
        EscapeDoor --> ExitLevers : Both players pull levers simultaneously (5s window)
    }
    Stage4 --> EndGame : final_exit_opened

    state EndGame {
        [*] --> ShowResults : EndGameScreen with Rank S/A/B/C/D
    }
    EndGame --> [*]
```

## 3. Interaction Workflow (Sequence Diagram)

```mermaid
sequenceDiagram
    actor Player
    participant PC as PlayerController
    participant RayCast as Camera3D/RayCast3D
    participant Puzzle as Puzzle (e.g. Terminal)
    participant GE as GameEvents

    Player->>PC: Left Click
    PC->>PC: check is_active and mouse captured

    alt Mouse not captured
        PC->>PC: Recapture mouse
    else Mouse captured
        PC->>RayCast: force_raycast_update()
        RayCast-->>PC: collider detected

        alt Collider has pick_up method
            PC->>Puzzle: pick_up(self)
            Puzzle->>PC: add_to_inventory(item_name)
        else Collider has FocusPoint child
            PC->>PC: enter_focus(target)
            Note over PC: Camera tweens to FocusPoint position
            Note over PC: Mouse mode set to VISIBLE
            Player->>PC: Click in focused mode
            PC->>Puzzle: receive_3d_click(Vector3)
            Puzzle->>Puzzle: Maps 3D hit to 2D SubViewport coords
            Puzzle->>Puzzle: Pushes fake InputEventMouseButton

            alt Puzzle solved
                Puzzle->>GE: advance_stage()
                GE->>GE: RPC broadcast_stage_changed to all peers
            end

            Player->>PC: ESC or Right Click
            PC->>PC: exit_focus() (camera tweens back)
        else Collider has interact method
            PC->>Puzzle: interact()
        end
    end
```

## 4. AI System Architecture

```mermaid
flowchart TD
    subgraph Godot_Client ["Godot Engine (Client)"]
        GE[GameEvents Singleton]
        HA[HintAgent]
        SA[SaboteurAgent]
        DA[DifficultyAgent]
        PG[PuzzleGen]
        Actuators[Physical Actuators]
        PAI[PaintingAI Node]
    end

    subgraph Ollama_Local ["Ollama - localhost 11434"]
        LLM[llama3 8b]
    end

    subgraph External ["External APIs"]
        Poll[Pollinations.ai]
        DALL[OpenAI DALL-E 3]
    end

    subgraph Backend_SaaS ["Backend - localhost 3000"]
        Express[Express.js + JWT + bcrypt]
    end

    GE -->|signals| HA
    GE -->|signals| SA
    GE -->|stage_changed| DA

    HA -->|HTTP POST| LLM
    SA -->|HTTP POST| LLM
    DA -->|HTTP POST| LLM
    LLM -->|JSON| HA
    LLM -->|JSON| SA
    LLM -->|JSON| DA

    HA -->|hint actuators| Actuators
    SA -->|scare actuators| Actuators
    DA -->|SCALE_UP / SCALE_DOWN| PG

    PAI -->|GET prompt| Poll
    PAI -->|POST prompt| DALL
    Poll -->|image bytes| PAI
    DALL -->|image URL| PAI
```

## 5. Agent-LLM Communication Sequences

### 5.1. HintAgent (On-Demand, Key H)
```mermaid
sequenceDiagram
    actor Player
    participant HA as HintAgent
    participant SA as SaboteurAgent
    participant Ollama as Ollama LLM
    participant World as Game World

    Player->>HA: Presses H key
    HA->>HA: Check cooldown (60s)

    alt Cooldown active
        HA-->>Player: Show remaining time on screen
    else Cooldown expired and Saboteur busy
        HA->>SA: Check _is_waiting_for_ollama
        HA->>HA: Wait 6s then retry or use FALLBACK_HINTS
    else Cooldown expired and LLM free
        HA->>HA: Build telemetry and prompt
        HA->>Ollama: HTTP POST llama3:8b temp 0.3
        Ollama-->>HA: JSON action + hint_text
        HA->>World: FLICKER_LIGHTS via CeilingLightLogic
        HA->>World: SHAKE_OBJECT tween on puzzle node
        HA->>World: SPAWN_BLOOD_TEXT Label3D on nearest wall
    end
```

### 5.2. SaboteurAgent (Automatic, Timer-Based)
```mermaid
sequenceDiagram
    participant Timer as CooldownTimer
    participant SA as SaboteurAgent
    participant HA as HintAgent
    participant Ollama as Ollama LLM
    participant World as Game World

    Note over SA: _process tracks idle time and tension each frame

    Timer->>SA: Cooldown expired

    alt HintAgent busy
        SA->>HA: Check _is_waiting_for_ollama
        SA->>SA: Wait 6s or use FALLBACK_ACTIONS
    else LLM free
        SA->>SA: Build telemetry and prompt
        SA->>Ollama: HTTP POST llama3:8b temp 0.9
        Ollama-->>SA: JSON action + glitch_text + target_player
        SA->>World: Execute action
        Note over World: DOOR_SLAM / FOOTSTEPS / VENTILATION_SHUTDOWN / LIGHT_BLACKOUT / PLAYER_ISOLATION / ASYMMETRIC_WHISPER / SPAWN_FAKE_CLUE
    end

    SA->>Timer: Restart cooldown
```

### 5.3. DifficultyAgent (Triggered at Stage 2 and 3)
```mermaid
sequenceDiagram
    participant GE as GameEvents
    participant DA as DifficultyAgent
    participant HA as HintAgent
    participant SA as SaboteurAgent
    participant Ollama as Ollama LLM
    participant PG as PuzzleGen

    GE->>DA: stage_changed(2) or stage_changed(3)

    loop Wait until LLM free
        DA->>HA: Check _is_waiting_for_ollama
        DA->>SA: Check _is_waiting_for_ollama
    end

    DA->>DA: Calculate elapsed time and total mistakes from HintAgent
    DA->>Ollama: HTTP POST (model: llama3:8b, temp: 0.1)
    Ollama-->>DA: JSON: action (SCALE_UP / SCALE_DOWN / KEEP_STANDARD)

    alt SCALE_UP at Stage 2
        DA->>PG: Extend color_sequence from 4 to 6 colors
    else SCALE_DOWN at Stage 2
        DA->>PG: Reduce color_sequence from 4 to 3 colors
    else SCALE_UP at Stage 3
        DA->>PG: Change numpad PIN from 4 to 6 digits
    else SCALE_DOWN at Stage 3
        DA->>PG: Change numpad PIN from 4 to 3 digits
    end
```

## 6. CI/CD Pipeline

```mermaid
flowchart TD
    subgraph Trigger ["Trigger"]
        Push[Push to main/master]
        PR[Pull Request to main/master]
    end

    subgraph CI_Pipeline ["CI Pipeline (ci.yml)"]
        direction TB
        subgraph Backend_CI ["Job: backend-ci"]
            Checkout1[Checkout]
            NodeSetup[Setup Node.js 20.x]
            NpmInstall[npm install]
            Checkout1 --> NodeSetup --> NpmInstall
        end

        subgraph Frontend_CI ["Job: frontend-ci"]
            Checkout2[Checkout]
            CheckProject[Verify src/project.godot exists]
            Python[Setup Python 3.10]
            GDToolkit[pip install gdtoolkit]
            Lint[gdlint src/Scripts/]
            SetupGodot[Setup Godot 4.2.1 headless]
            EvalHint[eval_hint_agent.gd]
            EvalSaboteur[eval_saboteur_agent.gd]
            EvalDifficulty[eval_difficulty_agent.gd]
            Checkout2 --> CheckProject --> Python --> GDToolkit --> Lint --> SetupGodot --> EvalHint --> EvalSaboteur --> EvalDifficulty
        end
    end

    subgraph CD_Pipeline ["CD Pipeline (cd.yml)"]
        direction TB
        BuildBackend[Package backend to build/backend]
        BuildGame[Copy src/ to build/game]
        Upload[Upload artifact: echo-chamber-production-build]
        BuildBackend --> BuildGame --> Upload
    end

    Push --> CI_Pipeline
    PR --> CI_Pipeline
    Push --> CD_Pipeline
    PR --> CD_Pipeline
```

## 7. Game Data Structure (ERD)

```mermaid
erDiagram
    BACKEND_USER {
        string username PK
        string password_hash
    }

    GAME_SESSION {
        int seed
        float start_time
        float end_time
        float total_time
        int total_mistakes
        int puzzles_solved
        string rank
    }

    PUZZLE {
        string puzzle_id PK
        string type
        string solution
        string clue_room
        string lock_room
    }

    PLAYER {
        string name PK
        Vector3 position
        float panic_level
        float idle_time
        bool is_active
    }

    AGENT_STATE {
        string agent_name PK
        bool is_waiting_for_ollama
        float cooldown_remaining
        float tension
    }

    TELEMETRY_SNAPSHOT {
        float stage
        float tension
        float p1_panic
        float p2_panic
        float p1_idle_seconds
        float p2_idle_seconds
    }

    GAME_SESSION ||--|{ PUZZLE : generates_via_PuzzleGen
    GAME_SESSION ||--|| PLAYER : has_Player1
    GAME_SESSION ||--|| PLAYER : has_Player2
    AGENT_STATE ||--o{ TELEMETRY_SNAPSHOT : reads_at_each_cycle
    PUZZLE ||--o{ TELEMETRY_SNAPSHOT : referenced_by
    BACKEND_USER ||--o{ GAME_SESSION : authenticates_for
```

## 8. State Machine - Player Controller

```mermaid
stateDiagram-v2
    [*] --> IDLE : Player spawns with is_active=true

    IDLE --> MOVING : WASD input detected
    MOVING --> IDLE : No movement input

    IDLE --> FOCUSED : Left Click hits object with FocusPoint
    MOVING --> FOCUSED : Left Click hits object with FocusPoint

    state FOCUSED {
        [*] --> CAMERA_TWEENING : Camera moves to FocusPoint
        CAMERA_TWEENING --> PUZZLE_INTERACTION : Tween complete
        PUZZLE_INTERACTION : Mouse visible, player clicks 2D UI in 3D
    }

    FOCUSED --> IDLE : ESC or Right Click (camera tweens back)

    IDLE --> PICKUP : Left Click hits object with pick_up method
    PICKUP --> IDLE : Item added to inventory

    IDLE --> TRANSMITTING : Hold T key (WalkieTalkie)
    TRANSMITTING --> IDLE : Release T key

    IDLE --> ISOLATED : SaboteurAgent PLAYER_ISOLATION
    MOVING --> ISOLATED : SaboteurAgent PLAYER_ISOLATION

    state ISOLATED {
        [*] --> LOCKED : is_active set to false
        LOCKED : Black overlay with glitch text, static audio
    }

    ISOLATED --> IDLE : 6 seconds expire, is_active restored

    IDLE --> INACTIVE : TAB pressed (singleplayer) or not multiplayer authority
    INACTIVE --> IDLE : TAB pressed back or authority regained

    state INACTIVE {
        [*] --> WAITING : is_active=false, camera not current
    }
```
