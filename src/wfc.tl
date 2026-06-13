(import "stdlib/ffi.tl")

;; WFC Tile Set for Platformer
;; 0 = Empty (air)
;; 1 = Solid (ground/wall)
;; 2 = Platform (solid from top only)

;; Tile type definitions
(define TILE-EMPTY   : i64 0)
(define TILE-SOLID   : i64 1)
(define TILE-PLATFORM : i64 2)
(define TILE-COUNT   : i64 3)

;; Directions
(define DIR-UP     : i64 0)
(define DIR-DOWN   : i64 1)
(define DIR-LEFT   : i64 2)
(define DIR-RIGHT  : i64 3)
(define DIR-COUNT  : i64 4)

;; Grid dimensions (must match game)
(define GRID-COLS  : i64 20)
(define GRID-ROWS  : i64 15)
(define GRID-SIZE  : i64 (* GRID-COLS GRID-ROWS))

;; Maximum number of tiles per cell (WFC wave state)
;; Each cell stores a bitmask of possible tiles
;; 3 tiles = bits 0, 1, 2 → max value 0b111 = 7
(define ALL-POSSIBLE : i64 0b111)

;; Cell state: (i64 bitmask) for each cell
;; We store as a flat array of i64 values
;; Each value is a bitmask of possible tiles

;; WFC Grid - stores possible tiles for each cell as bitmask
;; This is the "wave" state

;; Entropy cache: number of possible tiles for each cell
;; -1 means already collapsed

;; Helper: count set bits in a 3-bit number
(define (popcount-3 [n : i64]) : i64
  (let
    [c0 : i64 (if (> (bit-and n 1) 0) 1 0)]
    [c1 : i64 (if (> (bit-and n 2) 0) 1 0)]
    [c2 : i64 (if (> (bit-and n 4) 0) 1 0)]
    (+ c0 (+ c1 c2))))

;; Check if a tile is possible in a bitmask
(define (tile-possible? [mask : i64] [tile : i64]) : bool
  (> (bit-and mask (shl 1 tile)) 0))

;; Remove a tile from a bitmask, return new mask
(define (remove-tile [mask : i64] [tile : i64]) : i64
  (bit-and mask (bit-not (shl 1 tile))))

;; Get the only tile in a mask (assumes exactly one bit set)
(define (get-singleton-tile [mask : i64]) : i64
  (if (> (bit-and mask 1) 0) 0
    (if (> (bit-and mask 2) 0) 1 2)))

