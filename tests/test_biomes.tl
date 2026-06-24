(import "stdlib/ffi.tl")
(import "stdlib/test.tl")
(import "../src/assets.tl")

;; Biome constants tests
(test
  test-biome-constants
  (assert-true
    (and
      (= BIOME-OVERWORLD 0)
      (= BIOME-UNDERGROUND 1)
      (= BIOME-CASTLE 2))
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
          (= (struct-get c r) (cast 135 : u8))
          (= (struct-get c g) (cast 206 : u8))
          (= (struct-get c b) (cast 235 : u8)))
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
          (= (struct-get c r) (cast 30 : u8))
          (= (struct-get c g) (cast 30 : u8))
          (= (struct-get c b) (cast 40 : u8)))
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
          (= (struct-get c r) (cast 20 : u8))
          (= (struct-get c g) (cast 10 : u8))
          (= (struct-get c b) (cast 10 : u8)))
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
          (= (struct-get c r) (cast 90 : u8))
          (= (struct-get c g) (cast 60 : u8))
          (= (struct-get c b) (cast 30 : u8)))
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
          (= (struct-get c r) (cast 80 : u8))
          (= (struct-get c g) (cast 80 : u8))
          (= (struct-get c b) (cast 80 : u8)))
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
          (= (struct-get c r) (cast 60 : u8))
          (= (struct-get c g) (cast 60 : u8))
          (= (struct-get c b) (cast 60 : u8)))
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
          (= (struct-get c r) (cast 180 : u8))
          (= (struct-get c g) (cast 70 : u8))
          (= (struct-get c b) (cast 50 : u8)))
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
          (= (struct-get c r) (cast 120 : u8))
          (= (struct-get c g) (cast 60 : u8))
          (= (struct-get c b) (cast 40 : u8)))
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
          (= (struct-get c r) (cast 140 : u8))
          (= (struct-get c g) (cast 40 : u8))
          (= (struct-get c b) (cast 30 : u8)))
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
          (= (struct-get c r) (cast 255 : u8))
          (= (struct-get c g) (cast 0 : u8))
          (= (struct-get c b) (cast 255 : u8)))
        "unknown tile type should return magenta fallback"))))
