(import "stdlib/ffi.tl")
(import "physics.tl")
(import "world.tl")
(import "player.tl")

;; Enemy system: simple patrol enemies
;; Enemies walk back and forth, turn at walls and edges

;; Enemy constants
(define ENEMY-W : f64
  28.0)

(define ENEMY-H : f64
  28.0)

(define ENEMY-HW : f64
  14.0)

(define ENEMY-HH : f64
  14.0)

(define ENEMY-SPEED : f64
  80.0)

(define ENEMY-GRAVITY : f64
  1400.0)

;; Maximum number of enemies
(define MAX-ENEMIES : i64
  (cast 16 : i64))

;; Enemy struct
(defstruct Enemy
  (x f64)
  (y f64)
  (vx f64)
  (vy f64)
  (dir i64)
  (alive bool)
  (on-ground bool))

;; Enemy array (global for game loop, testable)
(define enemies : (Array Enemy)
  (make-array Enemy MAX-ENEMIES))

(define enemy-count : i64
  (cast 0 : i64))

;; Initialize enemy array (all dead)
(define (enemies-init) : unit
  (let [i : i64 0]
    (while (< i MAX-ENEMIES)
      (begin
        (array-set! enemies i
          (Enemy 0.0 0.0 0.0 0.0 (cast 1 : i64) false false))
        (set! i (+ i 1))))))

;; Spawn an enemy at a position
(define (enemy-spawn [ex : f64] [ey : f64]) : bool
  (if (>= enemy-count MAX-ENEMIES)
    false
    (begin
      (array-set! enemies enemy-count
        (Enemy ex ey 0.0 0.0 (cast 1 : i64) true false))
      (set! enemy-count (+ enemy-count 1))
      true)))

;; Check if there's ground ahead in the walking direction
(define (ground-ahead? [level : (Array i64)] [cols : i64] [rows : i64] [ex : f64] [ey : f64] [dir : i64]) : bool
  (let
    [ahead-x : f64 (+ ex (* (cast dir : f64) (+ ENEMY-HW 2.0)))]
    [check-y : f64 (+ (+ ey ENEMY-HH) 4.0)]
    (point-solid? level cols rows ahead-x check-y)))

;; Check if enemy collides with a wall in the walking direction
(define (wall-ahead? [level : (Array i64)] [cols : i64] [rows : i64] [ex : f64] [ey : f64] [dir : i64]) : bool
  (let
    [ahead-x : f64 (+ ex (* (cast dir : f64) (+ ENEMY-HW 2.0)))]
    (point-solid? level cols rows ahead-x ey)))

;; Update a single enemy
(define (enemy-update-single [dt : f64] [level : (Array i64)] [cols : i64] [rows : i64] [idx : i64]) : unit
  (let
    [e : Enemy (array-ref enemies idx)]
    (when (struct-get e alive)
      (let
        [x : f64 (struct-get e x)]
        [y : f64 (struct-get e y)]
        [dir : i64 (struct-get e dir)]
        [vy : f64 (struct-get e vy)]
        [on-ground : bool (struct-get e on-ground)]
        ;; Walk in current direction
        [walk-vx : f64 (* (cast dir : f64) ENEMY-SPEED)]
        ;; Check for wall ahead
        [hit-wall : bool (wall-ahead? level cols rows x y dir)]
        ;; Check for edge ahead (no ground)
        [at-edge : bool (not (ground-ahead? level cols rows x y dir))]
        ;; Turn around if wall or edge
        [new-dir : i64
          (if (or hit-wall (and on-ground at-edge))
            (- 0 dir)
            dir)]
        [new-vx : f64 (* (cast new-dir : f64) ENEMY-SPEED)]
        (begin
          ;; Apply gravity
          (set! vy (+ vy (* ENEMY-GRAVITY dt)))
          ;; Move horizontally with collision
          (set! x (resolve-horizontal level cols rows x y (* new-vx dt)))
          ;; Move vertically with collision
          (let
            [vresult : VerticalResult (resolve-vertical level cols rows x y (* vy dt))]
            (begin
              (set! y (struct-get vresult py))
              (set! on-ground (struct-get vresult on-ground))
              (when on-ground
                (set! vy 0.0))))
          ;; Store updated enemy
          (array-set! enemies idx
            (Enemy x y new-vx vy new-dir true on-ground)))))))

;; Update all enemies
(define (enemies-update [dt : f64] [level : (Array i64)] [cols : i64] [rows : i64]) : unit
  (let
    [i : i64 0]
    (while (< i enemy-count)
      (begin
        (enemy-update-single dt level cols rows i)
        (set! i (+ i 1))))))

;; Check if player stomps enemy (player above, falling)
(define (player-stomps-enemy? [px : f64] [py : f64] [pvy : f64] [ex : f64] [ey : f64]) : bool
  (and
    (> pvy 0.0)
    (< (+ py PLAYER-HH) (+ (- ey ENEMY-HH) 8.0))
    (< (- px PLAYER-HW) (+ ex ENEMY-HW))
    (> (+ px PLAYER-HW) (- ex ENEMY-HW))))

