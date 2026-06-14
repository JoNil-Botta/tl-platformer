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

## Phase 1: Solid Foundation (Next)

### Physics
- [ ] Horizontal collision (walls, platforms from sides)
- [ ] Ceiling collision (bonk head on blocks)
- [ ] Proper AABB collision instead of point sampling
- [ ] Coyote time (grace period for jumping after leaving ground)
- [ ] Jump buffering (queue jump input before landing)
- [ ] Variable jump height (hold space = higher)

### Camera
- [ ] Smooth follow camera with lookahead
- [ ] Camera bounds (don't show below level)

### Level Structure
- [ ] Fixed-width levels with start and goal (flag pole)
- [ ] WFC generates terrain; hand-placed start/goal zones
- [ ] Scrolling instead of single screen

## Phase 2: Gameplay Loop

### Enemies
- [ ] Basic enemy types with simple patrol AI
  - Ground-pounder: walks back and forth, falls off edges
  - Charger: walks, turns at edges
- [ ] Player-enemy collision (stomp to kill, side hit = damage)
- [ ] Enemy spawn system tied to WFC generation

### Items & Collectibles
- [ ] Coins (collect for score)
- [ ] Power-up blocks (question blocks that spawn items)
- [ ] Mushroom power-up (grow big, take extra hit)
- [ ] 1-UP mushroom (extra life)

### Game State
- [ ] Lives system (3 lives default)
- [ ] Score tracking (coins, enemy kills, time bonus)
- [ ] Timer (countdown, bonus for finishing fast)
- [ ] Death and respawn (fall in pit = death)
- [ ] Game over screen

## Phase 3: Procedural Worlds

### WFC Expansion
- [ ] Multiple tile types: ground, brick, question block, pipe, empty
- [ ] Adjacency rules for pipe placement (vertical stacks)
- [ ] Question blocks only placed where reachable
- [ ] Secret areas (hidden coin caches)

### Biomes
- [ ] Overworld (grass, blue sky)
- [ ] Underground (dark, limited visibility)
- [ ] Castle (lava hazards, harder enemies)
- [ ] Biome-specific tilesets and background colors

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

## Technical Constraints & Opportunities

TypeLisp is a developing language. We should:
- Push the language where it hurts and file issues (#2973, #2974, #2975 so far)
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
tests/
  test_wfc.tl      # WFC generation tests
  test_physics.tl  # Collision tests
```

## Immediate Next Steps

1. **Extract player into `player.tl`** — decouple from main
2. **Add horizontal collision** — `physics.tl` with AABB
3. **Camera follow** — simple offset tracking player
4. **Flag pole goal** — win condition, level complete screen
5. **Basic enemy** — one type, patrol AI, stomp to kill

## Notes

- Raylib handles windowing, input, textures, drawing
- TypeLisp handles all game logic
- WFC runs at level start; deterministic per seed
- Keep each file under ~300 lines for readability
- Prefer `begin` blocks over deeply nested `let` chains
