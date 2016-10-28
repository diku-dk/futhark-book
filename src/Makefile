FUTHARKC ?= futhark-c
FUTHARKOPENCL ?= futhark-opencl

FUTFILES=$(wildcard *.fut)
FUTEXECS=$(FUTFILES:%.fut=%.exe)
RESFILES=$(FUTFILES:%.fut=%.res)
RESOPENCLFILES=$(FUTFILES:%.fut=%.resopencl)

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

%.exe: %.fut
	$(FUTHARKC) -o $@ $<

%.exeopencl: %.fut
	$(FUTHARKOPENCL) -o $@ $<

%.out: %.exe
	./$< > $@

%.outopencl: %.exeopencl
	./$< -d $(OPENCL_DEVICE) > $@

%.res: %.out
	@(diff -aq $< $*.ok > /dev/null 2>&1; \
         if [ $$? -eq 0 ]; then \
             echo "Test $*.fut: OK" > $@ \
         ; else \
             if [ -e $*.ok ]; then \
                echo "Test $*.fut: *** ERR: file $< differs from $*.ok ***" > $@ \
             ; else \
                echo "Test $*.fut: *** ERR: file $*.ok does not exist ***" > $@ \
             ; fi \
         ; fi)

%.resopencl: %.outopencl
	@(diff -aq $< $*.ok > /dev/null 2>&1; \
         if [ $$? -eq 0 ]; then \
             echo "OpenCL Test $*.fut: OK" > $@ \
         ; else \
             if [ -e $*.ok ]; then \
                echo "OpenCL Test $*.fut: *** ERR: file $< differs from $*.ok ***" > $@ \
             ; else \
                echo "OpenCL Test $*.fut: *** ERR: file $*.ok does not exist ***" > $@ \
             ; fi \
         ; fi)

.PHONY: clean
clean:
	rm -f *~ *.c *.exe *.res *.out *.exeopencl *.resopencl *.outopencl
