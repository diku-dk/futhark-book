.. _practicals:

Practical Matters
=================

The previous chapter introduced the Futhark language, the notion of
parallel programming, and the most fundamental builtin functions.
However, more knowledge is needed to write real high-quality Futhark
programs.  This chapter discusses various practicalities around
Futhark programming: how to test and debug your code (:numref:`testing`),
how to benchmark it once it works (:numref:`benchmarking`), how to use
the Futhark package manager to access library code
(:numref:`package-management`), and finally how to work around
compiler limitations.

.. _testing:

Testing and Debugging
---------------------

This section discusses techniques for checking the correctness of
Futhark programs via unit tests, as well as the debugging facilities
provided by ``futhark repl``.

The testing experience for Futhark is still rather raw.  There are no
advanced unit testing frameworks, no test generators or doc-testing,
and certainly no property-based testing.  Instead, we have ``futhark
test``, which tests entry point functions against input/output example
pairs.  However, it is better than nothing, and quite simple to use.
``futhark test`` will test the program with both the interpreter and a
compiler backend (``futhark c`` by default, but this can be changed
with ``--backend``).

.. _futhark-test:

Testing with ``futhark test``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

A Futhark program may contain a *test block*, which is a sequence of
line comments in which one of the lines contains the divider ``--
==``.  The lines preceding the divider are ignored, while the lines
after are taken as a description of a test to perform.  When
``futhark test`` is passed one or more ``.fut`` files, it will look
for test blocks and perform the tests they describe.

As an example, let us consider how to test a function for matrix
multiplication.  Suppose that we have the following defined in a file
``matmul.fut``:

.. literalinclude:: src/matmul.fut
   :lines: 17-20

Note that we use ``entry`` instead of ``def`` in order for the
function to be callable from the outside.

We then add a test block:

.. literalinclude:: src/matmul.fut
   :lines: 1-3

The first line is a human-readable description, the second is the
divider, and the third specifies the entry point that we wish to test.
If the entry point is ``main``, this part can be elided.

We now come to the input/output sets, which are written as follows:

.. literalinclude:: src/matmul.fut
   :lines: 4-8

The values are enclosed in curly braces, and multiple
whitespace-separated values can be given.  Only a limited subset of
the Futhark value syntax is supported: Primitive values and
multidimensional arrays of primitive values.  In particular, no
records or tuples are permitted.  This subset is exactly that which is
supported by compiled Futhark executables.  If you have a need for
testing functions that take more sophisticated input types, you will
need to encode them using primitive types, and then construct them in
the test function itself.

It is also possible to write *negative* tests, where we assert that
the program must fail for a given input.  In our case, when the
shape of the matrices don't match up:

.. literalinclude:: src/matmul.fut
   :lines: 8-9

We provide a regular expression matching the expected error.  In this
case, we just assert that the error mentions the file name.

Type inference on the input/output values is not performed, so the
types must be unambiguous.  This means that the usual ``[]`` notation
for an empty array will not work.  Instead, a special ``empty(t)``
notation is used to represent an array of type ``t``.  For example, we
can test for empty arrays as such:

.. literalinclude:: src/matmul.fut
   :lines: 10-11

Note also that since plain integer literals are assumed to be of type
``i32``, and plain decimal literals to be of type ``f64``, you will
need to use type suffixes (:numref:`baselang`) to write values of other
types.

As a convenience, ``futhark test`` considers functions returning
*n*-tuples to really be functions returning *n* values.  This means we
can put multiple values in an ``output`` stanza, just as we do with
``input``.

External Data Files
...................

It is also possible to specify input- and output-data stored in a
separate file.  This is useful when testing with very large datasets,
in particular when they use the `binary data format
<https://futhark.readthedocs.io/en/latest/binary-data-format.html>`_,
which can be generated with the ``futhark dataset`` tool.  This is
done with the notation ``@ file``:

.. literalinclude:: src/matmul.fut
   :lines: 12-13

