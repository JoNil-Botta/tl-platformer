(import stdlib.ffi)
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
  (Texture2D 0 0 0 0 0))
(define tile-platform : Texture2D
  (Texture2D 0 0 0 0 0))
(define tile-wall : Texture2D
  (Texture2D 0 0 0 0 0))

;; Player sprite sheet
(define player-sprite : Texture2D
  (Texture2D 0 0 0 0 0))

;; Animation frame dimensions (in the sprite sheet)
(define PLAYER-FRAME-W : i32
  32)
(define PLAYER-FRAME-H : i32
  32)
(define PLAYER-FRAMES-PER-ROW : i64
  4)

;; Animation states
(define ANIM-IDLE : i64
  0)
(define ANIM-RUN : i64
  1)
(define ANIM-JUMP : i64
  2)
(define ANIM-FALL : i64
  3)

;; Current animation state
(define player-anim-state : i64
  ANIM-IDLE)
(define player-anim-timer : f64
  0.0)
(define player-anim-frame : i64
  0)
(define player-facing-right : bool
  true)

;; Animation timing
(define ANIM-FPS : f64
  8.0)

;; Fallback colors when textures aren't loaded
(define COLOR-GROUND : Color
  (Color 90 60 30 255))
(define COLOR-PLATFORM : Color
  (Color 139 90 43 255))
(define COLOR-WALL : Color
  (Color 100 100 100 255))
(define COLOR-PLAYER : Color
  (Color 220 40 40 255))
(define COLOR-FLAG : Color
  (Color 50 200 50 255))
(define COLOR-POLE : Color
  (Color 200 200 200 255))

;; Enemy colors
(define COLOR-ENEMY : Color
  (Color 140 40 220 255))

;; Coin color
(define COLOR-COIN : Color
  (Color 255 215 0 255))

;; Question block color
(define COLOR-QUESTION : Color
  (Color 255 165 0 255))

;; Empty/used block color
(define COLOR-EMPTY-BLOCK : Color
  (Color 139 90 43 255))

;; Brick block color
(define COLOR-BRICK : Color
  (Color 180 70 50 255))

;; Pipe top color
(define COLOR-PIPE-TOP : Color
  (Color 50 160 50 255))

;; Pipe body color
(define COLOR-PIPE-BODY : Color
  (Color 40 140 40 255))

;; Mushroom color
(define COLOR-MUSHROOM : Color
  (Color 220 60 60 255))

;; 1-UP mushroom color (green)
(define COLOR-ONEUP : Color
  (Color 60 220 60 255))

;; Spring block color
(define COLOR-SPRING : Color
  (Color 255 50 100 255))

;; Biome system
(define BIOME-OVERWORLD : i64
  0)
(define BIOME-UNDERGROUND : i64
  1)
(define BIOME-CASTLE : i64
  2)

;; Current biome (global, set before drawing)
(define current-biome : i64
  0)

;; Background colors per biome
(define COLOR-BG-OVERWORLD : Color
  (Color 135 206 235 255))
(define COLOR-BG-UNDERGROUND : Color
  (Color 30 30 40 255))
(define COLOR-BG-CASTLE : Color
  (Color 20 10 10 255))

;; Underground tile colors
(define COLOR-UG-GROUND : Color
  (Color 80 80 80 255))
(define COLOR-UG-PLATFORM : Color
  (Color 100 70 40 255))
(define COLOR-UG-QUESTION : Color
  (Color 200 120 0 255))
(define COLOR-UG-EMPTY-BLOCK : Color
  (Color 100 70 40 255))
(define COLOR-UG-BRICK : Color
  (Color 120 60 40 255))
(define COLOR-UG-PIPE-TOP : Color
  (Color 100 80 60 255))
(define COLOR-UG-PIPE-BODY : Color
  (Color 90 70 50 255))

;; Castle tile colors
(define COLOR-CASTLE-GROUND : Color
  (Color 60 60 60 255))
(define COLOR-CASTLE-PLATFORM : Color
  (Color 80 80 90 255))
(define COLOR-CASTLE-QUESTION : Color
  (Color 180 140 0 255))
(define COLOR-CASTLE-EMPTY-BLOCK : Color
  (Color 80 80 80 255))
(define COLOR-CASTLE-BRICK : Color
  (Color 140 40 30 255))
(define COLOR-CASTLE-PIPE-TOP : Color
  (Color 80 80 80 255))
(define COLOR-CASTLE-PIPE-BODY : Color
  (Color 70 70 70 255))

;; Get background color for current biome
(define (biome-background-color) : Color
  (cond
    [(= current-biome BIOME-UNDERGROUND) COLOR-BG-UNDERGROUND]
    [(= current-biome BIOME-CASTLE) COLOR-BG-CASTLE]
    [else COLOR-BG-OVERWORLD]))

