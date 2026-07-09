(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/assets.tl")

;; Biome constants tests
(test
  test-biome-constants
  (assert-true
    (and (= BIOME-OVERWORLD 0) (= BIOME-UNDERGROUND 1) (= BIOME-CASTLE 2))
    "biome constants should be 0, 1, 2"))

;; Default biome is overworld
(test
  test-default-biome
  (assert-true
    (= current-biome BIOME-OVERWORLD)
    "default biome should be overworld"))

;; Overworld background color
(test
  test-overworld-background
  (begin
    (set! current-biome BIOME-OVERWORLD)
    (let
      [c : Color (biome-background-color)]
      (assert-true
        (and
          (= (struct-get c r) 135)
          (= (struct-get c g) 206)
          (= (struct-get c b) 235))
        "overworld background should be sky blue"))))

;; Underground background color
(test
  test-underground-background
  (begin
    (set! current-biome BIOME-UNDERGROUND)
    (let
      [c : Color (biome-background-color)]
      (assert-true
        (and
          (= (struct-get c r) 30)
          (= (struct-get c g) 30)
          (= (struct-get c b) 40))
        "underground background should be dark gray"))))

;; Castle background color
(test
  test-castle-background
  (begin
    (set! current-biome BIOME-CASTLE)
    (let
      [c : Color (biome-background-color)]
      (assert-true
        (and
          (= (struct-get c r) 20)
          (= (struct-get c g) 10)
          (= (struct-get c b) 10))
        "castle background should be near black"))))

;; Overworld ground tile color
(test
  test-overworld-ground-tile
  (begin
    (set! current-biome BIOME-OVERWORLD)
    (let
      [c : Color (biome-tile-color 1)]
      (assert-true
        (and
          (= (struct-get c r) 90)
          (= (struct-get c g) 60)
          (= (struct-get c b) 30))
        "overworld ground tile should be brown"))))

;; Underground ground tile color
(test
  test-underground-ground-tile
  (begin
    (set! current-biome BIOME-UNDERGROUND)
    (let
      [c : Color (biome-tile-color 1)]
      (assert-true
        (and
          (= (struct-get c r) 80)
          (= (struct-get c g) 80)
          (= (struct-get c b) 80))
        "underground ground tile should be gray"))))

;; Castle ground tile color
(test
  test-castle-ground-tile
  (begin
    (set! current-biome BIOME-CASTLE)
    (let
      [c : Color (biome-tile-color 1)]
      (assert-true
        (and
          (= (struct-get c r) 60)
          (= (struct-get c g) 60)
          (= (struct-get c b) 60))
        "castle ground tile should be dark gray"))))

;; Overworld brick tile color
(test
  test-overworld-brick-tile
  (begin
    (set! current-biome BIOME-OVERWORLD)
    (let
      [c : Color (biome-tile-color 5)]
      (assert-true
        (and
          (= (struct-get c r) 180)
          (= (struct-get c g) 70)
          (= (struct-get c b) 50))
        "overworld brick tile should be reddish"))))

;; Underground brick tile color
(test
  test-underground-brick-tile
  (begin
    (set! current-biome BIOME-UNDERGROUND)
    (let
      [c : Color (biome-tile-color 5)]
      (assert-true
        (and
          (= (struct-get c r) 120)
          (= (struct-get c g) 60)
          (= (struct-get c b) 40))
        "underground brick tile should be dark brown"))))

;; Castle brick tile color
(test
  test-castle-brick-tile
  (begin
    (set! current-biome BIOME-CASTLE)
    (let
      [c : Color (biome-tile-color 5)]
      (assert-true
        (and
          (= (struct-get c r) 140)
          (= (struct-get c g) 40)
          (= (struct-get c b) 30))
        "castle brick tile should be dark red"))))

;; Unknown tile type returns magenta fallback
(test
  test-unknown-tile-fallback
  (begin
    (set! current-biome BIOME-OVERWORLD)
    (let
      [c : Color (biome-tile-color 99)]
      (assert-true
        (and
          (= (struct-get c r) 255)
          (= (struct-get c g) 0)
          (= (struct-get c b) 255))
        "unknown tile type should return magenta fallback"))))