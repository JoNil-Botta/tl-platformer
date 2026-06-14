(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/camera.tl")
(import "../src/world.tl")

;; Test: clamp works for middle values
(test
  test-clamp-middle
  (assert-true
    (= (clamp 5.0 0.0 10.0) 5.0)
    "clamp of 5 between 0 and 10 should be 5"))

;; Test: clamp clamps below minimum
(test
  test-clamp-min
  (assert-true
    (= (clamp -5.0 0.0 10.0) 0.0)
    "clamp of -5 between 0 and 10 should be 0"))

;; Test: clamp clamps above maximum
(test
  test-clamp-max
  (assert-true
    (= (clamp 15.0 0.0 10.0) 10.0)
    "clamp of 15 between 0 and 10 should be 10"))

;; Test: world-to-screen-x with zero camera
(test
  test-world-to-screen-x-zero
  (let
    [orig-cam-x : f64 camera-x]
    (begin
      (set! camera-x 0.0)
      (assert-true
        (= (world-to-screen-x 64.0) 64.0)
        "world-to-screen at 0 camera should be identity")
      (set! camera-x orig-cam-x))))

;; Test: world-to-screen-x with offset camera
(test
  test-world-to-screen-x-offset
  (let
    [orig-cam-x : f64 camera-x]
    (begin
      (set! camera-x 100.0)
      (assert-true
        (= (world-to-screen-x 164.0) 64.0)
        "world-to-screen with 100 offset should subtract 100")
      (set! camera-x orig-cam-x))))

;; Test: world-to-screen-y with offset camera
(test
  test-world-to-screen-y-offset
  (let
    [orig-cam-y : f64 camera-y]
    (begin
      (set! camera-y 50.0)
      (assert-true
        (= (world-to-screen-y 150.0) 100.0)
        "world-to-screen-y with 50 offset should subtract 50")
      (set! camera-y orig-cam-y))))

;; Test: is-visible for object fully on screen
(test
  test-is-visible-on-screen
  (let
    [orig-cam-x : f64 camera-x]
    [orig-cam-y : f64 camera-y]
    (begin
      (set! camera-x 0.0)
      (set! camera-y 0.0)
      (assert-true
        (is-visible 100.0 100.0 32.0 32.0 640.0 480.0)
        "object at 100,100 should be visible on screen")
      (set! camera-x orig-cam-x)
      (set! camera-y orig-cam-y))))

;; Test: is-visible for object off-screen to the right
(test
  test-is-visible-off-right
  (let
    [orig-cam-x : f64 camera-x]
    (begin
      (set! camera-x 0.0)
      (assert-false
        (is-visible 700.0 100.0 32.0 32.0 640.0 480.0)
        "object at 700 should be off-screen to the right")
      (set! camera-x orig-cam-x))))

;; Test: is-visible for object off-screen to the left
(test
  test-is-visible-off-left
  (let
    [orig-cam-x : f64 camera-x]
    (begin
      (set! camera-x 100.0)
      (assert-false
        (is-visible 0.0 100.0 32.0 32.0 640.0 480.0)
        "object at 0 with camera at 100 should be off-screen left")
      (set! camera-x orig-cam-x))))
