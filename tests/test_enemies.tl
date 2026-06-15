(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/physics.tl")
(import "../src/player.tl")
(import "../src/enemies.tl")

;; Test level: 5x3 grid, bottom row solid
;; 0 0 0 0 0
;; 0 0 0 0 0
;; 1 1 1 1 1
(define (make-test-level) : (Array i64)
  (let
    [level : (Array i64) (make-array i64 15)]
    (begin
      (array-set! level 0 0)
      (array-set! level 1 0)
      (array-set! level 2 0)
      (array-set! level 3 0)
      (array-set! level 4 0)
      (array-set! level 5 0)
      (array-set! level 6 0)
      (array-set! level 7 0)
      (array-set! level 8 0)
      (array-set! level 9 0)
      (array-set! level 10 0)
      (array-set! level 11 0)
      (array-set! level 12 0)
      (array-set! level 13 0)
      (array-set! level 14 0)
      (array-set! level 10 1)
      (array-set! level 11 1)
      (array-set! level 12 1)
      (array-set! level 13 1)
      (array-set! level 14 1)
      level)))

;; Test: enemies-init clears all enemies
(test
  test-enemies-init
  (begin
    (enemies-init)
    (assert-true
      (= enemy-count 0)
      "enemy-count should be 0 after init")
    (let
      [e : Enemy (array-ref enemies 0)]
      (assert-false
        (struct-get e alive)
        "first enemy should be dead after init"))))

;; Test: enemy-spawn adds an enemy
(test
  test-enemy-spawn
  (begin
    (enemies-init)
    (set! enemy-count 0)
    (assert-true
      (enemy-spawn 100.0 50.0)
      "should spawn an enemy")
    (assert-true
      (= enemy-count 1)
      "enemy-count should be 1 after spawn")
    (let
      [e : Enemy (array-ref enemies 0)]
      (begin
        (assert-true
          (struct-get e alive)
          "spawned enemy should be alive")
        (assert-true
          (= (struct-get e x) 100.0)
          "spawned enemy x should be 100.0")
        (assert-true
          (= (struct-get e y) 50.0)
          "spawned enemy y should be 50.0")))))

;; Test: enemy-spawn fails when max reached
(test
  test-enemy-spawn-max
  (begin
    (enemies-init)
    (set! enemy-count 0)
    (let
      [i : i64 0]
      (while (< i MAX-ENEMIES)
        (begin
          (enemy-spawn (cast i : f64) 50.0)
          (set! i (+ i 1)))))
    (assert-false
      (enemy-spawn 999.0 50.0)
      "should fail to spawn when max enemies reached")))

;; Test: enemy walks right
(test
  test-enemy-walk-right
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (enemies-init)
      (set! enemy-count 0)
      ;; Spawn at x=48, facing right, on ground at y=49 (bottom at 63, above ground tile)
      (enemy-spawn 48.0 49.0)
      ;; Update one frame
      (enemies-update 0.1 level 5 3)
      (let
        [e : Enemy (array-ref enemies 0)]
        (assert-true
          (> (struct-get e x) 48.0)
          "enemy should move right")))))

;; Test: enemy turns at wall
(test
  test-enemy-turn-wall
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      ;; Create a level with a wall on the right side
      (array-set! level 2 1)  ;; wall at row 2, col 1
      (array-set! level 7 1)  ;; wall at row 1, col 2
      (enemies-init)
      (set! enemy-count 0)
      ;; Spawn at x=32 (col 1), facing right, on ground at y=49
      (enemy-spawn 32.0 49.0)
      ;; Update several frames
      (enemies-update 0.1 level 5 3)
      (enemies-update 0.1 level 5 3)
      (enemies-update 0.1 level 5 3)
      (let
        [e : Enemy (array-ref enemies 0)]
        (assert-true
          (< (struct-get e vx) 0.0)
          "enemy should turn around and go left")))))

;; Test: enemy falls with gravity
(test
  test-enemy-falls
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (enemies-init)
      (set! enemy-count 0)
      ;; Spawn in air at y=19 (bottom at 33, well above ground)
      (enemy-spawn 48.0 19.0)
      (enemies-update 0.1 level 5 3)
      (let
        [e : Enemy (array-ref enemies 0)]
        (assert-true
          (> (struct-get e y) 20.0)
          "enemy should fall due to gravity")))))

