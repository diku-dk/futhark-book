.. _regular-flattening:

Regular Flattening
==================

In this chapter, we introduce the concept of regular *moderate
flattening* :cite:`Henriksen:2017:FPF:3062341.3062354`, which is the
essential technique used for making regular nested parallel Futhark
programs run efficiently in practice on parallel hardware such as
GPUs.

We first introduce a number of parallel segmented operations, which
are essential for dealing with nested parallelism. The segmented
operations, it turns out, can be implemented using Futhark's standard
SOAC parallel array combinators. In particular, it turns out that the
``scan`` operator is of critical importance in that it can be used to
develop the notion of a *segmented scan* operation, an operation that,
in its own right, is essential to many parallel algorithms. Based on
the segmented scan operation and the other Futhark SOAC operations, we
present a set of utility functions as well as their parallel
implementations.  The functions are used by the moderate flattening
transformation presented in :numref:`moderate-flattening`, but are also
useful, as we shall see in :numref:`irregular-flattening`, for the
programmer to manage irregular parallelism through flattening
transformations, performed manually by the programmer.

.. _sgmscan:

Segmented Scan
--------------

As mentioned, the segmented scan operation is quite essential for
Futhark to flatten nested regular parallelism and for the programmer
to flatten irregular nested parallel problems. The operation
can be implemented with a simple scan using an associative function
that operates on pairs of values
:cite:`Schwartz:1980:ULT:357114.357116,blelloch1990vector`.  Here is
the definition of the segmented scan operation, hardcoded to work with
addition:

.. literalinclude:: src/sgm_streak.fut
   :lines: 1-8

Note that we have to include the extra boolean in the accumulator to satisfy the
type signature of ``scan``.

We can make use of Futhark's support for higher-order functions and
polymorphism to define a generic version of segmented scan that will
work for other monoidal structures than addition on ``i32`` values:

.. literalinclude:: src/segmented.fut
   :lines: 7-13

We leave it up to the reader to prove that, given an associative
function ``g``, (1) the operator passed to ``scan`` is associative
and (2) ``(ne, false)`` is a neutral element for the operator.

.. _finding-the-longest-streak-segmented-scan:

Finding the Longest Streak Using Segmented Scan
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In this section we revisit the problem of
:numref:`finding-the-longest-streak` for finding the longest streak of
increasing numbers. We show how we can make direct use of a segmented
scan operation for solving the problem:

.. literalinclude:: src/sgm_streak.fut
   :lines: 27-34

The algorithm first constructs the ``is`` array, as in the previous
algorithm, and then uses a segmented scan over a negation of this array
over the unit-array to create the ``ss3`` vector directly.  Here is a
derivation of how the segmented-scan based algorithm works:

+----------+---+---+---+---+---+---+---+---+---+
| Variable |   |   |   |   |   |   |   |   |   |
+==========+===+===+===+===+===+===+===+===+===+
| ``xs``   | = | 1 | 5 | 3 | 4 | 2 | 6 | 7 | 8 |
+----------+---+---+---+---+---+---+---+---+---+
| ``ys``   | = | 5 | 3 | 4 | 2 | 6 | 7 | 8 | 1 |
+----------+---+---+---+---+---+---+---+---+---+
| ``is``   | = | 1 | 0 | 1 | 0 | 1 | 1 | 1 |   |
+----------+---+---+---+---+---+---+---+---+---+
| ``fs``   | = | 0 | 1 | 0 | 1 | 0 | 0 | 0 |   |
+----------+---+---+---+---+---+---+---+---+---+
| ``ss``   | = | 1 | 0 | 1 | 0 | 1 | 2 | 3 |   |
+----------+---+---+---+---+---+---+---+---+---+
| ``res``  | = | 3 |   |   |   |   |   |   |   |
+----------+---+---+---+---+---+---+---+---+---+

The morale here is that the segmented scan operation provides us with
a great abstraction.

.. _replicated-iota:

Replicated Iota
---------------

The first utility function that we will present is called
``replicated_iota``. Given an array of natural numbers specifying
repetitions, the function returns an array of weakly increasing
indices (starting from 0) and with each index repeated according to
the repetition array. As an example, ``replicated_iota [2,3,1,1]``
returns the array ``[0,0,1,1,1,2,3]``. The function is defined in
terms of other parallel operations, including ``scan``, ``map``,
``scatter``, and ``segmented_scan``:

.. literalinclude:: src/segmented.fut
   :lines: 44-49

