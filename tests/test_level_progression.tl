(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/level_progression.tl")

;; Tests for level progression system

;; Helper: reset to known state
(define (reset-to-start) : unit
  (begin
    (set! current-world (cast 1 : i64))
    (set! current-level (cast 1 : i64))))

;; Test 1: Initial state is world 1, level 1
(test
  test-initial-state
  (begin
    (reset-to-start)
    (assert-true
      (and (= current-world 1) (= current-level 1))
      "initial state should be world 1, level 1")))

;; Test 2: Seed determinism — same world/level gives same seed
(test
  test-seed-determinism
  (begin
    (reset-to-start)
    (let
      [seed1 : i64 (level-seed)]
      (begin
        (reset-to-start)
        (assert-true
          (= seed1 (level-seed))
          "same world/level should produce same seed")))))

;; Test 3: Different levels give different seeds
(test
  test-seed-uniqueness
  (begin
    (reset-to-start)
    (let
      [seed1 : i64 (level-seed)]
      (begin
        (next-level)
        (assert-false
          (= seed1 (level-seed))
          "different levels should produce different seeds")))))

;; Test 4: Biome progression: 1-1 = overworld, 1-2 = underground, 1-3 = overworld, 1-4 = castle
(test
  test-biome-progression
  (begin
    (reset-to-start)
    (assert-true
      (= (current-level-biome) LEVEL-1-BIOME)
      "level 1 should be overworld")
    (next-level)
    (assert-true
      (= (current-level-biome) LEVEL-2-BIOME)
      "level 2 should be underground")
    (next-level)
    (assert-true
      (= (current-level-biome) LEVEL-3-BIOME)
      "level 3 should be overworld")
    (next-level)
    (assert-true
      (= (current-level-biome) LEVEL-4-BIOME)
      "level 4 should be castle")))

;; Test 5: Enemy spacing increases difficulty (smaller numbers = more enemies)
(test
  test-enemy-spacing-scaling
  (begin
    (reset-to-start)
    (assert-true
      (= (level-enemy-spacing) 10)
      "level 1 should have enemy spacing 10")
    (next-level)
    (assert-true
      (= (level-enemy-spacing) 8)
      "level 2 should have enemy spacing 8")
    (next-level)
    (assert-true
      (= (level-enemy-spacing) 7)
      "level 3 should have enemy spacing 7")
    (next-level)
    (assert-true
      (= (level-enemy-spacing) 6)
      "level 4 should have enemy spacing 6")))

;; Test 6: Timer duration varies by level
(test
  test-timer-duration
  (begin
    (reset-to-start)
    (assert-true
      (= (level-timer-duration) 300.0)
      "level 1 should have 300 second timer")
    (next-level)
    (assert-true
      (= (level-timer-duration) 330.0)
      "level 2 should have 330 second timer")
    (next-level)
    (assert-true
      (= (level-timer-duration) 300.0)
      "level 3 should have 300 second timer")
    (next-level)
    (assert-true
      (= (level-timer-duration) 360.0)
      "level 4 should have 360 second timer")))

;; Test 7: next-level advances through all 4 levels
(test
  test-level-advancement
  (begin
    (reset-to-start)
    (assert-true
      (= current-level 1)
      "should start at level 1")
    (next-level)
    (assert-true
      (= current-level 2)
      "should advance to level 2")
    (next-level)
    (assert-true
      (= current-level 3)
      "should advance to level 3")
    (next-level)
    (assert-true
      (= current-level 4)
      "should advance to level 4")))

;; Test 8: next-level returns false after level 4 (world complete)
(test
  test-world-completion
  (begin
    (reset-to-start)
    (next-level)
    (next-level)
    (next-level)
    (assert-false
      (next-level)
      "next-level should return false after level 4")
    (assert-i64-eq
      current-level
      5
      "current-level should be 5 after completing all levels")
    (assert-true
      (is-world-finished?)
      "world should be complete after level 4")))

;; Test 9: next-world advances world and resets level
(test
  test-next-world
  (begin
    (reset-to-start)
    (next-level)
    (next-level)
    (next-level)
    (next-level)
    (next-world)
    (assert-true
      (= current-world 2)
      "should advance to world 2")
    (assert-true
      (= current-level 1)
      "should reset to level 1")))

;; Test 10: reset-world resets to level 1 keeping current world
(test
  test-reset-world
  (begin
    (reset-to-start)
    (next-level)
    (next-level)
    (reset-world)
    (assert-true
      (= current-world 1)
      "world should stay 1")
    (assert-true
      (= current-level 1)
      "should reset to level 1")))

;; Test 11: reset-progression resets to world 1, level 1
(test
  test-reset-progression
  (begin
    (reset-to-start)
    (next-level)
    (next-world)
    (next-level)
    (reset-progression)
    (assert-true
      (= current-world 1)
      "should reset to world 1")
    (assert-true
      (= current-level 1)
      "should reset to level 1")))

;; Test 12: world-level-number returns correct display value
(test
  test-world-level-number
  (begin
    (reset-to-start)
    (assert-true
      (= (world-level-number) 11)
      "world 1 level 1 should display as 11")
    (next-level)
    (assert-true
      (= (world-level-number) 12)
      "world 1 level 2 should display as 12")))
