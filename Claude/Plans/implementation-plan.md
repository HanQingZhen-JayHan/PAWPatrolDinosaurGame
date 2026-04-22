# PAW Patrol Endless Runner - Implementation Plan

## Context

Build a PAW Patrol themed Chrome Dino-style endless runner game for kids (4-10 years). The unique twist: **phone-as-controller** architecture where a host device (PC/browser) renders the game on a big screen, and players use their phones as wireless controllers via WiFi/WebSocket. Players scan a QR code to join and choose their favorite PAW Patrol pup.

---

## Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Framework | Flutter/Dart | Cross-platform (browser, Android, iOS, Windows) |
| Game Engine | `flame` ^1.21.0 | Endless runner rendering, physics, collision |
| Audio | `flame_audio` ^2.10.0 | Sound effects and music |
| Server | `shelf` + `shelf_web_socket` | WebSocket server on host device |
| Client | `web_socket_channel` | WebSocket client on controller phones |
| QR Code | `qr_flutter` ^4.1.0 | QR code for session URL |
| QR Scanner | `mobile_scanner` ^5.0.0 | Phone camera QR scanning |
| State | `provider` ^6.1.0 | State management |
| IDs | `uuid` ^4.0.0 | Player ID generation |
| Sensors | `sensors_plus` ^5.0.0 | Phone accelerometer for tilt controls |

**Platform routing**: Host mode requires `dart:io` (Windows/Android/iOS only). Web build defaults to controller mode since browsers can't run WebSocket servers.

---

## Architecture

```
[Host Device - Windows/Android/iOS]
├── Flame Game (2D canvas)
├── WebSocket Server (shelf)
└── QR Code Display (ws://ip:port/ws)

[Phone 1] ──WebSocket──┐
[Phone 2] ──WebSocket──┼──→ Host receives inputs, broadcasts state
[Phone N] ──WebSocket──┘
```

### WebSocket Message Protocol (JSON)

**Controller → Host:**
- `join` { playerName } — request to join session
- `select_character` { character } — pick a pup
- `ready` {} — mark ready in lobby
- `input` { action: jump/duck_start/duck_end } — detected from body motion sensors
- `request_start` {} — any controller can request game start (host auto-starts when ALL players ready)
- `request_end` {} — any controller can request to end the game early
- `leave` {} — disconnect gracefully

**Host → Controller:**
- `joined` { playerId } → `character_confirmed` { character }
- `game_starting` { countdown } → `game_started` {}
- `hit` { livesRemaining } → `eliminated` { finalScore }
- `game_over` { rankings: [{ rank, playerId, character, score, isWinner }] }

**Host → All (broadcast):**
- `lobby_update` { players[], allReady: bool } — includes ready state for auto-start
- `score_update` { scores } — periodic during gameplay

**Game Start Rules:**
- **Auto-start**: Host starts automatically when ALL connected players are `ready`
- **Manual start**: Any controller can send `request_start` to force start (requires ≥1 player ready)
- Host shows 3-2-1-GO countdown before game begins

**Game End Rules:**
- **Auto-end**: Host ends the game when ≤1 player remains alive (last survivor wins)
- **Manual end**: Any controller can send `request_end` to end the game early
- On game end: host calculates final score ranking, announces the winner
- If 1 player left: that player is the winner (last one standing)
- If 0 players left (simultaneous elimination): highest score wins
- If manual end: highest score at time of end wins

**Game Over Screen (Host):**
- Podium display: 1st/2nd/3rd place with character icons
- Winner announcement with celebration animation + sound
- Full ranking list: rank, character icon, player name, final score
- "PLAY AGAIN" and "BACK TO LOBBY" options

**Game Over Screen (Controller):**
- Personal result: "You placed #N!" with score
- Winner announcement: "Winner: [character name]!"
- "PLAY AGAIN" button (sends `ready` to re-queue)

---

## Project Structure

