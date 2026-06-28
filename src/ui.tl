(import "stdlib/ffi.tl")

;; UI system: title screen, pause menu, fade transitions
;; Title text constants
(define TITLE-TEXT : (Ptr u8)
  (ffi-cstr "TL-PLATFORMER"))
(define SUBTITLE-TEXT : (Ptr u8)
  (ffi-cstr "A TypeLisp Adventure"))
(define PRESS-ENTER-TEXT : (Ptr u8)
  (ffi-cstr "PRESS ENTER TO START"))
(define PAUSED-TEXT : (Ptr u8)
  (ffi-cstr "PAUSED"))
(define RESUME-TEXT : (Ptr u8)
  (ffi-cstr "PRESS P TO RESUME"))
(define CONTROLS-TEXT-1 : (Ptr u8)
  (ffi-cstr "LEFT/RIGHT: Move  SPACE: Jump"))
(define CONTROLS-TEXT-2 : (Ptr u8)
  (ffi-cstr "R: Restart  P: Pause"))

(extern (DrawText
  [text : (Ptr u8)]
  [posX : i32]
  [posY : i32]
  [fontSize : i32]
  [color : Color]) : unit)
(extern (DrawRectangle
  [posX : i32]
  [posY : i32]
  [width : i32]
  [height : i32]
  [color : Color]) : unit)

;; Get color with alpha modulation
(define (color-with-alpha [base : Color] [alpha : f64]) : Color
  (Color
    (struct-get base r)
    (struct-get base g)
    (struct-get base b)
    (cast (* (cast (struct-get base a) : f64) (- 1.0 alpha)) : u8)))

;; Title screen colors
(define TITLE-COLOR : Color
  (Color (cast 220 : u8) (cast 80 : u8) (cast 40 : u8) (cast 255 : u8)))
(define SUBTITLE-COLOR : Color
  (Color (cast 180 : u8) (cast 180 : u8) (cast 180 : u8) (cast 255 : u8)))
(define PROMPT-COLOR : Color
  (Color (cast 255 : u8) (cast 255 : u8) (cast 255 : u8) (cast 255 : u8)))
(define FADE-COLOR : Color
  (Color (cast 0 : u8) (cast 0 : u8) (cast 0 : u8) (cast 255 : u8)))

;; MeasureText from Raylib
(extern (MeasureText [text : (Ptr u8)] [fontSize : i32]) : i32)

;; Draw text centered horizontally
(define (draw-text-centered
  [text : (Ptr u8)]
  [y : i32]
  [font-size : i32]
  [color : Color]
  [screen-w : i64]) : unit
  (let
    [text-width : i32 (MeasureText text font-size)]
    [x : i32 (cast (- (/ screen-w 2) (cast text-width : i64)) : i32)]
    (DrawText text x y font-size color)))

;; Draw the title screen
(define (draw-title-screen [screen-w : i64] [high-score : i64]) : unit
  (begin
    ;; Draw title
    (draw-text-centered
      TITLE-TEXT
      (cast 140 : i32)
      (cast 48 : i32)
      TITLE-COLOR
      screen-w)
    ;; Draw subtitle
    (draw-text-centered
      SUBTITLE-TEXT
      (cast 200 : i32)
      (cast 20 : i32)
      SUBTITLE-COLOR
      screen-w)
    ;; Draw prompt (blinking handled by caller via alpha)
    (draw-text-centered
      PRESS-ENTER-TEXT
      (cast 300 : i32)
      (cast 24 : i32)
      PROMPT-COLOR
      screen-w)
    ;; Draw controls
    (draw-text-centered
      CONTROLS-TEXT-1
      (cast 380 : i32)
      (cast 16 : i32)
      SUBTITLE-COLOR
      screen-w)
    (draw-text-centered
      CONTROLS-TEXT-2
      (cast 405 : i32)
      (cast 16 : i32)
      SUBTITLE-COLOR
      screen-w)
    ;; Draw high score
    (when (> high-score 0)
      (begin
        (draw-text-centered
          (ffi-cstr "HIGH SCORE")
          (cast 450 : i32)
          (cast 12 : i32)
          SUBTITLE-COLOR
          screen-w)
        (draw-text-centered
          (ffi-cstr (int->string high-score))
          (cast 465 : i32)
          (cast 20 : i32)
          PROMPT-COLOR
          screen-w)))))

