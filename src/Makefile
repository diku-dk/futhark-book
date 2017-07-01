FUTHARKC ?= futhark-c
FUTHARKOPENCL ?= futhark-opencl

OPENCL_DEVICE ?= GeForce

.PHONY: all
all:
	@echo Run 'make test' or 'make testopencl'

.PHONY: test
test:
	futhark-test . --compiler=$(FUTHARKC)

.PHONY: testopencl
testopencl:
	futhark-test . --compiler=$(FUTHARKOPENCL) --pass-option=-d$(OPENCL_DEVICE)

# Generate executables
%.exe: %.fut
	$(FUTHARKC) -o $@ $<

%.exeopencl: %.fut
	$(FUTHARKOPENCL) -o $@ $<

.PHONY: clean
clean:
	rm -f *~ *.c *.exe *.bin *.res *.out *-c *-opencl

.PHONY: viz
viz:
	futhark-c -o lines.exe lines.fut
	./lines.exe | ./viz.sh

viz0:
	futhark-c -o lines.exe lines.fut
	./lines.exe