This also shows another feature of ``futhark test``: if we precede
``input`` with the word ``compiled``, that test is not run with the
interpreter. This is useful for large tests that would take too long
to run interpreted. By default ``futhark test`` does not use the
interpreter unless the ``-i`` option is passed. There are more ways to
filter which tests and programs should be skipped for a given
invocation of ``futhark test``; see the `manual
<https://futhark.readthedocs.io/en/latest/man/futhark-test.html>`_ for
more information.


Automatically Generated Input
.............................

In many cases we are not particularly interested in the specific
values of the workload we are benchmarking, merely its size.  Consider
again the dot product: what matters is the size of the vectors, not
their contents.  This is done with the stanza ``random input``:

.. literalinclude:: src/matmul.fut
   :lines: 14

We again use ``compiled`` to indicate that this data set should not be
used when testing with the interpreter.  However, instead of
containing literal values, as with plain ``input``, the braces enclose
types.  When ``futhark test`` is given this program, it will first
automatically generate data files containing values of the indicated
types and shapes.  This is only done once, after which the generated
files are kept in a ``data/`` directory relative to the ``.fut`` file.
This directory can be freely deleted and will be repopulated as
needed.

As the data file is randomly generated, we cannot in advance know what
its expected output might be.  We can use the ``auto output`` stanza
to ask ``futhark test`` to automatically construct an expected output
file before running the program:

.. literalinclude:: src/matmul.fut
   :lines: 14-15

The expected output is constructed by running the program compiled
with ``futhark c``, and so is mainly useful for detecting differences
between ``futhark c`` and one of the parallel backends, like for
example ``futhark opencl``.  Such differences can be due to compiler
bugs, programmer mistakes (like passing a non-associative function to
``reduce``), or merely floating-point jitter.

Testing a Futhark Library
.........................

A Futhark library typically comprises a number of ``.fut`` files means
to be ``include``-ed by Futhark programs.  Libraries typically do not
define entry points of the form required by ``futhark test``.  Indeed,
it is not unusual for Futhark libraries to consist entirely of
parametric modules and higher-order functions!  These are not directly
accessible to ``futhark test``.

The recommended solution is that, for every library file ``foo.fut``,
we define a corresponding ``foo_tests.fut`` that imports ``foo.fut``
and defines a number of entry points.

For example, suppose we have ``sum.fut`` that contains the ``sum``
module from :numref:`parametric-modules`:

.. literalinclude:: src/sum.fut

This cannot be tested directly with ``futhark test``, but we can
define a ``sum_tests.fut`` that can:

.. literalinclude:: src/sum_tests.fut

You will have to use your own judgment when deciding which specific
instantiations of a generic library you feel are worth testing.

Traces and Breakpoints
~~~~~~~~~~~~~~~~~~~~~~

Testing is useful for determining the correctness of code, but does
not in itself pinpoint the source of bugs.  While you can go far
simply by structuring your code as small functions that can be tested
in isolation, it is sometimes necessary to inspect internal state and
behaviour.

Compiled Futhark code does not possess much in the way of debugging
facilities, but the interpreter (accessed via ``futhark repl`` and
``futhark run``) has a couple of useful tools.  Since interpretation
is very slow compared to compiled code, this does mean that we can
only debug with cut-down smaller testing sets, not with realistic
workloads.

An *attribute* is a mechanism for adding additional information to a
Futhark program. Attributes are intended not to affect the semantics
of the program, meaning the value that results of evaluation, but can
influence the compiler or interpreter in various other ways. For
debugging, we can use the two attributes ``#[trace]`` and
``#[break]``. We can attach these attributes to an expression by
writing ``#[trace]`` or ``#[break]`` before any expression. After the
expression is evaluated, its value will be printed to the console. For
example, suppose we have the program ``trace.fut``:

.. literalinclude:: src/trace.fut

We can then run it with ``futhark run`` to get the following output:

.. code-block:: none

   $ echo [1,2,3] | futhark run trace.fut
   Trace at trace.fut:1:24-1:49: 1i32
   Trace at trace.fut:1:24-1:49: 2i32
   Trace at trace.fut:1:24-1:49: 3i32
   [3i32, 4i32, 5i32]

