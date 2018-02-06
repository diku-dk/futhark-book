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
    0.20user 0.07system 0:00.29elapsed ...

It seems that ``dotprod-c`` executes in less than 10 milliseconds,
while ``dotprod-opencl`` takes about 290 milliseconds. However, this
is not a useful comparison, as it also measures time taken to read the
input (for both executables), as well as time taken to initialise the
OpenCL driver (for ``dotprod-opencl``). Recall that in a real
application, the Futhark program would be compiled as a *library*, and
the startup cost paid just once, while the program may be invoked
multiple times. A more precise run-time measurement, where parsing,
initialisation, and printing of results is not included, can be
performed using the ``-t`` command line option, which specifies a file
where the run-time (measured in microseconds) should be put:

.. code-block:: none

    $ echo [2,2,3] [4,5,6] | ./dotprod-c -t /dev/stderr > /dev/null
    0

In this case, we ask for the runtime to be printed to the screen, and
for the normal evaluation result to be thrown away. Apparently it takes
less than one microsecond to compute the dot product of two
three-element vectors on a CPU (this is not very surprising). On an AMD
Vega 64 GPU:

.. code-block:: none

    $ echo [2,2,3] [4,5,6] | ./dotprod-opencl -t /dev/stderr > /dev/null
    103

Over 100 microseconds!  Most GPUs have fairly high launch invocation
latencies, and so are not suited for small problems. We can use the
``futhark-dataset(1)`` tool to generate random test data of a desired
size:

.. code-block:: none

    $ futhark-dataset -g [10000000]i32 -g [10000000]i32 > input

Two ten million element vectors should be enough work to amortise the
GPU startup cost:

.. code-block:: none

    $ cat input | ./dotprod-opencl -t /dev/stderr > /dev/null
    347
    $ cat input | ./dotprod-c -t /dev/stderr > /dev/null
    3801

That’s more like it - parallel execution is now more than ten times
faster than sequential execution. This program is entirely
memory-bound - on a compute-bound program we can expect much larger
speedups.

You may have notice that these programs take *significantly* longer to
run than indicated by these performance measurements.  While GPU
initialisation does take some time, most of the actual run-time in the
example above is spent reading the data file from disk.  By default,
``futhark-dataset`` produces output in a data format that is
human-readable, but very slow for programs to process.  We can use the
``-b`` option to make ``futhark-dataset`` to generate data in an
efficient binary format (which takes up less space on disk as well):

.. code-block:: none

    $ futhark-dataset -b -g [10000000]i32 -g [10000000]i32 > input

Reading binary data files is often orders of magnitude faster than
reading textual input files.  Compiled Futhark programs also support
binary output via a ``-b`` option.  The ``futhark-dataset`` tool can
perform conversion between the binary and human-readable formats - see
the manual page for more information.

Multiple Measurements
---------------------

The technique presented in the previous section still has some
problems.  In particular, it is impractical if you want several
measurements on the same dataset, which you generally do even out
noise. While you can just repeat the above line the desired number of
times, this has two problems:

1. The input file will be read multiple times, which can be slow for
   large data sets.

2. It prevents the device from "warming up", as every run re-initialises
   the GPU and re-uploads code.

The second point is more important than it may seem.  Certain OpenCL
operations (such as memory allocation) are relatively costly, and
Futhark uses various caches and buffers to minimise the number of
expensive OpenCL operations.  However, these caches will all be cold
the first time the program runs.  Hence we wish to perform more than
one run per program instance, so we can take advantage of the warm
caches.  This is also a more plausible proxy for real-world usage of
Futhark, as Futhark is typically compiled to a library, where the same
functions are called repeatedly by some client code.

Compiled Futhark executables support an ``-r N`` option that asks the
program to perform ``N`` runs internally, and report runtime for each.
Additionally, a non-measured warmup run is performed initially. We can
use it like this:

.. code-block:: none

    $ cat input | ./dotprod-opencl -t /dev/stderr -r 10 > /dev/null
    285
    330
    281
    284
    285
    278
    285
    330
    284
    282

Our runtimes are now much better. And importantly—there are more of
them, so we can perform analyses like determine the variance, to
figure out how predictable the performance is.

However, we can do better still.  Futhark comes with a tool for
performing automated benchmark runs of programs, called
``futhark-bench``.  This tool relies on a specially formatted header
comment that contains input/output pairs.  The `Futhark User's Guide`_
contains a full description, but here is a quick taste. First, we
introduce a new program, ``sumsquares.fut``, with smaller data sets
for convenience:

.. _`Futhark User's Guide`: https://futhark.readthedocs.org

.. literalinclude:: src/sumsquares.fut

The line containing ``==`` is used to separate the human-readable
benchmark description from input-output pairs.  It is also possible to
keep the data set is located in an external file (see the `manual page
<http://futhark.readthedocs.io/en/latest/man/futhark-bench.html>`_ for
more information.).

 We can use ``futhark-bench`` to measure the performance of
 ``sumsquares.fut`` as such:

.. code-block:: none

    $ futhark-bench sumsquares.fut
    Compiling src/sumsquares.fut...
    Results for src/sumsquares.fut:
    dataset #0 ("1000i32"):             0.20us (avg. of 10 runs; RSD: 2.00)
    dataset #1 ("1000000i32"):        290.00us (avg. of 10 runs; RSD: 0.03)
    dataset #2 ("1000000000i32"):  270154.20us (avg. of 10 runs; RSD: 0.01)

These are measurements using the default compiler, which is
``futhark-c``. If we want to see how our program performs when compiled
with ``futhark-opencl``, we can invoke ``futhark-bench`` as such:

.. code-block:: none

    $ futhark-bench --compiler=futhark-opencl sumsquares.fut
    Compiling src/sumsquares.fut...
    Results for src/sumsquares.fut:
    dataset #0 ("1000i32"):            49.70us (avg. of 10 runs; RSD: 0.18)
    dataset #1 ("1000000i32"):         44.40us (avg. of 10 runs; RSD: 0.02)
    dataset #2 ("1000000000i32"):    1693.80us (avg. of 10 runs; RSD: 0.04)

We can now compare the performance of CPU execution with GPU
execution.  The tool takes care of the mechanics of run-time
measurements, and even computes the relative standard deviation
("RSD") of the measurements for us. The correctness of the output is
also automatically checked. By default, ``futhark-bench`` performs ten
runs for every data set, but this can be changed with the ``--runs``
command line option.