;; Draw the pause overlay
(define (draw-pause-screen [screen-w : i64] [screen-h : i64]) : unit
  (begin
    ;; Darken background
    (DrawRectangle
      (cast 0 : i32)
      (cast 0 : i32)
      (cast screen-w : i32)
      (cast screen-h : i32)
      (Color (cast 0 : u8) (cast 0 : u8) (cast 0 : u8) (cast 180 : u8)))
    ;; Draw PAUSED text
    (draw-text-centered
      PAUSED-TEXT
      (cast 200 : i32)
      (cast 48 : i32)
      PROMPT-COLOR
      screen-w)
    ;; Draw resume prompt
    (draw-text-centered
      RESUME-TEXT
      (cast 280 : i32)
      (cast 24 : i32)
      SUBTITLE-COLOR
      screen-w)))

;; Draw fade overlay
(define (draw-fade [alpha : f64] [screen-w : i64] [screen-h : i64]) : unit
  (when
    (> alpha 0.0)
    (DrawRectangle
      (cast 0 : i32)
      (cast 0 : i32)
      (cast screen-w : i32)
      (cast screen-h : i32)
      (Color
        (cast 0 : u8)
        (cast 0 : u8)
        (cast 0 : u8)
        (cast (* alpha 255.0) : u8)))))

(import "stdlib/string.tl")

;; HUD colors
(define HUD-BG-COLOR : Color
  (Color (cast 0 : u8) (cast 0 : u8) (cast 0 : u8) (cast 140 : u8)))
(define HUD-TEXT-COLOR : Color
  (Color (cast 255 : u8) (cast 255 : u8) (cast 255 : u8) (cast 255 : u8)))
(define HUD-ACCENT-COLOR : Color
  (Color (cast 255 : u8) (cast 220 : u8) (cast 40 : u8) (cast 255 : u8)))

;; Draw a label + value pair at the given position
(define (draw-hud-pair
  [label : (Ptr u8)]
  [value : i64]
  [x : i32]
  [y : i32]
  [value-color : Color]) : unit
  (begin
    (DrawText label x y (cast 10 : i32) HUD-TEXT-COLOR)
    (DrawText
      (ffi-cstr (int->string value))
      x
      (+ y (cast 12 : i32))
      (cast 16 : i32)
      value-color)))

;; Draw the in-game HUD bar
(define (draw-hud
  [score : i64]
  [coins : i64]
  [lives : i64]
  [time-sec : i64]
  [world : i64]
  [level : i64]
  [screen-w : i64]) : unit
  (begin
    ;; Background bar
    (DrawRectangle
      (cast 0 : i32)
      (cast 0 : i32)
      (cast screen-w : i32)
      (cast 34 : i32)
      HUD-BG-COLOR)
    ;; Score (left)
    (draw-hud-pair
      (ffi-cstr "SCORE")
      score
      (cast 12 : i32)
      (cast 2 : i32)
      HUD-TEXT-COLOR)
    ;; Coins (left, next to score)
    (begin
      (DrawText
        (ffi-cstr "COINS")
        (cast 90 : i32)
        (cast 2 : i32)
        (cast 10 : i32)
        HUD-TEXT-COLOR)
      (DrawText
        (ffi-cstr "x")
        (cast 90 : i32)
        (cast 14 : i32)
        (cast 16 : i32)
        HUD-ACCENT-COLOR)
      (DrawText
        (ffi-cstr (int->string coins))
        (cast 102 : i32)
        (cast 14 : i32)
        (cast 16 : i32)
        HUD-ACCENT-COLOR))
    ;; World indicator (center)
    (begin
      (DrawText
        (ffi-cstr "WORLD")
        (cast 340 : i32)
        (cast 2 : i32)
        (cast 10 : i32)
        HUD-TEXT-COLOR)
      (DrawText
        (ffi-cstr "W")
        (cast 340 : i32)
        (cast 14 : i32)
        (cast 16 : i32)
        HUD-TEXT-COLOR)
      (DrawText
        (ffi-cstr (int->string world))
        (cast 352 : i32)
        (cast 14 : i32)
        (cast 16 : i32)
        HUD-TEXT-COLOR)
      (DrawText
        (ffi-cstr "-")
        (cast 360 : i32)
        (cast 14 : i32)
        (cast 16 : i32)
        HUD-TEXT-COLOR)
      (DrawText
        (ffi-cstr (int->string level))
        (cast 370 : i32)
        (cast 14 : i32)
        (cast 16 : i32)
        HUD-TEXT-COLOR))
    ;; Time (right)
    (draw-hud-pair
      (ffi-cstr "TIME")
      time-sec
      (cast 580 : i32)
      (cast 2 : i32)
      HUD-TEXT-COLOR)
    ;; Lives (right, next to time)
    (begin
      (DrawText
        (ffi-cstr "LIVES")
        (cast 650 : i32)
        (cast 2 : i32)
        (cast 10 : i32)
        HUD-TEXT-COLOR)
      (DrawText
        (ffi-cstr "x")
        (cast 650 : i32)
        (cast 14 : i32)
        (cast 16 : i32)
        (Color (cast 255 : u8) (cast 80 : u8) (cast 80 : u8) (cast 255 : u8)))
      (DrawText
        (ffi-cstr (int->string lives))
        (cast 662 : i32)
        (cast 14 : i32)
        (cast 16 : i32)
        (Color (cast 255 : u8) (cast 80 : u8) (cast 80 : u8) (cast 255 : u8))))))

