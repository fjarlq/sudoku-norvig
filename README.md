# sudoku-norvig
A translation of [Peter Norvig's Sudoku puzzle solver][1] into Racket.

[1]: http://norvig.com/sudoku.html

    $ make
    raco exe sudoku.rkt
    $ ./sudoku
    6 success(es) 0 failure(s) 0 error(s) 6 test(s) run
    Solved 50 of 50 easy puzzles (avg 11.32 msecs (88.34 Hz), max 29 msecs).
    Solved 95 of 95 hard puzzles (avg 30.59 msecs (32.69 Hz), max 169 msecs).
    Solved 11 of 11 hardest puzzles (avg 13.82 msecs (72.37 Hz), max 27 msecs).
    
    This puzzle has two solutions:
    ====================
    9 . 6 |. 7 . |4 . 3 
    . . . |4 . . |2 . . 
    . 7 . |. 2 3 |. 1 . 
    ------+------+------
    5 . . |. . . |1 . . 
    . 4 . |2 . 8 |. 6 . 
    . . 3 |. . . |. . 5 
    ------+------+------
    . 3 . |7 . . |. 5 . 
    . . 7 |. . 5 |. . . 
    4 . 5 |. 1 . |7 . 8 
    ====================
    
    Solutions found:
    ====================
    9 2 6 |5 7 1 |4 8 3 
    3 5 1 |4 8 6 |2 7 9 
    8 7 4 |9 2 3 |5 1 6 
    ------+------+------
    5 8 2 |3 6 7 |1 9 4 
    1 4 9 |2 5 8 |3 6 7 
    7 6 3 |1 9 4 |8 2 5 
    ------+------+------
    2 3 8 |7 4 9 |6 5 1 
    6 1 7 |8 3 5 |9 4 2 
    4 9 5 |6 1 2 |7 3 8 
    ====================
    ====================
    9 2 6 |5 7 1 |4 8 3 
    3 5 1 |4 8 6 |2 7 9 
    8 7 4 |9 2 3 |5 1 6 
    ------+------+------
    5 8 2 |3 6 7 |1 9 4 
    1 4 9 |2 5 8 |3 6 7 
    7 6 3 |1 4 9 |8 2 5 
    ------+------+------
    2 3 8 |7 9 4 |6 5 1 
    6 1 7 |8 3 5 |9 4 2 
    4 9 5 |6 1 2 |7 3 8 
    ====================