```
lib/
├── main.dart                         # Platform detection, provider setup
├── app.dart                          # MaterialApp, routing, theme
├── constants/
│   ├── game_constants.dart           # Speeds, gravity, dimensions
│   ├── characters.dart               # PawCharacter enum + metadata
│   ├── theme.dart                    # Child-friendly PAW Patrol theme
│   └── dev_config.dart               # Develop mode flags + easy-level tuning
├── models/
│   ├── player.dart                   # PlayerData: id, character, score, lives
│   ├── obstacle.dart                 # Obstacle type enum + dimensions
│   ├── game_state.dart               # GameStateModel: phase, players, speed
│   └── message.dart                  # GameMessage: type, payload, JSON codec
├── sensor/
│   ├── motion_detector.dart          # Core jump/duck detection from accelerometer
│   ├── motion_calibrator.dart        # Per-kid baseline calibration
│   └── motion_state.dart             # MotionState enum + transition logic
├── network/
│   ├── game_server.dart              # shelf WebSocket server (host)
│   ├── game_client.dart              # WebSocket client (controller)
│   ├── message_protocol.dart         # Message type constants
│   └── network_utils.dart            # Local IP discovery, port finder
├── game/
│   ├── paw_patrol_game.dart          # FlameGame subclass - root game
│   ├── components/
│   │   ├── ground.dart               # Scrolling ground/road
│   │   ├── parallax_background.dart  # Multi-layer scrolling background
│   │   ├── player_component.dart     # Character sprite + physics + collision
│   │   ├── obstacle_component.dart   # Obstacle sprite + movement
│   │   ├── heart_indicator.dart      # Lives HUD per player
│   │   ├── score_indicator.dart      # Score HUD per player
│   │   ├── game_over_overlay.dart    # Game over podium + rankings
│   │   └── winner_celebration.dart  # Winner animation + effects
│   ├── managers/
│   │   ├── obstacle_manager.dart     # Spawning, difficulty scaling
│   │   └── score_manager.dart        # Score tracking
│   └── systems/
│       └── difficulty_system.dart    # Speed/spawn rate progression
├── screens/
│   ├── splash_screen.dart            # PAW Patrol logo
│   ├── mode_select_screen.dart       # "Host Game" / "Join Game"
│   ├── host_lobby_screen.dart        # QR code + player list + start button
│   ├── controller_join_screen.dart   # QR scanner / manual IP
│   ├── character_select_screen.dart  # 8 pup grid selection
│   ├── controller_screen.dart        # Body motion detection + START/END
│   ├── calibration_screen.dart       # Sensor calibration before game
│   ├── game_over_result_screen.dart  # Controller: personal rank + winner
│   └── game_screen.dart              # Flame GameWidget + HUD + podium overlay
└── providers/
    ├── game_provider.dart            # Host: server + game state + Flame bridge
    ├── network_provider.dart         # Connection status tracking
    └── controller_provider.dart      # Controller: client + local state
```

---

## Game Mechanics

### Player
- 8 PAW Patrol characters: Chase, Marshall, Skye, Rubble, Rocky, Zuma, Everest, Tracker
- 3 states: running (default), jumping (tilt/flick UP), ducking (tilt DOWN)
- Jump physics: `velocityY = -600`, `gravity = 1800`, standard parabolic arc
- No double-jump (simplicity for kids)
- 3 lives (hearts), 1.5s invincibility after hit (sprite blinks)
- Eliminated when all hearts lost; character fades out but others continue

### Controller Input (Body-Mounted Phone)
The phone is strapped to the kid's body (arm band, waist belt, or chest harness). The kid physically jumps and ducks to control their character.

**Mounting positions supported:**
- **Waist/belt** (recommended): phone in a belt pouch or clipped to waistband
- **Arm band**: phone strapped to upper arm
- **Chest harness**: phone in a chest pocket/holder
- Player selects mount position during calibration so thresholds adapt

**Motion detection via accelerometer + gyroscope (`sensors_plus`):**

| Kid's action | Sensor signal | Detection logic |
|---|---|---|
| **Jump** | Sudden upward acceleration spike → brief freefall (near-zero g) → landing spike | Detect accel Y-axis spike > `jumpThreshold` followed by low-g window. Debounce 500ms to prevent double-trigger |
| **Duck/Crouch** | Rapid downward movement + sustained lower position | Detect accel Y-axis drop + gyroscope forward tilt. Sustained low position = stay ducking. Return to standing = stop ducking |
| **Standing (idle)** | Baseline steady-state accelerometer values | Character runs normally |

**Detection algorithm (`motion_detector.dart`):**
```
1. Read accelerometer at 50Hz (every 20ms via sensors_plus userAccelerometerEvents)
2. Apply low-pass filter to remove noise (moving average, window=5 samples)
3. Compare filtered accel-Y against calibrated baseline:
   - Spike > baseline + jumpThreshold → JUMP detected
   - Drop < baseline - duckThreshold (sustained 200ms) → DUCK_START
   - Return to baseline after duck → DUCK_END
4. Debounce: ignore jump triggers for 500ms after last jump
5. Send input messages to host only on state transitions
```

