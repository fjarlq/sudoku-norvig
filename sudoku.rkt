#lang racket/base

;;
;; A translation of Peter Norvig's Sudoku puzzle solver into Racket.
;; by Matt Day, based on http://norvig.com/sudoku.html
;;
;; Implements a Sudoku solver that works on an empty or partially-filled 9x9 board.
;;
;; DATA DEFINITION
;;
;; A Sudoku puzzle is a /grid/ of 81 squares:
;;     columns labelled 1-9
;;     rows labelled A-I
;;
;; A collection of 9 squares (column, row, or box) is a /unit/ and the squares
;; that share a unit are the /peers/.
;;
;; A puzzle is solved if the squares in each unit are filled with a permutation
;; of the digits 1 to 9.
;;
;; Throughout this program we have:
;;   r is a row,    e.g. #\A
;;   c is a column, e.g. #\3
;;   s is a square, e.g. "A3"
;;   d is a digit,  e.g. #\9
;;   u is a unit,   e.g. '("A2" "B2" "C2" "D2" "E2" "F2" "G2" "H2" "I2")
;;   grid is a grid,e.g. 81 non-blank chars, e.g. starting with ".18...7...
;;   values is a hash of possible values, e.g. '#hash(("A1" . (#\1 #\2)) ("A2" . (#\'8')) ...)
;;

(require racket/file)
(require racket/format)
(require racket/function)
(require racket/list)
(require racket/sequence)
(require racket/set)
(require racket/string)
(require rackunit)

;;;;;;;;;;;;;;;; Utilities used by definitions ;;;;;;;;;;;;;;;;

; flatten-once : list -> list
(define (flatten-once lst)
  (apply append lst))

; parts : num list -> (listof list)
(define (parts n lst)
  (cond [(empty? lst) '()]
        [(< (length lst) n) (list lst)]
        [else (cons
               (take lst n)
               (parts n (drop lst n)))]))

; member? : any sequence -> boolean
(define (member? item seq)
  (sequence-ormap (lambda (x) (equal? item x))
                  seq))

; Cross product of elements in A and elements in B.
; cross : (listof char) (listof char) -> (listof string)
(define (cross A B)
  (flatten (for/list ([a A])
             (for/list ([b B])
               (string a b)))))

;;;;;;;;;;;;;;;; Definitions ;;;;;;;;;;;;;;;;

(define digits (string->list "123456789"))
(define rows (string->list "ABCDEFGHI"))
(define cols digits)
(define squares (cross rows cols))

(define unitlist (append
                  (for/list ([c cols]) (cross rows (list c)))
                  (for/list ([r rows]) (cross (list r) cols))
                  (flatten-once (for/list ([rs (parts 3 rows)])
                                  (for/list ([cs (parts 3 cols)])
                                    (cross rs cs))))))
(define units (make-immutable-hash
               (for/list ([s squares])
                 (cons s (for/list ([u unitlist]
                                    #:when (member? s u))
                           u)))))

(define peers (make-immutable-hash
               (for/list ([s squares])
                 (cons s (remove s (remove-duplicates (flatten (hash-ref units s))))))))

;;;;;;;;;;;;;;;; Unit Tests ;;;;;;;;;;;;;;;;

; A set of tests that must pass.
(define-test-suite definition-tests
  (check-equal? (length squares) 81)
  (check-equal? (length unitlist) 27)
  (check-true (for/and ([s squares])
                (equal? (length (hash-ref units s)) 3)))
  (check-true (for/and ([s squares])
                (equal? (length (hash-ref peers s)) 20)))
  (check-equal? (hash-ref units "C2")
                '(("A2" "B2" "C2" "D2" "E2" "F2" "G2" "H2" "I2")
                  ("C1" "C2" "C3" "C4" "C5" "C6" "C7" "C8" "C9")
                  ("A1" "A2" "A3" "B1" "B2" "B3" "C1" "C2" "C3")))
  (check-equal? (hash-ref peers "C2")
                '("A2" "B2" "D2" "E2" "F2" "G2" "H2" "I2"
                       "C1" "C3" "C4" "C5" "C6" "C7" "C8" "C9"
                       "A1" "A3" "B1" "B3")))

;;;;;;;;;;;;;;;; Parse a Grid ;;;;;;;;;;;;;;;;

