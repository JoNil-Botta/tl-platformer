(import "stdlib/ffi.tl")

;; Audio system for tl-platformer
;; Loads and plays sound effects via Raylib

;; Raylib audio FFI
(extern (InitAudioDevice) : unit)
(extern (CloseAudioDevice) : unit)
(extern (LoadSound [fileName : (Ptr u8)]) : Sound)
(extern (UnloadSound [sound : Sound]) : unit)
(extern (PlaySound [sound : Sound]) : unit)
(extern (IsSoundValid [sound : Sound]) : bool)

;; Sound struct (opaque handle)
(defstruct Sound
  (stream AudioStream)
  (frameCount u32))

(defstruct AudioStream
  (buffer (Ptr unit))
  (processor (Ptr unit))
  (sampleRate u32)
  (sampleSize u32)
  (channels u16))

;; Sound handles
(define snd-jump : Sound
  (Sound (AudioStream (ptr-null : (Ptr unit)) (ptr-null : (Ptr unit)) (cast 0 : u32) (cast 0 : u32) (cast 0 : u16)) (cast 0 : u32)))
(define snd-coin : Sound
  (Sound (AudioStream (ptr-null : (Ptr unit)) (ptr-null : (Ptr unit)) (cast 0 : u32) (cast 0 : u32) (cast 0 : u16)) (cast 0 : u32)))
(define snd-stomp : Sound
  (Sound (AudioStream (ptr-null : (Ptr unit)) (ptr-null : (Ptr unit)) (cast 0 : u32) (cast 0 : u32) (cast 0 : u16)) (cast 0 : u32)))
(define snd-death : Sound
  (Sound (AudioStream (ptr-null : (Ptr unit)) (ptr-null : (Ptr unit)) (cast 0 : u32) (cast 0 : u32) (cast 0 : u16)) (cast 0 : u32)))
(define snd-powerup : Sound
  (Sound (AudioStream (ptr-null : (Ptr unit)) (ptr-null : (Ptr unit)) (cast 0 : u32) (cast 0 : u32) (cast 0 : u16)) (cast 0 : u32)))
(define snd-oneup : Sound
  (Sound (AudioStream (ptr-null : (Ptr unit)) (ptr-null : (Ptr unit)) (cast 0 : u32) (cast 0 : u32) (cast 0 : u16)) (cast 0 : u32)))
(define snd-bump : Sound
  (Sound (AudioStream (ptr-null : (Ptr unit)) (ptr-null : (Ptr unit)) (cast 0 : u32) (cast 0 : u32) (cast 0 : u16)) (cast 0 : u32)))

;; Audio enabled flag
(define audio-enabled : bool
  false)

;; Initialize audio and load all sounds
(define (audio-init) : unit
  (begin
    (InitAudioDevice)
    (set! snd-jump (LoadSound (ffi-cstr "assets/sounds/jump.wav")))
    (set! snd-coin (LoadSound (ffi-cstr "assets/sounds/coin.wav")))
    (set! snd-stomp (LoadSound (ffi-cstr "assets/sounds/stomp.wav")))
    (set! snd-death (LoadSound (ffi-cstr "assets/sounds/death.wav")))
    (set! snd-powerup (LoadSound (ffi-cstr "assets/sounds/powerup.wav")))
    (set! snd-oneup (LoadSound (ffi-cstr "assets/sounds/oneup.wav")))
    (set! snd-bump (LoadSound (ffi-cstr "assets/sounds/bump.wav")))
    (set! audio-enabled true)))

;; Unload all sounds and close audio
(define (audio-shutdown) : unit
  (begin
    (UnloadSound snd-jump)
    (UnloadSound snd-coin)
    (UnloadSound snd-stomp)
    (UnloadSound snd-death)
    (UnloadSound snd-powerup)
    (UnloadSound snd-oneup)
    (UnloadSound snd-bump)
    (CloseAudioDevice)
    (set! audio-enabled false)))

;; Play a sound if audio is enabled
(define (play-sound-if-enabled [sound : Sound]) : unit
  (when audio-enabled
    (PlaySound sound)))

;; Sound trigger helpers
(define (play-jump) : unit
  (play-sound-if-enabled snd-jump))

(define (play-coin) : unit
  (play-sound-if-enabled snd-coin))

(define (play-stomp) : unit
  (play-sound-if-enabled snd-stomp))

(define (play-death) : unit
  (play-sound-if-enabled snd-death))

(define (play-powerup) : unit
  (play-sound-if-enabled snd-powerup))

(define (play-oneup) : unit
  (play-sound-if-enabled snd-oneup))

(define (play-bump) : unit
  (play-sound-if-enabled snd-bump))
