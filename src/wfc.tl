
;; === Validation functions ===

;; Check that all cells are collapsed (single tile each)
(define (wfc-validate-collapsed [grid : (Array i64)]) : bool
  (let
    [valid : bool true]
    [i : i64 0]
    (begin
      (while (and valid (< i GRID-SIZE))
        (begin
          (if (> (popcount-3 (array-ref grid i)) 1)
            (set! valid false)
            (set! i (+ i 1)))))
      valid)))

;; Check that no cell has a contradiction (0 possible tiles)
(define (wfc-validate-no-contradiction [grid : (Array i64)]) : bool
  (not (has-contradiction? grid)))

;; Check that all adjacent cells follow the adjacency rules
(define (wfc-validate-adjacency [grid : (Array i64)]) : bool
  (let
    [valid : bool true]
    [i : i64 0]
    (begin
      (while (and valid (< i GRID-SIZE))
        (let
          [mask : i64 (array-ref grid i)]
          [tile : i64 (get-singleton-tile mask)]
          [row : i64 (/ i GRID-COLS)]
          [col : i64 (% i GRID-COLS)]
          [d : i64 0]
          (begin
            (while (and valid (< d DIR-COUNT))
              (let
                [nbr-idx : i64 (neighbor-idx row col d)]
                (begin
                  (when (>= nbr-idx 0)
                    (let
                      [nbr-tile : i64 (get-singleton-tile (array-ref grid nbr-idx))]
                      (begin
                        (if (not (compatible? nbr-tile tile d))
                          (set! valid false)
                          unit))))
                  (set! d (+ d 1))))))
        (set! i (+ i 1))))
      valid)))

;; Check that bottom row is all solid
(define (wfc-validate-bottom-solid [grid : (Array i64)]) : bool
  (let
    [valid : bool true]
    [c : i64 0]
    (begin
      (while (and valid (< c GRID-COLS))
        (begin
          (let
            [tile : i64 (get-singleton-tile (array-ref grid (cell-idx (- GRID-ROWS 1) c)))]
            (begin
              (if (not (= tile TILE-SOLID))
                (set! valid false)
                (set! c (+ c 1))))))
      valid)))

;; Check that top row is all empty
(define (wfc-validate-top-empty [grid : (Array i64)]) : bool
  (let
    [valid : bool true]
    [c : i64 0]
    (begin
      (while (and valid (< c GRID-COLS))
        (begin
          (let
            [tile : i64 (get-singleton-tile (array-ref grid (cell-idx 0 c)))]
            (begin
              (if (not (= tile TILE-EMPTY))
                (set! valid false)
                (set! c (+ c 1))))))
      valid)))

;; Check that there is at least one non-solid tile in the middle rows
;; (so the player has somewhere to move)
(define (wfc-validate-playable-area [grid : (Array i64)]) : bool
  (let
    [found-empty : bool false]
    [i : i64 0]
    (begin
      (while (and (not found-empty) (< i GRID-SIZE))
        (let
          [tile : i64 (get-singleton-tile (array-ref grid i))]
          [row : i64 (/ i GRID-COLS)]
          (begin
            (when (and (> row 0) (< row (- GRID-ROWS 1)) (= tile TILE-EMPTY))
              (set! found-empty true))
            (set! i (+ i 1)))))
      found-empty)))

;; Run all validation checks and return true if all pass
(define (wfc-validate [grid : (Array i64)]) : bool
  (and
    (wfc-validate-collapsed grid)
    (wfc-validate-no-contradiction grid)
    (wfc-validate-adjacency grid)
    (wfc-validate-bottom-solid grid)
    (wfc-validate-top-empty grid)
    (wfc-validate-playable-area grid)))
