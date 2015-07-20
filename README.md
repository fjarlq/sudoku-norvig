# sudoku-norvig
Peter Norvig's Sudoku puzzle solver: http://norvig.com/sudoku.html
(translated into Racket by Matt Day)

Sample output:

    6 success(es) 0 failure(s) 0 error(s) 6 test(s) run
    Solved 50 of 50 easy puzzles (avg 19.72 msecs (50.71 Hz), max 54 msecs).
    Solved 95 of 95 hard puzzles (avg 51.67 msecs (19.35 Hz), max 248 msecs).
    Solved 11 of 11 hardest puzzles (avg 23.73 msecs (42.15 Hz), max 48 msecs).
    
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