An example evaluation of a call to the function ``replicated_iota`` is
provided below.  Notice that in order to use this Futhark code with
``futhark opencl``, we need to prefix the array indexing in line 3 and
line 4 with the ``unsafe`` keyword.

+--------------------+---+---+---+---+---+---+---+---+
| Args/Result        |   |   |   |   |   |   |   |   |
+====================+===+===+===+===+===+===+===+===+
| ``reps``           | = | 2 | 3 | 1 | 1 |   |   |   |
+--------------------+---+---+---+---+---+---+---+---+
| ``s1``             | = | 2 | 5 | 6 | 7 |   |   |   |
+--------------------+---+---+---+---+---+---+---+---+
| ``s2``             | = | 0 | 2 | 5 | 6 |   |   |   |
+--------------------+---+---+---+---+---+---+---+---+
| ``replicate``      | = | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
+--------------------+---+---+---+---+---+---+---+---+
| ``tmp``            | = | 0 | 0 | 1 | 0 | 0 | 2 | 3 |
+--------------------+---+---+---+---+---+---+---+---+
| ``flags``          | = | 0 | 0 | 1 | 0 | 0 | 1 | 1 |
+--------------------+---+---+---+---+---+---+---+---+
| ``segmented_scan`` | = | 0 | 0 | 1 | 1 | 1 | 2 | 3 |
+--------------------+---+---+---+---+---+---+---+---+

.. _segmented-replicate:

Segmented Replicate
-------------------

Another useful utility function is called
``segmented_replicate``. Given a one-dimensional replication array
containing natural numbers and a data array of the same shape,
``segmented_replicate`` returns an array of size equal to the sum of
the values in the replication array with values from the data array
replicated according to the corresponding replication values. As an
example, a call ``segmented_replicate [2,1,0,3,0] [5,6,9,8,4]`` result
in the array ``[5,5,6,8,8,8]``. Here is the code that implements the
function ``segmented_replicate``:

.. literalinclude:: src/sgm_repl.fut
   :lines: 20-22

The ``segmented_replicate`` function makes use of the previously
defined function ``replicated_iota``.  Notice the use of the
``unsafe`` keyword in the last line; it is necessary because Futhark
cannot prove that the index ``i`` will always be within bounds of the
array ``vs``.

.. _segmented-iota:

Segmented Iota
--------------

Another useful utility function is the function ``segmented_iota``
that, given a array of flags (i.e., booleans), returns an array of
index sequences, each of which is reset according to the booleans in
the array of flags. As an example, the expression::

    segmented_iota [false,false,false,true,false,false,false]

returns the array ``[0,1,2,0,1,2,3]``. The ``segmented_iota`` function
can be implemented with the use of a simple call to ``segmented_scan``
followed by a call to ``map``:

.. literalinclude:: src/segmented.fut
   :lines: 57-59

.. _idxs_to_flags:

Indexes to Flags
----------------

Many segmented operations, such as ``segmented_scan`` takes as
argument an array of boolean flags for specifying when new segments
start. Often, only the sizes of segments are known, which means that
it may come in useful to be able to transform an array of segment
sizes to a corresponding array of boolean flags. Here is one possible
parallel implementation of such an ``idxs_to_flags`` function:

.. literalinclude:: src/idxs_to_flags.fut
   :lines: 25-27

As an example use of the function, the expression ``idxs_to_flags
[2,1,3]`` evaluates to the flag array
``[false,false,true,true,false,false]``. Notice that the
implementation also works in case some segments are of size zero.

.. _moderate-flattening:

Moderate Flattening
-------------------

The flattening rules that we shall introduce here allow the Futhark
compiler to generate parallel kernels for various code block
patterns. In contrast to the general concept of flattening as
introduced by Blelloch :cite:`blelloch1994implementation`, Futhark
applies a technique called *moderate flattening*
:cite:`Henriksen:2017:FPF:3062341.3062354`, which does not cover
arbitrary nested parallelism, but does cover well many regular
nested parallel patterns. We shall come back to the issue of
flattening irregular nested parallelism in
:numref:`irregular-flattening`.

In essence, moderate flattening works by matching compositions of
fused constructs against a number of flattening rules. The aim is to merge (i.e.,
flatten) nested parallel operations into sequences of parallel
operations. Although, such flattening is often possible, in particular
due to an integrated transformation called vectorisation, there are
situations where choices needs to be made. In particular, when a map
is nested on top of a loop, we may choose to parallelise the outer map
and sequentialise the inner loop, which on the GPU will amount to all
threads running sequential loops in parallel. An alternative, when
possible, will be to interchange the outer map and the loop and then
sequentialise the outer loop (on the host) and parallelise the inner
map, which will then be executed multiple times. It turns out that
Futhark can make some guesses about which strategy to pursue based on
possible information about the sizes of the arrays. An extension to
the static concept moderate flattening, Futhark also supports a notion
of flattening that generates multiple versions of flattened code,
guarded by parameters that may be autotuned to achieve good
performance for a range of different data sets
:cite:`ppopp19henriksen`.

