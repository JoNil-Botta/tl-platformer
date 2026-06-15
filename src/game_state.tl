(import "stdlib/ffi.tl")
(import "player.tl")

;; Game state management: lives, death, respawn, timer, game over

;; Starting lives
(define START-LIVES : i64
  (cast 3 : i64))

;; Timer: 5 minutes (300 seconds)
(define TIMER-START : f64
  300.0)

;; Game state enum
(define STATE-PLAYING : i64
  (cast 0 : i64))

(define STATE-GAME-OVER : i64
  (cast 1 : i64))

;; Global state
(define lives : i64
  START-LIVES)

(define game-state : i64
  STATE-PLAYING)

(define time-remaining : f64
  TIMER-START)

;; Check if game is over
(define (is-game-over?) : bool
  (= game-state STATE-GAME-OVER))

;; Check if game is active (not over)
(define (is-playing?) : bool
  (= game-state STATE-PLAYING))

;; Update timer: decrement by dt, return true if time ran out this frame
(define (timer-update [dt : f64]) : bool
  (if (is-playing?)
    (begin
      (set! time-remaining (- time-remaining dt))
      (if (<= time-remaining 0.0)
        (begin
          (set! time-remaining 0.0)
          true)
        false))
    false))

;; Reset timer to start value
(define (timer-reset) : unit
  (set! time-remaining TIMER-START))

;; Calculate time bonus (10 points per remaining second)
(define (timer-bonus) : i64
  (cast (* time-remaining 10.0) : i64))

;; Player dies: lose a life, respawn if lives remain, else game over
;; Returns true if respawned, false if game over
(define (player-die) : bool
  (begin
    (set! lives (- lives 1))
    (if (> lives 0)
      (begin
        (player-reset)
        true)
      (begin
        (set! game-state STATE-GAME-OVER)
        false))))

;; Full game reset: restore lives, score, timer, player position, enemies, coins
(define (game-reset) : unit
  (begin
    (set! lives START-LIVES)
    (set! game-state STATE-PLAYING)
    (timer-reset)
    (player-reset)))