;; Get tile color for current biome and tile type
(define (biome-tile-color [tile-type : i64]) : Color
  (cond
    [(= tile-type 1)
      (if (= current-biome BIOME-UNDERGROUND)
        COLOR-UG-GROUND
        (if (= current-biome BIOME-CASTLE)
          COLOR-CASTLE-GROUND
          COLOR-GROUND))]
    [(= tile-type 2)
      (if (= current-biome BIOME-UNDERGROUND)
        COLOR-UG-PLATFORM
        (if (= current-biome BIOME-CASTLE)
          COLOR-CASTLE-PLATFORM
          COLOR-PLATFORM))]
    [(= tile-type 3)
      (if (= current-biome BIOME-UNDERGROUND)
        COLOR-UG-QUESTION
        (if (= current-biome BIOME-CASTLE)
          COLOR-CASTLE-QUESTION
          COLOR-QUESTION))]
    [(= tile-type 4)
      (if (= current-biome BIOME-UNDERGROUND)
        COLOR-UG-EMPTY-BLOCK
        (if (= current-biome BIOME-CASTLE)
          COLOR-CASTLE-EMPTY-BLOCK
          COLOR-EMPTY-BLOCK))]
    [(= tile-type 5)
      (if (= current-biome BIOME-UNDERGROUND)
        COLOR-UG-BRICK
        (if (= current-biome BIOME-CASTLE)
          COLOR-CASTLE-BRICK
          COLOR-BRICK))]
    [(= tile-type 6)
      (if (= current-biome BIOME-UNDERGROUND)
        COLOR-UG-PIPE-TOP
        (if (= current-biome BIOME-CASTLE)
          COLOR-CASTLE-PIPE-TOP
          COLOR-PIPE-TOP))]
    [(= tile-type 7)
      (if (= current-biome BIOME-UNDERGROUND)
        COLOR-UG-PIPE-BODY
        (if (= current-biome BIOME-CASTLE)
          COLOR-CASTLE-PIPE-BODY
          COLOR-PIPE-BODY))]
    [(= tile-type 8) COLOR-SPRING]
    [else (Color 255 0 255 255)]))

;; Check if a texture is loaded (id > 0)
(define (texture-loaded? [tex : Texture2D]) : bool
  (> (struct-get tex id) 0))

;; Load all game assets
(define (load-assets) : unit
  (begin
    (set! tile-ground (LoadTexture (ffi.cstr "assets/tiles/ground.png")))
    (set! tile-platform (LoadTexture (ffi.cstr "assets/tiles/platform.png")))
    (set! tile-wall (LoadTexture (ffi.cstr "assets/tiles/wall.png")))
    (set!
      player-sprite
      (LoadTexture (ffi.cstr "assets/player/spritesheet.png")))))

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
          (% (+ player-anim-frame 1) PLAYER-FRAMES-PER-ROW))))))

(extern (DrawRectangleRec [rec : Rectangle] [color : Color]) : unit)

;; Draw a tile at world position (x, y) with given size
;; Camera offset is applied to transform to screen coordinates
(define (draw-tile [wx : f64] [wy : f64] [tile-size : f32] [tile-type : i64]) : unit
  (let
    [sx : f32 (world-to-screen-x wx)]
    [sy : f32 (world-to-screen-y wy)]
    (cond
      ;; Empty tile - draw nothing (sky is background)
      [(= tile-type 0) unit]
      ;; Solid ground
      [(= tile-type 1)
        (if (texture-loaded? tile-ground)
          (DrawTexture
            tile-ground
            (cast sx : i32)
            (cast sy : i32)
            (Color 255 255 255 255))
          (DrawRectangleRec
            (Rectangle sx sy tile-size tile-size)
            (biome-tile-color tile-type)))]
      ;; Platform
      [(= tile-type 2)
        (if (texture-loaded? tile-platform)
          (DrawTexture
            tile-platform
            (cast sx : i32)
            (cast sy : i32)
            (Color 255 255 255 255))
          (DrawRectangleRec
            (Rectangle sx sy tile-size tile-size)
            (biome-tile-color tile-type)))]
      ;; Question block
      [(= tile-type 3)
        (DrawRectangleRec
          (Rectangle sx sy tile-size tile-size)
          (biome-tile-color tile-type))]
      ;; Empty/used block
      [(= tile-type 4)
        (DrawRectangleRec
          (Rectangle sx sy tile-size tile-size)
          (biome-tile-color tile-type))]
      ;; Brick block
      [(= tile-type 5)
        (DrawRectangleRec
          (Rectangle sx sy tile-size tile-size)
          (biome-tile-color tile-type))]
      ;; Pipe top
      [(= tile-type 6)
        (DrawRectangleRec
          (Rectangle sx sy tile-size tile-size)
          (biome-tile-color tile-type))]
      ;; Pipe body
      [(= tile-type 7)
        (DrawRectangleRec
          (Rectangle sx sy tile-size tile-size)
          (biome-tile-color tile-type))]
      ;; Spring block
      [(= tile-type 8)
        (DrawRectangleRec (Rectangle sx sy tile-size tile-size) COLOR-SPRING)]
      [else unit])))

;; Draw the player with animation at world position (px, py)
;; Camera offset is applied to transform to screen coordinates
(define (draw-player [px : f64] [py : f64] [player-size : f32]) : unit
  (let
    [dest-x : f32 (world-to-screen-x (- px (* (cast player-size : f64) 0.5)))]
    [dest-y : f32 (world-to-screen-y (- py (* (cast player-size : f64) 0.5)))]
    (if (texture-loaded? player-sprite)
      (DrawTextureRec
        player-sprite
        (player-frame-rect player-anim-frame player-anim-state)
        (Vector2 dest-x dest-y)
        (Color 255 255 255 255))
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
        (Rectangle (+ sx (* (- ts pole-w) 0.5)) sy pole-w ts)
        COLOR-POLE)
      ;; Draw flag
      (DrawRectangleRec
        (Rectangle (+ sx 3.0) (+ sy 3.0) flag-w flag-h)
        COLOR-FLAG))))