;; Check AABB overlap between player and enemy
(define (player-enemy-overlap? [px : f64] [py : f64] [ex : f64] [ey : f64]) : bool
  (and
    (< (- px PLAYER-HW) (+ ex ENEMY-HW))
    (> (+ px PLAYER-HW) (- ex ENEMY-HW))
    (< (- py PLAYER-HH) (+ ey ENEMY-HH))
    (> (+ py PLAYER-HH) (- ey ENEMY-HH))))

;; Check player vs all enemies
;; Returns: 0 = no collision, 1 = stomp, 2 = side hit
(define (player-enemy-collide [px : f64] [py : f64] [pvy : f64]) : i64
  (let
    [result : i64 (cast 0 : i64)]
    [i : i64 0]
    (begin
      (while (< i enemy-count)
        (let
          [e : Enemy (array-ref enemies i)]
          (begin
            (when (struct-get e alive)
              (let
                [ex : f64 (struct-get e x)]
                [ey : f64 (struct-get e y)]
                (when (player-enemy-overlap? px py ex ey)
                  (if (player-stomps-enemy? px py pvy ex ey)
                    (begin
                      (array-set! enemies i
                        (Enemy ex ey 0.0 0.0 (struct-get e dir) false false))
                      (set! result (cast 1 : i64)))
                    (begin
                      (when (not (player-take-damage))
                      (set! result (cast 2 : i64))))))))
            (set! i (+ i 1)))))
      result)))

;; Spawn enemies along the level ground with custom spacing
;; spacing: minimum columns between enemy spawns (smaller = more enemies)
(define (enemies-spawn-in-level-with-spacing [level : (Array i64)] [cols : i64] [rows : i64] [spacing : i64]) : unit
  (begin
    (enemies-init)
    (let
      [last-col : i64 0]
      [col : i64 5]
      (while (< col (- cols 5))
        (begin
          (when (>= (- col last-col) spacing)
            (let
              [row : i64 (- rows 1)]
              (begin
                (while (and (>= row 0) (not (tile-solid? level cols rows col row)))
                  (set! row (- row 1)))
                (when (>= row 0)
                  (begin
                    (let
                      [ex : f64 (+ (* (cast col : f64) TILE-SIZE-F) (* TILE-SIZE-F 0.5))]
                      [ey : f64 (- (* (cast row : f64) TILE-SIZE-F) ENEMY-HH)]
                      (enemy-spawn ex ey))
                    (set! last-col col))))))
          (set! col (+ col 1)))))))

;; Spawn enemies along the level ground with default spacing
;; Places enemies at regular intervals, skipping start and goal zones
(define (enemies-spawn-in-level [level : (Array i64)] [cols : i64] [rows : i64]) : unit
  (enemies-spawn-in-level-with-spacing level cols rows (cast 10 : i64)))

;; Kill all enemies touching player (for star power-up)
;; Returns number of enemies killed
(define (star-kill-enemies [px : f64] [py : f64]) : i64
  (let
    [count : i64 0]
    [i : i64 0]
    (begin
      (while (< i enemy-count)
        (let
          [e : Enemy (array-ref enemies i)]
          (begin
            (when (struct-get e alive)
              (let
                [ex : f64 (struct-get e x)]
                [ey : f64 (struct-get e y)]
                [dx : f64 (- px ex)]
                [dy : f64 (- py ey)]
                [hw : f64 (+ PLAYER-HW ENEMY-HW)]
                [hh : f64 (+ PLAYER-HH ENEMY-HH)]
                (when (and (< (abs-f64 dx) hw) (< (abs-f64 dy) hh))
                  (begin
                    (array-set! enemies i
                      (Enemy
                        (struct-get e x)
                        (struct-get e y)
                        0.0
                        0.0
                        (struct-get e dir)
                        false
                        false))
                    (set! score (+ score 200))
                    (set! count (+ count 1))))))
            (set! i (+ i 1)))))
      count)))

;; Check if fireball hits any enemy
;; Returns number of enemies killed
(define (fireball-hit-enemies [fx : f64] [fy : f64]) : i64
  (let
    [count : i64 0]
    [i : i64 0]
    (begin
      (while (< i enemy-count)
        (let
          [e : Enemy (array-ref enemies i)]
          (begin
            (when (struct-get e alive)
              (let
                [ex : f64 (struct-get e x)]
                [ey : f64 (struct-get e y)]
                [dx : f64 (- fx ex)]
                [dy : f64 (- fy ey)]
                [hw : f64 (+ 4.0 ENEMY-HW)]
                [hh : f64 (+ 4.0 ENEMY-HH)]
                (when (and (< (abs-f64 dx) hw) (< (abs-f64 dy) hh))
                  (begin
                    (array-set! enemies i
                      (Enemy
                        (struct-get e x)
                        (struct-get e y)
                        0.0
                        0.0
                        (struct-get e dir)
                        false
                        false))
                    (set! score (+ score 200))
                    (set! count (+ count 1))))))
            (set! i (+ i 1)))))
      count)))
