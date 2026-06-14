(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/physics.tl")

;; Test level: 3x3 grid, center bottom is solid
;; 0 0 0
;; 0 0 0
;; 0 1 0
(define (make-test-level) : (Array i64)
  (let
    [level : (Array i64) (make-array i64 9)]
    (begin
      (array-set! level 0 0)
      (array-set! level 1 0)
      (array-set! level 2 0)
      (array-set! level 3 0)
      (array-set! level 4 0)
      (array-set! level 5 0)
      (array-set! level 6 0)
      (array-set! level 7 1)
      (array-set! level 8 0)
      level)))

;; Test: point-solid? on empty tile returns false
(test
  test-point-solid-empty
  (let
    [level : (Array i64) (make-test-level)]
    (assert-false
      (point-solid? level 3 3 16.0 16.0)
      "center of empty tile should not be solid")))

;; Test: point-solid? on solid tile returns true
(test
  test-point-solid-solid
  (let
    [level : (Array i64) (make-test-level)]
    (assert-true
      (point-solid? level 3 3 48.0 80.0)
      "center of solid tile (1,2) should be solid")))

;; Test: horizontal movement into wall is blocked (player cannot enter solid tile)
(test
  test-horizontal-wall
  (let
    [level : (Array i64) (make-test-level)]
    [new-px : f64 (resolve-horizontal level 3 3 16.0 48.0 100.0)]
    (assert-false
      (point-solid? level 3 3 (- new-px PLAYER-HW) 48.0)
      "after horizontal resolution, player left edge should not be in solid")))

;; Test: horizontal movement in open space works
(test
  test-horizontal-open
  (let
    [level : (Array i64) (make-test-level)]
    [new-px : f64 (resolve-horizontal level 3 3 16.0 16.0 16.0)]
    (assert-f64-eq
      new-px
      32.0
      "horizontal movement in open space should succeed")))

;; Test: falling onto ground sets on-ground flag
(test
  test-vertical-ground
  (let
    [level : (Array i64) (make-test-level)]
    [result : VerticalResult (resolve-vertical level 3 3 48.0 32.0 100.0)]
    (begin
      (assert-true
        (struct-get result on-ground)
        "falling onto ground should set on-ground flag")
      (assert-false
        (point-solid? level 3 3 48.0 (+ (struct-get result py) PLAYER-HH))
        "after falling, player bottom should not be in solid"))))

;; Test: moving up into ceiling is blocked
(test
  test-vertical-ceiling
  (let
    [level : (Array i64) (make-test-level)]
    [result : VerticalResult (resolve-vertical level 3 3 48.0 80.0 -100.0)]
    (begin
      (assert-false
        (struct-get result on-ground)
        "moving up should not be on-ground")
      (assert-false
        (point-solid? level 3 3 48.0 (- (struct-get result py) PLAYER-HH))
        "after moving up, player top should not be in solid"))))