;; Adjacency rules: for each tile, for each direction, which tiles are allowed
;; Stored as a flat array: rules[tile * 4 + dir] = bitmask of allowed tiles
;;
;; Rules for platformer tiles:
;; - Empty can be next to anything (air is everywhere)
;; - Solid needs solid below it (for ground) or can be next to anything
;; - Platform needs empty below (it's floating) and solid/platform on sides

;; Define adjacency rules
;; For each tile and direction, specify which tiles are allowed
;;
;; Tile 0 (Empty):
;;   - Can be next to any tile in any direction
;;   - UP: any, DOWN: any, LEFT: any, RIGHT: any
;;
;; Tile 1 (Solid):
;;   - UP: solid or platform (solid ground above)
;;   - DOWN: solid or empty (can have ground below or be bottom)
;;   - LEFT: any, RIGHT: any
;;
;; Tile 2 (Platform):
;;   - UP: empty (platforms are floating)
;;   - DOWN: empty (platforms float)
;;   - LEFT: empty or platform
;;   - RIGHT: empty or platform

;; Manually define adjacency rules as a function
;; Returns bitmask of allowed tiles
(define (get-allowed [tile : i64] [dir : i64]) : i64
  (cond
    ;; Tile 0 (Empty) - can be next to anything
    (= tile 0) ALL-POSSIBLE
    
    ;; Tile 1 (Solid)
    (= tile 1)
    (cond
      (= dir DIR-UP)    ;; Above solid: solid or platform
        (bit-or (shl 1 1) (shl 1 2))
      (= dir DIR-DOWN)  ;; Below solid: anything
        ALL-POSSIBLE
      (= dir DIR-LEFT)  ;; Left of solid: anything
        ALL-POSSIBLE
      (= dir DIR-RIGHT) ;; Right of solid: anything
        ALL-POSSIBLE
      ALL-POSSIBLE)
    
    ;; Tile 2 (Platform)
    (= tile 2)
    (cond
      (= dir DIR-UP)    ;; Above platform: empty
        (shl 1 0)
      (= dir DIR-DOWN)  ;; Below platform: empty
        (shl 1 0)
      (= dir DIR-LEFT)  ;; Left of platform: empty or platform
        (bit-or (shl 1 0) (shl 1 2))
      (= dir DIR-RIGHT) ;; Right of platform: empty or platform
        (bit-or (shl 1 0) (shl 1 2))
      ALL-POSSIBLE)
    
    ALL-POSSIBLE))

;; Get the opposite direction
(define (opposite-dir [dir : i64]) : i64
  (cond
    (= dir DIR-UP)    DIR-DOWN
    (= dir DIR-DOWN)  DIR-UP
    (= dir DIR-LEFT)  DIR-RIGHT
    (= dir DIR-RIGHT) DIR-LEFT
    dir))

;; Check if two tiles are compatible (tile_a can be in direction from tile_b)
(define (compatible? [tile-a : i64] [tile-b : i64] [dir : i64]) : bool
  (tile-possible? (get-allowed tile-b dir) tile-a))

;; Initialize a WFC grid with all cells having all possible tiles
(define (init-wfc-grid [grid : (Array i64)]) : unit
  (let ([i : i64 0])
    (while (< i GRID-SIZE)
      (begin
        (array-set! grid i ALL-POSSIBLE)
        (set! i (+ i 1))))))

;; Get cell index from row, col
(define (cell-idx [row : i64] [col : i64]) : i64
  (+ (* row GRID-COLS) col))

;; Get neighbor cell index in a direction, return -1 if out of bounds
(define (neighbor-idx [row : i64] [col : i64] [dir : i64]) : i64
  (cond
    (= dir DIR-UP)
    (if (> row 0) (cell-idx (- row 1) col) -1)
    (= dir DIR-DOWN)
    (if (< row (- GRID-ROWS 1)) (cell-idx (+ row 1) col) -1)
    (= dir DIR-LEFT)
    (if (> col 0) (cell-idx row (- col 1)) -1)
    (= dir DIR-RIGHT)
    (if (< col (- GRID-COLS 1)) (cell-idx row (+ col 1)) -1)
    -1))

;; Find the cell with minimum entropy (fewest possible tiles, but > 1)
;; Return -1 if all cells are collapsed or if contradiction found
(define (find-min-entropy [grid : (Array i64)]) : i64
  (let
    [min-entropy : i64 4]  ;; More than max possible (3)
    [min-idx : i64 -1]
    [i : i64 0]
    (begin
      (while (< i GRID-SIZE)
        (let
          [mask : i64 (array-ref grid i)]
          [entropy : i64 (popcount-3 mask)]
          (begin
            (when (and (> entropy 1) (< entropy min-entropy))
              (set! min-entropy entropy)
              (set! min-idx i))
            (set! i (+ i 1)))))
      min-idx)))

;; Check if there's a contradiction (any cell has 0 possible tiles)
(define (has-contradiction? [grid : (Array i64)]) : bool
  (let
    [found : bool false]
    [i : i64 0]
    (begin
      (while (and (not found) (< i GRID-SIZE))
        (begin
          (if (= (array-ref grid i) 0)
            (set! found true)
            (set! i (+ i 1)))))
      found)))

;; Check if all cells are collapsed (exactly one tile each)
(define (all-collapsed? [grid : (Array i64)]) : bool
  (let
    [all-done : bool true]
    [i : i64 0]
    (begin
      (while (and all-done (< i GRID-SIZE))
        (begin
          (if (> (popcount-3 (array-ref grid i)) 1)
            (set! all-done false)
            (set! i (+ i 1)))))
      all-done)))

;; Propagate constraints from a collapsed cell
;; Uses a simple queue-based propagation
;; Returns false if contradiction found
(define (propagate [grid : (Array i64)]) : bool
  (let
    [changed : bool true]
    [passes : i64 0]
    [max-passes : i64 (* GRID-SIZE 2)]
    (begin
      (while (and changed (< passes max-passes))
        (begin
          (set! changed false)
          (set! passes (+ passes 1))
          (let
            [i : i64 0]
            (begin
              (while (< i GRID-SIZE)
                (let
                  [mask : i64 (array-ref grid i)]
                  [entropy : i64 (popcount-3 mask)]
                  (begin
                    (when (> entropy 0)
                      (let
                        [row : i64 (/ i GRID-COLS)]
                        [col : i64 (% i GRID-COLS)]
                        [d : i64 0]
                        (begin
                          (while (< d DIR-COUNT)
                            (let
                              [nbr-idx : i64 (neighbor-idx row col d)]
                              (begin
                                (when (>= nbr-idx 0)
                                  (let
                                    [nbr-mask : i64 (array-ref grid nbr-idx)]
                                    [nbr-entropy : i64 (popcount-3 nbr-mask)]
                                    (begin
                                      (when (> nbr-entropy 0)
                                        (let
                                          [allowed : i64 0]
                                          [t : i64 0]
                                          (begin
                                            ;; For each possible tile in current cell
                                            (while (< t TILE-COUNT)
                                              (begin
                                                (when (tile-possible? mask t)
                                                  (let
                                                    [rev-dir : i64 (opposite-dir d)]
                                                    [allowed-tiles : i64 (get-allowed t rev-dir)]
                                                    (set! allowed (bit-or allowed allowed-tiles)))
                                                  )
                                                (set! t (+ t 1))))
                                            ;; Intersect with neighbor's possibilities
                                            (let
                                              [new-mask : i64 (bit-and nbr-mask allowed)]
                                              (begin
                                                (when (< new-mask nbr-mask)
                                                  (set! changed true)
                                                  (array-set! grid nbr-idx new-mask)))))))))
                                (set! d (+ d 1)))))))
                    (set! i (+ i 1)))))))
      (not (has-contradiction? grid)))))

;; Collapse a cell to a single tile (chosen randomly or deterministically)
;; For now, just pick the first available tile
(define (collapse-cell [grid : (Array i64)] [idx : i64]) : unit
  (let
    [mask : i64 (array-ref grid idx)]
    [t : i64 0]
    (begin
      (while (< t TILE-COUNT)
        (begin
          (when (tile-possible? mask t)
            (array-set! grid idx (shl 1 t))
            (set! t TILE-COUNT))  ;; Exit loop
          (set! t (+ t 1)))))))

;; Run WFC algorithm to generate a level
;; Returns true on success, false on contradiction
(define (wfc-generate [grid : (Array i64)]) : bool
  (begin
    ;; Initialize grid with all possibilities
    (init-wfc-grid grid)
    
    ;; Optionally constrain edges (e.g., bottom row must be solid)
    ;; Constrain bottom row to be solid
    (let ([c : i64 0])
      (while (< c GRID-COLS)
        (begin
          (array-set! grid (cell-idx (- GRID-ROWS 1) c) (shl 1 TILE-SOLID))
          (set! c (+ c 1)))))
    
    ;; Constrain top row to be empty
    (let ([c : i64 0])
      (while (< c GRID-COLS)
        (begin
          (array-set! grid (cell-idx 0 c) (shl 1 TILE-EMPTY))
          (set! c (+ c 1)))))
    
    ;; Initial propagation
    (if (not (propagate grid))
      false
      (begin
        ;; Main WFC loop
        (let
          [iterations : i64 0]
          [max-iterations : i64 GRID-SIZE]
          (begin
            (while (and (< iterations max-iterations) (not (all-collapsed? grid)))
              (let
                [idx : i64 (find-min-entropy grid)]
                (begin
                  (if (< idx 0)
                    (set! iterations max-iterations)  ;; All collapsed or contradiction
                    (begin
                      (collapse-cell grid idx)
                      (if (not (propagate grid))
                        (set! iterations max-iterations)  ;; Contradiction
                        (set! iterations (+ iterations 1)))))))
            (all-collapsed? grid)))))))

;; Convert WFC grid to game level array (0 = empty, 1 = solid/platform)
(define (wfc-to-level [grid : (Array i64)] [level : (Array i64)]) : unit
  (let
    [i : i64 0]
    (begin
      (while (< i GRID-SIZE)
        (let
          [mask : i64 (array-ref grid i)]
          [tile : i64 (get-singleton-tile mask)]
          (begin
            (if (= tile 0)
              (array-set! level i 0)  ;; Empty
              (array-set! level i 1))  ;; Solid or Platform → solid for collision
            (set! i (+ i 1))))))))
