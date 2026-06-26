(import "stdlib/ffi.tl")
(import "assets.tl")
(import "ui.tl")

(define MAX-PARTICLES : i64 (cast 256 : i64))

(define PARTICLE-DUST : i64 (cast 0 : i64))
(define PARTICLE-SPARKLE : i64 (cast 1 : i64))
(define PARTICLE-BURST : i64 (cast 2 : i64))

(defstruct Particle
  (x f64)
  (y f64)
  (vx f64)
  (vy f64)
  (life f64)
  (max-life f64)
  (size f64)
  (ptype i64)
  (active bool))

(define particles : (Array Particle)
  (make-array Particle MAX-PARTICLES))

(define (particles-init) : unit
  (let
    [i : i64 0]
    (while (< i MAX-PARTICLES)
      (begin
        (array-set! particles i (Particle 0.0 0.0 0.0 0.0 0.0 0.0 0.0 PARTICLE-DUST false))
        (set! i (+ i 1))))))

(define (particle-find-slot) : i64
  (let
    [result : i64 (cast -1 : i64)]
    [i : i64 0]
    (begin
      (while (and (< i MAX-PARTICLES) (< result 0))
        (begin
          (let
            [p : Particle (array-ref particles i)]
            (when (not (struct-get p active))
              (set! result i)))
          (set! i (+ i 1))))
      result)))

(define (particle-spawn [x : f64] [y : f64] [vx : f64] [vy : f64] [life : f64] [size : f64] [ptype : i64]) : bool
  (let
    [slot : i64 (particle-find-slot)]
    (if (>= slot 0)
      (begin
        (array-set! particles slot (Particle x y vx vy life life size ptype true))
        true)
      false)))

(define (spawn-dust [x : f64] [y : f64]) : unit
  (begin
    (particle-spawn x y -40.0 -20.0 0.3 3.0 PARTICLE-DUST)
    (particle-spawn (- x 5.0) y 30.0 -30.0 0.25 2.0 PARTICLE-DUST)
    (particle-spawn (+ x 5.0) y 50.0 -15.0 0.35 3.0 PARTICLE-DUST)
    (particle-spawn (- x 8.0) (+ y 2.0) -60.0 -10.0 0.2 2.0 PARTICLE-DUST)
    unit))

(define (spawn-coin-sparkle [x : f64] [y : f64]) : unit
  (begin
    (particle-spawn x y -30.0 -80.0 0.4 2.0 PARTICLE-SPARKLE)
    (particle-spawn x y 0.0 -100.0 0.5 3.0 PARTICLE-SPARKLE)
    (particle-spawn x y 30.0 -80.0 0.4 2.0 PARTICLE-SPARKLE)
    (particle-spawn (- x 4.0) y -50.0 -60.0 0.3 2.0 PARTICLE-SPARKLE)
    (particle-spawn (+ x 4.0) y 50.0 -60.0 0.3 2.0 PARTICLE-SPARKLE)
    unit))

(define (spawn-stomp-burst [x : f64] [y : f64]) : unit
  (begin
    (particle-spawn x y -60.0 -60.0 0.3 3.0 PARTICLE-BURST)
    (particle-spawn x y 60.0 -60.0 0.3 3.0 PARTICLE-BURST)
    (particle-spawn x y -30.0 -90.0 0.4 4.0 PARTICLE-BURST)
    (particle-spawn x y 30.0 -90.0 0.4 4.0 PARTICLE-BURST)
    (particle-spawn x y 0.0 -120.0 0.5 5.0 PARTICLE-BURST)
    unit))

(define (particles-update [dt : f64]) : unit
  (let
    [i : i64 0]
    (while (< i MAX-PARTICLES)
      (begin
        (let
          [p : Particle (array-ref particles i)]
          (when (struct-get p active)
            (begin
              (let
                [new-x : f64 (+ (struct-get p x) (* (struct-get p vx) dt))]
                [new-y : f64 (+ (struct-get p y) (* (struct-get p vy) dt))]
                [new-vy : f64 (+ (struct-get p vy) (* 200.0 dt))]
                [new-life : f64 (- (struct-get p life) dt)]
                (if (<= new-life 0.0)
                  (array-set! particles i (Particle 0.0 0.0 0.0 0.0 0.0 0.0 0.0 PARTICLE-DUST false))
                  (array-set! particles i (Particle new-x new-y (struct-get p vx) new-vy new-life (struct-get p max-life) (struct-get p size) (struct-get p ptype) true)))))))
        (set! i (+ i 1))))))

(define (particle-active-count) : i64
  (let
    [count : i64 (cast 0 : i64)]
    [i : i64 0]
    (begin
      (while (< i MAX-PARTICLES)
        (begin
          (let
            [p : Particle (array-ref particles i)]
            (when (struct-get p active)
              (set! count (+ count 1))))
          (set! i (+ i 1))))
      count)))

(define (particle-is-active? [idx : i64]) : bool
  (if (and (>= idx 0) (< idx MAX-PARTICLES))
    (let
      [p : Particle (array-ref particles idx)]
      (struct-get p active))
    false))

;; Draw all active particles
(define (draw-particles) : unit
  (let
    [i : i64 0]
    (while (< i MAX-PARTICLES)
      (begin
        (let
          [p : Particle (array-ref particles i)]
          (when (struct-get p active)
            (begin
              (let
                [alpha : u8 (cast (* 255.0 (/ (struct-get p life) (struct-get p max-life))) : u8)]
                [color : Color
                  (if (= (struct-get p ptype) PARTICLE-DUST)
                    (Color (cast 200 : u8) (cast 200 : u8) (cast 180 : u8) alpha)
                    (if (= (struct-get p ptype) PARTICLE-SPARKLE)
                      (Color (cast 255 : u8) (cast 220 : u8) (cast 50 : u8) alpha)
                      (Color (cast 255 : u8) (cast 100 : u8) (cast 50 : u8) alpha)))]
                (DrawRectangle
                  (cast (- (struct-get p x) (* (struct-get p size) 0.5)) : i32)
                  (cast (- (struct-get p y) (* (struct-get p size) 0.5)) : i32)
                  (cast (struct-get p size) : i32)
                  (cast (struct-get p size) : i32)
                  color)))))
        (set! i (+ i 1))))))
