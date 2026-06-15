(import "stdlib/ffi.tl")

;; Minimal WFC level generator for tl-platformer
;; 0 = Empty (air), 1 = Solid (ground/wall), 3 = Question block

;; Generate a simple platformer level into the given grid
;; Returns true on success
(define (wfc-generate [grid : (Array i64)] [cols : i64] [rows : i64]) : bool
  (let
    [size : i64 (* cols rows)]
    (begin
      ;; Clear grid
      (let
        [i : i64 (cast 0 : i64)]
        (while (< i size)
          (begin
            (array-set! grid i (cast 0 : i64))
            (set! i (+ i (cast 1 : i64))))))
      ;; Solid ground at bottom row
      (let
        [c : i64 (cast 0 : i64)]
        (while (< c cols)
          (begin
            (array-set! grid (+ (* (- rows (cast 1 : i64)) cols) c) (cast 1 : i64))
            (set! c (+ c (cast 1 : i64))))))
      ;; Clear top row (sky)
      (let
        [c : i64 (cast 0 : i64)]
        (while (< c cols)
          (begin
            (array-set! grid c (cast 0 : i64))
            (set! c (+ c (cast 1 : i64))))))
      ;; Scattered platforms in middle section
      (let
        [r : i64 (cast 5 : i64)]
        (while (< r (- rows (cast 2 : i64)))
          (begin
            (let
              [c : i64 (cast 3 : i64)]
              (while (< c (- cols (cast 3 : i64)))
                (begin
                  (when
                    (> (% (+ (* r cols) c) (cast 7 : i64)) (cast 3 : i64))
                    (array-set! grid (+ (* r cols) c) (cast 1 : i64)))
                  (set! c (+ c (cast 1 : i64))))))
            (set! r (+ r (cast 1 : i64))))))
      ;; Place question blocks above ground
      (let
        [c : i64 (cast 5 : i64)]
        (while (< c (- cols (cast 5 : i64)))
          (begin
            (when (= (% c (cast 10 : i64)) (cast 3 : i64))
              (let
                [ground-row : i64 (- rows (cast 2 : i64))]
                (begin
                  ;; Find ground in this column
                  (while (and (>= ground-row 0) (= (array-ref grid (+ (* ground-row cols) c)) 0))
                    (set! ground-row (- ground-row 1)))
                  ;; If ground found and there's space above, place question block
                  (when (>= ground-row 3)
                    (let
                      [block-row : i64 (- ground-row 3)]
                      (when (= (array-ref grid (+ (* block-row cols) c)) 0)
                        (array-set! grid (+ (* block-row cols) c) 3)))))))
            (set! c (+ c 1)))))
      true)))

;; Copy WFC grid to level array
(define (wfc-to-level [grid : (Array i64)] [level : (Array i64)] [cols : i64] [rows : i64]) : unit
  (let
    [size : i64 (* cols rows)]
    [i : i64 (cast 0 : i64)]
    (while (< i size)
      (begin
        (array-set! level i (array-ref grid i))
        (set! i (+ i (cast 1 : i64)))))))