(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/world.tl")
(import "../src/wfc.tl")

;; Helper: make a small test grid
(define (make-test-grid [size : i64]) : (Array i64)
  (make-array i64 size))

;; Test: generation is deterministic with same seed
(test
  test-deterministic
  (let
    [grid1 : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    [grid2 : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid1 LEVEL-COLS LEVEL-ROWS (cast 123 : i64))
      (wfc-generate grid2 LEVEL-COLS LEVEL-ROWS (cast 123 : i64))
      (let
        [same : bool true]
        [i : i64 (cast 0 : i64)]
        (begin
          (while (< i LEVEL-SIZE)
            (begin
              (when (not (= (array-ref grid1 i) (array-ref grid2 i)))
                (set! same false))
              (set! i (+ i 1))))
          (assert-true
            same
            "same seed should produce identical grid"))))))

;; Test: generation differs with different seeds
(test
  test-different-seeds
  (let
    [grid1 : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    [grid2 : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid1 LEVEL-COLS LEVEL-ROWS (cast 1 : i64))
      (wfc-generate grid2 LEVEL-COLS LEVEL-ROWS (cast 999 : i64))
      (let
        [diff : bool false]
        [i : i64 (cast 0 : i64)]
        (begin
          (while (< i LEVEL-SIZE)
            (begin
              (when (not (= (array-ref grid1 i) (array-ref grid2 i)))
                (set! diff true))
              (set! i (+ i 1))))
          (assert-true
            diff
            "different seeds should produce different grids"))))))

;; Test: bottom row is always solid ground
(test
  test-bottom-row-ground
  (let
    [grid : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))
      (let
        [all-ground : bool true]
        [c : i64 (cast 0 : i64)]
        (begin
          (while (< c LEVEL-COLS)
            (begin
              (when (not (= (array-ref grid (level-idx (- LEVEL-ROWS 1) c)) TILE-GROUND))
                (set! all-ground false))
              (set! c (+ c 1))))
          (assert-true
            all-ground
            "bottom row should be all ground tiles"))))))

;; Test: top 2 rows are always empty
(test
  test-top-rows-empty
  (let
    [grid : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))
      (let
        [all-empty : bool true]
        [c : i64 (cast 0 : i64)]
        (begin
          (while (< c LEVEL-COLS)
            (begin
              (when (not (= (array-ref grid (level-idx 0 c)) TILE-EMPTY))
                (set! all-empty false))
              (when (not (= (array-ref grid (level-idx 1 c)) TILE-EMPTY))
                (set! all-empty false))
              (set! c (+ c 1))))
          (assert-true
            all-empty
            "top 2 rows should be empty"))))))

;; Test: pipe stacks are valid (PIPE-TOP has PIPE-BODY or ground below it)
(test
  test-pipe-stacks-valid
  (let
    [grid : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))
      (let
        [valid : bool true]
        [r : i64 (cast 2 : i64)]
        (begin
          (while (< r (- LEVEL-ROWS 1))
            (begin
              (let [c : i64 (cast 0 : i64)]
                (while (< c LEVEL-COLS)
                  (begin
                    (when (= (array-ref grid (level-idx r c)) TILE-PIPE-TOP)
                      (let
                        [below : i64 (array-ref grid (level-idx (+ r 1) c))]
                        (when (not (or (= below TILE-PIPE-BODY) (= below TILE-GROUND)))
                          (set! valid false))))
                    (set! c (+ c 1)))))
              (set! r (+ r 1))))
          (assert-true
            valid
            "every pipe top should have pipe body or ground below it"))))))

;; Test: question blocks have solid ground below and empty above
(test
  test-question-blocks-reachable
  (let
    [grid : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))
      (let
        [valid : bool true]
        [r : i64 (cast 1 : i64)]
        (begin
          (while (< r (- LEVEL-ROWS 1))
            (begin
              (let [c : i64 (cast 1 : i64)]
                (while (< c (- LEVEL-COLS 1))
                  (begin
                    (when (= (array-ref grid (level-idx r c)) TILE-QUESTION)
                      (begin
                        ;; Must have solid below
                        (when (= (array-ref grid (level-idx (+ r 1) c)) TILE-EMPTY)
                          (set! valid false))
                        ;; Must have empty above
                        (when (not (= (array-ref grid (level-idx (- r 1) c)) TILE-EMPTY))
                          (set! valid false))))
                    (set! c (+ c 1)))))
              (set! r (+ r 1))))
          (assert-true
            valid
            "every question block should have solid below and empty above"))))))

;; Test: all tiles are valid types (0-7)
(test
  test-all-tiles-valid
  (let
    [grid : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))
      (let
        [valid : bool true]
        [i : i64 (cast 0 : i64)]
        (begin
          (while (< i LEVEL-SIZE)
            (begin
              (let [t : i64 (array-ref grid i)]
                (when (or (< t 0) (> t 7))
                  (set! valid false)))
              (set! i (+ i 1))))
          (assert-true
            valid
            "all tiles should be valid types 0-7"))))))

;; Test: wfc-to-level copies grid correctly
(test
  test-wfc-to-level
  (let
    [grid : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    [lvl : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))
      (wfc-to-level grid lvl LEVEL-COLS LEVEL-ROWS)
      (let
        [same : bool true]
        [i : i64 (cast 0 : i64)]
        (begin
          (while (< i LEVEL-SIZE)
            (begin
              (when (not (= (array-ref grid i) (array-ref lvl i)))
                (set! same false))
              (set! i (+ i 1))))
          (assert-true
            same
            "wfc-to-level should copy all tiles exactly"))))))

;; Test: at least one pipe exists in level
(test
  test-pipes-exist
  (let
    [grid : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))
      (let
        [found : bool false]
        [i : i64 (cast 0 : i64)]
        (begin
          (while (< i LEVEL-SIZE)
            (begin
              (when (= (array-ref grid i) TILE-PIPE-TOP)
                (set! found true))
              (set! i (+ i 1))))
          (assert-true
            found
            "level should contain at least one pipe"))))))

;; Test: at least one question block exists in level
(test
  test-questions-exist
  (let
    [grid : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))
      (let
        [found : bool false]
        [i : i64 (cast 0 : i64)]
        (begin
          (while (< i LEVEL-SIZE)
            (begin
              (when (= (array-ref grid i) TILE-QUESTION)
                (set! found true))
              (set! i (+ i 1))))
          (assert-true
            found
            "level should contain at least one question block"))))))

;; Test: at least some bricks exist in level
(test
  test-bricks-exist
  (let
    [grid : (Array i64) (make-test-grid (* LEVEL-COLS LEVEL-ROWS))]
    (begin
      (wfc-generate grid LEVEL-COLS LEVEL-ROWS (cast 42 : i64))
      (let
        [found : bool false]
        [i : i64 (cast 0 : i64)]
        (begin
          (while (< i LEVEL-SIZE)
            (begin
              (when (= (array-ref grid i) TILE-BRICK)
                (set! found true))
              (set! i (+ i 1))))
          (assert-true
            found
            "level should contain at least one brick"))))))