When using the interpreter, the value is a faithful representation of
the underlying Futhark value. When using the compiler, the value
printed will be based on the optimised run-time representation, which
may be somewhat obscure. In some cases, such as when using a GPU
backend, some traces may even be ignored, if they happen to occur in
code that runs on the GPU. It is generally best to use the interpreter
when tracing.

The ``#[break]`` attribute is attached to an expression in a similar
manner. When the interpreter encounters ``break``, it suspends
execution and lets us inspect the variables in scope. At the moment,
this works *only* when running an expression within ``futhark repl``,
*not* when using ``futhark run``. Suppose ``break.fut`` is:

.. literalinclude:: src/break.fut

Then we can load and run it from ``futhark repl``:

.. code-block:: none

   [1]> main [1,2,3]
   Breaking at [1]> :1:1-1:12 -> break.fut:1:24-1:49 -> /futlib/soacs.fut:35:3-35:24 -> break.fut:1:35-1:41.
   <Enter> to continue.
   > x
   1i32
   >
   Continuing...
   Breaking at [1]> :1:1-1:12 -> break.fut:1:24-1:49 -> /futlib/soacs.fut:35:3-35:24 -> break.fut:1:35-1:41.
   <Enter> to continue.
   >
   Continuing...
   Breaking at [1]> :1:1-1:12 -> break.fut:1:24-1:49 -> /futlib/soacs.fut:35:3-35:24 -> break.fut:1:35-1:41.
   <Enter> to continue.
   >
   Continuing...
   [3i32, 4i32, 5i32]
   >

Whenever we are stopped at a break point, we can enter arbitrary
Futhark expressions to inspect the state of the environment.  This is
useful when operating on complex values.

The prelude also defines functions ``trace`` and ``break`` that are
semantically the identity function, but attach respectively the
``#[trace]`` and ``#[break]`` attributes to their result. Sometimes
using these functions is more syntactically convenient than using
attributes.

.. _benchmarking:

Benchmarking
------------

Consider an implementation of the dot product of two integer vectors:

.. literalinclude:: src/dotprod.fut
   :lines: 5-

We previously mentioned that, for small data sets, sequential
execution is likely to be much faster than parallel execution. But how
much faster? To answer this question, we need to measure the run time
of the program on some data sets. This task is called *benchmarking*. There
are many properties one can benchmark: memory usage, size of compiled
executable, robustness to errors, and so forth. In this section, we
are only concerned with run time. Specifically, we wish to measure
*wall time*, which is how much time elapses in the real world from the
time the computation starts, to the time it ends.

There is still some wiggle room in how we benchmark. For example,
should we measure the time it takes to load the input data from disk?
Or time it takes to initialise various devices and drivers? Should we
perform a clean shutdown? How many times should we run the program,
and should we report maximum, minimum, or average run time? We will
not try to answer all of these questions, but instead merely describe
the benchmarking tools provided by Futhark.

Simple Measurements
~~~~~~~~~~~~~~~~~~~

First, let us compile ``dotprod.fut`` to two different executables, one
for each compiler:

.. code-block:: none

    $ futhark c dotprod.fut -o dotprod-c
    $ futhark opencl dotprod.fut -o dotprod-opencl

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
comparison is not useful, as it also measures time taken to read the
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
latencies, and so are not suited for small problems. We can use
``futhark dataset`` tool to generate random test data of a desired
size:

.. code-block:: none

    $ futhark dataset -g [10000000]i32 -g [10000000]i32 > input

Two ten million element vectors should be enough work to amortise the
GPU startup cost:

.. code-block:: none

    $ cat input | ./dotprod-opencl -t /dev/stderr > /dev/null
    347
    $ cat input | ./dotprod-c -t /dev/stderr > /dev/null
    3801

That’s more like it! Parallel execution is now more than ten times
faster than sequential execution. This program is entirely
memory-bound; on a compute-bound program we can expect much larger
speedups.

You may have noticed that these programs take *significantly* longer to
run than indicated by these performance measurements.  While GPU
initialisation does take some time, most of the actual run-time in the
example above is spent reading the data file from disk.  By default,
``futhark dataset`` produces output in a data format that is
human-readable, but very slow for programs to process.  We can use the
``-b`` option to make ``futhark dataset`` generate data in an
efficient binary format (which takes up less space on disk as well):

