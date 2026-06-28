(import "stdlib/ffi.tl")
(import "wfc.tl")
(import "assets.tl")
(import "physics.tl")
(import "player.tl")
(import "camera.tl")
(import "world.tl")
(import "ui.tl")
(import "game_state.tl")
(import "items.tl")
(import "enemies.tl")
(import "level_progression.tl")
(import "screen_shake.tl")
(import "particles.tl")
(import "audio.tl")
(import "high_score.tl")

;; Counter for question block hits (every 5th spawns a 1-UP)
(define question-hits : i64
  (cast 0 : i64))

;; Biome switch cooldown (seconds)
(define biome-cooldown : f64
  0.0)

;; Pending transition for fade system (0=none, 1=start, 2=next-level, 3=next-world, 4=restart)
(define pending-transition : i64
  (cast 0 : i64))

;; Previous frame jump input (for detecting rising edge)
(define prev-jump-input : bool
  false)

;; Track whether high score has been updated for this game over
(define high-score-checked : bool
  false)

(extern (InitWindow [width : i32] [height : i32] [title : (Ptr u8)]) : unit)
(extern (SetTargetFPS [fps : i32]) : unit)
(extern (WindowShouldClose) : bool)
(extern (BeginDrawing) : unit)
(extern (EndDrawing) : unit)
(extern (ClearBackground [color : Color]) : unit)
(extern (IsKeyDown [key : i32]) : bool)
(extern (IsKeyPressed [key : i32]) : bool)
(extern (GetFrameTime) : f32)
(extern (CloseWindow) : unit)

(define KEY_RIGHT : i32
  (cast 262 : i32))
(define KEY_LEFT : i32
  (cast 263 : i32))
(define KEY_SPACE : i32
  (cast 32 : i32))
(define KEY_R : i32
  (cast 82 : i32))
(define KEY_B : i32
  (cast 66 : i32))
(define KEY_ENTER : i32
  (cast 257 : i32))
(define KEY_P : i32
  (cast 80 : i32))

;; Generate level for current world/level: WFC, biome, enemies, coins, timer
(define (generate-current-level) : unit
  (begin
    ;; Generate level using WFC with deterministic seed from progression
    (let
      [seed : i64 (level-seed)]
      [wfc-success : bool (wfc-generate wfc-grid LEVEL-COLS LEVEL-ROWS seed)]
      (begin
        (if wfc-success
          (wfc-to-level wfc-grid level LEVEL-COLS LEVEL-ROWS)
          (begin
            ;; Fallback: clear level and create simple ground
            (let
              [i : i64 0]
              (while (< i LEVEL-SIZE)
                (begin
                  (array-set! level i 0)
                  (set! i (+ i 1)))))
            (let
              [c : i64 0]
              (while (< c LEVEL-COLS)
                (begin
                  (array-set! level (level-idx (- LEVEL-ROWS 1) c) 1)
                  (set! c (+ c 1)))))))))
    ;; Set biome for this level
    (set! current-biome (current-level-biome))
    ;; Spawn enemies with difficulty-scaled spacing
    (enemies-spawn-in-level-with-spacing
      level
      LEVEL-COLS
      LEVEL-ROWS
      (level-enemy-spacing))
    ;; Spawn coins and secrets
    (coins-spawn-in-level level LEVEL-COLS LEVEL-ROWS)
    (coins-spawn-secrets level LEVEL-COLS LEVEL-ROWS)
    ;; Reset items
    (mushrooms-init)
    (oneups-init)
    (particles-init)
    (set! question-hits 0)
    ;; Reset player and camera
    (player-reset)
    (camera-init START-X START-Y SCREEN-W-F SCREEN-H-F)
    ;; Set timer for this level
    (apply-timer-duration (level-timer-duration))
    ;; NOTE: caller must set game state (e.g., start-new-level or fade)
    unit))

(define TILE-F : f32
  (cast TILE-SIZE : f32))

