# Architecture and Workflow Diagrams - Echo Chamber Co-op

## 1. Component Architecture (UML Class Diagram)

```mermaid
classDiagram
    class GameEvents {
        <<Singleton>>
        +int current_stage
        +advance_stage()
        +signal stage_changed(new_stage)
    }

    class PuzzleGen {
        <<Singleton>>
        +Dictionary active_puzzles
    }

    class NetworkManager {
        <<Singleton>>
        +host()
        +join(ip)
    }
    
    class WalkieTalkie {
        <<Singleton>>
        +bool is_transmitting
        +receive_voice_chunk(bytes)
    }

    class PaintingAI {
        +bool USE_DALLE
        +String chosen_prompt
        -_request_pollinations()
        -_request_dalle()
        +sync_prompt(prompt)
    }

    class HintAgent {
        <<Singleton>>
        -_call_ollama(prompt)
        -_execute_hint(action, text)
    }

    class SaboteurAgent {
        <<Singleton>>
        -_call_ollama(prompt)
        -_execute_action(action)
    }

    class DifficultyAgent {
        <<Singleton>>
        -_evaluate_difficulty(stage)
        -_apply_difficulty(stage, decision)
    }

    class BackendServer {
        <<Node.js / Express>>
        +POST /auth/register
        +POST /auth/login
    }

    class PlayerController {
        +bool is_active
        +bool is_focused
        +enter_focus(target)
        +sync_movement()
    }

    PlayerController --> NetworkManager : P2P Connection
    PlayerController --> WalkieTalkie : Captures/Sends Voice (Push-to-Talk)
    PaintingAI --> NetworkManager : RPC Sync Prompt
    HintAgent --> GameEvents : Listens to signals
    SaboteurAgent --> HintAgent : Checks Ollama Semaphore
    DifficultyAgent --> GameEvents : Listens to stage_changed
    DifficultyAgent --> PuzzleGen : Modifies parameters
```

## 2. Game Flow (Workflow / State Diagram)

```mermaid
stateDiagram-v2
    [*] --> Lobby : Launch Game
    Lobby --> Session_Generation : Authentication & NetworkManager (Host/Join)
    
    state Session_Generation {
        PaintingAI_Request : Generates AI Painting (Pollinations/DALL-E)
        Procedural_Gen : Generates Room Layouts
    }
    
    Session_Generation --> Stage1_Fuses : Spawn Players (P1 Room A, P2 Room B)
    
    Stage1_Fuses --> Stage15_Drawer : P2 solves the electrical panel
    Stage15_Drawer --> Stage2_Safe : P1 unlocks the drawer with key
    Stage2_Safe --> Stage3_Hacking : P1 solves color sequence
    Stage3_Hacking --> Stage4_Escape : P1 bypasses firewall
    Stage4_Escape --> EndGame : P2 inputs code on Numpad
    
    state EndGame {
        Display_Stats : Rank S-D, Mistakes, Time
        Backend_Save : Transmit score data to SaaS
    }
    EndGame --> [*]
```

## 3. Interaction Workflow (Sequence Diagram)

```mermaid
sequenceDiagram
    actor Player
    participant PlayerController
    participant MultiplayerAPI
    participant PuzzleObject as PuzzleObject (e.g. Terminal)
    participant GameEvents

    Player->>PlayerController: Left Click on Monitor
    PlayerController->>MultiplayerAPI: is_multiplayer_authority()?
    
    alt Client Without Authority
        MultiplayerAPI-->>PlayerController: False (Ignores input)
    else Client With Authority
        MultiplayerAPI-->>PlayerController: True
        PlayerController->>PuzzleObject: RayCast Detection
        PuzzleObject-->>PlayerController: returns true (has FocusPoint)
        PlayerController->>PlayerController: enter_focus() (moves camera & frees mouse)
        
        Player->>PlayerController: Click on 2D screen
        PlayerController->>PuzzleObject: receive_3d_click(Vector3)
        PuzzleObject->>PuzzleObject: Emulates click on Control Node buttons
        
        alt Puzzle Completed Successfully
            PuzzleObject->>GameEvents: advance_stage()
        end
    end
```

## 4. AI System Architecture (Integration with Ollama & External APIs)

```mermaid
flowchart TD
    subgraph Godot_Engine ["Godot Engine (Client)"]
        Game[Game Events / Player Actions]
        Agent[Agents: Hint / Saboteur / Difficulty]
        Actuator[Effects: Lights, Audio, UI, Difficulty]
        Painting[PaintingAI Node]
    end

    subgraph Ollama_Server ["Ollama (Local Server)"]
        LLM[LLaMA3:8b]
    end
    
    subgraph External_APIs ["External APIs"]
        Pollinations[Pollinations.ai / DALL-E]
    end

    Game -->|Telemetry| Agent
    Agent -->|HTTP POST JSON| LLM
    LLM -->|JSON Response| Agent
    Agent -->|Executes JSON| Actuator
    
    Game -->|Init| Painting
    Painting -->|HTTP Request Prompts| Pollinations
    Pollinations -->|Image Bytes| Painting
    Painting -->|Applies Texture to 3D Material| Game
```

## 5. Agent-LLM Communication Sequences (Agent-Sequence Diagrams)

