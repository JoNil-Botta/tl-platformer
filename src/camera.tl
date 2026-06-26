(import "stdlib/ffi.tl")
(import "screen_shake.tl")

;; Smooth follow camera with lookahead and bounds
;; All values in world (pixel) coordinates

;; Camera state (top-left corner of viewport)
(define camera-x : f64
  0.0)

(define camera-y : f64
  0.0)

;; Smoothing factor (higher = tighter follow, 0-1 range)
(define CAMERA-SMOOTH : f64
  0.12)

;; Lookahead distance in pixels
(define CAMERA-LOOKAHEAD : f64
  60.0)

;; Initialize camera to center on a position
(define (camera-init [target-x : f64] [target-y : f64] [screen-w : f64] [screen-h : f64]) : unit
  (begin
    (set! camera-x (- target-x (* screen-w 0.5)))
    (set! camera-y (- target-y (* screen-h 0.5)))))

;; Clamp a value between min and max
(define (clamp [v : f64] [min-v : f64] [max-v : f64]) : f64
  (if (< v min-v)
    min-v
    (if (> v max-v)
      max-v
      v)))

;; Update camera to smoothly follow target with lookahead
(define (camera-update [dt : f64] [target-x : f64] [target-y : f64] [target-vx : f64] [screen-w : f64] [screen-h : f64] [world-w : f64] [world-h : f64]) : unit
  (let
    ;; Target camera position (centered on player + lookahead)
    [target-cam-x : f64
      (- (+ target-x (* target-vx 0.15)) (* screen-w 0.5))]
    [target-cam-y : f64
      (- target-y (* screen-h 0.5))]
    ;; Smooth interpolation
    [new-x : f64
      (+ camera-x (* (- target-cam-x camera-x) CAMERA-SMOOTH))]
    [new-y : f64
      (+ camera-y (* (- target-cam-y camera-y) CAMERA-SMOOTH))]
    ;; Clamp to world bounds
    [max-cam-x : f64 (- world-w screen-w)]
    [max-cam-y : f64 (- world-h screen-h)]
    (begin
      (set! camera-x (clamp new-x 0.0 max-cam-x))
      (set! camera-y (clamp new-y 0.0 max-cam-y)))))

;; Transform world x to screen x (includes shake offset)
(define (world-to-screen-x [wx : f64]) : f32
  (cast (- (- wx camera-x) (get-shake-x)) : f32))

;; Transform world y to screen y (includes shake offset)
(define (world-to-screen-y [wy : f64]) : f32
  (cast (- (- wy camera-y) (get-shake-y)) : f32))

;; Check if a world rectangle is visible on screen
(define (is-visible [wx : f64] [wy : f64] [ww : f64] [wh : f64] [screen-w : f64] [screen-h : f64]) : bool
  (and
    (< (- wx camera-x) screen-w)
    (> (+ (- wx camera-x) ww) 0.0)
    (< (- wy camera-y) screen-h)
    (> (+ (- wy camera-y) wh) 0.0)))
