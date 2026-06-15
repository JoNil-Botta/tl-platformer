(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/player.tl")
(import "../src/game_state.tl")
(import "../src/items.tl")

;; Test: coins-init clears all coins
(test
  test-coins-init
  (begin
    (coins-init)
    (assert-true
      (= coin-count 0)
      "coin-count should be 0 after init")
    (let
      [c : Coin (array-ref coins 0)]
      (assert-false
        (struct-get c active)
        "first coin should be inactive after init"))))

;; Test: coin-spawn adds a coin
(test
  test-coin-spawn
  (begin
    (coins-init)
    (set! coin-count 0)
    (assert-true
      (coin-spawn 100.0 50.0)
      "should spawn a coin")
    (assert-true
      (= coin-count 1)
      "coin-count should be 1 after spawn")
    (let
      [c : Coin (array-ref coins 0)]
      (begin
        (assert-true
          (struct-get c active)
          "spawned coin should be active")
        (assert-true
          (= (struct-get c x) 100.0)
          "spawned coin x should be 100.0")
        (assert-true
          (= (struct-get c y) 50.0)
          "spawned coin y should be 50.0")))))

;; Test: coin-spawn fails when max reached
(test
  test-coin-spawn-max
  (begin
    (coins-init)
    (set! coin-count 0)
    (let
      [i : i64 0]
      (while (< i MAX-COINS)
        (begin
          (coin-spawn (cast i : f64) 50.0)
          (set! i (+ i 1)))))
    (assert-false
      (coin-spawn 999.0 50.0)
      "should fail to spawn when max coins reached")))

;; Test: player-coin-overlap? detects overlap
(test
  test-coin-overlap
  (assert-true
    (player-coin-overlap? 64.0 64.0 64.0 64.0)
    "player and coin at same position should overlap"))

;; Test: player-coin-overlap? no overlap when far apart
(test
  test-coin-no-overlap
  (assert-false
    (player-coin-overlap? 0.0 0.0 200.0 200.0)
    "player and coin far apart should not overlap"))

;; Test: coins-collect collects overlapping coin and increments score
(test
  test-coin-collect
  (begin
    (coins-init)
    (set! coin-count 0)
    (score-reset)
    (coin-spawn 64.0 64.0)
    ;; Player at same position as coin
    (let
      [collected : i64 (coins-collect 64.0 64.0)]
      (begin
        (assert-true
          (= collected 1)
          "should collect 1 coin")
        (assert-true
          (= score 100)
          "score should be 100 after collecting 1 coin")
        (assert-true
          (= coins-collected 1)
          "coins-collected should be 1")))))

;; Test: collected coin becomes inactive
(test
  test-coin-inactive-after-collect
  (begin
    (coins-init)
    (set! coin-count 0)
    (score-reset)
    (coin-spawn 64.0 64.0)
    (coins-collect 64.0 64.0)
    (let
      [c : Coin (array-ref coins 0)]
      (assert-false
        (struct-get c active)
        "coin should be inactive after collection"))))

;; Test: collecting same inactive coin again does nothing
(test
  test-no-double-collect
  (begin
    (coins-init)
    (set! coin-count 0)
    (score-reset)
    (coin-spawn 64.0 64.0)
    (coins-collect 64.0 64.0)
    (let
      [collected2 : i64 (coins-collect 64.0 64.0)]
      (begin
        (assert-true
          (= collected2 0)
          "should not collect inactive coin again")
        (assert-true
          (= score 100)
          "score should still be 100")))))

;; Test: multiple coins can be collected in one frame
(test
  test-multi-collect
  (begin
    (coins-init)
    (set! coin-count 0)
    (score-reset)
    (coin-spawn 64.0 64.0)
    (coin-spawn 64.0 64.0)
    (coin-spawn 64.0 64.0)
    (let
      [collected : i64 (coins-collect 64.0 64.0)]
      (begin
        (assert-true
          (= collected 3)
          "should collect all 3 overlapping coins")
        (assert-true
          (= score 300)
          "score should be 300 after 3 coins")))))

;; Test: score-reset clears score
(test
  test-score-reset
  (begin
    (coins-init)
    (set! coin-count 0)
    (score-reset)
    (coin-spawn 64.0 64.0)
    (coins-collect 64.0 64.0)
    (score-reset)
    (assert-true
      (= score 0)
      "score should be 0 after reset")
    (assert-true
      (= coins-collected 0)
      "coins-collected should be 0 after reset")))

;; Mushroom tests

;; Test: mushrooms-init clears all mushrooms
(test
  test-mushrooms-init
  (begin
    (mushrooms-init)
    (set! mushroom-count 0)
    (assert-true
      (= mushroom-count 0)
      "mushroom-count should be 0 after init")
    (let
      [m : Mushroom (array-ref mushrooms 0)]
      (assert-false
        (struct-get m active)
        "first mushroom should be inactive after init"))))

;; Test: mushroom-spawn adds a mushroom
(test
  test-mushroom-spawn
  (begin
    (mushrooms-init)
    (set! mushroom-count 0)
    (assert-true
      (mushroom-spawn 100.0 50.0)
      "should spawn a mushroom")
    (assert-true
      (= mushroom-count 1)
      "mushroom-count should be 1 after spawn")
    (let
      [m : Mushroom (array-ref mushrooms 0)]
      (begin
        (assert-true
          (struct-get m active)
          "spawned mushroom should be active")
        (assert-true
          (= (struct-get m x) 100.0)
          "spawned mushroom x should be 100.0")
        (assert-true
          (= (struct-get m y) 50.0)
          "spawned mushroom y should be 50.0")))))

;; Test: mushroom-spawn fails when max reached
(test
  test-mushroom-spawn-max
  (begin
    (mushrooms-init)
    (set! mushroom-count 0)
    (let
      [i : i64 0]
      (while (< i MAX-MUSHROOMS)
        (begin
          (mushroom-spawn (cast i : f64) 50.0)
          (set! i (+ i 1)))))
    (assert-false
      (mushroom-spawn 999.0 50.0)
      "should fail to spawn when max mushrooms reached")))

;; Test: player-mushroom-overlap? detects overlap
(test
  test-mushroom-overlap
  (assert-true
    (player-mushroom-overlap? 64.0 64.0 64.0 64.0)
    "player and mushroom at same position should overlap"))

;; Test: player-mushroom-overlap? no overlap when far apart
(test
  test-mushroom-no-overlap
  (assert-false
    (player-mushroom-overlap? 0.0 0.0 200.0 200.0)
    "player and mushroom far apart should not overlap"))

;; Test: mushrooms-collect makes player big
(test
  test-mushroom-collect-grows-player
  (begin
    (mushrooms-init)
    (set! mushroom-count 0)
    (set! player-big false)
    (mushroom-spawn 64.0 64.0)
    (let
      [got : bool (mushrooms-collect 64.0 64.0)]
      (begin
        (assert-true
          got
          "should collect the mushroom")
        (assert-true
          player-big
          "player should be big after collecting mushroom")))))

;; Test: collected mushroom becomes inactive
(test
  test-mushroom-inactive-after-collect
  (begin
    (mushrooms-init)
    (set! mushroom-count 0)
    (mushroom-spawn 64.0 64.0)
    (mushrooms-collect 64.0 64.0)
    (let
      [m : Mushroom (array-ref mushrooms 0)]
      (assert-false
        (struct-get m active)
        "mushroom should be inactive after collection"))))

;; 1-UP mushroom tests

;; Test: oneups-init clears all 1-UP mushrooms
(test
  test-oneups-init
  (begin
    (oneups-init)
    (set! oneup-count 0)
    (assert-true
      (= oneup-count 0)
      "oneup-count should be 0 after init")
    (let
      [o : OneUp (array-ref oneups 0)]
      (assert-false
        (struct-get o active)
        "first 1-UP should be inactive after init"))))

;; Test: oneup-spawn adds a 1-UP mushroom
(test
  test-oneup-spawn
  (begin
    (oneups-init)
    (set! oneup-count 0)
    (assert-true
      (oneup-spawn 100.0 50.0)
      "should spawn a 1-UP mushroom")
    (assert-true
      (= oneup-count 1)
      "oneup-count should be 1 after spawn")
    (let
      [o : OneUp (array-ref oneups 0)]
      (begin
        (assert-true
          (struct-get o active)
          "spawned 1-UP should be active")
        (assert-true
          (= (struct-get o x) 100.0)
          "spawned 1-UP x should be 100.0")
        (assert-true
          (= (struct-get o y) 50.0)
          "spawned 1-UP y should be 50.0")))))

;; Test: oneup-spawn fails when max reached
(test
  test-oneup-spawn-max
  (begin
    (oneups-init)
    (set! oneup-count 0)
    (let
      [i : i64 0]
      (while (< i MAX-ONEUPS)
        (begin
          (oneup-spawn (cast i : f64) 50.0)
          (set! i (+ i 1)))))
    (assert-false
      (oneup-spawn 999.0 50.0)
      "should fail to spawn when max 1-UPs reached")))

;; Test: player-oneup-overlap? detects overlap
(test
  test-oneup-overlap
  (assert-true
    (player-oneup-overlap? 64.0 64.0 64.0 64.0)
    "player and 1-UP at same position should overlap"))

;; Test: player-oneup-overlap? no overlap when far apart
(test
  test-oneup-no-overlap
  (assert-false
    (player-oneup-overlap? 0.0 0.0 200.0 200.0)
    "player and 1-UP far apart should not overlap"))

;; Test: oneups-collect adds a life
(test
  test-oneup-collect-adds-life
  (begin
    (oneups-init)
    (set! oneup-count 0)
    (game-reset)
    (let
      [start-lives : i64 lives]
      (begin
        (oneup-spawn 64.0 64.0)
        (let
          [got : bool (oneups-collect 64.0 64.0)]
          (begin
            (assert-true
              got
              "should collect the 1-UP")
            (assert-true
              (= lives (+ start-lives 1))
              "lives should increase by 1 after collecting 1-UP")))))))

;; Test: collected 1-UP becomes inactive
(test
  test-oneup-inactive-after-collect
  (begin
    (oneups-init)
    (set! oneup-count 0)
    (oneup-spawn 64.0 64.0)
    (oneups-collect 64.0 64.0)
    (let
      [o : OneUp (array-ref oneups 0)]
      (assert-false
        (struct-get o active)
        "1-UP should be inactive after collection"))))

;; Test: coins-spawn-secrets places coins under a brick ceiling
(test
  test-secret-coins-under-ceiling
  (begin
    (coins-init)
    (set! coin-count 0)
    ;; Build a 10x8 level with a brick ceiling at row 3, cols 3-5
    ;; Empty space below it, solid walls on sides
    (let
      [lvl : (Array i64) (make-array i64 (* 10 8))]
      [i : i64 0]
      (begin
        ;; Clear all to empty
        (while (< i (* 10 8))
          (begin
            (array-set! lvl i TILE-EMPTY)
            (set! i (+ i 1))))
        ;; Solid floor at bottom row (row 7)
        (let [c : i64 0]
          (while (< c 10)
            (begin
              (array-set! lvl (+ (* 7 10) c) TILE-GROUND)
              (set! c (+ c 1)))))
        ;; Brick ceiling at row 3, cols 3-5
        (array-set! lvl (+ (* 3 10) 3) TILE-BRICK)
        (array-set! lvl (+ (* 3 10) 4) TILE-BRICK)
        (array-set! lvl (+ (* 3 10) 5) TILE-BRICK)
        ;; Side walls at col 2 and col 6, rows 3-6
        (let [r : i64 3]
          (while (<= r 6)
            (begin
              (array-set! lvl (+ (* r 10) 2) TILE-BRICK)
              (array-set! lvl (+ (* r 10) 6) TILE-BRICK)
              (set! r (+ r 1)))))
        ;; Spawn secret coins
        (coins-spawn-secrets lvl 10 8)
        ;; Should have spawned coins under the ceiling (rows 4-6, cols 3-5)
        (assert-true
          (> coin-count 0)
          "secret coins should spawn under brick ceiling")))))

;; Test: coins-spawn-secrets does not place coins in open areas
(test
  test-no-secret-coins-in-open
  (begin
    (coins-init)
    (set! coin-count 0)
    ;; Build a flat open level with ground at bottom, nothing above
    (let
      [lvl : (Array i64) (make-array i64 (* 10 8))]
      [i : i64 0]
      (begin
        (while (< i (* 10 8))
          (begin
            (array-set! lvl i TILE-EMPTY)
            (set! i (+ i 1))))
        ;; Ground at bottom
        (let [c : i64 0]
          (while (< c 10)
            (begin
              (array-set! lvl (+ (* 7 10) c) TILE-GROUND)
              (set! c (+ c 1)))))
        (coins-spawn-secrets lvl 10 8)
        (assert-true
          (= coin-count 0)
          "no secret coins should spawn in open areas without ceilings")))))

;; Test: coins-spawn-secrets does not place coins without side walls
(test
  test-no-secret-coins-without-sides
  (begin
    (coins-init)
    (set! coin-count 0)
    ;; Build a level with a brick ceiling but no side walls
    (let
      [lvl : (Array i64) (make-array i64 (* 10 8))]
      [i : i64 0]
      (begin
        (while (< i (* 10 8))
          (begin
            (array-set! lvl i TILE-EMPTY)
            (set! i (+ i 1))))
        ;; Ground at bottom
        (let [c : i64 0]
          (while (< c 10)
            (begin
              (array-set! lvl (+ (* 7 10) c) TILE-GROUND)
              (set! c (+ c 1)))))
        ;; Brick ceiling at row 3, cols 3-5, but open sides
        (array-set! lvl (+ (* 3 10) 3) TILE-BRICK)
        (array-set! lvl (+ (* 3 10) 4) TILE-BRICK)
        (array-set! lvl (+ (* 3 10) 5) TILE-BRICK)
        (coins-spawn-secrets lvl 10 8)
        (assert-true
          (= coin-count 0)
          "no secret coins should spawn without side walls")))))

;; Test: secret coins add to existing coins without clearing them
(test
  test-secret-coins-add-to-existing
  (begin
    (coins-init)
    (set! coin-count 0)
    (coin-spawn 50.0 50.0)
    (let
      [before : i64 coin-count]
      [lvl : (Array i64) (make-array i64 (* 10 8))]
      [i : i64 0]
      (begin
        (while (< i (* 10 8))
          (begin
            (array-set! lvl i TILE-EMPTY)
            (set! i (+ i 1))))
        ;; Ground at bottom
        (let [c : i64 0]
          (while (< c 10)
            (begin
              (array-set! lvl (+ (* 7 10) c) TILE-GROUND)
              (set! c (+ c 1)))))
        ;; Brick ceiling with side walls
        (array-set! lvl (+ (* 3 10) 3) TILE-BRICK)
        (array-set! lvl (+ (* 3 10) 4) TILE-BRICK)
        (array-set! lvl (+ (* 3 10) 5) TILE-BRICK)
        (array-set! lvl (+ (* 4 10) 2) TILE-BRICK)
        (array-set! lvl (+ (* 4 10) 6) TILE-BRICK)
        (coins-spawn-secrets lvl 10 8)
        (assert-true
          (> coin-count before)
          "secret coins should add to existing coins")))))
