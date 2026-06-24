(import "stdlib/ffi.tl")
(import "player.tl")

;; Game state management: lives, death, respawn, timer, game over, level complete

;; Starting lives
(define START-LIVES : i64
  (cast 3 : i64))

;; Mutable timer start value (changed per level)
(define start-duration : f64
  300.0)

;; Timer: 5 minutes (300 seconds) — overridden per level
(define TIMER-START : f64
  300.0)

;; Game state enum
(define STATE-PLAYING : i64
  (cast 0 : i64))

(define STATE-GAME-OVER : i64
  (cast 1 : i64))

(define STATE-LEVEL-COMPLETE : i64
  (cast 2 : i64))

(define STATE-WORLD-COMPLETE : i64
  (cast 3 : i64))

;; Global state
(define lives : i64
  START-LIVES)

(define game-state : i64
  STATE-PLAYING)

(define time-remaining : f64
  TIMER-START)

;; Level complete transition timer (seconds, counts down)
(define level-complete-timer : f64
  0.0)

;; Level complete transition duration
(define LEVEL-COMPLETE-DELAY : f64
  2.0)

;; Check if game is over
(define (is-game-over?) : bool
  (= game-state STATE-GAME-OVER))

;; Check if game is active (not over or in transition)
(define (is-playing?) : bool
  (= game-state STATE-PLAYING))

;; Check if level complete transition is active
(define (is-level-complete?) : bool
  (= game-state STATE-LEVEL-COMPLETE))

;; Check if world complete transition is active
(define (is-world-complete?) : bool
  (= game-state STATE-WORLD-COMPLETE))

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
  (set! time-remaining start-duration))

;; Reset timer to a specific duration
(define (apply-timer-duration [duration : f64]) : unit
  (begin
    (set! start-duration duration)
    (set! time-remaining duration)))

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

;; Trigger level complete state
(define (level-complete) : unit
  (begin
    (set! game-state STATE-LEVEL-COMPLETE)
    (set! level-complete-timer LEVEL-COMPLETE-DELAY)))

;; Trigger world complete state
(define (world-complete) : unit
  (begin
    (set! game-state STATE-WORLD-COMPLETE)
    (set! level-complete-timer LEVEL-COMPLETE-DELAY)))

;; Update level/world complete transition timer
;; Returns true when transition is done (timer expired)
(define (update-level-transition [dt : f64]) : bool
  (if (is-level-complete?)
    (begin
      (set! level-complete-timer (- level-complete-timer dt))
      (if (<= level-complete-timer 0.0)
        (begin
          (set! level-complete-timer 0.0)
          true)
        false))
    (if (is-world-complete?)
      (begin
        (set! level-complete-timer (- level-complete-timer dt))
        (if (<= level-complete-timer 0.0)
          (begin
            (set! level-complete-timer 0.0)
            true)
          false))
      false)))

;; Full game reset: restore lives, score, timer, player position, enemies, coins
(define (game-reset) : unit
  (begin
    (set! lives START-LIVES)
    (set! game-state STATE-PLAYING)
    (timer-reset)
    (player-reset)))

;; Start a new level: reset state but keep lives and score
(define (start-new-level) : unit
  (begin
    (set! game-state STATE-PLAYING)
    (set! level-complete-timer 0.0)))
