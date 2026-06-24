# tl-platformer Game Design Document

A Mario-style 2D platformer built in [TypeLisp](https://github.com/JoNil-Botta/typelisp), compiled to native x86_64. Procedural level generation via Wave Function Collapse. Raylib for rendering.

## Core Vision

Side-scrolling platformer with:
- Tight, responsive platforming physics
- Procedurally generated levels per playthrough
- Enemies, items, coins, secrets
- Multiple biomes (overworld, underground, castle)
- Progressive difficulty curve

## Current State

- [x] Window creation, rendering loop
- [x] Basic player movement (left/right/jump)
- [x] Gravity and ground collision
- [x] WFC-based level generation (simplified)
- [x] Asset loading (textures, sprite sheets)
- [x] Player animation (idle/run/jump/fall)
- [x] Player extracted to `player.tl` with testable update function
- [x] Physics extracted to `physics.tl` with AABB collision
- [x] Coyote time, jump buffering, variable jump height
- [x] `tests/test_player.tl` — 11 tests (movement, jump, coyote, buffer, variable)
- [x] `tests/test_physics.tl` — 11 tests (collision, wall, ground, ceiling, floor-div)

## Phase 1: Solid Foundation (Complete)

### Physics
- [x] Horizontal collision (walls, platforms from sides)
- [x] Ceiling collision (bonk head on blocks)
- [x] Proper AABB collision instead of point sampling
- [x] Coyote time (grace period for jumping after leaving ground)
- [x] Jump buffering (queue jump input before landing)
- [x] Variable jump height (hold space = higher)

### Camera
- [x] Smooth follow camera with lookahead
- [x] Camera bounds (don't show below level)

### Level Structure
- [x] Fixed-width levels with start and goal (flag pole)
- [x] WFC generates terrain; hand-placed start/goal zones
- [x] Scrolling instead of single screen
- [x] Tile culling (only draw visible tiles)

## Phase 2: Gameplay Loop

### Enemies
- [x] Basic enemy types with simple patrol AI
  - Ground-pounder: walks back and forth, falls off edges
  - Charger: walks, turns at edges
- [x] Player-enemy collision (stomp to kill, side hit = damage)
- [x] Enemy spawn system tied to WFC generation

### Items & Collectibles
- [x] Coins (collect for score)
- [x] Power-up blocks (question blocks that spawn items)
- [x] Mushroom power-up (grow big, take extra hit)
- [x] 1-UP mushroom (extra life)

### Game State
- [x] Score tracking (coins, enemy kills, time bonus)
- [x] Lives system (3 lives default)
- [x] Timer (countdown, bonus for finishing fast)
- [x] Death and respawn (fall in pit = death, enemy side-hit = death)
- [x] Game over screen

## Phase 3: Procedural Worlds (In Progress)

### WFC Expansion
- [x] Multiple tile types: ground, brick, question block, pipe, empty
- [x] Adjacency rules for pipe placement (vertical stacks)
- [x] Question blocks only placed where reachable
- [x] Secret areas (hidden coin caches)

### Biomes
- [x] Overworld (grass, blue sky)
- [x] Underground (dark, limited visibility)
- [x] Castle (lava hazards, harder enemies)
- [x] Biome-specific tilesets and background colors

### Level Progression
- [ ] Sequence of levels: 1-1, 1-2, 1-3, 1-4 (castle)
- [ ] Difficulty scaling: more enemies, harder platforming
- [ ] World map (simple node graph between levels)

## Phase 4: Polish

### Audio
- [ ] Jump sound
- [ ] Coin collect sound
- [ ] Enemy stomp sound
- [ ] Background music per biome

### Visual
- [ ] Particle effects (coin sparkle, dust on landing)
- [ ] Screen shake on landing from height
- [ ] Death animation
- [ ] Transitions (fade in/out between levels)

### UI
- [ ] HUD (score, coins, lives, timer, world indicator)
- [ ] Title screen
- [ ] Pause menu
- [ ] High score persistence (simple file I/O)

## Testing Strategy: Simulated Gameplay

Since we can't run a GUI in CI/headless, we test by simulating gameplay without Raylib. Each game module exposes a pure update function that takes a `GameState` struct and an `Input` struct, returning a new `GameState`. Rendering is a separate concern that only reads `GameState`.

### Architecture

```
GameState: player pos/vel, enemies array, coins array, camera offset, level data, score, lives...

Input: left (bool), right (bool), jump (bool), dt (f64)

update-game(state, input) -> state
render-game(state) -> void (Raylib calls, untested in CI)
```

### Testable Modules

| Feature | Simulation Test | File |
|---------|----------------|------|
| Player movement | Apply input, assert position changes | `tests/test_player.tl` |
| Gravity | One frame with no input, assert y increases | `tests/test_player.tl` |
| Ground collision | Player above solid tile, assert y snaps to tile | `tests/test_physics.tl` |
| Wall collision | Walk into wall, assert x unchanged | `tests/test_physics.tl` |
| Coyote time | Walk off ledge, jump within N frames, assert jump works | `tests/test_player.tl` |
| Jump buffer | Press jump before landing, assert jump on next frame | `tests/test_player.tl` |
| Enemy patrol | Spawn enemy, N frames, assert position within range | `tests/test_enemies.tl` |
| Stomp | Player above enemy, assert enemy dead, player bounced | `tests/test_enemies.tl` |
| Side hit | Player beside enemy, assert player damaged | `tests/test_enemies.tl` |
| Coin collect | Overlap coin, assert coin gone, score +1 | `tests/test_items.tl` |
| Power-up | Touch mushroom, assert player big | `tests/test_items.tl` |
| Biome colors | Set biome, assert background and tile colors change | `tests/test_biomes.tl` |
| WFC generation | Generate, assert valid (no contradictions, collapsed) | `tests/test_wfc.tl` |
| Level complete | Reach flag pole, assert win state | `tests/test_world.tl` |
| Death (pit) | y below level, assert lives--, respawn | `tests/test_world.tl` |
| Game over | Lives reach 0, assert game over state | `tests/test_world.tl` |

### Seed-Based Determinism

WFC and enemy spawn use a seeded RNG. Tests pass a fixed seed so the same level is generated every run. This lets us write assertions against specific tile coordinates.

### No Raylib in Tests

Tests import `player.tl`, `physics.tl`, `world.tl` directly — never `assets.tl` or `main.tl`. The pure update functions have no `extern` dependencies. If we need a mock level, we build an `(Array i64)` by hand in the test.

## TypeLisp as a Co-Development Target

We are building the game *and* stress-testing the language. Every feature we add is a chance to find rough edges. **Note: filing issues to the typelisp repo requires Jonathan's approval first.**

### When to File an Issue

- Syntax that feels wrong or inconsistent (e.g. needing `cast` for literals)
- Error messages that don't point to the right location
- Formatter output that doesn't compile
- Missing stdlib functions we'd expect (e.g. `abs`, `min`, `max` for `f64`)
- Performance surprises (compilation too slow, generated code too slow)
- Any crash or assertion failure in the compiler

### Issue Filing Process

1. **Get approval from Jonathan** — since we control the language, issue filing requires explicit approval
2. Create a minimal reproduction in `/tmp/` or a new file
3. Verify it against the latest stage0 (`scripts/fetch-stage0.sh`)
4. Check if it exists in the tracker already
5. File with: title, reproduction steps, expected vs actual behavior, `typelisp --version` output

### Issues Filed So Far

*Filed with Jonathan's explicit approval:*
- #2973 — `define` with explicit scalar type should accept literals without `cast`
- #2974 — Duplicate extern diagnostic should list both source locations
- #2975 — Formatter inserts excessive blank lines between declarations

## Technical Constraints & Opportunities

TypeLisp is a developing language. We should:
- Push the language where it hurts and file issues (see above)
- Avoid features not yet implemented (closures with mutable captures, GC)
- Use arrays for game state (enemies, particles, coins)
- Use FFI for anything Raylib doesn't expose directly

## File Structure

```
src/
  main.tl          # Entry point, game loop, state machine
  player.tl        # Player physics, animation, input
  world.tl         # Level data, scrolling, tile rendering
  wfc.tl           # Wave Function Collapse generator
  enemies.tl       # Enemy types, AI, spawning
  items.tl         # Coins, power-ups, blocks
  assets.tl        # Texture loading, sprite management
  physics.tl       # Collision detection, AABB
  camera.tl        # Camera follow, bounds
  ui.tl            # HUD, menus, text rendering
  audio.tl         # Sound effects, music (future)
  game_state.tl    # GameState struct, update/render split
tests/
  test_wfc.tl      # WFC generation tests
  test_physics.tl  # Collision tests
  test_player.tl   # Player movement, coyote, buffer
  test_enemies.tl  # Enemy AI, stomp, damage
  test_items.tl    # Coin collect, power-ups
  test_biomes.tl   # Biome colors and backgrounds
  test_world.tl    # Level complete, death, respawn
```

## Immediate Next Steps

1. ~~Create `game_state.tl`~~ — `GameState` struct, `Input` struct, pure `update` function (deferred; globals work for now)
2. ~~Extract player into `player.tl`~~ ✅ Done
3. ~~Add `physics.tl`~~ ✅ Done
4. ~~Add `tests/test_player.tl`~~ ✅ Done
5. ~~Add `tests/test_physics.tl`~~ ✅ Done
6. ~~Add `camera.tl`~~ ✅ Done
7. ~~Add `world.tl`~~ ✅ Done
8. ~~Add `tests/test_camera.tl` and `tests/test_world.tl`~~ ✅ Done
9. **Phase 2: Gameplay loop** — enemies, coins, lives/score
10. **Flag any language snags** as issues during the above

## Notes

- Raylib handles windowing, input, textures, drawing
- TypeLisp handles all game logic
- WFC runs at level start; deterministic per seed
- Keep each file under ~300 lines for readability
- Prefer `begin` blocks over deeply nested `let` chains
- Test-first for physics: every collision behavior gets a test before the fix