(define (draw-gameplay) : unit
  (begin
    ;; Draw visible tiles only (cull off-screen)
    (let
      [start-col : i64 (floor-div (cast camera-x : i64) TILE-SIZE)]
      [end-col : i64
        (+ (+ start-col (floor-div (cast SCREEN-W : i64) TILE-SIZE)) 2)]
      [start-row : i64 (floor-div (cast camera-y : i64) TILE-SIZE)]
      [end-row : i64
        (+ (+ start-row (floor-div (cast SCREEN-H : i64) TILE-SIZE)) 2)]
      (begin
        (when (< start-col 0) (set! start-col 0))
        (when (> end-col LEVEL-COLS) (set! end-col LEVEL-COLS))
        (when (< start-row 0) (set! start-row 0))
        (when (> end-row LEVEL-ROWS) (set! end-row LEVEL-ROWS))
        (let
          [row : i64 start-row]
          (while (< row end-row)
            (begin
              (let
                [col : i64 start-col]
                (while (< col end-col)
                  (begin
                    (draw-tile
                      (cast (* col TILE-SIZE) : f64)
                      (cast (* row TILE-SIZE) : f64)
                      TILE-F
                      (array-ref level (level-idx row col)))
                    (set! col (+ col 1)))))
              (set! row (+ row 1)))))))
    ;; Draw goal flag
    (draw-goal GOAL-X GOAL-Y TILE-F)
    ;; Draw visible enemies
    (let
      [i : i64 0]
      (while (< i enemy-count)
        (begin
          (let
            [e : Enemy (array-ref enemies i)]
            (when
              (struct-get e alive)
              (draw-enemy (struct-get e x) (struct-get e y) TILE-F)))
          (set! i (+ i 1)))))
    ;; Draw visible mushrooms
    (let
      [i : i64 0]
      (while (< i mushroom-count)
        (begin
          (let
            [m : Mushroom (array-ref mushrooms i)]
            (when
              (struct-get m active)
              (draw-mushroom (struct-get m x) (struct-get m y))))
          (set! i (+ i 1)))))
    ;; Draw visible coins
    (let
      [i : i64 0]
      (while (< i coin-count)
        (begin
          (let
            [c : Coin (array-ref coins i)]
            (when
              (struct-get c active)
              (draw-coin (struct-get c x) (struct-get c y))))
          (set! i (+ i 1)))))
    ;; Draw visible 1-UP mushrooms
    (let
      [i : i64 0]
      (while (< i oneup-count)
        (begin
          (let
            [o : OneUp (array-ref oneups i)]
            (when
              (struct-get o active)
              (draw-oneup (struct-get o x) (struct-get o y))))
          (set! i (+ i 1)))))
    ;; Draw player
    (draw-player px py TILE-F)
    ;; Draw particles (on top of gameplay, below HUD)
    (draw-particles)
    ;; HUD with actual values
    (draw-hud
      score
      coins-collected
      lives
      (cast time-remaining : i64)
      current-world
      current-level
      (cast SCREEN-W : i64))))

(define (draw) : unit
  (begin
    (BeginDrawing)
    (cond
      [(is-title?)
       (begin
         (ClearBackground
           (Color (cast 20 : u8) (cast 20 : u8) (cast 30 : u8) (cast 255 : u8)))
         (draw-title-screen (cast SCREEN-W : i64) (get-high-score)))]
      [(is-map?)
       (draw-world-map (cast SCREEN-W : i64) (cast SCREEN-H : i64) current-world current-level)]
      [else
       (begin
         (ClearBackground (biome-background-color))
         (draw-gameplay)
         (when (is-paused?) (draw-pause-screen SCREEN-W SCREEN-H))
         (when
           (is-level-complete?)
           (begin
             (DrawText
               (ffi-cstr "LEVEL COMPLETE")
               (cast 180 : i32)
               (cast 200 : i32)
               (cast 40 : i32)
               (Color
                 (cast 50 : u8)
                 (cast 200 : u8)
                 (cast 50 : u8)
                 (cast 255 : u8)))
             (DrawText
               (ffi-cstr "Press ENTER to continue")
               (cast 200 : i32)
               (cast 260 : i32)
               (cast 20 : i32)
               (Color
                 (cast 30 : u8)
                 (cast 30 : u8)
                 (cast 30 : u8)
                 (cast 255 : u8)))))
         (when
           (is-world-complete?)
           (begin
             (DrawText
               (ffi-cstr "WORLD COMPLETE")
               (cast 180 : i32)
               (cast 200 : i32)
               (cast 40 : i32)
               (Color
                 (cast 50 : u8)
                 (cast 200 : u8)
                 (cast 50 : u8)
                 (cast 255 : u8)))
             (DrawText
               (ffi-cstr "Press ENTER for next world")
               (cast 190 : i32)
               (cast 260 : i32)
               (cast 20 : i32)
               (Color
                 (cast 30 : u8)
                 (cast 30 : u8)
                 (cast 30 : u8)
                 (cast 255 : u8)))))
         (when
           (is-game-over?)
           (begin
             (DrawText
               (ffi-cstr "GAME OVER")
               (cast 200 : i32)
               (cast 200 : i32)
               (cast 40 : i32)
               (Color
                 (cast 200 : u8)
                 (cast 50 : u8)
                 (cast 50 : u8)
                 (cast 255 : u8)))
             (DrawText
               (ffi-cstr "Press R to restart")
               (cast 220 : i32)
               (cast 260 : i32)
               (cast 20 : i32)
               (Color
                 (cast 30 : u8)
                 (cast 30 : u8)
                 (cast 30 : u8)
                 (cast 255 : u8)))
             (DrawText
               (ffi-cstr "HIGH SCORE:")
               (cast 260 : i32)
               (cast 300 : i32)
               (cast 16 : i32)
               (Color
                 (cast 180 : u8)
                 (cast 180 : u8)
                 (cast 180 : u8)
                 (cast 255 : u8)))
             (DrawText
               (ffi-cstr (int->string (get-high-score)))
               (cast 300 : i32)
               (cast 320 : i32)
               (cast 20 : i32)
               (Color
                 (cast 255 : u8)
                 (cast 220 : u8)
                 (cast 40 : u8)
                 (cast 255 : u8))))))])
    (draw-fade (get-fade-alpha) SCREEN-W SCREEN-H)
    (EndDrawing)))

