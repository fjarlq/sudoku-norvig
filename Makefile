exe = sudoku
src = sudoku.rkt

$(exe): $(src)
	raco exe $(src)

clean:
	$(RM) $(exe)

.PHONY: clean
