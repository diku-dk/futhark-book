.. _benchmarking:

Benchmarking
============

Consider an implementation of the dot product of two vectors:

::

    let main (x: []i32) (y: []i32): i32 =
      reduce (+) 0 (map (*) x y)

We previously mentioned that, for small data sets, sequential execution
is likely to be much faster than parallel execution. But how much
faster? To answer this question, we need to measure measure the run time
of the program on some data sets. This is called *benchmarking*. There
are many properties one can benchmark: memory usage, size of compiled
executable, robustness to errors, and so forth. In this section, we are
only concerned with run time. Specifically, we wish to measure *wall
time*, which is how much time elapses in the real world from the time
the computation starts, to the time it ends.

There is still some wiggle room in how we benchmark — for example,
should we measure the time it takes to load the input data from disk?
Initialise various devices and drivers? Perform a clean shutdown? How
many times should we run the program, and should we report maximum,
minimum, or average run time? We will not try to answer all of these
questions, but instead merely describe the benchmarking tools provided
by Futhark.

Simple Measurements
-------------------

First, let us compile ``dotprod.fut`` to two different executables, one
for each compiler:

.. code-block:: none

    $ futhark-c dotprod.fut -o dotprod-c
    $ futhark-opencl dotprod.fut -o dotprod-opencl

One way to time execution is to use the standard ``time(1)`` tool:

.. code-block:: none

    $ echo [2,2,3] [4,5,6] | time ./dotprod-c
    36i32
    0.00user 0.00system 0:00.00elapsed ...
    $ echo [2,2,3] [4,5,6] | time ./dotprod-opencl
    36i32
    0.12user 0.00system 0:00.14elapsed ...

It seems that ``dotprod-c`` executes in less than 10 milliseconds, while
``dotprod-opencl`` takes about 120 milliseconds. However, this is not a
truly useful comparison, as it also measures time taken to read the
input (for both executables), as well as time taken to initialise the
OpenCL driver (for ``dotprod-opencl``). Recall that in a real
application, the Futhark program would be compiled as a *library*, and
the startup cost paid just once, while the program may be invoked
multiple times. A more precise run-time measurement, where parsing,
initialisation, and printing of results is not included, can be
performed using the ``-t`` command line option, which specifies a file
where the run-time (measured in microseconds) should be put:

.. code-block:: none

    $ echo [2,2,3] [4,5,6] | \
      ./dotprod-c -t /dev/stderr > /dev/null
    0

In this case, we ask for the runtime to be printed to the screen, and
for the normal evaluation result to be thrown away. Apparently it takes
less than one microsecond to compute the dot product of two
three-element vectors on a CPU (this is not very surprising). On an AMD
W8100 GPU:

.. code-block:: none

    $ echo [2,2,3] [4,5,6] | \
      ./dotprod-opencl -t /dev/stderr > /dev/null
    575

Almost half a millisecond! This particular GPU has fairly high launch
cost, and so is not particularly suited for this small problem. We can
use the ``futhark-dataset(1)`` tool to generate random test data of a
desired size:

.. code-block:: none

    $ futhark-dataset -g [10000000]i32 -g [10000000]i32 > input

Two ten million element vectors should be enough work to amortise the
GPU startup cost:

.. code-block:: none

    $ cat input | ./dotprod-opencl -t /dev/stderr > /dev/null
    2238
    $ cat input | ./dotprod-c -t /dev/stderr > /dev/null
    17078

That’s more like it - parallel execution is now more than seven times
faster than sequential execution. This program is entirely memory-bound
- on a compute-bound program we can expect much larger speedups.

Multiple Measurements
---------------------

The technique presented in the previous section is sufficient, but
impractical if you want several measurements on the same dataset. While
you can just repeat the above line the desired number of times, this has
two problems:

#. The input file will be read multiple times, which can be slow for
   large data sets.

#. It prevents the device from "warming up", as every run re-initialises
   the GPU and re-uploads code.

Compiled Futhark executables support an ``-r N`` option that asks the
program to perform ``N`` runs internally, and report runtime for each.
Additionally, a non-measured warmup run is performed initially. We can
use it like this:

.. code-block:: none

    $ cat input | ./dotprod-opencl -t /dev/stderr -r 10 > /dev/null
    891
    1074
    1239
    1170
    1312
    1079
    1146
    1273
    1216
    1085

Our runtimes are now much better. And importantly—there are more of
them, so we can perform analyses like determine the variance, to figure
out how predictable the performance is.

However, we can do better still. Futhark comes with a tool for
performing automated benchmark runs of programs, called
``futhark-bench``. This tool relies on a specially formatted header
comment that contains input/output pairs. The `Futhark User's Guide`_
contains a full description, but here is a quick taste. First, we
introduce a new program, ``sumsquares.fut``, with smaller data sets for
convenience:

.. _`Futhark User's Guide`: https://futhark.readthedocs.org

::

    -- Given N, compute the sum of squares of the first N integers.
    -- ==
    -- input          {       1000 } output {   332833500 }
    -- compiled input {    1000000 } output {   584144992 }
    -- compiled input { 1000000000 } output { -2087553280 }

    let main (n: i32): i32 =
      reduce (+) 0 (map (**2) (iota n))

The line containing ``==`` is used to separate the human-readable
benchmark description from input-output pairs. We can use
``futhark-bench`` to measure its performance as such:

.. code-block: none

    $ futhark-bench sumsquares.fut
    sumsquares.fut:
    dataset #0: 2.30us (average; relative standard deviation: 0.20)
    dataset #1: 1307.40us (average; relative standard deviation: 0.38)
    dataset #2: 982640.30us (average; relative standard deviation: 0.00)

These are measurements using the default compiler, which is
``futhark-c``. If we want to see how our program performs when compiled
with ``futhark-opencl``, we can invoke ``futhark-bench`` as such:

.. code-block:: none

    $ futhark-bench --compiler=futhark-opencl sumsquares.fut
    sumsquares.fut:
    dataset #0: 832.60us (average; relative standard deviation: 0.44)
    dataset #1: 970.60us (average; relative standard deviation: 0.56)
    dataset #2: 5950.50us (average; relative standard deviation: 0.02)

We can now compare the performance of CPU execution with GPU execution.
The tool takes care of the mechanics of run-time measurements, and even
computes the standard deviation of the measurements for us. The
correctness of the output is also automatically checked. By default,
``futhark-bench`` performs ten runs for every data set, but this can be
modified using command line options. See the manual page for more
information.
