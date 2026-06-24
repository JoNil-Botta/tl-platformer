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
(define (draw-title-screen [screen-w : i64] [screen-h : i64]) : unit
  (begin
    ;; Draw title
    (draw-text-centered TITLE-TEXT (cast 140 : i32) (cast 48 : i32) TITLE-COLOR screen-w)
    ;; Draw subtitle
    (draw-text-centered SUBTITLE-TEXT (cast 200 : i32) (cast 20 : i32) SUBTITLE-COLOR screen-w)
    ;; Draw prompt (blinking handled by caller via alpha)
    (draw-text-centered PRESS-ENTER-TEXT (cast 300 : i32) (cast 24 : i32) PROMPT-COLOR screen-w)
    ;; Draw controls
    (draw-text-centered CONTROLS-TEXT-1 (cast 380 : i32) (cast 16 : i32) SUBTITLE-COLOR screen-w)
    (draw-text-centered CONTROLS-TEXT-2 (cast 405 : i32) (cast 16 : i32) SUBTITLE-COLOR screen-w)))

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
    (draw-text-centered PAUSED-TEXT (cast 200 : i32) (cast 48 : i32) PROMPT-COLOR screen-w)
    ;; Draw resume prompt
    (draw-text-centered RESUME-TEXT (cast 280 : i32) (cast 24 : i32) SUBTITLE-COLOR screen-w)))

;; Draw fade overlay
(define (draw-fade [alpha : f64] [screen-w : i64] [screen-h : i64]) : unit
  (when (> alpha 0.0)
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
