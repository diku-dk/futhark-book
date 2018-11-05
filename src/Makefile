FUTHARKC ?= futhark-c
FUTHARKOPENCL ?= futhark-opencl

OPENCL_DEVICE ?= GeForce

.PHONY: all
all:
	@echo Run 'make test' or 'make testopencl'

.PHONY: test
test: lib
	futhark-test . --compiler=$(FUTHARKC)

.PHONY: testopencl
testopencl:
	futhark-test . --compiler=$(FUTHARKOPENCL) --pass-option=-d$(OPENCL_DEVICE)

lib: futhark.pkg
	futhark-pkg sync

# Generate executables
%.exe: %.fut
	$(FUTHARKC) -o $@ $<

%.exeopencl: %.fut
	$(FUTHARKOPENCL) -o $@ $<

.PHONY: clean
clean:
	rm -f *~ *.c *.exe *.bin *.res *-c *-opencl *.viz break
	rm -f concat_with_map debug dotprod fib_sequential find_idx
	rm -f indices_of_nonzero lines lines_flat lines_seq2 matmul maxidx
	rm -f multable primes radix_sort reduce_contract rsort rsort_idx
	rm -f sgm_repl sgm_scan sgm_streak streak sum sum_tests sumsquares
	rm -f trace lines_seq *_grid.pdf *_grid.tex *_grid.aux *_grid.svg *_grid.log
	rm -f lines_seq_coords

.PHONY: viz
viz: lines.exe
	./lines.exe | ./viz.sh

viz0: lines.exe
	./lines.exe

%.viz: %.exe
	./$< | ./viz.sh > $@
	cat $@

%_grid.pdf: %_grid.tex
	pdflatex $<

%_grid.svg: %_grid.pdf
	pdf2svg $< $@

lines_grid.tex: lines_seq_coords.exe
	cat grid_prefix.tex > $@
	./$< | ./points.sh >> $@
	cat grid_postfix.tex >> $@

triangles_grid.tex: triangles.exe
	cat grid_prefix.tex > $@
	./$< -e coords | ./points.sh >> $@
	cat grid_postfix.tex >> $@
