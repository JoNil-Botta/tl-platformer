(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/screen_shake.tl")

;; Test: shake starts at zero
(test
  test-shake-starts-zero
  (begin
    (assert-equal (get-shake-x) 0.0 "shake-x should start at 0")
    (assert-equal (get-shake-y) 0.0 "shake-y should start at 0")
    (assert-equal (is-shaking?) false "should not be shaking initially")))

;; Test: trigger shake activates it
(test
  test-trigger-shake
  (begin
    (shake-reset)
    (trigger-shake 10.0 0.5)
    (assert-equal (is-shaking?) true "should be shaking after trigger")
    ;; Update a tiny amount — offset should be non-zero (random but bounded)
    (update-shake 0.01)
    (assert-equal (> (abs (get-shake-x)) 0.0) true "shake-x should be non-zero")
    (assert-equal (> (abs (get-shake-y)) 0.0) true "shake-y should be non-zero")))

;; Test: shake decays over time
(test
  test-shake-decay
  (begin
    (shake-reset)
    (trigger-shake 10.0 1.0)
    ;; Update for a long time — shake should die out
    (update-shake 2.0)
    (assert-equal (is-shaking?) false "shake should expire after duration")
    (assert-equal (get-shake-x) 0.0 "shake-x should return to 0")
    (assert-equal (get-shake-y) 0.0 "shake-y should return to 0")))

;; Test: reset clears shake immediately
(test
  test-shake-reset
  (begin
    (trigger-shake 10.0 1.0)
    (shake-reset)
    (assert-equal (is-shaking?) false "should not shake after reset")
    (assert-equal (get-shake-x) 0.0 "shake-x should be 0 after reset")
    (assert-equal (get-shake-y) 0.0 "shake-y should be 0 after reset")))

;; Test: hash-random produces values in [0, 1)
(test
  test-hash-random-range
  (let
    [r : f64 (hash-random 42)]
    (begin
      (assert-equal (>= r 0.0) true "hash-random should be >= 0")
      (assert-equal (< r 1.0) true "hash-random should be < 1"))))

;; Test: hash-random is deterministic
(test
  test-hash-random-deterministic
  (let
    [r1 : f64 (hash-random 123)]
    [r2 : f64 (hash-random 123)]
    (assert-equal r1 r2 "same seed should produce same value")))

;; Test: shake offset is bounded by intensity
(test
  test-shake-bounded
  (begin
    (shake-reset)
    (trigger-shake 5.0 1.0)
    (update-shake 0.016)
    (assert-equal (<= (abs (get-shake-x)) 5.0) true "shake-x should be <= intensity")
    (assert-equal (<= (abs (get-shake-y)) 5.0) true "shake-y should be <= intensity")))

;; Test: small/medium/large presets are ordered
(test
  test-shake-presets
  (begin
    (assert-equal (< SHAKE-SMALL SHAKE-MEDIUM) true "small < medium")
    (assert-equal (< SHAKE-MEDIUM SHAKE-LARGE) true "medium < large")))
