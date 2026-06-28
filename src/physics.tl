(import "stdlib/ffi.tl")

;; Constants
(define TILE-SIZE : i64
  (cast 32 : i64))

(define TILE-SIZE-F : f64
  (cast 32.0 : f64))

;; Player hitbox dimensions (slightly smaller than tile for leniency)
(define PLAYER-W : f64
  28.0)

(define PLAYER-H : f64
  28.0)

(define PLAYER-HW : f64
  14.0)

(define PLAYER-HH : f64
  14.0)

;; Abs helper for f64
(define (abs-f64 [x : f64]) : f64
  (if (< x 0.0) (- 0.0 x) x))

;; Check if a tile coordinate is solid (bounds = solid walls)
;; Any non-zero tile type is solid
(define (tile-solid? [level : (Array i64)] [cols : i64] [rows : i64] [col : i64] [row : i64]) : bool
  (if (or (< col 0) (>= col cols) (< row 0) (>= row rows))
    true
    (not (= (array-ref level (+ (* row cols) col)) 0))))

;; Floor division: works correctly for negative numerators
;; C integer division truncates toward zero; we need floor for tile coords
(define (floor-div [a : i64] [b : i64]) : i64
  (let
    [q : i64 (/ a b)]
    [r : i64 (% a b)]
    (if (and (not (= r 0)) (< r 0))
      (- q 1)
      q)))

;; Check if a point is inside a solid tile
(define (point-solid? [level : (Array i64)] [cols : i64] [rows : i64] [x : f64] [y : f64]) : bool
  (tile-solid? level cols rows
    (floor-div (cast x : i64) TILE-SIZE)
    (floor-div (cast y : i64) TILE-SIZE)))

;; Check if a player position collides with any solid tiles
(define (player-collides? [level : (Array i64)] [cols : i64] [rows : i64] [px : f64] [py : f64]) : bool
  (let
    [left   : f64 (- px PLAYER-HW)]
    [right  : f64 (+ px PLAYER-HW)]
    [top    : f64 (- py PLAYER-HH)]
    [bottom : f64 (+ py PLAYER-HH)]
    (or
      (point-solid? level cols rows left top)
      (point-solid? level cols rows left bottom)
      (point-solid? level cols rows right top)
      (point-solid? level cols rows right bottom))))

;; Resolve horizontal movement with wall collision
;; If collision, don't move. Otherwise move freely.
(define (resolve-horizontal [level : (Array i64)] [cols : i64] [rows : i64] [px : f64] [py : f64] [dx : f64]) : f64
  (let
    [new-px : f64 (+ px dx)]
    (if (player-collides? level cols rows new-px py)
      px
      new-px)))

;; Result struct for vertical collision resolution
(defstruct VerticalResult
  (py f64)
  (on-ground bool)
  (hit-ceiling bool))

;; Find the first solid row below the player, starting from start-row
(define (find-first-solid-below [level : (Array i64)] [cols : i64] [rows : i64] [col : i64] [start-row : i64]) : i64
  (let
    [row : i64 start-row]
    (begin
      (while (and (< row rows) (not (tile-solid? level cols rows col row)))
        (set! row (+ row 1)))
      row)))

;; Resolve vertical movement with ground/ceiling collision
;; For downward: snap to ground. For upward: stop at ceiling.
(define (resolve-vertical [level : (Array i64)] [cols : i64] [rows : i64] [px : f64] [py : f64] [dy : f64]) : VerticalResult
  (let
    [new-py : f64 (+ py dy)]
    (if (player-collides? level cols rows px new-py)
      ;; Collision detected - need to find exact contact point
      (if (> dy 0.0)
        ;; Moving down: find first solid row below and snap to top of it
        (let
          [bottom-y : f64 (+ py PLAYER-HH)]
          [current-row : i64 (floor-div (cast bottom-y : i64) TILE-SIZE)]
          [left-col : i64 (floor-div (cast (- px PLAYER-HW) : i64) TILE-SIZE)]
          [right-col : i64 (floor-div (cast (+ px PLAYER-HW) : i64) TILE-SIZE)]
          [snap-row-left : i64 (find-first-solid-below level cols rows left-col current-row)]
          [snap-row-right : i64 (find-first-solid-below level cols rows right-col current-row)]
          [snap-row : i64 (if (< snap-row-left snap-row-right) snap-row-left snap-row-right)]
          (VerticalResult
            (- (- (cast (* snap-row TILE-SIZE) : f64) PLAYER-HH) 0.1)
            true
            false))
        ;; Moving up: snap to bottom of tile above, report ceiling hit
        (let
          [top-y : f64 (- new-py PLAYER-HH)]
          [top-row : i64 (floor-div (cast top-y : i64) TILE-SIZE)]
          [snap-row : i64 (if (< top-row 0) -1 top-row)]
          (VerticalResult
            (+ (+ (cast (* (+ snap-row 1) TILE-SIZE) : f64) PLAYER-HH) 0.1)
            false
            true)))
      (VerticalResult new-py false false))))

;; Check if player is on ground (point at feet)
(define (on-ground? [level : (Array i64)] [cols : i64] [rows : i64] [px : f64] [py : f64]) : bool
  (point-solid? level cols rows px (+ (+ py PLAYER-HH) 0.1)))
