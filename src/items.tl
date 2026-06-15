(import "stdlib/ffi.tl")
(import "physics.tl")
(import "world.tl")

;; Items and collectibles: coins, mushrooms, score tracking
;; Coins are placed in the level and collected on player overlap
;; Mushrooms spawn from question blocks and make the player big

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

;; Mushroom constants
(define MUSHROOM-W : f64
  24.0)

(define MUSHROOM-H : f64
  24.0)

(define MUSHROOM-HW : f64
  12.0)

(define MUSHROOM-HH : f64
  12.0)

(define MUSHROOM-SPEED : f64
  60.0)

(define MUSHROOM-GRAVITY : f64
  1400.0)

;; Maximum coins in a level
(define MAX-COINS : i64
  (cast 64 : i64))

;; Maximum mushrooms active at once
(define MAX-MUSHROOMS : i64
  (cast 8 : i64))

;; Coin struct
(defstruct Coin
  (x f64)
  (y f64)
  (active bool))

;; Mushroom struct
(defstruct Mushroom
  (x f64)
  (y f64)
  (vx f64)
  (vy f64)
  (active bool)
  (on-ground bool))

;; Coin array
(define coins : (Array Coin)
  (make-array Coin MAX-COINS))

(define coin-count : i64
  (cast 0 : i64))

;; Mushroom array
(define mushrooms : (Array Mushroom)
  (make-array Mushroom MAX-MUSHROOMS))

(define mushroom-count : i64
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

;; Initialize mushrooms (all inactive)
(define (mushrooms-init) : unit
  (let [i : i64 0]
    (while (< i MAX-MUSHROOMS)
      (begin
        (array-set! mushrooms i
          (Mushroom 0.0 0.0 0.0 0.0 false false))
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

;; Spawn a mushroom at position (pops out and moves right)
(define (mushroom-spawn [mx : f64] [my : f64]) : bool
  (if (>= mushroom-count MAX-MUSHROOMS)
    false
    (begin
      (array-set! mushrooms mushroom-count
        (Mushroom mx my MUSHROOM-SPEED 0.0 true false))
      (set! mushroom-count (+ mushroom-count 1))
      true)))

;; Check if player overlaps a coin (AABB)
(define (player-coin-overlap? [px : f64] [py : f64] [cx : f64] [cy : f64]) : bool
  (and
    (< (- px PLAYER-HW) (+ cx COIN-HW))
    (> (+ px PLAYER-HW) (- cx COIN-HW))
    (< (- py PLAYER-HH) (+ cy COIN-HH))
    (> (+ py PLAYER-HH) (- cy COIN-HH))))

;; Check if player overlaps a mushroom (AABB)
(define (player-mushroom-overlap? [px : f64] [py : f64] [mx : f64] [my : f64]) : bool
  (and
    (< (- px PLAYER-HW) (+ mx MUSHROOM-HW))
    (> (+ px PLAYER-HW) (- mx MUSHROOM-HW))
    (< (- py PLAYER-HH) (+ my MUSHROOM-HH))
    (> (+ py PLAYER-HH) (- my MUSHROOM-HH))))

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

;; Check player vs all mushrooms, collect overlapping ones
;; Returns true if a mushroom was collected this frame
(define (mushrooms-collect [px : f64] [py : f64]) : bool
  (let
    [got-one : bool false]
    [i : i64 0]
    (begin
      (while (< i mushroom-count)
        (begin
          (let
            [m : Mushroom (array-ref mushrooms i)]
            (when (struct-get m active)
              (let
                [mx : f64 (struct-get m x)]
                [my : f64 (struct-get m y)]
                (when (player-mushroom-overlap? px py mx my)
                  (begin
                    (array-set! mushrooms i (Mushroom mx my 0.0 0.0 false false))
                    (player-grow)
                    (set! got-one true))))))
          (set! i (+ i 1))))
      got-one)))

;; Update a single mushroom: gravity + horizontal movement + collision
(define (mushroom-update-single [dt : f64] [level : (Array i64)] [cols : i64] [rows : i64] [idx : i64]) : unit
  (let
    [m : Mushroom (array-ref mushrooms idx)]
    (when (struct-get m active)
      (let
        [x : f64 (struct-get m x)]
        [y : f64 (struct-get m y)]
        [vx : f64 (struct-get m vx)]
        [vy : f64 (struct-get m vy)]
        [on-ground : bool (struct-get m on-ground)]
        ;; Apply gravity
        [new-vy : f64 (+ vy (* MUSHROOM-GRAVITY dt))]
        ;; Move horizontally with collision
        [new-x : f64 (resolve-horizontal level cols rows x y (* vx dt))]
        ;; If horizontal movement was blocked, reverse direction
        [new-vx : f64 (if (= new-x x) (- 0.0 vx) vx)]
        ;; Move vertically with collision
        [vresult : VerticalResult (resolve-vertical level cols rows new-x y (* new-vy dt))]
        [new-y : f64 (struct-get vresult py)]
        [new-on-ground : bool (struct-get vresult on-ground)]
        (begin
          (when new-on-ground
            (set! new-vy 0.0))
          (array-set! mushrooms idx
            (Mushroom new-x new-y new-vx new-vy true new-on-ground)))))))

;; Update all mushrooms
(define (mushrooms-update [dt : f64] [level : (Array i64)] [cols : i64] [rows : i64]) : unit
  (let
    [i : i64 0]
    (while (< i mushroom-count)
      (begin
        (mushroom-update-single dt level cols rows i)
        (set! i (+ i 1))))))

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