.. code-block:: none

    $ futhark dataset -b -g [10000000]i32 -g [10000000]i32 > input

Reading binary data files is often orders of magnitude faster than
reading textual input files.  Compiled Futhark programs also support
binary output via a ``-b`` option.  The ``futhark dataset`` tool can
perform conversion between the binary and human-readable formats; see
the manual page for more information.

Multiple Measurements
~~~~~~~~~~~~~~~~~~~~~

The technique presented in the previous section still has some
problems.  In particular, it is impractical if you want several
measurements on the same dataset, which is in general preferable to
even out noise. While you can just repeat execution the desired number
of times, this method has two problems:

1. The input file will be read multiple times, which can be slow for
   large data sets.

2. It prevents the device from "warming up", as every run re-initialises
   the GPU and re-uploads code.

The second point is more important than it may seem.  Certain OpenCL
operations (such as memory allocation) are relatively costly, and
Futhark uses various caches and buffers to minimise the number of
expensive OpenCL operations.  However, these caches will all be cold
the first time the program runs.  Hence we wish to perform more than
one run per program instance, so that we can take advantage of the warm
caches.  This method is also a more plausible proxy for real-world usage of
Futhark, as Futhark is typically compiled to a library, where the same
functions are called repeatedly by some client code.

Compiled Futhark executables support an ``-r N`` option that asks the
program to perform ``N`` runs internally, and report runtime for each.
Additionally, a non-measured warm-up run is performed initially. We can
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

Our runtimes are now much better. And importantly, there are more of
them, so we can perform analyses such as determining the variance, to
figure out how predictable the runtime is.

Using `futhark bench`
~~~~~~~~~~~~~~~~~~~~~

However, we can do better still.  Futhark comes with a tool for
performing automated benchmark runs of programs, called ``futhark
bench``.  This tool relies on a specially formatted header comment
that contains input/output pairs, exactly like ``futhark test`` (see
:numref:`futhark-test`).  The `Futhark User's Guide`_ contains a full
description, but here is a simple example. First, we introduce a new
program, ``sumsquares.fut``, with smaller data sets for convenience:

.. _`Futhark User's Guide`: https://futhark.readthedocs.org

.. literalinclude:: src/sumsquares.fut

The line containing ``==`` is used to separate the human-readable
benchmark description from input-output pairs.  It is also possible to
keep the data set in an external file, or to generate it
automatically.  See the `manual page
<http://futhark.readthedocs.io/en/latest/man/futhark-bench.html>`_ for
more information.

 We can use ``futhark bench`` to measure the performance of
 ``sumsquares.fut`` as follows:

.. code-block:: none

    $ futhark bench sumsquares.fut
    Compiling src/sumsquares.fut...
    Results for src/sumsquares.fut:
    dataset #0 ("1000i32"):             0.20us (avg. of 10 runs; RSD: 2.00)
    dataset #1 ("1000000i32"):        290.00us (avg. of 10 runs; RSD: 0.03)
    dataset #2 ("1000000000i32"):  270154.20us (avg. of 10 runs; RSD: 0.01)

These are measurements using the default compiler, which is
``futhark c``. If we want to see how our program performs when compiled
with ``futhark opencl``, we can invoke ``futhark bench``:

.. code-block:: none

    $ futhark bench --backend=opencl sumsquares.fut
    Compiling src/sumsquares.fut...
    Results for src/sumsquares.fut:
    dataset #0 ("1000i32"):            49.70us (avg. of 10 runs; RSD: 0.18)
    dataset #1 ("1000000i32"):         44.40us (avg. of 10 runs; RSD: 0.02)
    dataset #2 ("1000000000i32"):    1693.80us (avg. of 10 runs; RSD: 0.04)

