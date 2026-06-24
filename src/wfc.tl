(import "stdlib/ffi.tl")
(import "world.tl")

;; Seeded pseudo-random number generator (LCG)
;; Deterministic per seed -- essential for testing
(define wfc-rng-state : i64
  (cast 0 : i64))

(define (wfc-rng-seed! [s : i64]) : unit
  (set! wfc-rng-state s))

(define (wfc-rng-next) : i64
  (begin
    (set! wfc-rng-state (% (+ (* wfc-rng-state (cast 1103515245 : i64)) (cast 12345 : i64)) (cast 2147483648 : i64)))
    wfc-rng-state))

;; Random integer in range [0, n-1]
(define (wfc-rng-int [n : i64]) : i64
  (% (wfc-rng-next) n))

;; Random integer in range [lo, hi-1]
(define (wfc-rng-range [lo : i64] [hi : i64]) : i64
  (+ lo (% (wfc-rng-next) (- hi lo))))

;; Check if a tile type is solid (non-empty)
(define (tile-solid-type? [t : i64]) : bool
  (not (= t TILE-EMPTY)))

;; Generate a platformer level into the given grid with seed
;; Returns true on success
(define (wfc-generate [grid : (Array i64)] [cols : i64] [rows : i64] [seed : i64]) : bool
  (let
    [size : i64 (* cols rows)]
    (begin
      ;; Seed RNG
      (wfc-rng-seed! seed)

      ;; Clear grid to empty
      (let
        [i : i64 (cast 0 : i64)]
        (while (< i size)
          (begin
            (array-set! grid i TILE-EMPTY)
            (set! i (+ i (cast 1 : i64))))))

      ;; Top 2 rows always empty (sky)
      (let
        [c : i64 (cast 0 : i64)]
        (while (< c cols)
          (begin
            (array-set! grid c TILE-EMPTY)
            (array-set! grid (+ cols c) TILE-EMPTY)
            (set! c (+ c (cast 1 : i64))))))

      ;; Bottom row: solid ground
      (let
        [c : i64 (cast 0 : i64)]
        (while (< c cols)
          (begin
            (array-set! grid (+ (* (- rows (cast 1 : i64)) cols) c) TILE-GROUND)
            (set! c (+ c (cast 1 : i64))))))

      ;; Second-to-bottom row: mostly ground, some brick variation
      (let
        [c : i64 (cast 0 : i64)]
        (while (< c cols)
          (begin
            (when (= (wfc-rng-int (cast 5 : i64)) (cast 0 : i64))
              (begin
                (array-set! grid (+ (* (- rows (cast 2 : i64)) cols) c) TILE-BRICK)
                (when (= (wfc-rng-int (cast 3 : i64)) (cast 0 : i64))
                  (array-set! grid (+ (* (- rows (cast 3 : i64)) cols) c) TILE-BRICK))))
            (set! c (+ c (cast 1 : i64))))))

      ;; Pipe stacks: 1-2 pipes at random x positions
      (let
        [pipe-count : i64 (+ (cast 1 : i64) (wfc-rng-int (cast 2 : i64)))]
        [p : i64 (cast 0 : i64)]
        (while (< p pipe-count)
          (begin
            (let
              [pipe-x : i64 (+ (cast 5 : i64) (wfc-rng-int (- cols (cast 10 : i64))))]
              [pipe-height : i64 (+ (cast 2 : i64) (wfc-rng-int (cast 3 : i64)))]
              [ground-row : i64 (- rows (cast 2 : i64))]
              [top-row : i64 (- ground-row (- pipe-height (cast 1 : i64)))]
              (begin
                ;; Place pipe body from ground-row down to top-row+1
                (let
                  [r : i64 ground-row]
                  (while (>= r (+ top-row (cast 1 : i64)))
                    (begin
                      (array-set! grid (+ (* r cols) pipe-x) TILE-PIPE-BODY)
                      (set! r (- r (cast 1 : i64))))))
                ;; Place pipe top at top-row
                (when (>= top-row 0)
                  (array-set! grid (+ (* top-row cols) pipe-x) TILE-PIPE-TOP))))
            (set! p (+ p (cast 1 : i64))))))

      ;; Floating platforms: 3-5 platforms at mid-height
      (let
        [platform-count : i64 (+ (cast 3 : i64) (wfc-rng-int (cast 3 : i64)))]
        [pl : i64 (cast 0 : i64)]
        (while (< pl platform-count)
          (begin
            (let
              [plat-y : i64 (+ (cast 4 : i64) (wfc-rng-int (- rows (cast 8 : i64))))]
              [plat-x : i64 (+ (cast 3 : i64) (wfc-rng-int (- cols (cast 6 : i64))))]
              [plat-w : i64 (+ (cast 3 : i64) (wfc-rng-int (cast 4 : i64)))]
              [px : i64 (cast 0 : i64)]
              (while (< px plat-w)
                (begin
                  (when (< (+ plat-x px) cols)
                    (array-set! grid (+ (* plat-y cols) (+ plat-x px)) TILE-PLATFORM))
                  (set! px (+ px (cast 1 : i64))))))
            (set! pl (+ pl (cast 1 : i64))))))

      ;; Question blocks: place above solid ground where reachable
      (let
        [c : i64 (cast 3 : i64)]
        (while (< c (- cols (cast 3 : i64)))
          (begin
            (when (= (% c (cast 5 : i64)) (cast 2 : i64))
              (let
                [ground-row : i64 (- rows (cast 2 : i64))]
                (begin
                  ;; Find ground in this column
                  (while (and (>= ground-row 0) (= (array-ref grid (+ (* ground-row cols) c)) TILE-EMPTY))
                    (set! ground-row (- ground-row 1)))
                  ;; If ground found and there is space above, place question block
                  (when (>= ground-row 2)
                    (let
                      [block-row : i64 (- ground-row 1)]
                      (when (= (array-ref grid (+ (* block-row cols) c)) TILE-EMPTY)
                        (array-set! grid (+ (* block-row cols) c) TILE-QUESTION)))))))
            (set! c (+ c 1)))))

      ;; Brick ceilings: horizontal rows of bricks creating secret areas underneath
      (let
        [ceiling-count : i64 (+ (cast 1 : i64) (wfc-rng-int (cast 3 : i64)))]
        [c : i64 (cast 0 : i64)]
        (while (< c ceiling-count)
          (begin
            (let
              [cy : i64 (+ (cast 3 : i64) (wfc-rng-int (- rows (cast 7 : i64))))]
              [cx : i64 (+ (cast 3 : i64) (wfc-rng-int (- cols (cast 10 : i64))))]
              [cw : i64 (+ (cast 3 : i64) (wfc-rng-int (cast 5 : i64)))]
              [px : i64 (cast 0 : i64)]
              (while (< px cw)
                (begin
                  (when (< (+ cx px) (- cols 2))
                    (array-set! grid (+ (* cy cols) (+ cx px)) TILE-BRICK))
                  (set! px (+ px (cast 1 : i64))))))
            (set! c (+ c (cast 1 : i64))))))

      ;; Small brick barriers attached to platforms or ground (secret alcoves)
      (let
        [barrier-count : i64 (wfc-rng-int (cast 3 : i64))]
        [b : i64 (cast 0 : i64)]
        (while (< b barrier-count)
          (begin
            (let
              [bc : i64 (+ (cast 4 : i64) (wfc-rng-int (- cols (cast 8 : i64))))]
              [br : i64 (+ (cast 4 : i64) (wfc-rng-int (- rows (cast 7 : i64))))]
              (begin
                ;; Place a small L-shaped brick cluster if there is something solid nearby
                (when (> (array-ref grid (+ (* br cols) bc)) TILE-EMPTY)
                  (begin
                    (array-set! grid (+ (* br cols) bc) TILE-BRICK)
                    (when (< (+ bc 1) cols)
                      (array-set! grid (+ (* br cols) (+ bc 1)) TILE-BRICK))
                    (when (> (- br 1) 0)
                      (array-set! grid (+ (* (- br 1) cols) bc) TILE-BRICK))))))
            (set! b (+ b (cast 1 : i64))))))

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
