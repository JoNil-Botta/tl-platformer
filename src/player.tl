(import "stdlib/ffi.tl")
(import "physics.tl")

;; Player constants
(define PLAYER-START-X : f64
  64.0)

(define PLAYER-START-Y : f64
  64.0)

(define GRAVITY : f64
  1400.0)

(define MOVE-SPEED : f64
  220.0)

(define JUMP-VEL : f64
  -520.0)

;; Player state (globals for game loop)
(define px : f64
  PLAYER-START-X)

(define py : f64
  PLAYER-START-Y)

(define vx : f64
  0.0)

(define vy : f64
  0.0)

(define on-ground : bool
  false)

;; Reset player to start position
(define (player-reset) : unit
  (begin
    (set! px PLAYER-START-X)
    (set! py PLAYER-START-Y)
    (set! vx 0.0)
    (set! vy 0.0)
    (set! on-ground false)))

;; Pure player update: takes all state as parameters, returns nothing but computes new state
;; This is the core testable function - it writes results to the provided mutable references
;; For TypeLisp, we use globals for the game loop, but this function is structured so
;; it could be tested by setting up globals, calling it, and reading them back
(define (player-update [dt : f64] [input-left : bool] [input-right : bool] [input-jump : bool] [level : (Array i64)] [cols : i64] [rows : i64]) : unit
  (begin
    ;; Apply horizontal input
    (set! vx 0.0)
    (when input-right (set! vx MOVE-SPEED))
    (when input-left (set! vx (- 0.0 MOVE-SPEED)))
    ;; Jump
    (when
      (and on-ground input-jump)
      (begin
        (set! vy JUMP-VEL)
        (set! on-ground false)))
    ;; Apply gravity
    (set! vy (+ vy (* GRAVITY dt)))
    ;; Move horizontally with collision
    (set! px (resolve-horizontal level cols rows px py (* vx dt)))
    ;; Move vertically with collision
    (let
      [vresult : VerticalResult (resolve-vertical level cols rows px py (* vy dt))]
      (begin
        (set! py (struct-get vresult py))
        (set! on-ground (struct-get vresult on-ground))))))