We can now compare the performance of CPU execution with GPU
execution.  The tool takes care of the mechanics of run-time
measurements, and even computes the relative standard deviation
("RSD") of the measurements for us. The correctness of the output is
also automatically checked. By default, ``futhark bench`` performs ten
runs for every data set, but this number can be changed with the
``--runs`` command line option.  Unless you can articulate a good
reason not to, always use ``futhark bench`` for benchmarking.

.. _package-management:

Package Management
------------------

A Futhark package is a downloadable collection of ``.fut`` files and
little more.  There is a (not necessarily comprehensive) `list of
known packages <https://futhark-lang.org/pkgs>`_.  The following
discusses only how to *use* packages.  For authoring your own, please
see the `corresponding section in the User's Guide
<https://futhark.readthedocs.io/en/latest/package-management.html#creating-packages>`_.

Basic Concepts
~~~~~~~~~~~~~~

A package is uniquely identified with a *package path*, which is
similar to a URL, except without a protocol.  At the moment, package
paths are always links to Git repositories hosted on GitHub or GitLab.
As an example, a package path may be ``github.com/athas/fut-foo``.

Packages are versioned with `semantic version numbers
<https://semver.org/>`_ of the form ``X.Y.Z``.  Whenever versions are
indicated, all three digits must always be given (that is, ``1.0`` is
not a valid shorthand for ``1.0.0``).

Most ``futhark pkg`` operations involve reading and writing a *package
manifest*, which is always stored in a file called ``futhark.pkg``.
The ``futhark.pkg`` file is human-editable, but is in day-to-day use
mainly modified by ``futhark pkg`` automatically.  You will normally
have one ``futhark.pkg`` file for each of your Futhark projects.
Packages are installed in a location relative to the location of
``futhark.pkg``.

Installing Packages
~~~~~~~~~~~~~~~~~~~

Required packages can be added by using ``futhark pkg add``, for example::

  $ futhark pkg add github.com/athas/fut-foo 0.1.0

This will create a new file ``futhark.pkg`` with the following contents:

.. code-block:: text

   require {
     github.com/athas/fut-foo 0.1.0 #d285563c25c5152b1ae80fc64de64ff2775fa733
   }

This lists one required package, with its package path, minimum
version, and the expected commit hash.  The latter is used for
verification, to ensure that the contents of a package version cannot
silently change.

``futhark pkg`` will perform network requests to determine whether a
package of the given name and with the given version exists and fail
otherwise (but it will not check whether the package is otherwise
well-formed).  The version number can be elided, in which case
``futhark pkg`` will use the newest available version.  If the package
is already present in ``futhark.pkg``, it will simply have its version
requirement changed to the one specified in the command.  Any
dependencies of the package will *not* be added to ``futhark.pkg``,
but will still be downloaded by ``futhark pkg sync`` (see below).

Adding a package with ``futhark pkg add`` modifies ``futhark.pkg``,
but does not download the package files.  This is done with
``futhark pkg sync`` (without further options).  The contents of each
required dependency and any transitive dependencies will be stored in
a subdirectory of ``lib/`` corresponding to their package path.
Following the earlier example::

  $ futhark pkg sync
  $ tree lib
  lib
  └── github.com
      └── athas
          └── fut-foo
              └── foo.fut

  3 directories, 1 file

**Warning:** ``futhark sync`` will remove any unrecognized files or
local modifications to files in ``lib/``.  Unless you are creating
your own package, you should not add anything to the ``lib/``
directory - it is fully controlled by ``futhark pkg``.

Packages can be removed from ``futhark.pkg`` with::

  $ futhark pkg remove pkgpath

You will need to run ``futhark sync`` to actually remove the files in
``lib/``.

The intended usage is that ``futhark.pkg`` is added to version
control, but ``lib/`` is not, as the contents of ``lib/`` can always
be reproduced from ``futhark.pkg``.  However, adding ``lib/`` works
just fine as well.

Importing Files from Dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``futhark pkg sync`` will populate the ``lib/`` directory, but does
not interact with the compiler in any way.  The downloaded files can
be imported using the ``import`` mechanism (see
:numref:`other-files`). For example, assuming the package contains a file
``foo.fut``, the following top-level declaration brings all names
declared in the file into scope::

  import "lib/github.com/athas/fut-foo/foo"

