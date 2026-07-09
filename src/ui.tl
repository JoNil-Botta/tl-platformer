(import stdlib.ffi)

;; UI system: title screen, pause menu, fade transitions
;; Title text constants
(define TITLE-TEXT : (Ptr u8)
  (ffi.cstr "TL-PLATFORMER"))
(define SUBTITLE-TEXT : (Ptr u8)
  (ffi.cstr "A TypeLisp Adventure"))
(define PRESS-ENTER-TEXT : (Ptr u8)
  (ffi.cstr "PRESS ENTER TO START"))
(define PAUSED-TEXT : (Ptr u8)
  (ffi.cstr "PAUSED"))
(define RESUME-TEXT : (Ptr u8)
  (ffi.cstr "PRESS P TO RESUME"))
(define CONTROLS-TEXT-1 : (Ptr u8)
  (ffi.cstr "LEFT/RIGHT: Move  SPACE: Jump"))
(define CONTROLS-TEXT-2 : (Ptr u8)
  (ffi.cstr "R: Restart  P: Pause"))

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
  (Color 220 80 40 255))
(define SUBTITLE-COLOR : Color
  (Color 180 180 180 255))
(define PROMPT-COLOR : Color
  (Color 255 255 255 255))
(define FADE-COLOR : Color
  (Color 0 0 0 255))

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
    (draw-text-centered TITLE-TEXT 140 48 TITLE-COLOR screen-w)
    ;; Draw subtitle
    (draw-text-centered SUBTITLE-TEXT 200 20 SUBTITLE-COLOR screen-w)
    ;; Draw prompt (blinking handled by caller via alpha)
    (draw-text-centered PRESS-ENTER-TEXT 300 24 PROMPT-COLOR screen-w)
    ;; Draw controls
    (draw-text-centered CONTROLS-TEXT-1 380 16 SUBTITLE-COLOR screen-w)
    (draw-text-centered CONTROLS-TEXT-2 405 16 SUBTITLE-COLOR screen-w)
    ;; Draw high score
    (when
      (> high-score 0)
      (begin
        (draw-text-centered
          (ffi.cstr "HIGH SCORE")
          450
          12
          SUBTITLE-COLOR
          screen-w)
        (draw-text-centered
          (ffi.cstr (int->string high-score))
          465
          20
          PROMPT-COLOR
          screen-w)))))

;; Draw the pause overlay
(define (draw-pause-screen [screen-w : i64] [screen-h : i64]) : unit
  (begin
    ;; Darken background
    (DrawRectangle
      0
      0
      (cast screen-w : i32)
      (cast screen-h : i32)
      (Color 0 0 0 180))
    ;; Draw PAUSED text
    (draw-text-centered PAUSED-TEXT 200 48 PROMPT-COLOR screen-w)
    ;; Draw resume prompt
    (draw-text-centered RESUME-TEXT 280 24 SUBTITLE-COLOR screen-w)))

;; Draw fade overlay
(define (draw-fade [alpha : f64] [screen-w : i64] [screen-h : i64]) : unit
  (when
    (> alpha 0.0)
    (DrawRectangle
      0
      0
      (cast screen-w : i32)
      (cast screen-h : i32)
      (Color 0 0 0 (cast (* alpha 255.0) : u8)))))

(import "stdlib/string.tl")

;; HUD colors
(define HUD-BG-COLOR : Color
  (Color 0 0 0 140))
(define HUD-TEXT-COLOR : Color
  (Color 255 255 255 255))
(define HUD-ACCENT-COLOR : Color
  (Color 255 220 40 255))

;; Draw a label + value pair at the given position
(define (draw-hud-pair
  [label : (Ptr u8)]
  [value : i64]
  [x : i32]
  [y : i32]
  [value-color : Color]) : unit
  (begin
    (DrawText label x y 10 HUD-TEXT-COLOR)
    (DrawText (ffi.cstr (int->string value)) x (+ y 12) 16 value-color)))

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
    (DrawRectangle 0 0 (cast screen-w : i32) 34 HUD-BG-COLOR)
    ;; Score (left)
    (draw-hud-pair (ffi.cstr "SCORE") score 12 2 HUD-TEXT-COLOR)
    ;; Coins (left, next to score)
    (begin
      (DrawText (ffi.cstr "COINS") 90 2 10 HUD-TEXT-COLOR)
      (DrawText (ffi.cstr "x") 90 14 16 HUD-ACCENT-COLOR)
      (DrawText (ffi.cstr (int->string coins)) 102 14 16 HUD-ACCENT-COLOR))
    ;; World indicator (center)
    (begin
      (DrawText (ffi.cstr "WORLD") 340 2 10 HUD-TEXT-COLOR)
      (DrawText (ffi.cstr "W") 340 14 16 HUD-TEXT-COLOR)
      (DrawText (ffi.cstr (int->string world)) 352 14 16 HUD-TEXT-COLOR)
      (DrawText (ffi.cstr "-") 360 14 16 HUD-TEXT-COLOR)
      (DrawText (ffi.cstr (int->string level)) 370 14 16 HUD-TEXT-COLOR))
    ;; Time (right)
    (draw-hud-pair (ffi.cstr "TIME") time-sec 580 2 HUD-TEXT-COLOR)
    ;; Lives (right, next to time)
    (begin
      (DrawText (ffi.cstr "LIVES") 650 2 10 HUD-TEXT-COLOR)
      (DrawText (ffi.cstr "x") 650 14 16 (Color 255 80 80 255))
      (DrawText (ffi.cstr (int->string lives)) 662 14 16 (Color 255 80 80 255)))))

;; World map colors
(define MAP-NODE-COLOR : Color
  (Color 80 80 80 255))
(define MAP-NODE-ACTIVE : Color
  (Color 50 200 50 255))
(define MAP-NODE-COMPLETE : Color
  (Color 50 150 220 255))
(define MAP-LINE-COLOR : Color
  (Color 120 120 120 255))
(define MAP-PLAYER-COLOR : Color
  (Color 255 80 80 255))

;; Draw a circular node on the world map (using square for simplicity)
(define (draw-map-node [cx : i32] [cy : i32] [radius : i32] [color : Color]) : unit
  (DrawRectangle (- cx radius) (- cy radius) (* radius 2) (* radius 2) color))

;; Draw the world map screen
(define (draw-world-map
  [screen-w : i64]
  [screen-h : i64]
  [world : i64]
  [current-lvl : i64]) : unit
  (begin
    ;; Background
    (DrawRectangle
      0
      0
      (cast screen-w : i32)
      (cast screen-h : i32)
      (Color 20 20 35 255))
    ;; World title
    (draw-text-centered (ffi.cstr "WORLD MAP") 80 36 TITLE-COLOR screen-w)
    ;; Draw connecting line
    (DrawRectangle 150 248 500 4 MAP-LINE-COLOR)
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
              (draw-map-node nx 250 16 node-color)
              (DrawText
                (ffi.cstr (int->string i))
                (- nx 5)
                243
                16
                (Color 255 255 255 255))))
          (set! i (+ i 1)))))
    ;; Player indicator on current level
    (let
      [px : i32 (cast (+ 150 (* (- current-lvl 1) 167)) : i32)]
      (draw-map-node px 210 8 MAP-PLAYER-COLOR))
    ;; Prompt
    (draw-text-centered
      (ffi.cstr "PRESS ENTER TO START")
      350
      24
      PROMPT-COLOR
      screen-w)))