(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/player.tl")
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