**Calibration flow (`calibration_screen.dart`):**
1. Kid stands still for 3 seconds → record baseline accelerometer values
2. Kid does 3 practice jumps → record jump acceleration peaks → set jumpThreshold to 60% of average peak
3. Kid crouches once → record duck acceleration pattern → set duckThreshold
4. Show "You're all set!" with a fun animation
5. Store calibration per player session (not persisted)

**Key design for kids:**
- **Generous thresholds**: better to detect a small jump than miss a big one
- **Visual feedback on host**: character briefly glows when input is detected, so kids can see cause-and-effect
- **Audio feedback on phone**: short beep/vibrate on jump detection so kid knows it registered
- **Fallback buttons**: small on-screen JUMP/DUCK buttons remain available at bottom of controller screen for accessibility or when sensors fail
- **Safety**: controller screen shows "PAUSE" button; game auto-pauses if phone detects a fall (sudden high-g impact)

### Multi-Player Layout
- 1 player: centered · 2-4 players: stacked lanes · 5-8: two rows, 0.75x scale
- All players share the same obstacle field (cooperative survival, competitive scoring)

### Obstacles
- **Ground** (jump over): traffic cones, barrels, rocks, puddles
- **Air** (duck under): birds - introduced after score 500
- Scroll right-to-left at `gameSpeed`, obstacles check collision against ALL players

### Difficulty Progression
- Speed: 300 → 800 px/s (+10 every 5s)
- Spawn interval: 2.5s → 0.8s (-0.1 every 10s)
- Score 500: air obstacles appear
- Score 1000: simultaneous ground+air obstacles

### Scoring & Game End
- Continuous: `score += gameSpeed * dt * 0.1` (only while player is alive)
- Each player tracked independently
- **Game ends when ≤1 player remains alive** (not when ALL eliminated)
  - Last survivor is the winner
  - If all eliminated simultaneously → highest score wins
  - Tie-breaker: player who survived longer wins
- Any controller can also end the game early via `request_end`
- Final ranking: sorted by elimination order (last eliminated = highest rank), then by score
- Winner gets celebration animation + trophy icon on podium

---

## Screen Flow

```
Splash → Mode Select
  ├─ HOST: Lobby (QR + player list, auto-start when all ready)
  │        → Game Screen (Flame + HUD)
  │        → Game Over Podium (rankings + winner + play again)
  │
  └─ CONTROLLER: Join (scan QR) → Character Select → Calibration (strap phone, practice jumps)
           → Ready → Controller Screen (motion detection active + START/END)
           → Game Over Result (personal rank + winner + play again)
```

### Game Lifecycle (detailed)
1. **Lobby**: Players join via QR, select characters, mark ready
2. **Auto-start**: When ALL players are `ready`, host begins 3-2-1 countdown
3. **Manual start**: Any controller can press START to force-start (≥1 ready player required)
4. **Playing**: Players jump/duck to survive, any controller can press END to stop early
5. **Auto-end**: When ≤1 player alive, game ends automatically
6. **Game Over**: Host shows podium with 1st/2nd/3rd + full ranking; controllers show personal result
7. **Replay**: "Play Again" returns to lobby, "READY" re-queues

---

## Develop Mode

A toggle for developers/testers to iterate faster without restarting sessions or chasing gameplay loops. Configured via `lib/constants/dev_config.dart` with a single `DevConfig.enabled` flag.

