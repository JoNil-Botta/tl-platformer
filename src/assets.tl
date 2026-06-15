(import "stdlib/ffi.tl")
(import "camera.tl")

;; Asset system for tl-platformer
;; Loads textures and manages animations.
;; Uses colored rectangles as fallback until image files exist.
(defstruct Color
  (r u8)
  (g u8)
  (b u8)
  (a u8))

(defstruct Rectangle
  (x f32)
  (y f32)
  (width f32)
  (height f32))

;; Texture loading from Raylib
(extern (LoadTexture [fileName : (Ptr u8)]) : Texture2D)

(extern (UnloadTexture [texture : Texture2D]) : unit)

(extern (DrawTexture
  [texture : Texture2D]
  [posX : i32]
  [posY : i32]
  [tint : Color]) : unit)

(extern (DrawTextureRec
  [texture : Texture2D]
  [source : Rectangle]
  [position : Vector2]
  [tint : Color]) : unit)

(extern (DrawTexturePro
  [texture : Texture2D]
  [source : Rectangle]
  [dest : Rectangle]
  [origin : Vector2]
  [rotation : f32]
  [tint : Color]) : unit)

(extern (GetTime) : f64)

(defstruct Vector2
  (x f32)
  (y f32))

;; Raylib Texture2D struct
(defstruct Texture2D
  (id u32)
  (width i32)
  (height i32)
  (mipmaps i32)
  (format i32))

;; Tile textures
(define tile-ground : Texture2D
  (Texture2D
    (cast 0 : u32)
    (cast 0 : i32)
    (cast 0 : i32)
    (cast 0 : i32)
    (cast 0 : i32)))

(define tile-platform : Texture2D
  (Texture2D
    (cast 0 : u32)
    (cast 0 : i32)
    (cast 0 : i32)
    (cast 0 : i32)
    (cast 0 : i32)))

(define tile-wall : Texture2D
  (Texture2D
    (cast 0 : u32)
    (cast 0 : i32)
    (cast 0 : i32)
    (cast 0 : i32)
    (cast 0 : i32)))

;; Player sprite sheet
(define player-sprite : Texture2D
  (Texture2D
    (cast 0 : u32)
    (cast 0 : i32)
    (cast 0 : i32)
    (cast 0 : i32)
    (cast 0 : i32)))

;; Animation frame dimensions (in the sprite sheet)
(define PLAYER-FRAME-W : i32
  (cast 32 : i32))

(define PLAYER-FRAME-H : i32
  (cast 32 : i32))

(define PLAYER-FRAMES-PER-ROW : i64
  (cast 4 : i64))

;; Animation states
(define ANIM-IDLE : i64
  (cast 0 : i64))

(define ANIM-RUN : i64
  (cast 1 : i64))

(define ANIM-JUMP : i64
  (cast 2 : i64))

(define ANIM-FALL : i64
  (cast 3 : i64))

;; Current animation state
(define player-anim-state : i64
  ANIM-IDLE)

(define player-anim-timer : f64
  0.0)

(define player-anim-frame : i64
  (cast 0 : i64))

(define player-facing-right : bool
  true)

;; Animation timing
(define ANIM-FPS : f64
  8.0)

;; Fallback colors when textures aren't loaded
(define COLOR-GROUND : Color
  (Color (cast 90 : u8) (cast 60 : u8) (cast 30 : u8) (cast 255 : u8)))

(define COLOR-PLATFORM : Color
  (Color (cast 139 : u8) (cast 90 : u8) (cast 43 : u8) (cast 255 : u8)))

(define COLOR-WALL : Color
  (Color (cast 100 : u8) (cast 100 : u8) (cast 100 : u8) (cast 255 : u8)))

(define COLOR-PLAYER : Color
  (Color (cast 220 : u8) (cast 40 : u8) (cast 40 : u8) (cast 255 : u8)))

(define COLOR-FLAG : Color
  (Color (cast 50 : u8) (cast 200 : u8) (cast 50 : u8) (cast 255 : u8)))

(define COLOR-POLE : Color
  (Color (cast 200 : u8) (cast 200 : u8) (cast 200 : u8) (cast 255 : u8)))

;; Enemy colors
(define COLOR-ENEMY : Color
  (Color (cast 140 : u8) (cast 40 : u8) (cast 220 : u8) (cast 255 : u8)))

