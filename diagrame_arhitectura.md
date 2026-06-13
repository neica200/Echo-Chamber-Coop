# Diagrame de Arhitectură și Workflow - Echo Chamber Co-op

## 1. Arhitectura Componentelor (UML Class Diagram)
Această diagramă ilustrează structura Singleton-urilor, a claselor principale, și a noilor componente de rețea, AI Generativ și Backend, evidențiind modul de comunicare global.

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

    PlayerController --> NetworkManager : Conexiune P2P
    PlayerController --> WalkieTalkie : Capturează/Trimite voce (Push-to-Talk)
    PaintingAI --> NetworkManager : RPC Sync Prompt
    HintAgent --> GameEvents : Ascultă semnale
    SaboteurAgent --> HintAgent : Verifică Semafor Ollama
    DifficultyAgent --> GameEvents : Ascultă stage_changed
    DifficultyAgent --> PuzzleGen : Modifică parametrii (SCALE_UP/DOWN)
```

## 2. Diagrama de Flux a Jocului (Workflow / State Diagram)
Flow-ul actualizat al Escape Room-ului, incluzând conectarea multiplayer, generarea AI-ului vizual la început și încheierea sesiunii cu afișarea ecranului de final.

```mermaid
stateDiagram-v2
    [*] --> Lobby : Lansare Joc
    Lobby --> Generare_Sesiune : Autentificare & NetworkManager (Host/Join)
    
    state Generare_Sesiune {
        PaintingAI_Request : Se generează tabloul AI (Pollinations/DALL-E)
        Procedural_Gen : Se generează structura camerelor
    }
    
    Generare_Sesiune --> Faza1_Sigurante : Spawn Jucători (P1 Room A, P2 Room B)
    
    Faza1_Sigurante --> Faza15_Sertar : P2 rezolvă panoul electric
    Faza15_Sertar --> Faza2_Seif : P1 deschide sertarul cu cheia
    Faza2_Seif --> Faza3_Hacking : [DifficultyAgent evaluează] P1 rezolvă culorile
    Faza3_Hacking --> Faza4_Evadare : [DifficultyAgent evaluează] P1 sparge firewall-ul
    Faza4_Evadare --> EndGame : P2 introduce codul pe Numpad
    
    state EndGame {
        Afisare_Statistici : Rank S-D, Mistakes, Time
        Salvare_Backend : Transmitere date scor către SaaS
    }
    EndGame --> [*]
```

## 3. Workflow de Interacțiune (Sequence Diagram)
Diagrama detaliată pentru "Focus Mode", actualizată pentru a include verificările stricte de rețea (`is_multiplayer_authority`).

```mermaid
sequenceDiagram
    actor Jucator
    participant PlayerController
    participant MultiplayerAPI
    participant PuzzleObject as "PuzzleObject (ex: Terminal)"
    participant GameEvents

    Jucator->>PlayerController: Click stânga pe un monitor
    PlayerController->>MultiplayerAPI: is_multiplayer_authority()?
    
    alt Client Fără Autoritate
        MultiplayerAPI-->>PlayerController: False (Ignoră input)
    else Client Cu Autoritate
        MultiplayerAPI-->>PlayerController: True
        PlayerController->>PuzzleObject: detectare RayCast
        PuzzleObject-->>PlayerController: returnează true (has FocusPoint)
        PlayerController->>PlayerController: enter_focus() (mută camera & eliberează mouse-ul)
        
        Jucator->>PlayerController: Click pe ecranul 2D
        PlayerController->>PuzzleObject: receive_3d_click(Vector3)
        PuzzleObject->>PuzzleObject: Emulează click pe butoanele de Control Node
        
        alt Puzzle Finalizat cu Succes
            PuzzleObject->>GameEvents: advance_stage()
        end
    end
```

## 4. Arhitectura Sistemului AI (Integrarea cu Ollama & API-uri Externe)
Această diagramă ilustrează noile direcții ale inteligenței artificiale din proiect: LLM-urile locale (Ollama) care operează prin agenți și generatoarele externe de imagini (PaintingAI).

```mermaid
flowchart TD
    subgraph Godot_Engine ["Godot Engine (Client)"]
        Game[Evenimente Joc / Acțiuni Jucători]
        Agent[Agenți: Hint / Saboteur / Difficulty]
        Actuator[Efecte: Lumini, Sunete, UI, Dificultate]
        Painting[PaintingAI Node]
    end

    subgraph Ollama_Server ["Ollama (Server Local)"]
        LLM[LLaMA3:8b]
    end
    
    subgraph External_APIs ["API-uri Externe"]
        Pollinations[Pollinations.ai / DALL-E]
    end

    Game -->|Telemetrie| Agent
    Agent -->|HTTP POST JSON| LLM
    LLM -->|Răspuns JSON| Agent
    Agent -->|Execută JSON| Actuator
    
    Game -->|Init| Painting
    Painting -->|HTTP Request Prompts| Pollinations
    Pollinations -->|Image Bytes| Painting
    Painting -->|Aplică Textură Material 3D| Game
