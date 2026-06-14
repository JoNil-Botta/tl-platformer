(import "stdlib/ffi.tl")

;; Minimal WFC level generator for tl-platformer
;; 0 = Empty (air), 1 = Solid (ground/wall)
(define GRID-COLS : i64
  (cast 20 : i64))

(define GRID-ROWS : i64
  (cast 15 : i64))

(define GRID-SIZE : i64
  (* GRID-COLS GRID-ROWS))

(define (cell-idx [row : i64] [col : i64]) : i64
  (+ (* row GRID-COLS) col))

(define (wfc-to-level [grid : (Array i64)] [level : (Array i64)]) : unit
  (let
    [i : i64 (cast 0 : i64)]
    (while (< i GRID-SIZE)
      (begin
        (array-set! level i (array-ref grid i))
        (set! i (+ i (cast 1 : i64)))))))

(define (wfc-generate [grid : (Array i64)]) : bool
  (begin
    (let
      [i : i64 (cast 0 : i64)]
      (while (< i GRID-SIZE)
        (begin
          (array-set! grid i (cast 0 : i64))
          (set! i (+ i (cast 1 : i64))))))
    (let
      [c : i64 (cast 0 : i64)]
      (while (< c GRID-COLS)
        (begin
          (array-set!
            grid
            (cell-idx (- GRID-ROWS (cast 1 : i64)) c)
            (cast 1 : i64))
          (set! c (+ c (cast 1 : i64))))))
    (let
      [c : i64 (cast 0 : i64)]
      (while (< c GRID-COLS)
        (begin
          (array-set! grid (cell-idx (cast 0 : i64) c) (cast 0 : i64))
          (set! c (+ c (cast 1 : i64))))))
    (let
      [r : i64 (cast 5 : i64)]
      (while (< r (- GRID-ROWS (cast 2 : i64)))
        (begin
          (let
            [c : i64 (cast 3 : i64)]
            (while (< c (- GRID-COLS (cast 3 : i64)))
              (begin
                (when
                  (> (% (+ (* r GRID-COLS) c) (cast 7 : i64)) (cast 3 : i64))
                  (array-set! grid (cell-idx r c) (cast 1 : i64)))
                (set! c (+ c (cast 1 : i64))))))
          (set! r (+ r (cast 1 : i64))))))
    true))