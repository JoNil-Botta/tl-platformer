(import "stdlib/ffi.tl")

;; Level progression system
;; Tracks world/level sequence, difficulty scaling, and biome assignment
;; Levels: 1-1 (overworld), 1-2 (underground), 1-3 (overworld), 1-4 (castle)
;; Current world (1+)
(define current-world : i64
  1)

;; Current level within world (1-4)
(define current-level : i64
  1)

;; Levels per world
(define LEVELS-PER-WORLD : i64
  4)

;; Seed base for deterministic generation
(define SEED-BASE : i64
  1000)

;; Biome assignments per level
(define LEVEL-1-BIOME : i64
  0)
(define LEVEL-2-BIOME : i64
  1)
(define LEVEL-3-BIOME : i64
  0)
(define LEVEL-4-BIOME : i64
  2)

;; Generate a deterministic seed for the current world/level
(define (level-seed) : i64
  (+ (* current-world SEED-BASE) current-level))

;; Get the biome for the current level
(define (current-level-biome) : i64
  (cond
    [(= current-level 1) LEVEL-1-BIOME]
    [(= current-level 2) LEVEL-2-BIOME]
    [(= current-level 3) LEVEL-3-BIOME]
    [(= current-level 4) LEVEL-4-BIOME]
    [else LEVEL-1-BIOME]))

;; Get enemy spawn density for the current level (higher = more enemies)
;; Level 1: 10, Level 2: 8, Level 3: 7, Level 4: 6 (smaller spacing = more enemies)
(define (level-enemy-spacing) : i64
  (cond
    [(= current-level 1) 10]
    [(= current-level 2) 8]
    [(= current-level 3) 7]
    [(= current-level 4) 6]
    [else 10]))

;; Get timer duration for the current level (seconds)
;; Harder levels get slightly more time, castle gets most
(define (level-timer-duration) : f64
  (cond [(= current-level 4) 360.0] [(= current-level 2) 330.0] [else 300.0]))

;; Advance to the next level
;; Returns true if there are more levels in this world, false if world complete
(define (next-level) : bool
  (if (< current-level LEVELS-PER-WORLD)
    (begin
      (set! current-level (+ current-level 1))
      true)
    (begin
      (set! current-level (+ current-level 1))
      false)))

;; Reset to start of current world (level 1)
(define (reset-world) : unit
  (set! current-level 1))

;; Advance to next world (after completing all levels)
(define (next-world) : unit
  (begin
    (set! current-world (+ current-world 1))
    (set! current-level 1)))

;; Check if all levels in current world are complete
(define (is-world-finished?) : bool
  (>= current-level LEVELS-PER-WORLD))

;; Reset all progression (new game)
(define (reset-progression) : unit
  (begin
    (set! current-world 1)
    (set! current-level 1)))

;; Format world-level as string for HUD (e.g., "W1-1")
;; We use a simple fixed format: W{world}-{level}
;; For display, we compute a single number: world * 10 + level
;; HUD draws this as separate text
(define (world-level-number) : i64
  (+ (* current-world 10) current-level))