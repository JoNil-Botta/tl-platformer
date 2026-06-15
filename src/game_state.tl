(import "stdlib/ffi.tl")
(import "player.tl")

;; Game state management: lives, death, respawn, game over

;; Starting lives
(define START-LIVES : i64
  (cast 3 : i64))

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

;; Check if game is over
(define (is-game-over?) : bool
  (= game-state STATE-GAME-OVER))

;; Check if game is active (not over)
(define (is-playing?) : bool
  (= game-state STATE-PLAYING))

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

;; Full game reset: restore lives, score, player position, enemies, coins
(define (game-reset) : unit
  (begin
    (set! lives START-LIVES)
    (set! game-state STATE-PLAYING)
    (player-reset)))