;; Track previous frame's on-ground for landing detection
(define was-on-ground : bool
  false)

(define (main) : i64
  (begin
    ;; Load high score if it exists
    (high-score-load)
    ;; Generate level using WFC with fixed seed (vary per level later)
    (let
      [wfc-success : bool
        (wfc-generate wfc-grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))]
      (begin
        (if wfc-success
          (wfc-to-level wfc-grid level LEVEL-COLS LEVEL-ROWS)
          (begin
            ;; Fallback: clear level and create simple ground
            (let
              [i : i64 0]
              (while (< i LEVEL-SIZE)
                (begin
                  (array-set! level i 0)
                  (set! i (+ i 1)))))
            (let
              [c : i64 0]
              (while (< c LEVEL-COLS)
                (begin
                  (array-set! level (level-idx (- LEVEL-ROWS 1) c) 1)
                  (set! c (+ c 1)))))))))
    ;; Spawn enemies, coins, and mushrooms based on generated level
    (enemies-spawn-in-level level LEVEL-COLS LEVEL-ROWS)
    (coins-spawn-in-level level LEVEL-COLS LEVEL-ROWS)
    (coins-spawn-secrets level LEVEL-COLS LEVEL-ROWS)
    (mushrooms-init)
    (oneups-init)
    (score-reset)
    (set-title-screen)
    (set! question-hits 0)
    ;; Initialize camera centered on player start
    (camera-init START-X START-Y SCREEN-W-F SCREEN-H-F)
    (set! was-on-ground false)
    (shake-reset)
    (InitWindow
      (cast SCREEN-W : i32)
      (cast SCREEN-H : i32)
      (ffi-cstr "tl-platformer"))
    (SetTargetFPS (cast 60 : i32))
    (load-assets)
    (audio-init)
    (while (not (WindowShouldClose))
      (begin
        (let
          [dt : f64 (cast (GetFrameTime) : f64)]
          (begin
            ;; Update fade transitions
            (when (is-fading-out?)
              (when (update-fade dt)
                (begin
                  ;; Fade out complete — execute pending transition
                  (cond
                    [(= pending-transition 1)
                     (begin
                       (show-map)
                       (set! fade-alpha 0.0)
                       (set! pending-transition 0))]
                    [(= pending-transition 2)
                     (begin
                       (show-map)
                       (set! fade-alpha 0.0)
                       (set! pending-transition 0))]
                    [(= pending-transition 3)
                     (begin
                       (show-map)
                       (set! fade-alpha 0.0)
                       (set! pending-transition 0))]
                    [(= pending-transition 4)
                     (begin
                       (reset-progression)
                       (game-reset)
                       (score-reset)
                       (show-map)
                       (set! fade-alpha 0.0)
                       (set! pending-transition 0))]
                    [(= pending-transition 5)
                     (begin
                       (generate-current-level)
                       (start-fade-in))]
                    [else unit])
                  (set! pending-transition 0))))
            (when (is-fading-in?)
              (when (update-fade dt)
                (start-new-level)))
            ;; Update screen shake
            (update-shake dt)
            ;; State-specific update and input
            (cond
              [(is-title?)
               (when (IsKeyPressed KEY_ENTER)
                 (begin
                   (reset-progression)
                   (score-reset)
                   (set! lives START-LIVES)
                   (set! pending-transition 1)
                   (start-fade-out)))]
              [(is-playing?)
               (begin
                 (when (IsKeyPressed KEY_P)
                   (pause-game))
                 (if (is-player-dying?)
                   ;; Death animation running
                   (begin
                     (if (player-update-death dt)
                       (begin
                         (player-die)
                         unit)
                       unit)
                     unit)
                   ;; Normal gameplay
                   (begin
                     ;; Detect jump edge and play sound
                 (let
                   [jump-now : bool (IsKeyDown KEY_SPACE)]
                   [jump-pressed : bool (and jump-now (not prev-jump-input))]
                   (begin
                     (when jump-pressed (play-jump))
                     (player-update
                       dt
                       (IsKeyDown KEY_LEFT)
                       (IsKeyDown KEY_RIGHT)
                       jump-now
                       level
                       LEVEL-COLS
                       LEVEL-ROWS)
                     (set! prev-jump-input jump-now)))
                 (update-player-anim dt vx vy on-ground)
                 (camera-update
                   dt
                   px
                   py
                   vx
                   SCREEN-W-F
                   SCREEN-H-F
                   WORLD-W
                   WORLD-H)
                 (enemies-update dt level LEVEL-COLS LEVEL-ROWS)
                 (mushrooms-update dt level LEVEL-COLS LEVEL-ROWS)
                 (particles-update dt)
                 ;; Check landing from height (was in air, now on ground, moving down fast)
                 (when
                   (and (not was-on-ground) on-ground (> vy 200.0))
                   (begin
                     (trigger-shake SHAKE-SMALL 0.15)
                     (spawn-dust px py)))
                 (set! was-on-ground on-ground)
                 ;; Check for question block hit and spawn mushroom or 1-UP
                 (when player-hit-ceiling
                   (begin
                     (when (hit-question-block level LEVEL-COLS LEVEL-ROWS px py)
                       (begin
                         (play-bump)
                         (set! question-hits (+ question-hits 1))
                         (if (= (% question-hits 5) 0)
                           (oneup-spawn px (- py (* TILE-SIZE-F 1.5)))
                           (mushroom-spawn px (- py (* TILE-SIZE-F 1.5))))
                         unit))
                     unit))
                 (set! player-hit-ceiling false)
                 ;; Check coin collection
                 (let
                   [coins-collected : i64 (coins-collect px py)]
                   (when (> coins-collected 0)
                     (begin
                       (play-coin)
                       (spawn-coin-sparkle px py))))
                 ;; Check mushroom collection
                 (when (mushrooms-collect px py)
                   (play-powerup))
                 ;; Check 1-UP collection
                 (when (oneups-collect px py)
                   (play-oneup))
                 ;; Update 1-UP mushrooms
                 (oneups-update dt level LEVEL-COLS LEVEL-ROWS)
                 ;; Update timer
                 (let
                   [time-out : bool (timer-update dt)]
                   (when time-out
                     (begin
                       (play-death)
                       (player-start-death)
                       unit)))
                 ;; Check player-enemy collision
                 (let
                   [collision : i64 (player-enemy-collide px py vy)]
                   (begin
                     (when (= collision 1)
                       ;; Stomp: bounce player up + screen shake + particles + sound
                       (begin
                         (play-stomp)
                         (set! vy (* JUMP-VEL 0.5))
                         (trigger-shake SHAKE-MEDIUM 0.2)
                         (spawn-stomp-burst px py)))
                     (when (= collision 2)
                       ;; Side hit: player dies + strong shake + sound
                       (begin
                         (play-death)
                         (player-start-death)
                         (trigger-shake SHAKE-LARGE 0.35)
                         unit))))
                 ;; Check for pit death
                 (when (> py WORLD-H)
                   (begin
                     (play-death)
                     (player-start-death)
                     (trigger-shake SHAKE-LARGE 0.4)
                     unit))
                 ;; Check for goal
                 (when (reached-goal? px py)
                   (begin
                     (set! score (+ score (timer-bonus)))
                     (if (< current-level LEVELS-PER-WORLD)
                       (level-complete)
                       (world-complete)))))))]
              [(is-paused?)
               (when (IsKeyPressed KEY_P)
                 (resume-game))]
              [(is-level-complete?)
               (begin
                 (update-level-transition dt)
                 (when (IsKeyPressed KEY_ENTER)
                   (begin
                     (next-level)
                     (set! pending-transition 2)
                     (start-fade-out))))]
              [(is-world-complete?)
               (begin
                 (update-level-transition dt)
                 (when (IsKeyPressed KEY_ENTER)
                   (begin
                     (next-world)
                     (set! pending-transition 3)
                     (start-fade-out))))]
              [(is-map?)
               (when (IsKeyPressed KEY_ENTER)
                 (begin
                   (set! pending-transition 5)
                   (start-fade-out)))]
              [(is-game-over?)
               (begin
                 (when (not high-score-checked)
                   (begin
                     (high-score-update score)
                     (set! high-score-checked true)))
                 (when (IsKeyPressed KEY_R)
                   (begin
                     (set! high-score-checked false)
                     (set! pending-transition 4)
                     (start-fade-out))))]
              [else unit])
            ;; Cycle biome on B key with cooldown
            (when
              (and (IsKeyDown KEY_B) (<= biome-cooldown 0.0))
              (begin
                (set! current-biome (% (+ current-biome 1) 3))
                (set! biome-cooldown 0.2)))
            (when
              (> biome-cooldown 0.0)
              (set! biome-cooldown (- biome-cooldown dt)))))
        (draw)))
    (unload-assets)
    (audio-shutdown)
    (CloseWindow)
    0))