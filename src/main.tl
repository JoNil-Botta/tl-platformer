(import "stdlib/ffi.tl")
(import "wfc.tl")
(import "assets.tl")
(import "physics.tl")
(import "player.tl")
(import "camera.tl")
(import "world.tl")

(import "game_state.tl")
(import "items.tl")
(import "enemies.tl")

;; Counter for question block hits (every 5th spawns a 1-UP)
(define question-hits : i64
  (cast 0 : i64))

(extern (InitWindow [width : i32] [height : i32] [title : (Ptr u8)]) : unit)
(extern (SetTargetFPS [fps : i32]) : unit)
(extern (WindowShouldClose) : bool)
(extern (BeginDrawing) : unit)
(extern (EndDrawing) : unit)
(extern (ClearBackground [color : Color]) : unit)
(extern (DrawText
  [text : (Ptr u8)]
  [posX : i32]
  [posY : i32]
  [fontSize : i32]
  [color : Color]) : unit)
(extern (IsKeyDown [key : i32]) : bool)
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

(define TILE-F : f32
  (cast TILE-SIZE : f32))

(define (draw) : unit
  (begin
    (BeginDrawing)
    (ClearBackground
      (Color (cast 135 : u8) (cast 206 : u8) (cast 235 : u8) (cast 255 : u8)))
    ;; Draw visible tiles only (cull off-screen)
    (let
      [start-col : i64 (floor-div (cast camera-x : i64) TILE-SIZE)]
      [end-col : i64 (+ (+ start-col (floor-div (cast SCREEN-W : i64) TILE-SIZE)) 2)]
      [start-row : i64 (floor-div (cast camera-y : i64) TILE-SIZE)]
      [end-row : i64 (+ (+ start-row (floor-div (cast SCREEN-H : i64) TILE-SIZE)) 2)]
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
            (when (struct-get e alive)
              (draw-enemy (struct-get e x) (struct-get e y) TILE-F)))
          (set! i (+ i 1)))))
    ;; Draw visible mushrooms
    (let
      [i : i64 0]
      (while (< i mushroom-count)
        (begin
          (let
            [m : Mushroom (array-ref mushrooms i)]
            (when (struct-get m active)
              (draw-mushroom (struct-get m x) (struct-get m y))))
          (set! i (+ i 1)))))
    ;; Draw visible coins
    (let
      [i : i64 0]
      (while (< i coin-count)
        (begin
          (let
            [c : Coin (array-ref coins i)]
            (when (struct-get c active)
              (draw-coin (struct-get c x) (struct-get c y))))
          (set! i (+ i 1)))))
    ;; Draw visible 1-UP mushrooms
    (let
      [i : i64 0]
      (while (< i oneup-count)
        (begin
          (let
            [o : OneUp (array-ref oneups i)]
            (when (struct-get o active)
              (draw-oneup (struct-get o x) (struct-get o y))))
          (set! i (+ i 1)))))
    ;; Draw player
    (draw-player px py TILE-F)
    ;; HUD: title + score + lives + time
    (DrawText
      (ffi-cstr "tl-platformer")
      (cast 12 : i32)
      (cast 12 : i32)
      (cast 20 : i32)
      (Color (cast 30 : u8) (cast 30 : u8) (cast 30 : u8) (cast 255 : u8)))
    (DrawText
      (ffi-cstr "SCORE: ")
      (cast 12 : i32)
      (cast 36 : i32)
      (cast 16 : i32)
      (Color (cast 30 : u8) (cast 30 : u8) (cast 30 : u8) (cast 255 : u8)))
    (DrawText
      (ffi-cstr "LIVES: ")
      (cast 12 : i32)
      (cast 54 : i32)
      (cast 16 : i32)
      (Color (cast 30 : u8) (cast 30 : u8) (cast 30 : u8) (cast 255 : u8)))
    (DrawText
      (ffi-cstr "TIME: ")
      (cast 12 : i32)
      (cast 72 : i32)
      (cast 16 : i32)
      (Color (cast 30 : u8) (cast 30 : u8) (cast 30 : u8) (cast 255 : u8)))
    ;; Game over overlay
    (when (is-game-over?)
      (begin
        (DrawText
          (ffi-cstr "GAME OVER")
          (cast 200 : i32)
          (cast 200 : i32)
          (cast 40 : i32)
          (Color (cast 200 : u8) (cast 50 : u8) (cast 50 : u8) (cast 255 : u8)))
        (DrawText
          (ffi-cstr "Press R to restart")
          (cast 220 : i32)
          (cast 260 : i32)
          (cast 20 : i32)
          (Color (cast 30 : u8) (cast 30 : u8) (cast 30 : u8) (cast 255 : u8)))))
    (EndDrawing)))

(define (main) : i64
  (begin
    ;; Generate level using WFC with fixed seed (vary per level later)
    (let
      [wfc-success : bool (wfc-generate wfc-grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))]
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
    (game-reset)
    (set! question-hits 0)
    ;; Initialize camera centered on player start
    (camera-init START-X START-Y SCREEN-W-F SCREEN-H-F)
    (InitWindow
      (cast SCREEN-W : i32)
      (cast SCREEN-H : i32)
      (ffi-cstr "tl-platformer"))
    (SetTargetFPS (cast 60 : i32))
    (load-assets)
    (while (not (WindowShouldClose))
      (begin
        (let
          [dt : f64 (cast (GetFrameTime) : f64)]
          (begin
            (when (is-playing?)
              (begin
                (player-update
              dt
              (IsKeyDown KEY_LEFT)
              (IsKeyDown KEY_RIGHT)
              (IsKeyDown KEY_SPACE)
              level
              LEVEL-COLS
              LEVEL-ROWS)
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
            ;; Check for question block hit and spawn mushroom or 1-UP
            (when player-hit-ceiling
              (begin
                (when (hit-question-block level LEVEL-COLS LEVEL-ROWS px py)
                  (begin
                    (set! question-hits (+ question-hits 1))
                    (if (= (% question-hits 5) 0)
                      (oneup-spawn px (- py (* TILE-SIZE-F 1.5)))
                      (mushroom-spawn px (- py (* TILE-SIZE-F 1.5))))
                    unit))
                unit))
            (set! player-hit-ceiling false)
            ;; Check coin collection
            (coins-collect px py)
            ;; Check mushroom collection
            (mushrooms-collect px py)
            ;; Check 1-UP collection
            (oneups-collect px py)
            ;; Update 1-UP mushrooms
            (oneups-update dt level LEVEL-COLS LEVEL-ROWS)
            ;; Update timer
            (let
              [time-out : bool (timer-update dt)]
              (when time-out
                (begin
                  (player-die)
                  unit)))
            ;; Check player-enemy collision
            (let
              [collision : i64 (player-enemy-collide px py vy)]
              (begin
                (when (= collision 1)
                  ;; Stomp: bounce player up
                  (set! vy (* JUMP-VEL 0.5)))
                (when (= collision 2)
                  ;; Side hit: player dies
                  (begin
                    (player-die)
                    unit))))
            ;; Check for pit death
            (when (> py WORLD-H)
              (begin
                (player-die)
                unit))
            ;; Check for goal
            (when (reached-goal? px py)
              (begin
                (set! score (+ score (timer-bonus)))
                (player-reset)))))
            ;; Reset / restart on R key
            (when (IsKeyDown KEY_R)
              (begin
                (mushrooms-init)
                (oneups-init)
                (if (is-game-over?)
                  (game-reset)
                  (player-reset))
                (set! question-hits 0)))))
        (draw)))
    (unload-assets)
    (CloseWindow)
    0))