Ultimately, everything boils down to ordinary file system semantics.
This has the downside of relatively long and clumsy import paths, but
the upside of predictability.

Upgrading Dependencies
~~~~~~~~~~~~~~~~~~~~~~

The ``futhark pkg upgrade`` command will update every version
requirement in ``futhark.pkg`` to be the most recent available
version.  You still need to run ``futhark pkg sync`` to actually
retrieve the new versions.  Be careful - while upgrades are safe if
semantic versioning is followed correctly, this is not yet properly
machine-checked, so human mistakes may occur.

As an example:

.. code-block:: text

   $ cat futhark.pkg
   require {
     github.com/athas/fut-foo 0.1.0 #d285563c25c5152b1ae80fc64de64ff2775fa733
   }
   $ futhark pkg upgrade
   Upgraded github.com/athas/fut-foo 0.1.0 => 0.2.1.
   $ cat futhark.pkg
   require {
     github.com/athas/fut-foo 0.2.1 #3ddc9fc93c1d8ce560a3961e55547e5c78bd0f3e
   }
   $ futhark pkg sync
   $ tree lib
   lib
   └── github.com
       └── athas
           ├── fut-bar
           │   └── bar.fut
           └── fut-foo
               └── foo.fut

   4 directories, 2 files

Note that ``fut-foo 0.2.1`` depends on ``github.com/athas/fut-bar``,
so it was fetched by ``futhark pkg sync``.

``futhark pkg upgrade`` will *never* upgrade across a major version
number.  Due to the principle of `Semantic Import Versioning
<https://research.swtch.com/vgo-import>`_, a new major version is a
completely different package from the point of view of the package
manager.  Thus, to upgrade to a new major version, you will need to
use ``futhark pkg add`` to add the new version and ``futhark pkg
remove`` to remove the old version.  Or you can keep it around - it is
perfectly acceptable to depend on multiple major versions of the same
package, because they are really different packages.

.. _when-things-go-wrong:

When Things Go Wrong
--------------------

Futhark is a young language and an *on-going research project*, and
you should not expect the same predictability and quality of error
messages that you may be used to from more mature languages.  Further,
not all Futhark compilers are guaranteed to be able to compile all
Futhark programs.  In general, the limitations you will encounter will
tend to fall in two categories:

Essential
    limitations touch upon fundamental restrictions in the target
    platform(s) for the Futhark compiler. For example, GPUs do not
    permit dynamic memory allocation inside GPU code. All memory must be
    pre-allocated before GPU programs are launched. This means that the
    Futhark compiler must be able to pre-compute the size of all
    intermediate arrays (symbolically), or compilation will fail.

Implementation
    limitations are weaknesses in the Futhark compiler that could
    reasonably be solved. Many implementation limitations, such as the
    inability to pre-compute some array sizes, or eliminate bounds
    checks inside parallel sections, will manifest themselves as
    essential limitations that could be worked around by a smarter
    compiler.

For example, consider this program:

::

    def main (n: i32): [][]i32 =
      map (\i ->
             let a = (0..<i)
             let b = (0..<n-i)
             in concat a b)
          (0..<n)

At the time of this writing, ``futhark opencl`` will fail with the not
particularly illuminating error message ``Cannot allocate memory in
kernel``. The reason is that the compiler is trying to compile the
``map`` to parallel code, which involves pre-allocating memory for the
``a`` and ``b`` array. It is unable to do this, as the sizes of these
two arrays depend on values that are only known *inside* the map,
which is too late. There are various techniques the Futhark compiler
could use to estimate how much memory would be needed, but these have
not yet been implemented.

It is usually possible, sometimes with some pain, to come up with a
workaround. We could rewrite the program as:

::

    def main(n: i32): [][]i32 =
      let scratch = (0..<n)
      in map (\i ->
                let res = (0..<n)
                let res[i:n] = scratch[0:n-i]
                in res)
             (0..<n)

This exploits the fact that the compiler does not generate allocations
for array slices or in-place updates. The only allocation is of the
initial ``scratch``, the size of which can be computed before entering
the ``map``.
