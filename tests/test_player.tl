(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/player.tl")
(import "../src/physics.tl")

;; Test level: 5x3 grid, bottom row is solid
;; 0 0 0 0 0
;; 0 0 0 0 0
;; 1 1 1 1 1
(define (make-test-level) : (Array i64)
  (let
    [level : (Array i64) (make-array i64 15)]
    (begin
      (array-set! level 0 0)
      (array-set! level 1 0)
      (array-set! level 2 0)
      (array-set! level 3 0)
      (array-set! level 4 0)
      (array-set! level 5 0)
      (array-set! level 6 0)
      (array-set! level 7 0)
      (array-set! level 8 0)
      (array-set! level 9 0)
      (array-set! level 10 0)
      (array-set! level 11 0)
      (array-set! level 12 0)
      (array-set! level 13 0)
      (array-set! level 14 0)
      (array-set! level 10 1)
      (array-set! level 11 1)
      (array-set! level 12 1)
      (array-set! level 13 1)
      (array-set! level 14 1)
      level)))

;; Reset player to a position in the air for testing
(define (setup-player-in-air) : unit
  (begin
    (set! px 64.0)
    (set! py 32.0)
    (set! vx 0.0)
    (set! vy 0.0)
    (set! on-ground false)
    (set! coyote-timer 0.0)
    (set! jump-buffer-timer 0.0)
    (set! prev-jump false)))

;; Test: player falls with gravity
(test
  test-player-falls
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      (player-update 0.1 false false false level 5 3)
      (assert-true
        (> py 32.0)
        "player should fall due to gravity"))))

;; Test: player can move right
(test
  test-player-move-right
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      (player-update 0.1 false true false level 5 3)
      (assert-true
        (> px 64.0)
        "player should move right when input_right is true"))))

;; Test: player can move left
(test
  test-player-move-left
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      (player-update 0.1 true false false level 5 3)
      (assert-true
        (< px 64.0)
        "player should move left when input_left is true"))))

;; Test: player lands on ground
(test
  test-player-lands
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      ;; Let player fall for several frames
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (assert-true
        on-ground
        "player should be on ground after falling"))))

;; Test: player can jump when on ground
(test
  test-player-jumps
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      ;; First land on ground
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      ;; Now jump - check vy is negative (upward velocity)
      (player-update 0.1 false false true level 5 3)
      (assert-true
        (< vy 0.0)
        "player should have upward velocity after jumping"))))

;; Test: player cannot jump when in air
(test
  test-player-no-air-jump
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      ;; Player starts in air, try to jump immediately
      (player-update 0.1 false false true level 5 3)
      (assert-false
        on-ground
        "player should not be on ground at start")
      (assert-true
        (> py 32.0)
        "player should fall, not jump, when not on ground"))))

;; Test: player stops at left wall
(test
  test-player-left-wall
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      ;; Land on ground first
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      ;; Now at ground, try to move left into wall
      (player-update 0.1 true false false level 5 3)
      (player-update 0.1 true false false level 5 3)
      (player-update 0.1 true false false level 5 3)
      (assert-true
        (<= px 64.0)
        "player should not move past left wall"))))

;; Test: coyote time — can jump briefly after leaving ground
(test
  test-coyote-time
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      ;; Land on ground
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      ;; Simulate leaving ground with coyote time active
      (set! on-ground false)
      (set! coyote-timer 0.10)
      ;; In air with coyote timer still active, try to jump
      (player-update 0.1 false false true level 5 3)
      (assert-true
        (< vy 0.0)
        "coyote time: should be able to jump after leaving ground"))))

;; Test: jump buffer — pressing jump before landing auto-jumps on landing
(test
  test-jump-buffer
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      ;; Player is in air, press jump (buffer it)
      (player-update 0.1 false false true level 5 3)
      (assert-true
        (> jump-buffer-timer 0.0)
        "jump buffer should be active after pressing jump in air")
      ;; Move player close to ground so they land quickly
      (set! px 64.0)
      (set! py 48.0)
      (set! vy 0.0)
      (set! on-ground false)
      (set! prev-jump true)
      (player-update 0.1 false false false level 5 3)
      ;; After landing with buffer, should have auto-jumped
      (assert-true
        (< vy 0.0)
        "jump buffer: should auto-jump on landing"))))

;; Test: variable jump height — releasing jump cuts upward velocity
(test
  test-variable-jump
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      ;; Set player going up fast
      (set! vy -400.0)
      (set! prev-jump true)
      ;; Release jump (input-jump = false) while going up
      (player-update 0.1 false false false level 5 3)
      (assert-true
        (> vy -400.0)
        "variable jump: releasing jump should cut upward velocity")
      (assert-true
        (< vy 0.0)
        "variable jump: should still be going up after cut"))))

;; Test: coyote time timer expires after too long
(test
  test-coyote-time-expires
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (setup-player-in-air)
      ;; Land on ground
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      (player-update 0.1 false false false level 5 3)
      ;; Simulate leaving ground with expired coyote time, player in air
      (set! on-ground false)
      (set! coyote-timer 0.0)
      (set! py 32.0)
      (set! vy 0.0)
      (set! prev-jump false)
      ;; Try to jump — should fail because coyote expired
      (let
        [pre-vy : f64 vy]
        (begin
          (player-update 0.1 false false true level 5 3)
          (assert-true
            (>= vy pre-vy)
            "coyote time expired: should not be able to jump"))))))

;; Big player / mushroom tests

;; Test: player starts small after reset
(test
  test-player-starts-small
  (begin
    (player-reset)
    (assert-false
      player-big
      "player should start small after reset")))

;; Test: player-grow makes player big
(test
  test-player-grow
  (begin
    (player-reset)
    (player-grow)
    (assert-true
      player-big
      "player should be big after grow")))

;; Test: player reset clears big state
(test
  test-player-reset-clears-big
  (begin
    (player-reset)
    (player-grow)
    (player-reset)
    (assert-false
      player-big
      "player should be small after reset")))

;; Test: player-take-damage when small returns false
(test
  test-damage-small-kills
  (begin
    (player-reset)
    (set! player-big false)
    (assert-false
      (player-take-damage)
      "take-damage when small should return false")))

;; Test: player-take-damage when big shrinks and returns true
(test
  test-damage-big-shrinks
  (begin
    (player-reset)
    (player-grow)
    (assert-true
      (player-take-damage)
      "take-damage when big should return true")
    (assert-false
      player-big
      "player should shrink after damage")))

;; Test: player-hit-ceiling is cleared each frame
(test
  test-hit-ceiling-cleared
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (player-reset)
      (set! player-hit-ceiling true)
      (player-update 0.1 false false false level 5 3)
      (assert-false
        player-hit-ceiling
        "hit-ceiling should be cleared after update with no collision"))))
