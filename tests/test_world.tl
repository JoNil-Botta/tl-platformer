(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/world.tl")

;; Test: level-idx computes correct index
(test
  test-level-idx
  (assert-true
    (= (level-idx 0 0) 0)
    "level-idx at 0,0 should be 0")
  (assert-true
    (= (level-idx 0 1) 1)
    "level-idx at 0,1 should be 1")
  (assert-true
    (= (level-idx 1 0) 80)
    "level-idx at 1,0 should be 80 (LEVEL-COLS)")
  (assert-true
    (= (level-idx 1 1) 81)
    "level-idx at 1,1 should be 81"))

;; Test: world dimensions are correct
(test
  test-world-dimensions
  (assert-true
    (= WORLD-W 2560.0)
    "world width should be 80 * 32 = 2560")
  (assert-true
    (= WORLD-H 480.0)
    "world height should be 15 * 32 = 480"))

;; Test: goal is near right edge
(test
  test-goal-position
  (assert-true
    (> GOAL-X 2400.0)
    "goal x should be near right edge")
  (assert-true
    (< GOAL-Y 200.0)
    "goal y should be near top of level"))

;; Test: reached-goal? at goal position
(test
  test-reached-goal-at-goal
  (assert-true
    (reached-goal? GOAL-X GOAL-Y)
    "should detect goal at exact goal position"))

;; Test: reached-goal? before goal
(test
  test-not-reached-goal
  (assert-false
    (reached-goal? 0.0 0.0)
    "should not detect goal at start position"))

;; Test: level array is correct size
(test
  test-level-size
  (assert-true
    (= LEVEL-SIZE 1200)
    "level size should be 80 * 15 = 1200"))