In the following we shall focus on the transformations performed by
moderate flattening.

Vectorisation
~~~~~~~~~~~~~

Assuming ``e'`` contains SOACs, transform the expression

::

    map (\x -> let y = e in e') xs

into the expression

::

    let ys = map (\x -> e) xs
    in map (\(x,y) -> e') (zip xs ys)

This transformation does not itself capture any nested parallelism but
may enable other transformations by eliminating the inner
``let``-expression.


Map-Map Nesting
~~~~~~~~~~~~~~~

Nested applications of ``map`` constructs are in essence transformed
into a single ``map`` construct by (1) flattening the argument
array, (2) applying the inner function on the flattened array, and (3)
unflattening the concatenated results. This process can be repeated
for multiple nested ``map`` constructs. It turns out that the
administrative operations can be implemented with zero overhead.

Map-Scan Nesting
~~~~~~~~~~~~~~~~

In case of an expression made up from a ``map`` construct appearing on
top of a ``scan`` operation, the expression is transformed into a
regular segmented scan operation. That is, the expression::

    map (\xs -> scan f ne xs) xss

is transformed into the expression::

    regular_segmented_scan f ne xss

Notice here that we assume the availability of a regular segmented
scan operation of type::

    val regular_segmented_scan 't [n] [m]: (t->t->t) -> t -> [n][m]t -> [n][m]t

Internally, this function will use the inner size of the
multi-dimensional argument array (i.e., ``m``) to construct an
appropriate flag vector suitable for the segmented scan. Again, for an
in-depth discussion of how to implement a segmented scan operation on
top of an ordinary scan operation, please consult
:numref:`sgmscan`.

Map-Reduce Nesting
~~~~~~~~~~~~~~~~~~

In case of a ``map`` construct appearing on top of a ``reduce``
operation, this expression is transformed into a regular segmented
reduction :cite:`Larsen:2017:SRS:3122948.3122952`. That is, the
expression::

    map (\xs -> reduce f ne xs) xss

is transformed into the expression::

    regular_segmented_reduce f ne xss

Notice here that we assume the availability of a regular segmented
reduction operation of type::

    val regular_segmented_reduce 't [n] : (t->t->t) -> t -> [n][]t -> [n]t

Internally, this function can be implemented based on the function
``regular_segmented_scan`` discussed above. Here is a simple definition:::

    let regular_segmented_reduce = map last <-< regular_segmented_scan


Map-Iota Nesting
~~~~~~~~~~~~~~~~

A ``map`` over an ``iota`` expression can be transformed to the
composition of the ``segmented_iota`` function defined in
:numref:`segmented-iota` and a function ``ìdxs_to_flags``, which converts
an array of indices to an array ``fs`` of boolean flags of size equal
to the sum of the values in ``xs`` and with ``true``-values in
indexes specified by the prefix sums of the index values.

As an example, the expression ``idxs_to_flags [2,1,3]`` evaluates to
the flag array ``[false,false,true,true,false,false]``. Notice that
the expression ``idxs_to_flags [2,0,4]`` evaluates to the same boolean
vector as ``idxs_to_flags [2,4]``. We shall not here give a definition
of the ``idxs_to_flags`` function, but refer the reader to
:numref:`idxs_to_flags`.

All in all, an expression of the form::

   map iota xs

is transformed into::

   (segmented_iota <-< idxs_to_flags) xs

Map-Replicate Nesting
~~~~~~~~~~~~~~~~~~~~~

Recall that ``replicate`` has the type::

   val replicate 't : (n:i32) -> t -> [n]t

A ``map`` over a ``replicate`` expression takes the form::

   map (\x -> replicate n x) xs

where ``n`` is invariant to ``x``. Such an expression can be
transformed into the expression::

   segmented_replicate (replicate (length xs) n) xs

As an example, consider the expression ``map (replicate 2)
[8,5,1]``. This expression is transformed into the expression::

   segmented_replicate (replicate 3 2) [8,5,1]

which evaluates to ``[8,8,5,5,1,1]``. Notice that the subexpression
``replicate 3 2`` evaluates to ``[2,2,2]``.
