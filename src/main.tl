(defstruct Color (:repr c) (r u8) (g u8) (b u8) (a u8))
(defstruct Rectangle (:repr c) (x f32) (y f32) (width f32) (height f32))

(extern InitWindow     : (-> i32 i32 (Ptr u8) unit))
(extern SetTargetFPS   : (-> i32 unit))
(extern WindowShouldClose : (-> bool))
(extern BeginDrawing   : (-> unit))
(extern EndDrawing     : (-> unit))
(extern ClearBackground : (-> Color unit))
(extern DrawRectangleRec : (-> Rectangle Color unit))
(extern DrawText       : (-> (Ptr u8) i32 i32 i32 Color unit))
(extern IsKeyDown      : (-> i32 bool))
(extern GetFrameTime   : (-> f32))
(extern CloseWindow    : (-> unit))

(define KEY_RIGHT : i32 262)
(define KEY_LEFT  : i32 263)
(define KEY_SPACE : i32 32)

(define TILE   : i64 32)
(define COLS   : i64 20)
(define ROWS   : i64 15)

(define level : (Array i64) (make-array i64 300))

(define px : f64 64.0)
(define py : f64 64.0)
(define vx : f64 0.0)
(define vy : f64 0.0)
(define on-ground : bool false)

(define GRAVITY   : f64 1400.0)
(define MOVE-SPEED : f64 220.0)
(define JUMP-VEL  : f64 -520.0)

(define (tile-solid? [col : i64] [row : i64]) : bool
  (if (or (< col 0) (or (>= col COLS) (or (< row 0) (>= row ROWS))))
    true                                   ; out of bounds = wall
    (= (array-ref level (+ (* row COLS) col)) 1)))

(define (solid-at? [wx : f64] [wy : f64]) : bool
  (tile-solid? (/ (cast wx : i64) TILE) (/ (cast wy : i64) TILE)))

(define (update [dt : f64]) : unit
  (begin
    (set! vx 0.0)
    (if (IsKeyDown KEY_RIGHT) (set! vx MOVE-SPEED) unit)
    (if (IsKeyDown KEY_LEFT)  (set! vx (- 0.0 MOVE-SPEED)) unit)
    (if (and on-ground (IsKeyDown KEY_SPACE))
      (begin (set! vy JUMP-VEL) (set! on-ground false))
      unit)
    (set! vy (+ vy (* GRAVITY dt)))
    (set! px (+ px (* vx dt)))
    (set! py (+ py (* vy dt)))
    (if (solid-at? px (+ py 31.0))
      (begin
        (set! py (cast (* (/ (cast py : i64) TILE) TILE) : f64))
        (set! vy 0.0)
        (set! on-ground true))
      (set! on-ground false))))

(define (draw) : unit
  (begin
    (BeginDrawing)
    (ClearBackground (Color 135 206 235 255))   ; sky blue
    (let ([row : i64 0])
      (while (< row ROWS)
        (begin
          (let ([col : i64 0])
            (while (< col COLS)
              (begin
                (if (tile-solid? col row)
                  (DrawRectangleRec
                    (Rectangle
                      (cast (* col TILE) : f32) (cast (* row TILE) : f32)
                      (cast TILE : f32) (cast TILE : f32))
                    (Color 90 60 30 255))
                  unit)
                (set! col (+ col 1)))))
          (set! row (+ row 1)))))
    (DrawRectangleRec
      (Rectangle (cast px : f32) (cast py : f32) 28.0 28.0)
      (Color 220 40 40 255))
    (DrawText (cstr "tl-platformer") 12 12 20 (Color 30 30 30 255))
    (EndDrawing)))

(define (main) : i64
  (begin
    (let ([i : i64 0])
      (while (< i 300) (begin (array-set! level i 0) (set! i (+ i 1)))))
    (let ([c : i64 0])
      (while (< c COLS)
        (begin (array-set! level (+ (* 14 COLS) c) 1) (set! c (+ c 1)))))  ; floor
    (array-set! level (+ (* 11 COLS) 5) 1)
    (array-set! level (+ (* 11 COLS) 6) 1)
    (array-set! level (+ (* 9 COLS) 10) 1)

    (InitWindow (cast (* COLS TILE) : i32) (cast (* ROWS TILE) : i32)
                (cstr "tl-platformer"))
    (SetTargetFPS 60)
    (while (not (WindowShouldClose))
      (begin
        (update (cast (GetFrameTime) : f64))
        (draw)))
    (CloseWindow)
    0))