### How to Enable
- **Runtime toggle**: secret gesture on host splash screen (e.g., tap PAW Patrol logo 5 times) opens the Dev panel
- **Build flag**: `--dart-define=DEV_MODE=true` at build time for CI/automated tests
- **Persisted setting**: `SharedPreferences` stores the last choice so dev sessions survive restarts
- A visible **"DEV MODE"** red banner is always shown across the top of host and controller screens when enabled (so it's never left on by accident in a real game)

### Develop Mode Behaviors

**1. Fixed Room / Connection (no shuffling):**
- **Fixed port**: Server always binds to `8080` (production uses dynamic port)
- **Fixed room code / session ID**: Always `"DEV-ROOM"` instead of generated UUID
- **Stable WebSocket URL**: `ws://<localIp>:8080/ws` — doesn't change between restarts
- **QR code stays valid** across host restarts, so you don't have to rescan on every test cycle
- **Predictable player IDs**: first connection = `dev-p1`, second = `dev-p2`, etc. (instead of UUIDs) — easier log reading

**2. Game Never Ends:**
- Players cannot be eliminated (hits are detected and logged but lives don't drop below 1)
- Collisions still flash invincibility so visual feedback works
- Auto-end rule (`≤1 player alive`) is disabled
- `request_end` from controllers still works (manual stop remains available)
- Score continues to accumulate for testing ranking/podium display

**3. Easy Level (frozen difficulty for logic testing):**
- `gameSpeed` locked at **200 px/s** (vs normal 300→800 progression)
- `spawnInterval` locked at **3.0 s** (vs normal 2.5→0.8 shrinking)
- Air obstacles (birds) disabled — only ground obstacles spawn
- Difficulty progression system paused — no speed ramp, no harder patterns
- Obstacle variety limited to cones only (most predictable shape/hitbox)

**4. Extra Developer Affordances:**
- **Keyboard shortcuts on host** (in addition to controllers):
  - `Space` = jump for player 1, `Down` = duck for player 1
  - `1-8` = simulate hit on player N
  - `K` = kill player 1 (forces elimination despite immortality, to test game_over flow)
  - `R` = force reset to lobby
  - `T` = trigger game_over with current scores (test podium)
- **Dummy bots**: `B` on host spawns a bot player that randomly jumps (avoids needing multiple phones)
- **Verbose logging**: all WebSocket messages logged to console with timestamps
- **Debug overlay**: shows FPS, player count, active obstacles, gameSpeed, elapsed time

### Implemented Behavior

`DevConfig` is a simple `ValueNotifier<bool>` toggle (defaults to build-time `--dart-define=DEV_MODE=true` if set). Hooked into the existing Firebase-based codebase:

- **`FirebaseRoomHost.createRoom()`**: in dev mode, always uses `DevConfig.fixedRoomCode` (`"DEV1"`) and clears any stale state at that path first
- **`GameProvider.playerHit()`**: in dev mode, tops lives back to `immortalLives` (99) when they'd hit 0, keeps player in invincibility state for visual feedback
- **`GameProvider._checkGameEnd()`**: in dev mode, skip the `aliveCount <= 1` auto-end check — `requestEnd` from controllers still works
- **`GameProvider._startGame()`** / `restartGame()`: start with `immortalLives` and `easyGameSpeed` when dev mode on
- **`DifficultySystem.isEasyMode`**: returns `true` forever in dev mode, speed locked to `easyGameSpeed`
- **`ObstacleManager.updateSpawnInterval()`**: in dev mode, locks spawn interval to `easySpawnInterval` (4.0s) and only spawns ground obstacles (inherited from easyMode branch)
- **`DevModeBanner` widget** + **Switch toggle on `ModeSelectScreen`**: user-facing control plus visible red "DEV MODE" bar so it's never left on by accident

All production behavior is preserved when the flag is off — dev-mode changes are guarded by single-line `if (DevConfig.enabled)` checks at decision points.

---

## Implementation Phases

### Phase 1: Project Setup & Models
- `flutter create` project, configure `pubspec.yaml` with all dependencies
- Implement all model classes (PawCharacter, PlayerData, GameStateModel, GameMessage)
- Create constants (game_constants.dart, characters.dart, theme.dart, dev_config.dart)
- Set up DevConfig flag infrastructure from day one (gates all dev-mode behaviors)
- Unit tests for model serialization

### Phase 2: Networking Layer
- `network_utils.dart` - local IP discovery, port finding
- `GameServer` - shelf pipeline, WebSocket handler, client management, broadcast/sendTo
- `GameClient` - connect, send, receive, disconnect
- `message_protocol.dart` - message type constants
- Integration test: server ↔ client message exchange

### Phase 3: Motion Detection & Calibration
- `motion_detector.dart` — accelerometer stream, low-pass filter, jump/duck detection algorithm
- `motion_calibrator.dart` — baseline recording, threshold calculation from practice jumps
- `motion_state.dart` — state machine: standing → jumping → standing, standing → ducking → standing
- `calibration_screen.dart` — guided calibration UX (stand still → jump 3x → crouch)
- Unit tests: mock accelerometer data → verify correct jump/duck detection

### Phase 4: Screens & Navigation
- `main.dart` with platform detection, Provider setup
- `app.dart` with routing and PAW Patrol theme
- All screens with basic UI (placeholder assets), including calibration flow
- Wire providers so controller join flow works end-to-end

### Phase 5: Flame Game (Single Player First)
- `PawPatrolGame` FlameGame class
- Ground + parallax background components
- `PlayerComponent` with jump/duck physics and rectangle hitbox
- `ObstacleComponent` + `ObstacleManager` for spawning
- Collision detection, HUD overlay (score + hearts)
- Test with keyboard input (space=jump, down=duck)

### Phase 6: Multiplayer Integration
- Wire `GameProvider` to bridge WebSocket inputs → Flame game
- Multi-player rendering with dynamic lane assignment
- Per-player input routing, elimination, game over detection
- Score broadcasting to controllers
- Full lobby → game → game over → lobby cycle

### Phase 7: Assets & Polish
- Character sprites (run/jump/duck animations + icons for all 8 pups)
- Obstacle sprites, parallax backgrounds (Adventure Bay theme)
- UI assets (hearts, logo, buttons)
- Sound effects via flame_audio
- Screen shake on hit, countdown animation (3-2-1-GO)

### Phase 8: Edge Cases & Hardening
- Graceful disconnect handling (mid-game phone disconnect → remove player)
- Host disconnect → controllers show error and return to join
- Haptic feedback on controller phone
- "Play Again" flow
- Responsive layout for different host screen sizes
- Performance test with 8 simultaneous players

---

## Critical Files (in order of importance)

1. **`lib/sensor/motion_detector.dart`** - Core jump/duck detection from body-mounted phone accelerometer
2. **`lib/network/game_server.dart`** - WebSocket server enabling the entire host-controller architecture
3. **`lib/game/paw_patrol_game.dart`** - Flame game root orchestrating all game components
4. **`lib/game/components/player_component.dart`** - Jump physics, collision, animation states
5. **`lib/models/message.dart`** - Host↔Controller protocol contract
6. **`lib/providers/game_provider.dart`** - Bridge between network layer and Flame game

---

## Assets Required

- **32 sprite files**: 8 characters × (run sheet + jump + duck + icon)
- **5 obstacle sprites**: cone, barrel, rock, bird, puddle
- **4 background layers**: sky, mountains, buildings, ground tile
- **4 UI assets**: heart_full, heart_empty, paw_logo, game title
- **6 audio files**: theme music, jump, hit, milestone, game over, countdown
- **1 font**: child-friendly (Fredoka One or Bubblegum Sans from Google Fonts)

Note: PAW Patrol is copyrighted. For personal use, create original cartoon-puppy sprites. For distribution, original art or licensed assets required.

---

## Verification

### Automated Tests
- Unit: model serialization, game state transitions, message protocol
- Widget: screen rendering, character selection, controller buttons
- Game: obstacle spawning, collision detection, jump physics
- Integration: full server↔client flow (join → play → game over)

### Manual Testing Checklist
- Host starts on Windows, QR displays correct local IP
- Android phone scans QR and connects
- iPhone scans QR and connects
- Character selection works, taken characters greyed out
- Auto-start triggers when all players ready (3-2-1 countdown)
- Manual start from controller works (≥1 ready)
- Calibration flow completes: stand still → practice jumps → crouch
- Kid physically jumps → character jumps on host screen
- Kid physically ducks → character ducks on host screen
- No false triggers while standing/walking normally
- Fallback buttons work when sensors unavailable
- Phone detects fall → game auto-pauses
- Collision removes hearts, invincibility frames work
- Game auto-ends when ≤1 player alive
- Manual end from controller works mid-game
- Podium shows correct 1st/2nd/3rd with character icons
- Winner announcement with celebration animation
- Full ranking list displays all players sorted correctly
- Controller shows personal rank + winner info
- "Play Again" returns to lobby correctly
- Phone disconnect handled gracefully
- 4+ players simultaneously without lag

### Develop Mode Testing Checklist
- Toggling dev mode shows red "DEV MODE" banner on host + controllers
- Server always binds to port 8080, room code is `DEV-ROOM`
- QR code remains valid across host restart (same URL)
- Collisions trigger visual feedback but don't eliminate players
- Auto-end is disabled — game keeps running with 0 players alive
- `request_end` from controller still ends the game manually
- Game speed stays at 200 px/s, no difficulty ramp-up
- Only ground obstacles (cones) spawn — no birds
- Host keyboard shortcuts work (Space, 1-8, K, R, T, B)
- Bot player (B key) spawns and randomly jumps
- Debug overlay shows FPS, player count, gameSpeed, elapsed time
- WebSocket messages log to console with timestamps
- Disabling dev mode fully reverts to production behavior

### Performance Targets
- 60 FPS on host with 8 players
- WebSocket latency <50ms on local WiFi
- Input-to-visual response <100ms
