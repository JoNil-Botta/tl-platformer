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

;; Question block tests

;; Test: hit-question-block converts question block to empty block
(test
  test-hit-question-block
  (let
    [test-level : (Array i64) (make-array i64 15)]
    (begin
      ;; 5x3 level, row 0 has a question block at col 2
      (array-set! test-level 0 0)
      (array-set! test-level 1 0)
      (array-set! test-level 2 3)
      (array-set! test-level 3 0)
      (array-set! test-level 4 0)
      (array-set! test-level 5 1)
      (array-set! test-level 6 1)
      (array-set! test-level 7 1)
      (array-set! test-level 8 1)
      (array-set! test-level 9 1)
      (array-set! test-level 10 1)
      (array-set! test-level 11 1)
      (array-set! test-level 12 1)
      (array-set! test-level 13 1)
      (array-set! test-level 14 1)
      ;; Player at x=64 (col 2), head at y=18 (row 0 after subtracting PLAYER-HH)
      (let
        [hit : bool (hit-question-block test-level 5 3 64.0 18.0)]
        (begin
          (assert-true
            hit
            "should hit question block")
          (assert-true
            (= (array-ref test-level 2) 4)
            "question block should become empty block (4)"))))))

;; Test: hit-question-block returns false when no question block
(test
  test-no-question-block
  (let
    [test-level : (Array i64) (make-array i64 15)]
    (begin
      (array-set! test-level 0 0)
      (array-set! test-level 1 0)
      (array-set! test-level 2 0)
      (array-set! test-level 3 0)
      (array-set! test-level 4 0)
      (array-set! test-level 5 1)
      (array-set! test-level 6 1)
      (array-set! test-level 7 1)
      (array-set! test-level 8 1)
      (array-set! test-level 9 1)
      (array-set! test-level 10 1)
      (array-set! test-level 11 1)
      (array-set! test-level 12 1)
      (array-set! test-level 13 1)
      (array-set! test-level 14 1)
      (assert-false
        (hit-question-block test-level 5 3 64.0 18.0)
        "should not hit when no question block present"))))