### 5.1. HintAgent (On-Demand AI Director)
```mermaid
sequenceDiagram
    actor Player
    participant Game as Game (GameEvents)
    participant HintAgent
    participant Ollama_LLM
    
    Player->>Game: Presses 'H' Key (Requests Hint)
    Game->>HintAgent: _on_hint_requested()
    
    HintAgent->>HintAgent: Checks Cooldown (60s)
    alt Cooldown Active
        HintAgent-->>Player: Visually displays remaining time
    else Cooldown Expired
        HintAgent->>HintAgent: Checks Semaphore (Waits if Saboteur uses LLM)
        HintAgent->>Game: Extracts Telemetry (Player Positions, Mistakes, Stage)
        HintAgent->>Ollama_LLM: HTTP POST Async (/api/generate)
        Ollama_LLM-->>HintAgent: JSON Response: {action: "FLICKER_LIGHTS", hint_text: "..."}
        HintAgent->>Game: _execute_hint(action)
        Note right of Game: Actuators: FLICKER_LIGHTS, SHAKE_OBJECT, SPAWN_BLOOD_TEXT
    end
```

### 5.2. SaboteurAgent (Asymmetric Horror Director)
```mermaid
sequenceDiagram
    participant Game
    participant SaboteurAgent
    participant Ollama_LLM
    
    Game->>SaboteurAgent: Increases Tension level (Tension > 0.7)
    
    loop Every N seconds (Cooldown)
        SaboteurAgent->>SaboteurAgent: Checks Ollama Semaphore
        SaboteurAgent->>Game: Requests Telemetry (Idle, Panic, Positions)
        SaboteurAgent->>Ollama_LLM: HTTP POST Async (/api/generate)
        
        Ollama_LLM-->>SaboteurAgent: JSON Response: {action: "LIGHT_BLACKOUT", target_player: "Player1"}
        
        SaboteurAgent->>Game: _execute_action(action)
        Note right of Game: Actuators: DOOR_SLAM, LIGHT_BLACKOUT, PLAYER_ISOLATION, SPAWN_FAKE_CLUE, ASYMMETRIC_WHISPER
    end
```

### 5.3. DifficultyAgent (Dynamic Difficulty Director)
```mermaid
sequenceDiagram
    participant GameEvents
    participant DifficultyAgent
    participant PuzzleGen
    participant Ollama_LLM
    
    GameEvents->>DifficultyAgent: stage_changed (Stage 2 or 3)
    
    DifficultyAgent->>DifficultyAgent: Checks Semaphore (Waits for Hint/Saboteur)
    DifficultyAgent->>DifficultyAgent: Calculates elapsed time and total errors
    
    DifficultyAgent->>Ollama_LLM: HTTP POST Async (Performance Evaluation)
    Ollama_LLM-->>DifficultyAgent: JSON Response: {action: "SCALE_UP", target_stage: 2}
    
    DifficultyAgent->>PuzzleGen: _apply_difficulty("SCALE_UP")
    Note right of PuzzleGen: Modifies solution on-the-fly: e.g. increases PIN from 4 to 6 digits
```

## 6. CI/CD Pipeline (Workflow)

```mermaid
flowchart LR
    Dev[Developer] -->|Push / Pull Request| GitHub_Repo[(GitHub Repository)]
    
    subgraph Pipeline_CICD ["CI/CD Pipeline (GitHub Actions)"]
        direction TB
        BackendTests[npm test on backend]
        Linter[gdtoolkit / GDLint on Godot]
        GodotTests[Godot Headless Evals: Hint, Saboteur, Difficulty]
        
        BackendTests --> Linter
        Linter --> GodotTests
    end
    
    GitHub_Repo --> Pipeline_CICD
    GodotTests -->|Build OK| Release([Release / Stable Version])
```

## 7. Game Data Structure (Entity Relationship Diagram - ERD)

```mermaid
erDiagram
    BACKEND_USER ||--o{ GAME_SESSION : participates_in
    BACKEND_USER {
        string user_id
        string username
        string password_hash
    }
    
    GAME_SESSION ||--o{ TELEMETRY : generates
    GAME_SESSION {
        string session_id
        float total_time
        string rank
    }
    
    PLAYER ||--o{ TELEMETRY : reports
    PLAYER {
        string peer_id
        Vector3 position
        float panic_level
    }
    
    PUZZLE ||--o{ WRONG_ATTEMPT : registers
    PUZZLE {
        string puzzle_id
        bool is_solved
    }
    
    AGENT ||--|{ TELEMETRY : processes_decisions
    AGENT {
        string agent_type
        float cooldown
    }
```

## 8. State Machine - Player Controller

```mermaid
stateDiagram-v2
    [*] --> NETWORK_CHECK : On Spawn

    state NETWORK_CHECK {
        [*] --> REMOTE_PEER : Not Authority
        [*] --> LOCAL_PLAYER : Is Authority
    }

    REMOTE_PEER --> [*] : Controller Disabled (Visual only)
    LOCAL_PLAYER --> IDLE

    IDLE --> MOVING : Input (WASD)
    MOVING --> IDLE : Lack of input
    
    IDLE --> FOCUSED : 3D Click on Puzzle
    MOVING --> FOCUSED : 3D Click on Puzzle
    
    state FOCUSED {
        INTERACTING : Player uses 2D UI in 3D space
        CAMERA_LOCKED : Movement blocked, mouse visible
    }
    
    FOCUSED --> IDLE : ESC / Right Click / Switch Player (TAB)
    
    IDLE --> TRANSMITTING_RADIO : 'T' Key pressed
    TRANSMITTING_RADIO --> IDLE : 'T' Key released
    
    IDLE --> DISABLED : Saboteur Agent (Isolation/Glitch)
    MOVING --> DISABLED : Saboteur Agent
    DISABLED --> IDLE : Time expires
```
