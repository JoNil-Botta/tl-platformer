(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/physics.tl")

;; Test level: 5x3 grid, bottom row solid
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

;; Test: no collision in open space
(test
  test-no-collision
  (let
    [level : (Array i64) (make-test-level)]
    (assert-false
      (player-collides? level 5 3 64.0 32.0)
      "should not collide in open space")))

;; Test: collision with ground
(test
  test-ground-collision
  (let
    [level : (Array i64) (make-test-level)]
    (assert-true
      (player-collides? level 5 3 64.0 80.0)
      "should collide with ground")))

;; Test: resolve-horizontal moves freely when no wall
(test
  test-resolve-horizontal-free
  (let
    [level : (Array i64) (make-test-level)]
    (assert-true
      (> (resolve-horizontal level 5 3 64.0 32.0 10.0) 64.0)
      "should move right freely")))

;; Test: resolve-horizontal stops at left wall
(test
  test-resolve-horizontal-left-wall
  (let
    [level : (Array i64) (make-test-level)]
    (assert-true
      (<= (resolve-horizontal level 5 3 10.0 32.0 -20.0) 10.0)
      "should not move past left wall")))

;; Test: resolve-vertical lands on ground
(test
  test-resolve-vertical-ground
  (let
    [level : (Array i64) (make-test-level)]
    (let
      [result : VerticalResult (resolve-vertical level 5 3 64.0 60.0 30.0)]
      (assert-true
        (struct-get result on-ground)
        "should land on ground"))))

;; Test: on-ground? detects ground below feet
(test
  test-on-ground
  (let
    [level : (Array i64) (make-test-level)]
    (assert-true
      (on-ground? level 5 3 64.0 60.0)
      "should detect ground below")))

;; Test: on-ground? returns false in air
(test
  test-not-on-ground
  (let
    [level : (Array i64) (make-test-level)]
    (assert-false
      (on-ground? level 5 3 64.0 32.0)
      "should not detect ground in air")))

;; Test: floor-div works for negative numbers
(test
  test-floor-div-negative
  (assert-true
    (= (floor-div -1 32) -1)
    "floor-div of -1 by 32 should be -1")
  (assert-true
    (= (floor-div -33 32) -2)
    "floor-div of -33 by 32 should be -2"))

;; Test: point-solid? respects left wall with negative coords
(test
  test-point-solid-left-wall
  (let
    [level : (Array i64) (make-test-level)]
    (assert-true
      (point-solid? level 5 3 -1.0 32.0)
      "point at x=-1 should be solid (left wall)")))

;; Test: player-collides? respects left wall
(test
  test-player-collides-left-wall
  (let
    [level : (Array i64) (make-test-level)]
    (assert-true
      (player-collides? level 5 3 10.0 32.0)
      "player at x=10 with half-width 14 should hit left wall")))

;; Test: ceiling collision stops upward movement
(test
  test-ceiling-collision
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      ;; Create a level with a ceiling: row 0 is solid
      (array-set! level 0 1)
      (array-set! level 1 1)
      (array-set! level 2 1)
      (array-set! level 3 1)
      (array-set! level 4 1)
      (let
        [result : VerticalResult (resolve-vertical level 5 3 64.0 40.0 -30.0)]
        (begin
          (assert-false
            (struct-get result on-ground)
            "hitting ceiling should not set on-ground")
          (assert-true
            (> (struct-get result py) 10.0)
            "should snap below ceiling")))))
)

;; Test: tile-solid? treats any non-zero tile as solid
(test
  test-tile-solid-nonzero
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      ;; Set tile 2 to question block (3) — should be solid
      (array-set! level 2 3)
      (assert-true
        (tile-solid? level 5 3 2 0)
        "question block (3) should be solid")
      ;; Set tile 3 to empty block (4) — should be solid
      (array-set! level 3 4)
      (assert-true
        (tile-solid? level 5 3 3 0)
        "empty block (4) should be solid")
      ;; Tile 0 remains empty — not solid
      (assert-false
        (tile-solid? level 5 3 0 0)
        "empty (0) should not be solid"))))

;; Test: resolve-vertical reports hit-ceiling when moving up into solid
(test
  test-hit-ceiling-flag
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      ;; Create a ceiling: row 0 is solid
      (array-set! level 0 1)
      (array-set! level 1 1)
      (array-set! level 2 1)
      (array-set! level 3 1)
      (array-set! level 4 1)
      (let
        [result : VerticalResult (resolve-vertical level 5 3 64.0 40.0 -30.0)]
        (begin
          (assert-true
            (struct-get result hit-ceiling)
            "should report hit-ceiling when moving up into solid")
          (assert-false
            (struct-get result on-ground)
            "should not be on ground when hitting ceiling"))))))