; Convert grid to a hash of possible values (square -> digits), or
; return false if a contradiction is detected.
; parse-grid : string -> hash-or-false
(define (parse-grid grid)
  ; To start, every square can be any digit; then assign values from the grid.
  (let ([initial-values (make-immutable-hash
                         (for/list ([s squares])
                           (cons s digits)))])
    (foldl-bool assign initial-values (filter
                                       (lambda (v) (member? (second v) digits))
                                       (hash->list (grid-values grid))))))

; Convert grid into a hash of (square -> digits) with '0' or '.' for empties.
; grid-values : string -> hash
(define (grid-values grid)
  (let* ([digits0. (append digits '(#\0 #\.))]
         [chars (for/list ([c grid]
                           #:when (member? c digits0.))
                  c)])
    (unless (= 81 (length chars))
      (error "invalid grid length"))
    (make-immutable-hash (zip squares chars))))

;;;;;;;;;;;;;;;; Constraint Propagation ;;;;;;;;;;;;;;;;

; Eliminate all the other values (except d) from values[s] and propagate.
; Return values, except return false if a contradiction is detected.
; assign : pair hash -> hash-or-false
(define (assign v values)
  (let* ([s (first v)]
         [d (second v)]
         [result (foldl-bool
                  (lambda (d-parm values-parm) (eliminate s d-parm values-parm))
                  values
                  (remove d (hash-ref values s)))])
    result))

; Eliminate d from values[s]; propagate when values or places <= 2.
; Return values, except return false if a contradiction is detected.
; eliminate : string char hash -> hash-or-false
(define (eliminate s d values)
  (let ([suspects (hash-ref values s)])
    (cond
      [(not (member? d suspects)) values] ; Already eliminated
      [(equal? 1 (length suspects)) #f]   ; Contradiction: removed last value
      [else
       (let* ([suspects (remove d suspects)]
              [values (hash-set values s suspects)]
              [result (if (equal? 1 (length (hash-ref values s)))
                          ; if square is reduced to one value, eliminate that value from the peers.
                          (foldl-bool
                           (lambda (s2 values-parm) (eliminate s2 (first suspects) values-parm))
                           values
                           (hash-ref peers s))
                          values)])
         ; If a unit u is reduced to only one place for a value d, then put it there.
         (foldl-bool
          (lambda (u values)
            (let ([dplaces (for/list ([s u]
                                      #:when (member? d (hash-ref values s)))
                             s)])
              (cond
                [(zero? (length dplaces)) #f] ; Contradiction: no place for this value
                [(equal? 1 (length dplaces))
                 ; d can only be in one place in unit; assign it there
                 (assign (list (first dplaces) d) values)]
                [else values])))
          result
          (hash-ref units s)))])))

;;;;;;;;;;;;;;;; Display as 2-D grid ;;;;;;;;;;;;;;;;

; Display these values as a 2-D grid.
; display-values : hash -> (void)
(define (display-values values)
  (let* ([width (add1 (apply max (for/list ([s squares])
                                   (length (hash-ref values s)))))]
         [line (string-join (make-list 3 (string-repeat (* 3 width) "-")) "+")]
         [edge (string-repeat (+ 2 (* width (length cols))) "=")])
    (displayln edge)
    (for ([r rows])
      (displayln (string-append* (for/list ([c cols])
                                   (let* ([s (string r c)]
                                          [vstr (list->string (hash-ref values s))])
                                     (string-append
                                      (~a vstr #:min-width width #:align 'center)
                                      (if (member? c '(#\3 #\6)) "|" ""))))))
      (when (member? r '(#\C #\F))
        (displayln line)))
    (displayln edge)))

;;;;;;;;;;;;;;;; Search ;;;;;;;;;;;;;;;;

; solve : string -> hash-or-false
(define (solve grid)
  (search/k (parse-grid grid)
            (lambda (values fail-k) values)
            (lambda () #f)))

; Using depth-first search and propagation, try all possible values.
; search/k : hash (hash (-> X) -> X) (-> X) -> X
(define (search/k values success-k fail-k)
  (cond
    [(boolean? values) (fail-k)] ; Failed earlier
    [(valid-solution? values) (success-k values fail-k)] ; Solved
    [else
     ; Choose the unfilled square with the fewest possibilities
     (let* ([unsolved-values (filter
                              (lambda (v) (> (length v) 2))
                              (hash->list values))]
            [min-unsolved-square (first (argmin
                                         (lambda (v) (length v))
                                         unsolved-values))])
       (let loop ([i 0])
         (let ([possibilities (hash-ref values min-unsolved-square)])
           (cond
             [(= i (length possibilities)) (fail-k)]
             [else
              (search/k (assign (list min-unsolved-square (list-ref possibilities i)) values)
                        success-k
                        (lambda ()
                          (loop (add1 i))))]))))]))

; valid-solution? : hash -> boolean
(define (valid-solution? values)
  (andmap (lambda (lst) (equal? 1 (length lst)))
          (hash-values values)))

;;;;;;;;;;;;;;;; Utilities ;;;;;;;;;;;;;;;;

; Similar to foldl but short-circuits when f returns a boolean.
; Based on Justin Kramer's "reduce-true" idea:
;   https://jkkramer.wordpress.com/2011/03/29/clojure-python-side-by-side/
; I wonder if continuations would be a better approach.
; foldl-bool : proc hash-or-false (listof any) -> hash-or-false
(define (foldl-bool f val lst)
  (cond
    [(boolean? val) val]
    [(empty? lst) val]
    [else
     (foldl-bool f (f (first lst) val) (rest lst))]))

; string-repeat : num string -> string
(define (string-repeat n str)
  (string-append* (make-list n str)))

; Parse a file into a list of strings, separated by sep.
; from-file : string string-or-regexp -> (listof string)
(define (from-file filename [sep (string #\newline)])
  (string-split (file->string filename) sep))

; sum : list -> num
(define (sum lst)
  (foldl + 0 lst))

; zip : list list -> (listof pair)
(define (zip p q)
  (map list p q))

;;;;;;;;;;;;;;;; System test ;;;;;;;;;;;;;;;;

; Attempt to solve a sequence of grids. Report results.
; solve-all : (listof string) string -> (void)
(define (solve-all grids name)
  (let*-values ([(times results) (for/lists (times results)
                                   ([grid grids])
                                   (time-solve grid))]
                [(num-grids) (length grids)]
                [(num-solutions) (length (filter identity (map solved? results)))])
    (printf "Solved ~a of ~a ~a puzzles (avg ~a msecs (~a Hz), max ~a msecs).~n"
            num-solutions
            num-grids
            name
            (real->decimal-string (/ (sum times) num-grids))
            (real->decimal-string (* 1000 (/ num-grids (sum times))))
            (apply max times))))

; time-solve : string -> (real hash)
(define (time-solve grid)
  (let-values ([(result cpu-ms real-ms gc-ms) (time-apply solve (list grid))])
    (values real-ms (first result))))

; unit-solved? : hash (listof string) -> boolean
(define (unit-solved? values unit)
  (equal? (list->set (for/list ([s unit]) (first (hash-ref values s))))
          (list->set digits)))

; A puzzle is solved correctly if each unit is a permutation of the digits 1 to 9.
; solved? : hash -> boolean
(define (solved? values)
  (cond
    [(boolean? values) #f]
    [else (andmap (lambda (unit) (unit-solved? values unit))
                  (for/list ([unit unitlist]) unit))]))

; display-solutions : string -> (void)
(define (display-solutions grid)
  (let ([values (parse-grid grid)])
    (search/k values
              (lambda (v f)
                (display-values v)
                (f))
              (lambda () (void)))))

(define grid1 "003020600900305001001806400008102900700000008006708200002609500800203009005010300")
(define grid2 "4.....8.5.3...00.....7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......")
(define hard1 ".....6....59.....82....8....45........3........6..3.54...325..6..................")
(define mult1 ".8...9743.5...8.1..1.......8....5......8.4......3....6.......7..3.5...8.9724...5.")
(define mult2 "9.6.7.4.3...4..2...7..23.1.5.....1...4.2.8.6...3.....5.3.7...5...7..5...4.5.1.7.8")
(define blank ".................................................................................")

(module+ main
  (require rackunit/text-ui)
  (unless (= 0 (run-tests definition-tests))
    (error "Error: unit test failure."))
  (solve-all (from-file "easy50.txt" "========") "easy")
  (solve-all (from-file "top95.txt") "hard")
  (solve-all (from-file "hardest.txt") "hardest")
  (printf "~nThis puzzle has two solutions:~n")
  (display-values (grid-values mult2))
  (printf "~nSolutions found:~n")
  (display-solutions mult2))

;; References used:
;; http://norvig.com/sudoku.html
;; https://jkkramer.wordpress.com/2011/03/29/clojure-python-side-by-side/
;; http://www.sudokuwiki.org/Strategy_Families
;; http://www.sudokudragon.com/sudokustrategy.htm
;; http://krazydad.com/blog/2005/09/29/an-index-of-sudoku-strategies/
;; http://www2.warwick.ac.uk/fac/sci/moac/people/students/peter_cock/python/sudoku
