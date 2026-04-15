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
- `join` { playerName } → `input` { action: jump/duck_start/duck_end } → `select_character` { character } → `ready` {}

**Host → Controller:**
- `joined` { playerId } → `character_confirmed` { character } → `game_starting` { countdown } → `hit` { livesRemaining } → `eliminated` { finalScore } → `game_over` { scores }

**Host → All (broadcast):**
- `lobby_update` { players[] } → `score_update` { scores }

---

## Project Structure

```
lib/
├── main.dart                         # Platform detection, provider setup
├── app.dart                          # MaterialApp, routing, theme
├── constants/
│   ├── game_constants.dart           # Speeds, gravity, dimensions
│   ├── characters.dart               # PawCharacter enum + metadata
│   └── theme.dart                    # Child-friendly PAW Patrol theme
├── models/
│   ├── player.dart                   # PlayerData: id, character, score, lives
│   ├── obstacle.dart                 # Obstacle type enum + dimensions
│   ├── game_state.dart               # GameStateModel: phase, players, speed
│   └── message.dart                  # GameMessage: type, payload, JSON codec
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
│   │   └── game_over_overlay.dart    # Game over screen
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
│   ├── controller_screen.dart        # Big JUMP + DUCK buttons
│   └── game_screen.dart              # Flame GameWidget + HUD overlays
└── providers/
    ├── game_provider.dart            # Host: server + game state + Flame bridge
    ├── network_provider.dart         # Connection status tracking
    └── controller_provider.dart      # Controller: client + local state
```

---

## Game Mechanics

### Player
- 8 PAW Patrol characters: Chase, Marshall, Skye, Rubble, Rocky, Zuma, Everest, Tracker
- 3 states: running (default), jumping (tap JUMP), ducking (hold DUCK)
- Jump physics: `velocityY = -600`, `gravity = 1800`, standard parabolic arc
- No double-jump (simplicity for kids)
- 3 lives (hearts), 1.5s invincibility after hit (sprite blinks)
- Eliminated when all hearts lost; character fades out but others continue

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

### Scoring
- Continuous: `score += gameSpeed * dt * 0.1`
- Each player tracked independently
- Game ends when ALL players eliminated

---

## Screen Flow

```
Splash → Mode Select → ┬─ Host Lobby (QR + player list) → Game Screen (Flame + HUD)
                        └─ Join (scan QR) → Character Select → Controller (JUMP/DUCK buttons)
                                                                     ↓
                                                              Game Over → Play Again / Lobby
```

---

## Implementation Phases

### Phase 1: Project Setup & Models
- `flutter create` project, configure `pubspec.yaml` with all dependencies
- Implement all model classes (PawCharacter, PlayerData, GameStateModel, GameMessage)
- Create constants (game_constants.dart, characters.dart, theme.dart)
- Unit tests for model serialization

### Phase 2: Networking Layer
- `network_utils.dart` - local IP discovery, port finding
- `GameServer` - shelf pipeline, WebSocket handler, client management, broadcast/sendTo
- `GameClient` - connect, send, receive, disconnect
- `message_protocol.dart` - message type constants
- Integration test: server ↔ client message exchange

### Phase 3: Screens & Navigation
- `main.dart` with platform detection, Provider setup
- `app.dart` with routing and PAW Patrol theme
- All 7 screens with basic UI (placeholder assets)
- Wire providers so controller join flow works end-to-end

### Phase 4: Flame Game (Single Player First)
- `PawPatrolGame` FlameGame class
- Ground + parallax background components
- `PlayerComponent` with jump/duck physics and rectangle hitbox
- `ObstacleComponent` + `ObstacleManager` for spawning
- Collision detection, HUD overlay (score + hearts)
- Test with keyboard input (space=jump, down=duck)

### Phase 5: Multiplayer Integration
- Wire `GameProvider` to bridge WebSocket inputs → Flame game
- Multi-player rendering with dynamic lane assignment
- Per-player input routing, elimination, game over detection
- Score broadcasting to controllers
- Full lobby → game → game over → lobby cycle

### Phase 6: Assets & Polish
- Character sprites (run/jump/duck animations + icons for all 8 pups)
- Obstacle sprites, parallax backgrounds (Adventure Bay theme)
- UI assets (hearts, logo, buttons)
- Sound effects via flame_audio
- Screen shake on hit, countdown animation (3-2-1-GO)

### Phase 7: Edge Cases & Hardening
- Graceful disconnect handling (mid-game phone disconnect → remove player)
- Host disconnect → controllers show error and return to join
- Haptic feedback on controller phone
- "Play Again" flow
- Responsive layout for different host screen sizes
- Performance test with 8 simultaneous players

---

## Critical Files (in order of importance)

1. **`lib/network/game_server.dart`** - WebSocket server enabling the entire host-controller architecture
2. **`lib/game/paw_patrol_game.dart`** - Flame game root orchestrating all game components
3. **`lib/game/components/player_component.dart`** - Jump physics, collision, animation states
4. **`lib/models/message.dart`** - Host↔Controller protocol contract
5. **`lib/providers/game_provider.dart`** - Bridge between network layer and Flame game

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
- Game starts with countdown
- JUMP/DUCK buttons on phone control character on host
- Collision removes hearts, invincibility frames work
- Player elimination + game over flow
- "Play Again" returns to lobby
- Phone disconnect handled gracefully
- 4+ players simultaneously without lag

### Performance Targets
- 60 FPS on host with 8 players
- WebSocket latency <50ms on local WiFi
- Input-to-visual response <100ms
