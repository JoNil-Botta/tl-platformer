(import "stdlib/ffi.tl")
(import "physics.tl")
(import "world.tl")

;; Spring blocks: when player lands on them, launch higher than normal jump

;; Spring bounce velocity (stronger than normal jump)
(define SPRING-BOUNCE-VEL : f64
  -750.0)

;; Spawn spring blocks in a level (replace some ground tiles)
(define (springs-spawn-in-level [lvl : (Array i64)] [cols : i64] [rows : i64]) : unit
  (let
    [i : i64 0]
    (begin
      (while (< i (* cols rows))
        (begin
          (when (= (array-ref lvl i) TILE-GROUND)
            (let
              [col : i64 (% i cols)]
              [row : i64 (/ i cols)]
              (when (= (% col 15) 0)
                (array-set! lvl i TILE-SPRING))))
          (set! i (+ i 1)))))))

;; Check if player is standing on a spring block
(define (on-spring? [px : f64] [py : f64] [lvl : (Array i64)] [cols : i64] [rows : i64]) : bool
  (let
    [bottom-y : f64 (+ py PLAYER-HH)]
    [bottom-row : i64 (floor-div (cast bottom-y : i64) TILE-SIZE)]
    [left-col : i64 (floor-div (cast (- px PLAYER-HW) : i64) TILE-SIZE)]
    [right-col : i64 (floor-div (cast (+ px PLAYER-HW) : i64) TILE-SIZE)]
    [left-spring : bool
      (if (and (>= bottom-row 0) (< bottom-row rows) (>= left-col 0) (< left-col cols))
        (= (array-ref lvl (+ (* bottom-row cols) left-col)) TILE-SPRING)
        false)]
    [right-spring : bool
      (if (and (>= bottom-row 0) (< bottom-row rows) (>= right-col 0) (< right-col cols))
        (= (array-ref lvl (+ (* bottom-row cols) right-col)) TILE-SPRING)
        false)]
    (or left-spring right-spring)))
