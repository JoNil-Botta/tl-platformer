(import "stdlib/ffi.tl")
(import "stdlib/string.tl")

;; High score persistence: simple file-based storage

(define HIGH-SCORE-FILE : (Ptr u8)
  (ffi-cstr "highscore.txt"))

(define high-score : i64
  (cast 0 : i64))

;; C file I/O FFI
(extern (fopen [filename : (Ptr u8)] [mode : (Ptr u8)]) : (Ptr unit))
(extern (fclose [stream : (Ptr unit)]) : i32)
(extern (fread [ptr : (MutPtr u8)] [size : i64] [nmemb : i64] [stream : (Ptr unit)]) : i64)
(extern (fwrite [ptr : (Ptr u8)] [size : i64] [nmemb : i64] [stream : (Ptr unit)]) : i64)
(extern (fputs [str : (Ptr u8)] [stream : (Ptr unit)]) : i32)
(extern (remove [filename : (Ptr u8)]) : i32)

;; Parse digits from a byte buffer, returning the numeric value.
;; Stops at first non-digit or null byte.
(define (parse-digits [buf : (Array u8)] [max-len : i64]) : i64
  (let
    [value : i64 0]
    [i : i64 0]
    [done : bool false]
    (begin
      (while (and (not done) (< i max-len))
        (let
          [b : u8 (array-ref buf i)]
          (if (and (>= (cast b : i64) 48) (<= (cast b : i64) 57))
            (begin
              (set! value (+ (* value 10) (- (cast b : i64) 48)))
              (set! i (+ i 1)))
            (set! done true))))
      value)))

;; Load high score from file. Returns true if successful.
(define (high-score-load) : bool
  (let
    [fp : (Ptr unit) (fopen HIGH-SCORE-FILE (ffi-cstr "r"))]
    (if (unsafe (ptr-null? (ptr-cast fp : (Ptr unit))))
      false
      (let
        [buf : (Array u8) (make-array u8 32)]
        [buf-ptr : (MutPtr u8) (unsafe (ptr-cast (array-data buf) : (MutPtr u8)))]
        [nread : i64 (fread buf-ptr (cast 1 : i64) (cast 31 : i64) fp)]
        (begin
          (fclose fp)
          (if (> nread 0)
            (begin
              (array-set! buf (cast 31 : i64) (cast 0 : u8))
              (set! high-score (parse-digits buf nread))
              true)
            false))))))

;; Save high score to file. Returns true if successful.
(define (high-score-save) : bool
  (let
    [fp : (Ptr unit) (fopen HIGH-SCORE-FILE (ffi-cstr "w"))]
    (if (unsafe (ptr-null? (ptr-cast fp : (Ptr unit))))
      false
      (let
        [score-str : String (int->string high-score)]
        (begin
          (fputs (ffi-cstr score-str) fp)
          (fputs (ffi-cstr "\n") fp)
          (fclose fp)
          true)))))

;; Update high score if current score is higher. Returns true if new high score.
(define (high-score-update [current : i64]) : bool
  (if (> current high-score)
    (begin
      (set! high-score current)
      (high-score-save)
      true)
    false))

;; Get the current high score
(define (get-high-score) : i64
  high-score)

;; Reset high score (for testing)
(define (high-score-reset) : unit
  (begin
    (set! high-score (cast 0 : i64))
    (remove HIGH-SCORE-FILE)
    unit))