;; Test: enemy lands on ground
(test
  test-enemy-lands
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (enemies-init)
      (set! enemy-count 0)
      (enemy-spawn 48.0 20.0)
      ;; Let it fall several frames
      (enemies-update 0.1 level 5 3)
      (enemies-update 0.1 level 5 3)
      (enemies-update 0.1 level 5 3)
      (enemies-update 0.1 level 5 3)
      (enemies-update 0.1 level 5 3)
      (let
        [e : Enemy (array-ref enemies 0)]
        (assert-true
          (struct-get e on-ground)
          "enemy should land on ground")))))

;; Test: player-enemy-overlap? detects overlap
(test
  test-overlap-detected
  (assert-true
    (player-enemy-overlap? 64.0 64.0 64.0 64.0)
    "player and enemy at same position should overlap"))

;; Test: player-enemy-overlap? no overlap when far apart
(test
  test-no-overlap
  (assert-false
    (player-enemy-overlap? 0.0 0.0 200.0 200.0)
    "player and enemy far apart should not overlap"))

;; Test: player-stomps-enemy? detects stomp
(test
  test-stomp-detected
  (assert-true
    (player-stomps-enemy? 64.0 30.0 100.0 64.0 64.0)
    "player above enemy, falling, should be a stomp"))

;; Test: player-stomps-enemy? no stomp when going up
(test
  test-no-stomp-going-up
  (assert-false
    (player-stomps-enemy? 64.0 30.0 -50.0 64.0 64.0)
    "player going up should not count as stomp"))

;; Test: player-stomps-enemy? no stomp when side by side
(test
  test-no-stomp-side
  (assert-false
    (player-stomps-enemy? 30.0 64.0 100.0 64.0 64.0)
    "player beside enemy should not be stomp"))

;; Test: player-enemy-collide returns stomp result
(test
  test-collide-stomp
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (enemies-init)
      (set! enemy-count 0)
      (enemy-spawn 64.0 50.0)
      ;; Player above enemy, falling down (bottom at 37, enemy top at 36)
      (let
        [result : i64 (player-enemy-collide 64.0 23.0 100.0)]
        (assert-true
          (= result 1)
          "stomp should return 1")))))

;; Test: player-enemy-collide returns side hit result
(test
  test-collide-side
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (enemies-init)
      (set! enemy-count 0)
      (enemy-spawn 64.0 50.0)
      ;; Player beside enemy, not falling (side hit)
      (let
        [result : i64 (player-enemy-collide 50.0 50.0 0.0)]
        (assert-true
          (= result 2)
          "side hit should return 2")))))

;; Test: stomp kills enemy
(test
  test-stomp-kills
  (let
    [level : (Array i64) (make-test-level)]
    (begin
      (enemies-init)
      (set! enemy-count 0)
      (enemy-spawn 64.0 50.0)
      ;; Player stomps enemy (bottom at 37, enemy top at 36)
      (player-enemy-collide 64.0 23.0 100.0)
      (let
        [e : Enemy (array-ref enemies 0)]
        (assert-false
          (struct-get e alive)
          "enemy should be dead after stomp")))))

;; Test: enemy turns at edge (no ground ahead)
(test
  test-enemy-turn-edge
  (let
    ;; Level: bottom row solid, but with a gap at col 2
    [level : (Array i64) (make-array i64 15)]
    (begin
      (array-set! level 0 0)
      (array-set! level 1 0)
      (array-set! level 2 0)
      (array-set! level 3 0)
      (array-set! level 4 0)
      (array-set! level 5 0)
      (array-set! level 6 0)
      (array-set! level 7 0)
      (array-set! level 8 0)
      (array-set! level 9 0)
      (array-set! level 10 1)
      (array-set! level 11 1)
      (array-set! level 12 0)  ;; gap at col 2
      (array-set! level 13 1)
      (array-set! level 14 1)
      (enemies-init)
      (set! enemy-count 0)
      ;; Spawn at col 1 (x=32+16=48), facing right, heading toward gap at col 2
      (enemy-spawn 48.0 50.0)
      ;; Force dir to right
      (let
        [e : Enemy (array-ref enemies 0)]
        (array-set! enemies 0
          (Enemy 48.0 50.0 0.0 0.0 (cast 1 : i64) true false)))
      ;; Update several frames to approach edge
      (enemies-update 0.1 level 5 3)
      (enemies-update 0.1 level 5 3)
      (enemies-update 0.1 level 5 3)
      (let
        [e2 : Enemy (array-ref enemies 0)]
        (assert-true
          (< (struct-get e2 vx) 0.0)
          "enemy should turn left at edge")))))
