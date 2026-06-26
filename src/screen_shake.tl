(import "stdlib/ffi.tl")

;; Screen shake system
;; Adds temporary camera offset for impact feedback

;; Current shake offset (applied in addition to camera position)
(define shake-x : f64
  0.0)

(define shake-y : f64
  0.0)

;; Remaining shake duration (seconds)
(define shake-timer : f64
  0.0)

;; Current shake intensity (pixels)
(define shake-intensity : f64
  0.0)

;; Shake decay rate (intensity per second)
(define SHAKE-DECAY : f64
  8.0)

;; Predefined shake presets
(define SHAKE-SMALL : f64
  3.0)

(define SHAKE-MEDIUM : f64
  6.0)

(define SHAKE-LARGE : f64
  12.0)

;; Simple hash for deterministic random from a seed value
;; Returns a value in range [0.0, 1.0)
(define (hash-random [seed : i64]) : f64
  (let
    [x : i64 (+ (* seed 1103515245) 12345)]
    (/ (cast (% (bit-and x 2147483647) 10000) : f64) 10000.0)))

;; Current seed for shake randomness (increments each frame)
(define shake-seed : i64
  (cast 0 : i64))

;; Trigger a screen shake with given intensity and duration
(define (trigger-shake [intensity : f64] [duration : f64]) : unit
  (begin
    (set! shake-intensity intensity)
    (set! shake-timer duration)))

;; Update shake: decay intensity, compute new random offset
;; Call once per frame with dt
(define (update-shake [dt : f64]) : unit
  (if (> shake-timer 0.0)
    (begin
      (set! shake-timer (- shake-timer dt))
      (set! shake-intensity (- shake-intensity (* SHAKE-DECAY dt)))
      (when (<= shake-intensity 0.0)
        (begin
          (set! shake-intensity 0.0)
          (set! shake-timer 0.0)))
      ;; Generate random offset using hash (deterministic per frame)
      (set! shake-seed (+ shake-seed (cast 1 : i64)))
      (let
        [r1 : f64 (hash-random shake-seed)]
        [r2 : f64 (hash-random (+ shake-seed (cast 73 : i64)))]
        (begin
          (set! shake-x (* (- (* r1 2.0) 1.0) shake-intensity))
          (set! shake-y (* (- (* r2 2.0) 1.0) shake-intensity)))))
    (begin
      (set! shake-x 0.0)
      (set! shake-y 0.0))))

;; Get current shake offset X
(define (get-shake-x) : f64
  shake-x)

;; Get current shake offset Y
(define (get-shake-y) : f64
  shake-y)

;; Check if shake is currently active
(define (is-shaking?) : bool
  (> shake-timer 0.0))

;; Reset shake to zero immediately
(define (shake-reset) : unit
  (begin
    (set! shake-x 0.0)
    (set! shake-y 0.0)
    (set! shake-timer 0.0)
    (set! shake-intensity 0.0)))
