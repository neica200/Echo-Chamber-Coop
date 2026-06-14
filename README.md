# 🎭 Echo Chamber - Co-op AI Escape Room

## 🚀 Project Overview
**Echo Chamber** is a cooperative, horror-themed escape room experience developed as a Software-as-a-Service (SaaS). The game leverages a complex system of **Intelligent Agents** to generate a unique experience for every session, forcing players to collaborate through asymmetric communication and real-time coordination.

## 🚀 Demo offline: https://youtu.be/2wJiNBIspg0

## 🧩 Game Components & Puzzles
The project is built using the **Godot 4 Engine** for the client and a **Node.js/Express** backend for SaaS functionalities.

- **Asymmetric Puzzles (`PuzzleGen.gd`):** Procedurally generates distinct escape room mechanics based on a shared network seed. Puzzles include:
  - *Color Panels*: Memorizing and syncing color sequences.
  - *Mathematical Grids*: Coordinated button pressing based on shared boolean grid states.
  - *Interactive Numpad / Safes*: Cracking access codes using clues from the other player's room.
- **Environment & Textures:** Uses high-quality **PBR Materials** (Albedo, Normal, Roughness, AO, Height mapped via `PBRMaterialManager.gd`) to render a realistic, terrifying atmosphere. This includes processing high-resolution textures (e.g., Velvet, Stone Tiles, Substance Graphs) dynamically.
- **Peer-to-Peer Networking:** Synchronizes player movements, item transfers, 3D ping systems, and puzzle states in real-time.
- **Proximity Voice Chat (`WalkieTalkie.gd`):** Spatially positioned 3D VoIP for immersive, horror-inducing communication.
- **SaaS Backend:** A Node.js Express API handling player registration, JWT authentication, and a Team Dashboard to track performance and escape times.

## 🤖 AI Agents & LLM Integration
Powered by a local **Ollama (`llama3:8b`)** LLM instance and deterministic scripts.

### LLM-Powered Agents (Async HTTP)
1. **Hint Agent (`HintAgent.gd`):** Monitors player telemetry (stage, location, mistakes) to generate contextual, diegetic hints without directly spoiling solutions.
2. **Saboteur Agent (`SaboteurAgent.gd`):** The horror director. Tracks inactivity/tension to trigger dynamic scares (flickering lights, slamming doors, cryptic bloody texts).
3. **Difficulty Agent (`DifficultyAgent.gd`):** Dynamically scales puzzle difficulty. `SCALE_UP` (e.g., 6-digit PIN) for fast players, or `SCALE_DOWN` (e.g., 3-digit PIN) for struggling ones.
4. **Painting AI (`PaintingAI.gd`):** Generates disturbing image clues using text-to-image APIs (Pollinations.ai / DALL-E) based on puzzle context.

### Procedural Agents
- **Room Generator Agent (`RoomGeneratorAgent.gd`):** Deterministically creates the room layout and distributes clues based on the network seed.
- **Puzzle Generator Agent (`PuzzleGeneratorAgent.gd`):** Calculates all asymmetric puzzle logic and solutions dynamically.

## ⚙️ Automated Testing & CI/CD
To ensure code reliability, the project includes a robust DevOps pipeline:
- **Headless Unit Tests:** Dedicated test scripts (e.g., `eval_hint_agent.gd`, `eval_game_stats.gd`, `eval_saboteur_agent.gd`) run locally without a GUI, mocking LLM calls and evaluating logic, state tracking, and rank calculation.
- **GitHub Actions (`ci.yml`):** Automatically triggers the headless Godot unit tests on every commit, alongside code checks, ensuring the `main` branch is always stable.

---

## 👥 Team
- Neica Mario - 234
- Șeitan Alexia - 234 
- Sali Melysa - 24
- Popa Andreea - 24

---


## 📂 Project Structure

```text
Echo-Chamber-SaaS/
├── src/                # Game Source Code (Godot 4)
│   ├── Scripts/
│   │   ├── Agents/     # Saboteur, Hint, Difficulty, RoomGen, PuzzleGen
│   │   ├── Core/       # GameStats, GameEvents, AudioManager
│   │   ├── Environment/# Room layout & geometry logic
│   │   ├── Networking/ # WalkieTalkie, P2P Sincronization
│   │   ├── Player/     # Player controllers & Interaction
│   │   ├── Props/      # Interactable objects (doors, safes)
│   │   ├── Puzzles/    # Mechanics (Numpad, Color Panels)
│   │   ├── Textures/   # PBR materials & textures
│   │   └── UI/         # AuthUI, EndGameScreen
│   └── Assets/         # 3D Models, Sounds, Prefabs
├── backend/            # SaaS Infrastructure (Node.js)
├── tests/              # Headless Automated Tests (GDScript)
└── .github/            # CI/CD Workflows
```
