(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/particles.tl")

;; Particle system tests

;; Test: particles-init sets all particles to inactive
(test
  particles-init-sets-all-inactive
  (begin
    (particles-init)
    (assert-true (not (particle-is-active? 0)) "particle 0 should be inactive")
    (assert-true (not (particle-is-active? 1)) "particle 1 should be inactive")
    (assert-true (not (particle-is-active? 255)) "particle 255 should be inactive")
    (assert-true (= (particle-active-count) (cast 0 : i64)) "active count should be 0")))

;; Test: particle-spawn creates an active particle
(test
  particle-spawn-creates-active-particle
  (begin
    (particles-init)
    (let
      [result : bool (particle-spawn 100.0 200.0 10.0 -20.0 0.5 3.0 PARTICLE-DUST)]
      (begin
        (assert-true result "particle-spawn should return true")
        (assert-true (particle-is-active? 0) "particle 0 should be active")
        (assert-true (= (particle-active-count) (cast 1 : i64)) "active count should be 1")))))

;; Test: spawn-dust creates multiple particles
(test
  spawn-dust-creates-4-particles
  (begin
    (particles-init)
    (spawn-dust 100.0 200.0)
    (assert-true (= (particle-active-count) (cast 4 : i64)) "dust should spawn 4 particles")))

;; Test: spawn-coin-sparkle creates 5 particles
(test
  spawn-coin-sparkle-creates-5-particles
  (begin
    (particles-init)
    (spawn-coin-sparkle 100.0 200.0)
    (assert-true (= (particle-active-count) (cast 5 : i64)) "sparkle should spawn 5 particles")))

;; Test: spawn-stomp-burst creates 5 particles
(test
  spawn-stomp-burst-creates-5-particles
  (begin
    (particles-init)
    (spawn-stomp-burst 100.0 200.0)
    (assert-true (= (particle-active-count) (cast 5 : i64)) "burst should spawn 5 particles")))

;; Test: particles-update decrements life and deactivates dead particles
(test
  particles-update-deactivates-dead
  (begin
    (particles-init)
    (particle-spawn 100.0 200.0 10.0 -20.0 0.1 3.0 PARTICLE-DUST)
    (assert-true (= (particle-active-count) (cast 1 : i64)) "should have 1 active particle")
    (particles-update 0.2)
    (assert-true (= (particle-active-count) (cast 0 : i64)) "particle should be dead after update")))

;; Test: particles-update moves particles by velocity
(test
  particles-update-moves-particles
  (begin
    (particles-init)
    (particle-spawn 100.0 200.0 10.0 -20.0 1.0 3.0 PARTICLE-DUST)
    (particles-update 0.1)
    (assert-true (= (particle-active-count) (cast 1 : i64)) "particle should still be active")))

;; Test: particle-spawn returns false when pool is full
(test
  particle-spawn-fails-when-full
  (begin
    (particles-init)
    (let
      [i : i64 0]
      (while (< i MAX-PARTICLES)
        (begin
          (particle-spawn 0.0 0.0 0.0 0.0 1.0 1.0 PARTICLE-DUST)
          (set! i (+ i 1)))))
    (assert-true (= (particle-active-count) MAX-PARTICLES) "pool should be full")
    (let
      [result : bool (particle-spawn 0.0 0.0 0.0 0.0 1.0 1.0 PARTICLE-DUST)]
      (assert-true (not result) "spawn should fail when pool is full"))))

;; Test: multiple spawn calls fill slots correctly
(test
  spawn-functions-fill-slots
  (begin
    (particles-init)
    (spawn-dust 0.0 0.0)
    (spawn-coin-sparkle 0.0 0.0)
    (assert-true (= (particle-active-count) (cast 9 : i64)) "should have 9 active particles")))
