FUTHARKC ?= futhark-c
FUTHARKOPENCL ?= futhark-opencl

#FUTFILES=$(wildcard *.fut)

SRCFILES=radix_sort sgm_scan reduce_contract find_idx streak sgm_streak rsort_idx maxidx
SRCFILES_INPUT=dotprod multable primes rsort

RESFILES=$(SRCFILES:%=%.res) $(SRCFILES_INPUT:%=%_inp.res)
RESOPENCLFILES=$(SRCFILES:%=%.resopencl)

OPENCL_DEVICE ?= GeForce

.PHONY: all
all:
	@echo Run 'make test' or 'make testopencl'

.PHONY: test
test: $(RESFILES)
	@cat $(RESFILES)
	@echo "-------T E S T --- R E P O R T-------"
	@echo "Tests succeeded:   `grep "OK" $(RESFILES) | wc -l` /`grep "Test" $(RESFILES) | wc -l`"
	@echo "Test errors:       `grep "ERR" $(RESFILES) | wc -l` /`grep "Test" $(RESFILES) | wc -l`"
	@echo "-------------------------------------"
	@exit `grep "ERR" $(RESFILES) | wc -l`

.PHONY: testopencl
testopencl: $(RESOPENCLFILES)
	@cat $(RESOPENCLFILES)
	@echo "-------O p e n C L --- T E S T --- R E P O R T-------"
	@echo "Tests succeeded:   `grep "OK" $(RESOPENCLFILES) | wc -l` /`grep "Test" $(RESOPENCLFILES) | wc -l`"
	@echo "Test errors:       `grep "ERR" $(RESOPENCLFILES) | wc -l` /`grep "Test" $(RESOPENCLFILES) | wc -l`"
	@echo "-----------------------------------------------------"
	@exit `grep "ERR" $(RESOPENCLFILES) | wc -l`

# Generate executables
%.exe: %.fut
	$(FUTHARKC) -o $@ $<

%.exeopencl: %.fut
	$(FUTHARKOPENCL) -o $@ $<

# Generate output for standard executables (no input)
%.out: %.exe
	./$< > $@

%.outopencl: %.exeopencl
	./$< -d $(OPENCL_DEVICE) > $@

# Generate output for executables that take input
%_inp.out: %.exe
	cat $*.inp | ./$< > $@


%.res: %.out
	@(diff -aq $< $*.ok > /dev/null 2>&1; \
         if [ $$? -eq 0 ]; then \
             echo "Test $*: OK" > $@ \
         ; else \
             if [ -e $*.ok ]; then \
                echo "Test $*: *** ERR: file $< differs from $*.ok ***" > $@ \
             ; else \
                echo "Test $*: *** ERR: file $*.ok does not exist ***" > $@ \
             ; fi \
         ; fi)

%.resopencl: %.outopencl
	@(diff -aq $< $*.ok > /dev/null 2>&1; \
         if [ $$? -eq 0 ]; then \
             echo "OpenCL Test $*: OK" > $@ \
         ; else \
             if [ -e $*.ok ]; then \
                echo "OpenCL Test $*: *** ERR: file $< differs from $*.ok ***" > $@ \
             ; else \
                echo "OpenCL Test $*: *** ERR: file $*.ok does not exist ***" > $@ \
             ; fi \
         ; fi)

.PHONY: clean
clean:
	rm -f *~ *.c *.exe *.res *.out *.exeopencl *.resopencl *.outopencl *-c *-opencl

.PHONY: viz
viz:
	futhark-c -o lines.exe lines.fut
	./lines.exe | ./viz.sh

viz0:
	futhark-c -o lines.exe lines.fut
	./lines.exe