;; Coin color
(define COLOR-COIN : Color
  (Color (cast 255 : u8) (cast 215 : u8) (cast 0 : u8) (cast 255 : u8)))

;; Question block color
(define COLOR-QUESTION : Color
  (Color (cast 255 : u8) (cast 165 : u8) (cast 0 : u8) (cast 255 : u8)))

;; Empty/used block color
(define COLOR-EMPTY-BLOCK : Color
  (Color (cast 139 : u8) (cast 90 : u8) (cast 43 : u8) (cast 255 : u8)))

;; Mushroom color
(define COLOR-MUSHROOM : Color
  (Color (cast 220 : u8) (cast 60 : u8) (cast 60 : u8) (cast 255 : u8)))

;; 1-UP mushroom color (green)
(define COLOR-ONEUP : Color
  (Color (cast 60 : u8) (cast 220 : u8) (cast 60 : u8) (cast 255 : u8)))

;; Check if a texture is loaded (id > 0)
(define (texture-loaded? [tex : Texture2D]) : bool
  (> (struct-get tex id) (cast 0 : u32)))

;; Load all game assets
(define (load-assets) : unit
  (begin
    (set! tile-ground (LoadTexture (ffi-cstr "assets/tiles/ground.png")))
    (set! tile-platform (LoadTexture (ffi-cstr "assets/tiles/platform.png")))
    (set! tile-wall (LoadTexture (ffi-cstr "assets/tiles/wall.png")))
    (set!
      player-sprite
      (LoadTexture (ffi-cstr "assets/player/spritesheet.png")))))

;; Unload all game assets
(define (unload-assets) : unit
  (begin
    (UnloadTexture tile-ground)
    (UnloadTexture tile-platform)
    (UnloadTexture tile-wall)
    (UnloadTexture player-sprite)))

;; Get source rectangle for a player animation frame
(define (player-frame-rect [frame : i64] [state : i64]) : Rectangle
  (let
    [row : i64 state]
    [col : i64 (% frame PLAYER-FRAMES-PER-ROW)]
    (Rectangle
      (cast (* col (cast PLAYER-FRAME-W : i64)) : f32)
      (cast (* row (cast PLAYER-FRAME-H : i64)) : f32)
      (cast PLAYER-FRAME-W : f32)
      (cast PLAYER-FRAME-H : f32))))

;; Update player animation based on state
(define (update-player-anim [dt : f64] [vx : f64] [vy : f64] [on-ground : bool]) : unit
  (begin
    ;; Determine animation state
    (if (not on-ground)
      (if (< vy 0.0)
        (set! player-anim-state ANIM-JUMP)
        (set! player-anim-state ANIM-FALL))
      (if (not (= vx 0.0))
        (set! player-anim-state ANIM-RUN)
        (set! player-anim-state ANIM-IDLE)))
    ;; Update facing direction
    (when (> vx 0.0) (set! player-facing-right true))
    (when (< vx 0.0) (set! player-facing-right false))
    ;; Update animation timer and frame
    (set! player-anim-timer (+ player-anim-timer dt))
    (when
      (>= player-anim-timer (/ 1.0 ANIM-FPS))
      (begin
        (set! player-anim-timer (- player-anim-timer (/ 1.0 ANIM-FPS)))
        (set!
          player-anim-frame
          (% (+ player-anim-frame (cast 1 : i64)) PLAYER-FRAMES-PER-ROW))))))

(extern (DrawRectangleRec [rec : Rectangle] [color : Color]) : unit)

;; Draw a tile at world position (x, y) with given size
;; Camera offset is applied to transform to screen coordinates
(define (draw-tile [wx : f64] [wy : f64] [tile-size : f32] [tile-type : i64]) : unit
  (let
    [sx : f32 (world-to-screen-x wx)]
    [sy : f32 (world-to-screen-y wy)]
    (cond
      ;; Empty tile - draw nothing (sky is background)
      (= tile-type 0)
      unit
      ;; Solid ground
      (= tile-type 1)
      (if (texture-loaded? tile-ground)
        (DrawTexture
          tile-ground
          (cast sx : i32)
          (cast sy : i32)
          (Color (cast 255 : u8) (cast 255 : u8) (cast 255 : u8) (cast 255 : u8)))
        (DrawRectangleRec (Rectangle sx sy tile-size tile-size) COLOR-GROUND))
      ;; Platform
      (= tile-type 2)
      (if (texture-loaded? tile-platform)
        (DrawTexture
          tile-platform
          (cast sx : i32)
          (cast sy : i32)
          (Color (cast 255 : u8) (cast 255 : u8) (cast 255 : u8) (cast 255 : u8)))
        (DrawRectangleRec (Rectangle sx sy tile-size tile-size) COLOR-PLATFORM))
      ;; Question block
      (= tile-type 3)
      (DrawRectangleRec (Rectangle sx sy tile-size tile-size) COLOR-QUESTION)
      ;; Empty/used block
      (= tile-type 4)
      (DrawRectangleRec (Rectangle sx sy tile-size tile-size) COLOR-EMPTY-BLOCK)
      unit)))

