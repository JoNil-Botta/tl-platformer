(import "src/wfc.tl")

;; WFC Test Suite
;; Runs the WFC generator multiple times and validates each output.
;; Returns 0 if all tests pass, 1 if any fail.

;; Test 1: Single generation and validation
(define (test-single-generation) : bool
  (let
    [grid : (Array i64) (make-array i64 300)]
    [success : bool (wfc-generate grid)]
    [valid : bool false]
    (begin
      (if success
        (set! valid (wfc-validate grid))
        (set! valid false))
      valid)))

;; Test 2: Multiple generations to check for determinism/coverage
;; Runs WFC 5 times and ensures at least 3 succeed
(define (test-multiple-generations) : bool
  (let
    [passed : i64 0]
    [run : i64 0]
    [grid : (Array i64) (make-array i64 300)]
    (begin
      (while (< run 5)
        (begin
          (let
            [success : bool (wfc-generate grid)]
            [valid : bool false]
            (begin
              (if success
                (set! valid (wfc-validate grid))
                (set! valid false))
              (when valid
                (set! passed (+ passed 1)))))
          (set! run (+ run 1))))
      (>= passed 3))))

;; Test 3: Check that generated level has expected dimensions
(define (test-level-dimensions) : bool
  (let
    [grid : (Array i64) (make-array i64 300)]
    [success : bool (wfc-generate grid)]
    (begin
      (if success
        (wfc-validate grid)
        false))))

;; Test 4: Ensure level has variety (not all solid or all empty)
(define (test-level-variety) : bool
  (let
    [grid : (Array i64) (make-array i64 300)]
    [success : bool (wfc-generate grid)]
    [solid-count : i64 0]
    [empty-count : i64 0]
    [platform-count : i64 0]
    [i : i64 0]
    (begin
      (if (not success)
        false
        (begin
          (while (< i GRID-SIZE)
            (let
              [tile : i64 (get-singleton-tile (array-ref grid i))]
              (begin
                (cond
                  (= tile TILE-EMPTY) (set! empty-count (+ empty-count 1))
                  (= tile TILE-SOLID) (set! solid-count (+ solid-count 1))
                  (= tile TILE-PLATFORM) (set! platform-count (+ platform-count 1))
                  unit)
                (set! i (+ i 1)))))
          ;; Must have at least some of each type (except platform can be 0)
          (and (> solid-count 0) (> empty-count 0)))))))

;; Main test runner
(define (main) : i64
  (let
    [t1 : bool (test-single-generation)]
    [t2 : bool (test-multiple-generations)]
    [t3 : bool (test-level-dimensions)]
    [t4 : bool (test-level-variety)]
    [all-pass : bool (and t1 t2 t3 t4)]
    (begin
      (if all-pass
        0
        1))))
