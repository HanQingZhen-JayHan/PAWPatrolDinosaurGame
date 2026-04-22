# Pup Dash — Project Guide

Flutter multiplayer endless runner. Host (PC/TV browser) renders the game; phones connect via QR code and use accelerometer sensors as controllers. Networking is done through Firebase Realtime Database so any phone on any network can join.

Live at: **https://hanqingzhen-jayhan.github.io/PAWPatrolDinosaurGame/**

---

## Stack

- **Flutter web** (primary target) — both host and controller run in browsers
- **Flame** 1.21 for the 2D game engine
- **Firebase Realtime Database** for room state & messaging (no WebSocket server)
- **sensors_plus** for phone accelerometer (via DeviceMotion API on web)
- **qr_flutter** for room QR codes
- **provider** for state management

GitHub Pages serves the web build from `/docs`.

Firebase project: `pupdash-e2a07` (config is in [lib/firebase_options.dart](lib/firebase_options.dart); it's a public web key so committing it is fine — the database is gated by security rules, not the apiKey).

---

## Architecture

```
Host browser (GameScreen)                  Phone browser (ControllerScreen)
     │                                              │
     │  writes /state, /players, /broadcast         │  writes /inputs/<id>
     │  reads /inputs/<id>                          │  reads /state, /broadcast, /players/<id>
     ▼                                              ▼
     ╰─────── Firebase Realtime Database ───────────╯
              /rooms/<ROOM_CODE>/
                  state/    - phase, countdown, gameSpeed
                  players/  - name, character, lives, score, ready, alive
                  inputs/   - per-player action messages (jump/duck)
                  broadcast/- host → all-players messages (lobbyUpdate, gameOver…)
                  messages/ - host → single-player messages (hit, eliminated)
```

### Message protocol

Abstract over transport — same `GameMessage` shape that WebSockets used. See [lib/models/message.dart](lib/models/message.dart) and [lib/network/firebase_room_host.dart](lib/network/firebase_room_host.dart) / [lib/network/firebase_room_client.dart](lib/network/firebase_room_client.dart).

- Controller → Host: `join`, `select_character`, `ready`, `input(action)`, `request_start`, `request_end`, `leave`
- Host → Controller: `joined`, `character_confirmed`, `lobby_update`, `game_starting(countdown)`, `game_started`, `hit(livesRemaining)`, `eliminated(finalScore)`, `score_update`, `game_over(rankings)`

### Flame ↔ Provider bridge

- [GameProvider](lib/providers/game_provider.dart) owns the authoritative `GameStateModel` and the Firebase room
- [PupDashGame](lib/game/pup_dash_game.dart) is the Flame root; it subscribes to provider callbacks (`onPlayerInput`, `onGameRestart`) and writes player scores/lives back through `gameProvider.updateScore()` / `playerHit()`
- The Flame `update()` loop runs only while `state.phase == playing` — scores freeze on game over

---

## Gameplay mechanics

- **Forward-by-jump**: character drifts backward (`backwardDriftSpeed`) while on ground; jumping gives persistent forward velocity (`jumpForwardVelocity`) that's kept on landing. X is clamped between `minPlayerX` and `55% * screenWidth`.
- **Jump arc**: `jumpVelocity=-640`, `gravity=850` → peak ~240px (2× character), airtime ~1.5s
- **Easy mode**: first 180s of each game uses slower speed (`easyModeSpeed=150`), sparser obstacles, ground-only (no birds)
- **Scoring**: +1 per obstacle that moves past an alive player's right edge (tracked via `ObstacleComponent.scoredBy`)
- **Visual jump-zone indicator**: green ground-strip in front of each player; glows red with a pulsing arrow as an obstacle approaches ([lib/game/components/jump_zone_indicator.dart](lib/game/components/jump_zone_indicator.dart))
- **Lives**: 5 hearts per player, game ends when ≤1 alive
- **Restart**: `restartGame()` resets scores/lives but keeps players ready and triggers `onGameRestart` so Flame clears obstacles and un-eliminates PlayerComponents

---

## Controller UX (phone)

- Scanning the room QR opens `https://.../?room=ABCD` which auto-routes to the join screen with the code pre-filled ([lib/main.dart](lib/main.dart))
- Flow: Join → Character Select → Calibration → ControllerScreen (auto-ready + sensors start on mount — no buttons)
- iOS requires a user-gesture-triggered `DeviceMotionEvent.requestPermission()`; this is invoked from the "Start Calibration" button via JS interop ([lib/screens/calibration_screen.dart](lib/screens/calibration_screen.dart))
- Screen Wake Lock is acquired on ControllerScreen mount so the phone doesn't dim/lock mid-game
- Default calibration thresholds: `jumpThreshold=2.0`, `duckThreshold=1.0` (low-pass filtered Y-axis accelerometer)
- Host can kick a player via the × button in the HUD / lobby; Firebase `onDisconnect` also auto-removes a player when their tab closes

---

## Character assets

- [PupCharacter](lib/constants/characters.dart) enum has 8 pups. Each has an emoji + color + optional image asset at `assets/images/characters/<name>_icon.png`.
- `PupCharacter._withIcon` lists which characters have image files committed. Currently: `skye`, `marshall`. Adding more = download PNG to the right path + add the name to the set.
- [CharacterIcon](lib/widgets/character_icon.dart) is the Flutter widget used across screens — image if available, emoji fallback.
- In-game (Flame) PlayerComponent loads the same asset as a `Sprite` in `onLoad()` and falls back to vector art.

---

## Commands

Build & deploy web (must be run from `e:/AI/Games/PAWPatrol`):

```bash
flutter analyze                # must be clean before committing
flutter test                   # splash screen widget test

# Build web for GitHub Pages. MSYS_NO_PATHCONV prevents git-bash
# from rewriting the base-href into a Windows path.
MSYS_NO_PATHCONV=1 flutter build web --release --base-href "/PAWPatrolDinosaurGame/"

# Deploy: GitHub Pages is configured to serve from master / /docs
rm -rf docs && cp -r build/web docs && touch docs/.nojekyll
git add -A && git commit -m "..."
git push
```

Local run:
```bash
flutter run -d windows            # host testing
flutter run -d chrome             # either mode in browser
```

---

## Conventions

- **Do not trust IDE diagnostics as ground truth.** The `<ide_diagnostics>` block often reports stale errors for imports/classes that were just added. Always run `flutter analyze` before believing a diagnostic.
- **JS interop declarations** (`@JS('fnName') external …`) must appear **after** all `import` statements — they're top-level declarations, and Dart rejects imports after declarations.
- **Firebase writes are eventually-consistent.** Phones may receive broadcasts in any order; don't rely on ordering. Idempotent handlers are safer.
- **Navigation guards**: both [ControllerScreen](lib/screens/controller_screen.dart) and [GameOverResultScreen](lib/screens/game_over_result_screen.dart) use one-shot flags (`_navigatedToResults`, `_navigatedBack`) to prevent duplicate `pushReplacement` calls — don't remove them.
- **Web sensors on iOS** only work after a user-gesture-initiated permission prompt; keep the calibration button as that prompt trigger.

---

## Dev mode

Toggle at runtime with the **Dev Mode** switch on the [Mode Select screen](lib/screens/mode_select_screen.dart) (bottom-right corner), or preload it with `--dart-define=DEV_MODE=true`. State lives in [lib/constants/dev_config.dart](lib/constants/dev_config.dart) as a `ValueNotifier<bool>` so UI reacts to changes.

When `DevConfig.enabled` is true:

- **Fixed room code** `DEV1` so the host QR stays valid across restarts
- **Players never die** — lives pinned at 99, elimination suppressed in [GameProvider.playerHit](lib/providers/game_provider.dart)
- **Game never auto-ends** — `_checkGameEnd` early-returns (controllers can still call `requestEnd`)
- **Difficulty locked to easy** — [DifficultySystem](lib/game/systems/difficulty_system.dart) stays at `DevConfig.easyGameSpeed` forever; [ObstacleManager](lib/game/managers/obstacle_manager.dart) keeps easy-mode spawn rate
- **Visible banner** — [DevModeBanner](lib/widgets/dev_mode_banner.dart) wraps screens to show an on-screen indicator

Use it to iterate on game logic without having to survive a full round.

## Known limitations

- Screen Wake Lock prevents the phone from dimming, but browsers still fully suspend the tab when the screen is **actually** off. No JS workaround — would need a native app.
- PAW Patrol character art is copyrighted by Spin Master. The two committed icons are fine for personal/local use but shouldn't be shipped commercially.
- Firebase Spark (free) plan caps at 100 simultaneous connections — easily enough for any number of game rooms in practice.