;; Draw the player with animation at world position (px, py)
;; Camera offset is applied to transform to screen coordinates
(define (draw-player [px : f64] [py : f64] [player-size : f32]) : unit
  (let
    [dest-x : f32 (world-to-screen-x px)]
    [dest-y : f32 (world-to-screen-y py)]
    [dest-w : f32
      (if player-facing-right
        player-size
        (- 0.0 player-size))]
    [dest-h : f32 player-size]
    (if (texture-loaded? player-sprite)
      (DrawTexturePro
        player-sprite
        (player-frame-rect player-anim-frame player-anim-state)
        (Rectangle dest-x dest-y dest-w dest-h)
        (Vector2 0.0 0.0)
        0.0
        (Color (cast 255 : u8) (cast 255 : u8) (cast 255 : u8) (cast 255 : u8)))
      (DrawRectangleRec
        (Rectangle dest-x dest-y (- player-size 4.0) (- player-size 4.0))
        COLOR-PLAYER))))

;; Draw a coin at world position (cx, cy)
(define (draw-coin [cx : f64] [cy : f64]) : unit
  (let
    [dest-x : f32 (world-to-screen-x cx)]
    [dest-y : f32 (world-to-screen-y cy)]
    [r : f32 8.0]
    (DrawRectangleRec
      (Rectangle (- dest-x r) (- dest-y r) (* r 2.0) (* r 2.0))
      COLOR-COIN)))

;; Draw an enemy at world position (ex, ey)
(define (draw-enemy [ex : f64] [ey : f64] [enemy-size : f32]) : unit
  (let
    [dest-x : f32 (world-to-screen-x ex)]
    [dest-y : f32 (world-to-screen-y ey)]
    (DrawRectangleRec
      (Rectangle dest-x dest-y (- enemy-size 4.0) (- enemy-size 4.0))
      COLOR-ENEMY)))

;; Draw a mushroom at world position (mx, my)
(define (draw-mushroom [mx : f64] [my : f64]) : unit
  (let
    [dest-x : f32 (world-to-screen-x mx)]
    [dest-y : f32 (world-to-screen-y my)]
    [hw : f32 10.0]
    (DrawRectangleRec
      (Rectangle (- dest-x hw) (- dest-y hw) (* hw 2.0) (* hw 2.0))
      COLOR-MUSHROOM)))

;; Draw a 1-UP mushroom at world position (ox, oy)
(define (draw-oneup [ox : f64] [oy : f64]) : unit
  (let
    [dest-x : f32 (world-to-screen-x ox)]
    [dest-y : f32 (world-to-screen-y oy)]
    [hw : f32 10.0]
    (DrawRectangleRec
      (Rectangle (- dest-x hw) (- dest-y hw) (* hw 2.0) (* hw 2.0))
      COLOR-ONEUP)))
(define (draw-goal [gx : f64] [gy : f64] [tile-size : f32]) : unit
  (let
    [sx : f32 (world-to-screen-x gx)]
    [sy : f32 (world-to-screen-y gy)]
    [ts : f32 tile-size]
    [pole-w : f32 4.0]
    [flag-w : f32 (- ts 6.0)]
    [flag-h : f32 (* ts 0.6)]
    (begin
      ;; Draw pole
      (DrawRectangleRec
        (Rectangle
          (+ sx (* (- ts pole-w) 0.5))
          sy
          pole-w
          ts)
        COLOR-POLE)
      ;; Draw flag
      (DrawRectangleRec
        (Rectangle
          (+ sx 3.0)
          (+ sy 3.0)
          flag-w
          flag-h)
        COLOR-FLAG))))
