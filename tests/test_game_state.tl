(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/physics.tl")
(import "../src/player.tl")
(import "../src/game_state.tl")

;; Test: lives start at 3 after game-reset
(test
  test-lives-start-at-three
  (begin
    (game-reset)
    (assert-i64-eq
      lives
      3
      "lives should start at 3")))

;; Test: game state is playing after reset
(test
  test-state-playing-after-reset
  (begin
    (game-reset)
    (assert-true
      (is-playing?)
      "game should be in playing state after reset")))

;; Test: player-die reduces lives
(test
  test-die-reduces-lives
  (begin
    (game-reset)
    (player-die)
    (assert-i64-eq
      lives
      2
      "lives should be 2 after one death")))

;; Test: player-die respawns when lives remain
(test
  test-die-respawns
  (begin
    (game-reset)
    ;; Move player away from start
    (set! px 999.0)
    (set! py 999.0)
    (let
      [respawned : bool (player-die)]
      (begin
        (assert-true
          respawned
          "should respawn when lives remain")
        (assert-f64-eq
          px
          START-X
          "player x should reset to start")
        (assert-f64-eq
          py
          START-Y
          "player y should reset to start")))))

;; Test: three deaths -> game over
(test
  test-three-deaths-game-over
  (begin
    (game-reset)
    (player-die)
    (player-die)
    (player-die)
    (assert-true
      (is-game-over?)
      "game should be over after 3 deaths")))

;; Test: game over leaves lives at 0
(test
  test-game-over-zero-lives
  (begin
    (game-reset)
    (player-die)
    (player-die)
    (player-die)
    (assert-i64-eq
      lives
      0
      "lives should be 0 at game over")))

;; Test: is-playing? is false when game over
(test
  test-not-playing-when-game-over
  (begin
    (game-reset)
    (player-die)
    (player-die)
    (player-die)
    (assert-false
      (is-playing?)
      "should not be playing when game over")))

;; Test: game-reset restores lives after game over
(test
  test-reset-after-game-over
  (begin
    (game-reset)
    (player-die)
    (player-die)
    (player-die)
    (game-reset)
    (assert-i64-eq
      lives
      3
      "lives should be restored to 3 after reset")
    (assert-true
      (is-playing?)
      "game should be playing after reset")))

;; Test: player-die returns false at game over
(test
  test-die-returns-false-on-game-over
  (begin
    (game-reset)
    (player-die)
    (player-die)
    (let
      [result : bool (player-die)]
      (assert-false
        result
        "player-die should return false when game over"))))

;; Timer tests

;; Test: timer starts at TIMER-START after game-reset
(test
  test-timer-starts-at-full
  (begin
    (game-reset)
    (assert-f64-eq
      time-remaining
      TIMER-START
      "timer should start at TIMER-START")))

;; Test: timer decrements on update
(test
  test-timer-decrements
  (begin
    (game-reset)
    (timer-update 1.0)
    (assert-f64-eq
      time-remaining
      (- TIMER-START 1.0)
      "timer should decrement by dt")))

;; Test: timer returns false when not expired
(test
  test-timer-not-expired
  (begin
    (game-reset)
    (let
      [expired : bool (timer-update 1.0)]
      (assert-false
        expired
        "timer-update should return false when not expired"))))

;; Test: timer returns true when expired
(test
  test-timer-expired
  (begin
    (game-reset)
    (let
      [expired : bool (timer-update (+ TIMER-START 1.0))]
      (assert-true
        expired
        "timer-update should return true when expired"))))

;; Test: timer stops at 0
(test
  test-timer-stops-at-zero
  (begin
    (game-reset)
    (timer-update (+ TIMER-START 1.0))
    (assert-f64-eq
      time-remaining
      0.0
      "timer should stop at 0")))

;; Test: timer does not decrement when game over
(test
  test-timer-paused-on-game-over
  (begin
    (game-reset)
    (player-die)
    (player-die)
    (player-die)
    (set! time-remaining 100.0)
    (timer-update 1.0)
    (assert-f64-eq
      time-remaining
      100.0
      "timer should not decrement when game over")))

;; Test: timer bonus is positive with time remaining
(test
  test-timer-bonus-positive
  (begin
    (game-reset)
    (set! time-remaining 10.0)
    (assert-i64-eq
      (timer-bonus)
      100
      "timer bonus should be 10x remaining seconds")))

;; Test: timer bonus is zero at 0
(test
  test-timer-bonus-zero
  (begin
    (game-reset)
    (set! time-remaining 0.0)
    (assert-i64-eq
      (timer-bonus)
      0
      "timer bonus should be 0 when no time remains")))

;; Test: timer reset restores full time
(test
  test-timer-reset
  (begin
    (game-reset)
    (timer-update 50.0)
    (timer-reset)
    (assert-f64-eq
      time-remaining
      TIMER-START
      "timer-reset should restore full time")))
