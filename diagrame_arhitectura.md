# Diagrame de Arhitectură și Workflow - Echo Chamber Co-op

## 1. Arhitectura Componentelor (UML Class Diagram)
Această diagramă ilustrează structura Singleton-urilor și a claselor principale, evidențiind modul de comunicare între sistemele de bază (Autoloads), Generatoarele de camere și controllerele jucătorilor.

```mermaid
classDiagram
    class GameEvents {
        <<Singleton>>
        +int current_stage
        +advance_stage()
        +signal stage_changed(new_stage)
        +signal puzzle_solved(puzzle_id)
        +signal room_lights_toggled(room_id, state)
        +signal safe_opened(room_id)
        +signal escape_door_opened()
        +signal drawer_opened()
    }

    class PuzzleGen {
        <<Singleton>>
        -Dictionary puzzles_data
        +generate_puzzles()
        +get_puzzle_data(id) Dictionary
        +verify_solution(id, attempt) bool
    }

    class AudioManager {
        <<Singleton>>
        +play_background_music()
        +play_click()
        +play_success()
        +play_error()
    }

    class NetworkManager {
        <<Singleton>>
        +host_game()
        +join_game(ip)
        +signal peer_connected(id)
    }

    class RoomGeneratorAgent {
        +generate_rooms(seed)
        +place_on_wall()
        +place_on_floor()
        -build_walls_and_floor()
    }

    class PlayerController {
        +bool is_active
        +bool is_focused
        +check_interaction()
        +enter_focus(target_puzzle)
        +handle_focus_click()
        +add_to_inventory(item)
    }

    class PuzzleBase {
        <<Interface>>
        +interact()
        +receive_3d_click(hit_position)
    }

    class HintAgent {
        <<Singleton>>
        +String model_name
        +Dictionary wrong_attempts
        +register_wrong_attempt(puzzle_type)
        +get_telemetry() Dictionary
        -_call_ollama(prompt)
    }

    class SaboteurAgent {
        <<Singleton>>
        +float tension
        +register_wrong_attempt(puzzle_type, player)
        -_call_ollama(prompt)
        -_trigger_scare(action, target)
    }

    class DifficultyAgent {
        <<Singleton>>
        +float game_start_time
        -_on_stage_changed(new_stage)
        -_evaluate_difficulty(stage)
        -_apply_difficulty(stage, decision)
    }

    RoomGeneratorAgent --> PuzzleGen : Solicită generare procedurale
    PlayerController --> GameEvents : Ascultă semnale / Declanșează
    PlayerController --> PuzzleBase : RayCast 3D Interaction
    PuzzleBase --> GameEvents : Verifică condiții / Emite semnale
    PuzzleBase --> AudioManager : Trigger SFX

    HintAgent --> GameEvents : Ascultă stage_changed / drawer_opened
    SaboteurAgent --> GameEvents : Ascultă stage_changed
    DifficultyAgent --> GameEvents : Ascultă stage_changed

    SaboteurAgent --> HintAgent : Verifică dacă LLM e ocupat (is_waiting_for_ollama)
    DifficultyAgent --> HintAgent : Citește wrong_attempts pentru evaluare
    DifficultyAgent --> PuzzleGen : Modifică active_puzzles (soluție mărită/micșorată)
    PlayerController --> NetworkManager : Inițiază conexiune multiplayer
```

## 2. Diagrama de Flux a Jocului (Workflow / State Diagram)
Aici este descris flow-ul liniar și strict al Escape Room-ului, demonstrând legătura cooperativă dintre Camera A și Camera B.

```mermaid
stateDiagram-v2
    [*] --> Start_Game : Jucătorii se spawnează (P1 în Room A, P2 în Room B)
    
    state Start_Game {
        MatrixMonitor_Hint : Matrix Monitor aprins pe baterii (Hint)
    }
    
    Start_Game --> Faza1_Sigurante : P2 rezolvă panoul electric
    
    state Faza1_Sigurante {
        Lumina_ON : Se aprinde lumina în ambele camere
    }
    
    Faza1_Sigurante --> Faza15_Sertar : P1 folosește cheia pe sertar
    
    state Faza15_Sertar {
        Sertar_Deschis : Se emite semnalul drawer_opened
        Panou_Culori_Aprins : Se aprinde Hint-ul de culori (Room A)
    }
    
    Faza15_Sertar --> Faza2_Seif : [DifficultyAgent evalueaza Faza 1 & ajusteaza secventa de culori] -> P2 introduce culorile
    
    state Faza2_Seif {
        Seif_Deschis : Se deschide Seiful (Room B)
        Terminal_ON : Se aprinde Terminalul PC (Room A)
    }
    
    Faza2_Seif --> Faza3_Hacking : [DifficultyAgent evalueaza Faza 2 & ajusteaza PIN-ul final] -> P1 sparge firewall-ul pe PC
    
    state Faza3_Hacking {
        Terminal_Hacked : Bypass Firewall -> Decrypt -> Core
        PIN_Afisat : PC-ul afișează PIN-ul final
    }
    
    Faza3_Hacking --> Faza4_Evadare : P2 introduce PIN-ul la Numpad
    
    state Faza4_Evadare {
        Usa_Deschisa : Escape Door Opened
    }
    
    Faza4_Evadare --> [*] : Game Won!
```

## 3. Workflow de Interacțiune (Sequence Diagram)
O diagramă detaliată despre cum funcționează sistemul unic de "Focus Mode" (click pe ecrane 3D).

```mermaid
sequenceDiagram
    actor Jucator
    participant PlayerController
    participant PuzzleObject as "PuzzleObject (ex: Terminal)"
    participant GameEvents
    participant AudioManager

    Jucator->>PlayerController: Click stânga pe un monitor
    PlayerController->>PuzzleObject: detectare RayCast
    PuzzleObject-->>PlayerController: returnează true (has FocusPoint)
    PlayerController->>PlayerController: enter_focus() (mută camera & eliberează mouse-ul)
    
    Jucator->>PlayerController: Click pe ecranul 2D
    PlayerController->>PuzzleObject: receive_3d_click(Vector3)
    
    alt Stadiu incorect
        PuzzleObject->>Jucator: Eroare consola (Trebuie finalizată faza precedentă)
    else Stadiu corect
        PuzzleObject->>AudioManager: play_click()
        PuzzleObject->>PuzzleObject: convertește Z local -> V (Viewport UV)
        PuzzleObject->>PuzzleObject: Generează InputEventMouseButton (simulare)
        PuzzleObject->>PuzzleObject: Emulează click pe butoanele de Control Node
        
        alt Puzzle Finalizat cu Succes
            PuzzleObject->>AudioManager: play_success()
            PuzzleObject->>GameEvents: advance_stage()
        end
    end
```
