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
