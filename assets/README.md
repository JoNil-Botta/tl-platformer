# Assets for tl-platformer

This directory contains game assets. The game loads textures from these paths at runtime.

## How to generate assets

Each subdirectory has a `_prompt.md` file with an image generation prompt.
Copy the prompt into your favorite image generator (DALL-E, Midjourney, Stable Diffusion, etc.) and save the result as the specified PNG file.

## Required assets

### Tiles (`assets/tiles/`)
- `ground.png` — 32x32, dirt block with grass top
- `platform.png` — 32x32, floating wooden platform
- `wall.png` — 32x32, stone wall block

### Player (`assets/player/`)
- `spritesheet.png` — 128x128, 4x4 grid of 32x32 frames
  - Row 1: Idle animation (4 frames)
  - Row 2: Run animation (4 frames)
  - Row 3: Jump animation (4 frames)
  - Row 4: Fall animation (4 frames)

## Fallback behavior

If image files are missing, the game renders colored rectangles as placeholders:
- Ground: brown
- Platform: light brown
- Wall: gray
- Player: red

So the game works immediately even without generated art.