;; World map colors
(define MAP-NODE-COLOR : Color
  (Color (cast 80 : u8) (cast 80 : u8) (cast 80 : u8) (cast 255 : u8)))

(define MAP-NODE-ACTIVE : Color
  (Color (cast 50 : u8) (cast 200 : u8) (cast 50 : u8) (cast 255 : u8)))

(define MAP-NODE-COMPLETE : Color
  (Color (cast 50 : u8) (cast 150 : u8) (cast 220 : u8) (cast 255 : u8)))

(define MAP-LINE-COLOR : Color
  (Color (cast 120 : u8) (cast 120 : u8) (cast 120 : u8) (cast 255 : u8)))

(define MAP-PLAYER-COLOR : Color
  (Color (cast 255 : u8) (cast 80 : u8) (cast 80 : u8) (cast 255 : u8)))

;; Draw a circular node on the world map (using square for simplicity)
(define (draw-map-node
  [cx : i32]
  [cy : i32]
  [radius : i32]
  [color : Color]) : unit
  (DrawRectangle
    (- cx radius)
    (- cy radius)
    (* radius 2)
    (* radius 2)
    color))

;; Draw the world map screen
(define (draw-world-map
  [screen-w : i64]
  [screen-h : i64]
  [world : i64]
  [current-lvl : i64]) : unit
  (begin
    ;; Background
    (DrawRectangle
      (cast 0 : i32)
      (cast 0 : i32)
      (cast screen-w : i32)
      (cast screen-h : i32)
      (Color (cast 20 : u8) (cast 20 : u8) (cast 35 : u8) (cast 255 : u8)))
    ;; World title
    (draw-text-centered
      (ffi-cstr "WORLD MAP")
      (cast 80 : i32)
      (cast 36 : i32)
      TITLE-COLOR
      screen-w)
    ;; Draw connecting line
    (DrawRectangle
      (cast 150 : i32)
      (cast 248 : i32)
      (cast 500 : i32)
      (cast 4 : i32)
      MAP-LINE-COLOR)
    ;; Draw 4 level nodes
    (let
      [i : i64 1]
      (while (<= i 4)
        (begin
          (let
            [nx : i32 (cast (+ 150 (* (- i 1) 167)) : i32)]
            [node-color : Color
              (if (< i current-lvl)
                MAP-NODE-COMPLETE
                (if (= i current-lvl)
                  MAP-NODE-ACTIVE
                  MAP-NODE-COLOR))]
            (begin
              (draw-map-node nx (cast 250 : i32) (cast 16 : i32) node-color)
              (DrawText
                (ffi-cstr (int->string i))
                (- nx (cast 5 : i32))
                (cast 243 : i32)
                (cast 16 : i32)
                (Color (cast 255 : u8) (cast 255 : u8) (cast 255 : u8) (cast 255 : u8)))))
          (set! i (+ i 1)))))
    ;; Player indicator on current level
    (let
      [px : i32 (cast (+ 150 (* (- current-lvl 1) 167)) : i32)]
      (draw-map-node px (cast 210 : i32) (cast 8 : i32) MAP-PLAYER-COLOR))
    ;; Prompt
    (draw-text-centered
      (ffi-cstr "PRESS ENTER TO START")
      (cast 350 : i32)
      (cast 24 : i32)
      PROMPT-COLOR
      screen-w)))
