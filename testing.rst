.. _testing:

Testing and Debugging
=====================

This chapter discusses techniques for checking the correctness of
Futhark programs via unit tests, as well as the debugging facilities
provided by ``futharki``.

The testing experience for Futhark is still rather raw.  There are no
advanced unit testing frameworks, no test generators or doc-testing,
and certainly no property-based testing.  Instead, we have
``futhark-test``, which tests entry point functions against
input/output example pairs.  However, it is better than nothing, and
quite simple to use.  ``futhark-test`` will test the program with both
a compiler (``futhark-c`` by default, but this can be changed with
``--compiler``) and ``futharki``.

Testing with ``futhark-test``
-----------------------------

A Futhark program may contain a *test block*, which is a sequence of
line comments in which one of the lines contains the divider ``--
==``.  The lines preceding the divider are ignored, while the lines
after are taken as a description of a test to perform.  When
``futhark-test`` is passed one or more ``.fut`` files, it will look
for test blocks and perform the tests they describe.

As an example, let us consider how to test a funtion for matrix
multiplication.  The function itself is defined as thus:

.. literalinclude:: src/matmul.fut
   :lines: 15-18

Note that we use ``entry`` instead of ``let`` in order for the
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
case, we just assert that the correct line number is provided.

Type inference on the input/output values is not performed, so the
types must be unambiguous.  This means that the usual ``[]`` notation
for an empty array will not work.  Instead, a special ``empty(t)``
notation is used to represent an array of *row type* ``t``.  For
example, we can test for empty arrays as such:

.. literalinclude:: src/matmul.fut
   :lines: 10-11

Note also that since plain integer literals are assumed to be of type
``i32``, and plain decimal literals to be of type ``f64``, you will
need to use type suffixes (:ref:`baselang`) to write values of other
types.

As a convenience, ``futhark-test`` considers functions returning
*n*-tuples to really be functions returning *n* values.  This means we
can put multiple values in an ``output`` stanza, just as we do with
``input``.

Finally, it is also possible to specify test data stored in a separate
file.  This is useful when testing with very large datasets, in
particular when they use the `binary data format
<https://futhark.readthedocs.io/en/latest/binary-data-format.html>`_.
This is done with the notation ``@ file``:

.. literalinclude:: src/matmul.fut
   :lines: 12-13

This also shows another feature of ``futhark-test``: if we precede
``input`` with the word ``compiled``, that test is not run with
``futharki``.  This is useful for large tests that would take too long
to run interpreted.  There are more ways to filter which tests and
programs should be skipped for a given invocation of ``futhark-test``;
see the `manual
<https://futhark.readthedocs.io/en/latest/man/futhark-test.html>`_ for
more information.

Testing a Futhark Library
~~~~~~~~~~~~~~~~~~~~~~~~~

A Futhark library typically comprises a number of ``.fut`` files means
to be ``include``-ed by Futhark programs.  Libraries typically do not
define entry points of the form required by ``futhark-test``.  Indeed,
it is not unusual for Futhark libraries to consist entirely of
parametric modules and higher-order functions!  These are not directly
accessible to ``futhark-test``.

The recommended solution is that, for every library file ``foo.fut``,
we define a corresponding ``foo_tests.fut`` that imports ``foo.fut``
and defines a number of entry points.

For example, suppose we have ``sum.fut`` that contains the ``sum``
module from :ref:`parametric-modules`:

.. literalinclude:: src/sum.fut

This cannot be tested directly with ``futhark-test``, but we can
define a ``sum_tests.fut`` that can:

.. literalinclude:: src/sum_tests.fut

You will have to use your own judgment when deciding which specific
instantiations of a generic library you feel are worth testing.

Traces and Breakpoints
----------------------

Testing is useful for determining the correctness of code, but does
not in itself pinpoint the source of bugs.  While you can go far
simply by structuring your code as small functions that can be tested
in isolation, it is sometimes necessary to inspect internal state and
behaviour.

Compiled Futhark code does not possess much in the way of debugging
facilities, but ``futharki`` has a couple of useful tools.  Since
``futharki`` is very slow when compared to compiled code, this does
mean that we can only debug on cut-down smaller testing sets, not on
realistic workloads.

Specifically, we use the two functions ``trace`` and ``break``.  The
``trace`` function has the following type::

  trace 't : t -> t

Semantically, ``trace`` just returns its argument unchanged, and when
compiling your Futhark code, this is indeed all that will happen.
However, ``futharki`` treats ``trace`` specially, and will print the
argument to the screen.  This is useful for seeing the value of
internal variables.  For example, suppose we have the program
``trace.fut``:

.. literalinclude:: src/trace.fut

We can then run it with ``futharki`` to get the following output:

.. code-block:: none

   $ echo [1,2,3] | futharki trace.fut
   Trace at trace.fut:1:24-1:49: 1i32
   Trace at trace.fut:1:24-1:49: 2i32
   Trace at trace.fut:1:24-1:49: 3i32
   [3i32, 4i32, 5i32]

Similarly, the ``break`` function is semantically also the identity function::

  break 't : t -> t

When ``futharki`` encounters ``break``, it suspends execution and lets
us inspect the variables in scope.  At the moment, this works *only*
when running an expression within the ``futharki`` REPL, *not* when
running directly from the command line.  Suppose ``break.fut`` is:

.. literalinclude:: src/trace.fut

Then we can load and run it from ``futharki``:

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

Whenever we are stopped at a breakpoint, we can enter arbitrary
Futhark expressions to inspect the state of the environment.  This is
useful when operating on complex values.
