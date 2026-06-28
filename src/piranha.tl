(import "stdlib/ffi.tl")
(import "physics.tl")
(import "world.tl")
(import "assets.tl")

;; Piranha plants: enemies that emerge from pipe-top tiles on a timer

(define PIRANHA-W : f64 20.0)
(define PIRANHA-H : f64 32.0)
(define PIRANHA-HW : f64 10.0)
(define PIRANHA-HH : f64 16.0)
(define PIRANHA-SPEED : f64 40.0)
(define PIRANHA-EMERGE-DIST : f64 48.0)
(define MAX-PIRANHAS : i64 (cast 16 : i64))

(define PIRANHA-HIDDEN : i64 (cast 0 : i64))
(define PIRANHA-EMERGING : i64 (cast 1 : i64))
(define PIRANHA-RETREATING : i64 (cast 2 : i64))

(defstruct Piranha
  (x f64)
  (y f64)
  (base-y f64)
  (timer f64)
  (active bool)
  (state i64))

(define piranhas : (Array Piranha)
  (make-array Piranha MAX-PIRANHAS))

(define piranha-count : i64
  (cast 0 : i64))

(define (piranhas-init) : unit
  (set! piranha-count (cast 0 : i64)))

(define (piranha-spawn [bx : f64] [by : f64]) : bool
  (if (>= piranha-count MAX-PIRANHAS)
    false
    (begin
      (array-set! piranhas piranha-count
        (Piranha bx (- by PIRANHA-HH) by 0.0 true PIRANHA-HIDDEN))
      (set! piranha-count (+ piranha-count 1))
      true)))

;; Spawn piranhas on pipe-top tiles
(define (piranhas-spawn-in-level [lvl : (Array i64)] [cols : i64] [rows : i64]) : unit
  (let
    [i : i64 0]
    (begin
      (while (< i (* cols rows))
        (begin
          (when (= (array-ref lvl i) TILE-PIPE-TOP)
            (let
              [col : i64 (% i cols)]
              [row : i64 (/ i cols)]
              [bx : f64 (+ (* (cast col : f64) TILE-SIZE-F) (* TILE-SIZE-F 0.5))]
              [by : f64 (+ (* (cast row : f64) TILE-SIZE-F) TILE-SIZE-F)]
              (begin
                (piranha-spawn bx by)
                unit)))
          (set! i (+ i 1)))))))

;; Update a single piranha
(define (piranha-update-single [dt : f64] [idx : i64]) : unit
  (let
    [p : Piranha (array-ref piranhas idx)]
    (when (struct-get p active)
      (let
        [state : i64 (struct-get p state)]
        [base-y : f64 (struct-get p base-y)]
        [y : f64 (struct-get p y)]
        [timer : f64 (struct-get p timer)]
        [new-state : i64 state]
        [new-y : f64 y]
        [new-timer : f64 timer]
        (begin
          (if (= state PIRANHA-HIDDEN)
            (begin
              (set! new-timer (+ timer dt))
              (when (> new-timer 2.0)
                (begin
                  (set! new-timer 0.0)
                  (set! new-state PIRANHA-EMERGING))))
            (if (= state PIRANHA-EMERGING)
              (begin
                (set! new-y (- y (* PIRANHA-SPEED dt)))
                (when (<= new-y (- base-y PIRANHA-EMERGE-DIST))
                  (begin
                    (set! new-y (- base-y PIRANHA-EMERGE-DIST))
                    (set! new-state PIRANHA-RETREATING))))
              (begin
                (set! new-y (+ y (* PIRANHA-SPEED dt)))
                (when (>= new-y base-y)
                  (begin
                    (set! new-y base-y)
                    (set! new-state PIRANHA-HIDDEN))))))
          (array-set! piranhas idx
            (Piranha
              (struct-get p x)
              new-y
              base-y
              new-timer
              true
              new-state)))))))

;; Update all piranhas
(define (piranhas-update [dt : f64]) : unit
  (let [i : i64 0]
    (while (< i piranha-count)
      (begin
        (piranha-update-single dt i)
        (set! i (+ i 1))))))

;; Check if player collides with any piranha
(define (piranhas-collide [px : f64] [py : f64]) : i64
  (let
    [result : i64 0]
    [i : i64 0]
    (begin
      (while (< i piranha-count)
        (let
          [p : Piranha (array-ref piranhas i)]
          (begin
            (when (struct-get p active)
              (let
                [dx : f64 (- px (struct-get p x))]
                [dy : f64 (- py (struct-get p y))]
                [hw : f64 (+ PLAYER-HW PIRANHA-HW)]
                [hh : f64 (+ PLAYER-HH PIRANHA-HH)]
                (when (and (< (abs-f64 dx) hw) (< (abs-f64 dy) hh))
                  (set! result 1))))
            (set! i (+ i 1)))))
      result)))

;; Piranha color
(define COLOR-PIRANHA : Color
  (Color (cast 200 : u8) (cast 50 : u8) (cast 50 : u8) (cast 255 : u8)))

;; Draw all piranhas
(define (draw-piranhas) : unit
  (let [i : i64 0]
    (while (< i piranha-count)
      (let
        [p : Piranha (array-ref piranhas i)]
        (begin
          (when (struct-get p active)
            (DrawRectangleRec
              (Rectangle
                (world-to-screen-x (- (struct-get p x) PIRANHA-HW))
                (world-to-screen-y (- (struct-get p y) PIRANHA-HH))
                (cast PIRANHA-W : f32)
                (cast PIRANHA-H : f32))
              COLOR-PIRANHA))
          (set! i (+ i 1)))))))

;; Kill piranhas on contact (for star power-up)
;; Returns number of piranhas killed
(define (piranha-kill-on-contact [px : f64] [py : f64]) : i64
  (let
    [count : i64 0]
    [i : i64 0]
    (begin
      (while (< i piranha-count)
        (let
          [p : Piranha (array-ref piranhas i)]
          (begin
            (when (struct-get p active)
              (let
                [dx : f64 (- px (struct-get p x))]
                [dy : f64 (- py (struct-get p y))]
                [hw : f64 (+ PLAYER-HW PIRANHA-HW)]
                [hh : f64 (+ PLAYER-HH PIRANHA-HH)]
                (when (and (< (abs-f64 dx) hw) (< (abs-f64 dy) hh))
                  (begin
                    (array-set! piranhas i
                      (Piranha
                        (struct-get p x)
                        (struct-get p y)
                        (struct-get p base-y)
                        (struct-get p timer)
                        false
                        (struct-get p state)))
                    (set! count (+ count 1))))))
            (set! i (+ i 1)))))
      count)))
