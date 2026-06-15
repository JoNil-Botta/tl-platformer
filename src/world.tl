(import "stdlib/ffi.tl")
(import "physics.tl")

;; World/level management
;; Defines level dimensions, start/goal zones, and level bounds

;; Screen dimensions (viewport)
(define SCREEN-W : i64
  (cast 640 : i64))

(define SCREEN-H : i64
  (cast 480 : i64))

(define SCREEN-W-F : f64
  (cast 640.0 : f64))

(define SCREEN-H-F : f64
  (cast 480.0 : f64))

;; Level dimensions (in tiles)
;; Wide level for scrolling
(define LEVEL-COLS : i64
  (cast 80 : i64))

(define LEVEL-ROWS : i64
  (cast 15 : i64))

;; Total level tiles
(define LEVEL-SIZE : i64
  (* LEVEL-COLS LEVEL-ROWS))

;; World dimensions in pixels (uses TILE-SIZE from physics.tl)
(define WORLD-W : f64
  (cast (* LEVEL-COLS TILE-SIZE) : f64))

(define WORLD-H : f64
  (cast (* LEVEL-ROWS TILE-SIZE) : f64))

;; Start zone: player spawns here
(define START-X : f64
  64.0)

(define START-Y : f64
  64.0)

;; Tile type constants
(define TILE-EMPTY : i64
  (cast 0 : i64))

(define TILE-GROUND : i64
  (cast 1 : i64))

(define TILE-PLATFORM : i64
  (cast 2 : i64))

(define TILE-QUESTION : i64
  (cast 3 : i64))

(define TILE-EMPTY-BLOCK : i64
  (cast 4 : i64))

(define TILE-BRICK : i64
  (cast 5 : i64))

(define TILE-PIPE-TOP : i64
  (cast 6 : i64))

(define TILE-PIPE-BODY : i64
  (cast 7 : i64))

;; Goal zone: flag pole position (right side of level)
(define GOAL-X : f64
  (- WORLD-W (* TILE-SIZE-F 3.0)))

(define GOAL-Y : f64
  (* TILE-SIZE-F 3.0))

;; Level data array
(define level : (Array i64)
  (make-array i64 1200))

;; WFC grid (same size as level)
(define wfc-grid : (Array i64)
  (make-array i64 1200))

;; Get tile index from row/col
(define (level-idx [row : i64] [col : i64]) : i64
  (+ (* row LEVEL-COLS) col))

;; Check if player has reached the goal
(define (reached-goal? [px : f64] [py : f64]) : bool
  (and
    (>= px (- GOAL-X TILE-SIZE-F))
    (<= py (+ GOAL-Y TILE-SIZE-F))))

;; Hit a question block from below: if there's a question block at player's head,
;; convert it to an empty block and return true
(define (hit-question-block [level : (Array i64)] [cols : i64] [rows : i64] [px : f64] [py : f64]) : bool
  (let
    [top-y : f64 (- py PLAYER-HH)]
    [top-row : i64 (floor-div (cast top-y : i64) TILE-SIZE)]
    [left-col : i64 (floor-div (cast (- px PLAYER-HW) : i64) TILE-SIZE)]
    [right-col : i64 (floor-div (cast (+ px PLAYER-HW) : i64) TILE-SIZE)]
    [hit-left : bool
      (if (and (>= top-row 0) (< top-row rows) (>= left-col 0) (< left-col cols))
        (= (array-ref level (+ (* top-row cols) left-col)) TILE-QUESTION)
        false)]
    [hit-right : bool
      (if (and (>= top-row 0) (< top-row rows) (>= right-col 0) (< right-col cols))
        (= (array-ref level (+ (* top-row cols) right-col)) TILE-QUESTION)
        false)]
    (begin
      (when hit-left
        (array-set! level (+ (* top-row cols) left-col) TILE-EMPTY-BLOCK))
      (when hit-right
        (array-set! level (+ (* top-row cols) right-col) TILE-EMPTY-BLOCK))
      (or hit-left hit-right))))
