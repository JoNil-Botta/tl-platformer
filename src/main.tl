(import "stdlib/ffi.tl")
(import "wfc.tl")
(import "assets.tl")
(import "physics.tl")
(import "player.tl")

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

(define TILE : i64
  (cast 32 : i64))
(define COLS : i64
  (cast 20 : i64))
(define ROWS : i64
  (cast 15 : i64))

(define WIDTH : i32
  (cast (* COLS TILE) : i32))
(define HEIGHT : i32
  (cast (* ROWS TILE) : i32))
(define TILE-F : f32
  (cast TILE : f32))

(define level : (Array i64)
  (make-array i64 300))

(define wfc-grid : (Array i64)
  (make-array i64 300))

(define (draw) : unit
  (begin
    (BeginDrawing)
    (ClearBackground
      (Color (cast 135 : u8) (cast 206 : u8) (cast 235 : u8) (cast 255 : u8)))
    (let
      [row : i64 0]
      (while (< row ROWS)
        (begin
          (let
            [col : i64 0]
            (while (< col COLS)
              (begin
                (draw-tile
                  (cast (* col TILE) : f32)
                  (cast (* row TILE) : f32)
                  TILE-F
                  (array-ref level (cell-idx row col)))
                (set! col (+ col 1)))))
          (set! row (+ row 1)))))
    (draw-player px py TILE-F)
    (DrawText
      (ffi-cstr "tl-platformer")
      (cast 12 : i32)
      (cast 12 : i32)
      (cast 20 : i32)
      (Color (cast 30 : u8) (cast 30 : u8) (cast 30 : u8) (cast 255 : u8)))
    (EndDrawing)))

(define (main) : i64
  (begin
    ;; Generate level using WFC
    (let
      [wfc-success : bool (wfc-generate wfc-grid)]
      (begin
        (if wfc-success
          (wfc-to-level wfc-grid level)
          (begin
            ;; Fallback: clear level and create simple ground
            (let
              [i : i64 0]
              (while (< i (cast 300 : i64))
                (begin
                  (array-set! level i 0)
                  (set! i (+ i 1)))))
            (let
              [c : i64 0]
              (while (< c COLS)
                (begin
                  (array-set! level (+ (* (cast 14 : i64) COLS) c) 1)
                  (set! c (+ c 1)))))
            (array-set! level (+ (* (cast 11 : i64) COLS) 5) 1)
            (array-set! level (+ (* (cast 11 : i64) COLS) 6) 1)
            (array-set! level (+ (* (cast 9 : i64) COLS) 10) 1)))))
    (InitWindow WIDTH HEIGHT (ffi-cstr "tl-platformer"))
    (SetTargetFPS (cast 60 : i32))
    (load-assets)
    (while (not (WindowShouldClose))
      (begin
        (player-update
          (cast (GetFrameTime) : f64)
          (IsKeyDown KEY_LEFT)
          (IsKeyDown KEY_RIGHT)
          (IsKeyDown KEY_SPACE)
          level
          COLS
          ROWS)
        (draw)))
    (unload-assets)
    (CloseWindow)
    0))