```

## 5. Secvența de Comunicare Agent-LLM (Agent-Sequence Diagram)
Acțiunile exacte extrase din codul sursă pentru `SaboteurAgent`, ilustrând modul în care generează evenimente asimetrice de groază fără a bloca jocul.

```mermaid
sequenceDiagram
    participant Game
    participant SaboteurAgent
    participant Ollama_LLM
    
    Game->>SaboteurAgent: Crește nivelul de Tensiune (Tension > 0.7)
    
    loop La fiecare N secunde (Cooldown)
        SaboteurAgent->>SaboteurAgent: Verifică Cooldown și Semaphore
        SaboteurAgent->>Game: Solicită Telemetrie (Idle, Panic, Pozitii)
        SaboteurAgent->>Ollama_LLM: HTTP POST Async (/api/generate)
        
        Note over SaboteurAgent,Ollama_LLM: Așteaptă răspuns asincron
        Ollama_LLM-->>SaboteurAgent: Răspuns JSON: {action: "LIGHT_BLACKOUT", target_player: "Player1"}
        
        SaboteurAgent->>SaboteurAgent: Parsare Strictă JSON & Protecție
        SaboteurAgent->>Game: _execute_action(action)
        
        Note right of Game: Actuatorii Reali din Cod:<br/>- DOOR_SLAM<br/>- LIGHT_BLACKOUT<br/>- PLAYER_ISOLATION<br/>- SPAWN_FAKE_CLUE<br/>- ASYMMETRIC_WHISPER
    end
```

## 6. Pipeline CI/CD (Workflow)
Fluxul automatizat prin GitHub Actions, incluzând verificarea noului backend Express.

```mermaid
flowchart LR
    Dev[Dezvoltator] -->|Push / Pull Request| GitHub_Repo[(GitHub Repository)]
    
    subgraph Pipeline_CICD ["Pipeline CI/CD (GitHub Actions)"]
        Direction TB
        BackendTests[npm test pe backend]
        Linter[gdtoolkit / GDLint pe Godot]
        GodotTests[Godot Headless Evals: Hint, Saboteur, Difficulty]
        
        BackendTests --> Linter
        Linter --> GodotTests
    end
    
    GitHub_Repo --> Pipeline_CICD
    GodotTests -->|Build OK| Release([Release / Versiune Stabilă])
```

## 7. Structura Datelor de Joc (Entity Relationship Diagram - ERD)
Extinderea modelului de date pentru a include logarea la backend-ul SaaS și sincronizarea statisticilor per jucător.

```mermaid
erDiagram
    BACKEND_USER ||--o{ GAME_SESSION : "participă la"
    BACKEND_USER {
        string user_id
        string username
        string password_hash
    }
    
    GAME_SESSION ||--o{ TELEMETRY : "generează"
    GAME_SESSION {
        string session_id
        float total_time
        string rank
    }
    
    PLAYER ||--o{ TELEMETRY : "raportează"
    PLAYER {
        string peer_id
        Vector3 position
        float panic_level
    }
    
    PUZZLE ||--o{ WRONG_ATTEMPT : "înregistrează"
    PUZZLE {
        string puzzle_id
        bool is_solved
    }
    
    AGENT ||--|{ TELEMETRY : "procesează decizii"
    AGENT {
        string agent_type
        float cooldown
    }
```

## 8. State Machine - Player Controller
Automatul de stări (State Machine) extins din codul `PlayerController.gd`, tratând logica de rețea, Walkie-Talkie-ul și comutarea între Focus Mode.

```mermaid
stateDiagram-v2
    [*] --> NETWORK_CHECK : La Spawn

    state NETWORK_CHECK {
        [*] --> REMOTE_PEER : Not Authority
        [*] --> LOCAL_PLAYER : Is Authority
    }

    REMOTE_PEER --> [*] : Controller Dezactivat (Doar vizual)
    LOCAL_PLAYER --> IDLE

    IDLE --> MOVING : Input (WASD)
    MOVING --> IDLE : Lipsă input
    
    IDLE --> FOCUSED : Click 3D pe Puzzle
    MOVING --> FOCUSED : Click 3D pe Puzzle
    
    state FOCUSED {
        INTERACTING : Jucătorul folosește UI 2D în 3D
        CAMERA_LOCKED : Mișcarea blocată, mouse vizibil
    }
    
    FOCUSED --> IDLE : ESC / Click Dreapta / Switch Player (TAB)
    
    IDLE --> TRANSMITTING_RADIO : Tasta 'T' apăsată
    TRANSMITTING_RADIO --> IDLE : Tasta 'T' eliberată
    
    IDLE --> DISABLED : Saboteur Agent (Isolation/Glitch)
    MOVING --> DISABLED : Saboteur Agent
    DISABLED --> IDLE : Expiră timpul
```
