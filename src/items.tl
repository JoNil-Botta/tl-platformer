(import "stdlib/ffi.tl")
(import "physics.tl")
(import "world.tl")

;; Items and collectibles: coins, score tracking
;; Coins are placed in the level and collected on player overlap

;; Coin constants
(define COIN-RADIUS : f64
  10.0)

(define COIN-WIDTH : f64
  20.0)

(define COIN-HEIGHT : f64
  20.0)

(define COIN-HW : f64
  10.0)

(define COIN-HH : f64
  10.0)

;; Maximum coins in a level
(define MAX-COINS : i64
  (cast 64 : i64))

;; Coin struct
(defstruct Coin
  (x f64)
  (y f64)
  (active bool))

;; Coin array
(define coins : (Array Coin)
  (make-array Coin MAX-COINS))

(define coin-count : i64
  (cast 0 : i64))

;; Score tracking
(define score : i64
  (cast 0 : i64))

(define coins-collected : i64
  (cast 0 : i64))

;; Initialize coins (all inactive)
(define (coins-init) : unit
  (let [i : i64 0]
    (while (< i MAX-COINS)
      (begin
        (array-set! coins i
          (Coin 0.0 0.0 false))
        (set! i (+ i 1))))))

;; Spawn a coin at position
(define (coin-spawn [cx : f64] [cy : f64]) : bool
  (if (>= coin-count MAX-COINS)
    false
    (begin
      (array-set! coins coin-count
        (Coin cx cy true))
      (set! coin-count (+ coin-count 1))
      true)))

;; Check if player overlaps a coin (AABB)
(define (player-coin-overlap? [px : f64] [py : f64] [cx : f64] [cy : f64]) : bool
  (and
    (< (- px PLAYER-HW) (+ cx COIN-HW))
    (> (+ px PLAYER-HW) (- cx COIN-HW))
    (< (- py PLAYER-HH) (+ cy COIN-HH))
    (> (+ py PLAYER-HH) (- cy COIN-HH))))

;; Check player vs all coins, collect overlapping ones
;; Returns number of coins collected this frame
(define (coins-collect [px : f64] [py : f64]) : i64
  (let
    [collected : i64 (cast 0 : i64)]
    [i : i64 0]
    (begin
      (while (< i coin-count)
        (begin
          (let
            [c : Coin (array-ref coins i)]
            (when (struct-get c active)
              (let
                [cx : f64 (struct-get c x)]
                [cy : f64 (struct-get c y)]
                (when (player-coin-overlap? px py cx cy)
                  (begin
                    (array-set! coins i (Coin cx cy false))
                    (set! collected (+ collected 1)))))))
          (set! i (+ i 1))))
      (when (> collected 0)
        (begin
          (set! score (+ score (* collected (cast 100 : i64))))
          (set! coins-collected (+ coins-collected collected))))
      collected)))

;; Spawn coins in a level
;; Places coins at regular intervals above ground tiles, skipping start/goal zones
(define (coins-spawn-in-level [level : (Array i64)] [cols : i64] [rows : i64]) : unit
  (begin
    (coins-init)
    (set! coin-count 0)
    (let
      [spacing : i64 8]
      [last-col : i64 0]
      [col : i64 4]
      (while (< col (- cols 5))
        (begin
          (when (>= (- col last-col) spacing)
            (let
              [row : i64 (- rows 2)]
              (begin
                ;; Find a spot above ground with empty space
                (while (and (>= row 0) (tile-solid? level cols rows col row))
                  (set! row (- row 1)))
                (when (and (>= row 1) (not (tile-solid? level cols rows col row)))
                  (begin
                    (let
                      [cx : f64 (+ (* (cast col : f64) TILE-SIZE-F) (* TILE-SIZE-F 0.5))]
                      [cy : f64 (- (* (cast row : f64) TILE-SIZE-F) (* TILE-SIZE-F 0.5))]
                      (coin-spawn cx cy))
                    (set! last-col col))))))
          (set! col (+ col 1)))))))

;; Reset score (for new game/level)
(define (score-reset) : unit
  (begin
    (set! score 0)
    (set! coins-collected 0)))
