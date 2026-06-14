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

;; Game-feel tunables
(define COYOTE-TIME : f64
  0.15)

(define JUMP-BUFFER-TIME : f64
  0.15)

(define JUMP-CUT-MULTIPLIER : f64
  0.40)

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

(define coyote-timer : f64
  0.0)

(define jump-buffer-timer : f64
  0.0)

(define prev-jump : bool
  false)

;; Reset player to start position
(define (player-reset) : unit
  (begin
    (set! px PLAYER-START-X)
    (set! py PLAYER-START-Y)
    (set! vx 0.0)
    (set! vy 0.0)
    (set! on-ground false)
    (set! coyote-timer 0.0)
    (set! jump-buffer-timer 0.0)
    (set! prev-jump false)))

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
    ;; Update coyote timer (set when on ground, countdown when in air)
    (when on-ground
      (set! coyote-timer COYOTE-TIME))
    (when (not on-ground)
      (set! coyote-timer (- coyote-timer dt)))
    (when (< coyote-timer 0.0)
      (set! coyote-timer 0.0))
    ;; Update jump buffer timer
    (when (> jump-buffer-timer 0.0)
      (set! jump-buffer-timer (- jump-buffer-timer dt)))
    (when (< jump-buffer-timer 0.0)
      (set! jump-buffer-timer 0.0))
    ;; Detect jump press (rising edge)
    (let
      [jump-pressed : bool (and input-jump (not prev-jump))]
      (begin
        ;; If jump pressed on ground or within coyote time: jump immediately
        (when
          (and jump-pressed (or on-ground (> coyote-timer 0.0)))
          (begin
            (set! vy JUMP-VEL)
            (set! on-ground false)
            (set! coyote-timer 0.0)
            (set! jump-buffer-timer 0.0)))
        ;; If jump pressed in air with no coyote time: buffer the jump
        (when
          (and jump-pressed (not on-ground) (<= coyote-timer 0.0))
          (set! jump-buffer-timer JUMP-BUFFER-TIME))))
    ;; Variable jump height: cut upward velocity when jump released while going up
    (when
      (and (not input-jump) prev-jump (< vy 0.0))
      (set! vy (* vy JUMP-CUT-MULTIPLIER)))
    ;; Remember jump state for next frame
    (set! prev-jump input-jump)
    ;; Apply gravity
    (set! vy (+ vy (* GRAVITY dt)))
    ;; Move horizontally with collision
    (set! px (resolve-horizontal level cols rows px py (* vx dt)))
    ;; Move vertically with collision
    (let
      [vresult : VerticalResult (resolve-vertical level cols rows px py (* vy dt))]
      (begin
        (set! py (struct-get vresult py))
        (set! on-ground (struct-get vresult on-ground))
        ;; If we just landed and a jump was buffered, auto-jump
        (when
          (and on-ground (> jump-buffer-timer 0.0))
          (begin
            (set! vy JUMP-VEL)
            (set! on-ground false)
            (set! jump-buffer-timer 0.0)))))))
