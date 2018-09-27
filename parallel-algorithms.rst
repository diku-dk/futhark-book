.. _parallel-algorithms:

Parallel Algorithms
===================

In this chapter, we will present a number of parallel algorithms for
solving a number of problems. We will make effective use of the SOAC
parallel array combinators. In particular, it turns out that the
operator is critical for writing parallel algorithms. In fact, we shall
first develop the notion of a *segmented scan* operation, which, as we
shall see, can be implemented using Futhark’s operator, and which in its
own right is essential to many of the later algorithms.

Based on the segmented scan operator and the other Futhark SOAC
operations, but before investigating more challenges algorithms, we also
present a set of utility functions as well as their parallel
implementations.

.. sec:sgmscan:

Segmented Scan
--------------

The segmented scan operator is quite essential as we shall see
demonstrated in many of the algorithms explained later. The operator
can be implemented with a simple scan using an associative function
that operates on pairs of values
:cite:`Schwartz:1980:ULT:357114.357116,blelloch1990vector`.  Here is
the definition of the segmented scan operation, hardcoded to work with
addition:

.. literalinclude:: src/sgm_scan.fut
   :lines: 4-11

We can make use of Futhark's support for higher-order functions and
polymorphism to define a generic version of segmented scan that will
work for other monoidal structures than addition on ``i32`` values:

.. literalinclude:: src/sgm_scan.fut
   :lines: 13-20

We leave it up to the reader to prove that, given an associative
function ``g``, (1) the operator passed to ``scan`` is associative
and (2) ``(ne, false)`` is a neutral element for the operator.


Parallel Utility Functions
--------------------------

For use by other algorithms, a set of utility functions for manipulating
and managing arrays is an important part of the tool box. We present a
number of utility functions here, ranging from finding elements in an
array to finding the maximum element and its index in an array.

Finding the Index of an Element in an Array
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

We device two different functions for finding an index in an array for
which the content is identical to some given value. The first
function, ``find_idx_first``, takes a value ``e`` and an array ``xs``
and returns the smallest index ``i`` into ``xs`` for which ``xs[i] =
e``:

.. literalinclude:: src/find_idx.fut
   :lines: 4-8

The second function, ``find_idx_last``, also takes a value and an
array but returns the largest index ``i`` into ``xs`` for which
``xs[i] = e``:

.. literalinclude:: src/find_idx.fut
   :lines: 10-13

The above two functions make use of the auxiliary functions
``i32.max`` and ``i32.min``.

Finding the Largest Element and its Index in an Array
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Futhark allows for reduction operators to take tuples as arguments. This
feature is exploited in the following function, which implements a
homomorphism for finding the largest element and its index in an array:

.. literalinclude:: src/maxidx.fut
   :lines: 4-11

The function is a *homomorphism* :cite:`BirdListTh`: For any :math:`x`
and :math:`y`, and with :math:`++` denoting array concatenation, there
exists an associative operator :math:`\oplus` such that

.. math::
   \kw{maxidx}(x \pp y) = \kw{maxidx}(x) \oplus \kw{maxidx}(y)

The operator :math:`\oplus = \kw{mx}`. We will leave it up to the
reader to verify that the ``maxidx`` function will operate efficiently
on large inputs.

Radix Sort
----------

A simple radix sort algorithm was presented already in
:ref:`radixsort`. In this section, we present two generalized versions
of radix sort, one for ascending sorting and one for descending
sorting. As a bonus, the sorting routines return both the sorted
array and an index array that can be used to sort an
array with respect to a permutation obtained by sorting another
array. The generalised ascending radix sort is as follows:

.. literalinclude:: src/rsort_idx.fut
   :lines: 14-31

And the descending version as follows:

.. literalinclude:: src/rsort_idx.fut
   :lines: 33-49

Notice that in case of identical elements in the source vector, one
cannot simply implement the ascending version by reversing the arrays
resulting from calling the descending version.

Finding the Longest Streak
--------------------------

In this section we shall demonstrate two different methods of finding
the longest streak of increasing numbers. One method makes use directly
of a segmented scan and the other method implicitly encodes the
segmented scan as an integrated part of the algorithm. We start by
showing the latter version of the longest streak problem:

.. literalinclude:: src/streak.fut
   :lines: 22-35

The following derivation shows how the algorithm works for a
particular input, namely when ``stream`` is given the argument array
``[1,5,3,4,2,6,7,8]``, in which case the algorithm should return the
value 3:

+----------+---+---+---+---+---+---+---+---+---+
| Variable |   |   |   |   |   |   |   |   |   |
+==========+===+===+===+===+===+===+===+===+===+
| ``xs``   | = | 1 | 5 | 3 | 4 | 2 | 6 | 7 | 8 |
+----------+---+---+---+---+---+---+---+---+---+
| ``ys``   | = | 5 | 3 | 4 | 2 | 6 | 7 | 8 | 1 |
+----------+---+---+---+---+---+---+---+---+---+
| ``is``   | = | 1 | 0 | 1 | 0 | 1 | 1 | 1 |   |
+----------+---+---+---+---+---+---+---+---+---+
| ``ss``   | = | 1 | 1 | 2 | 2 | 3 | 4 | 5 |   |
+----------+---+---+---+---+---+---+---+---+---+
| ``ss``   | = | 0 | 1 | 0 | 2 | 0 | 0 | 0 |   |
+----------+---+---+---+---+---+---+---+---+---+
| ``ss2``  | = | 0 | 1 | 1 | 2 | 2 | 2 | 2 |   |
+----------+---+---+---+---+---+---+---+---+---+
| ``ss3``  | = | 1 | 0 | 1 | 0 | 1 | 2 | 3 |   |
+----------+---+---+---+---+---+---+---+---+---+
| ``res``  | = | 3 |   |   |   |   |   |   |   |
+----------+---+---+---+---+---+---+---+---+---+

A simpler algorithm builds directly on the segmented scan operation
defined earlier. The algorithm first constructs the ``is`` array as in
the previous algorithm and then uses a segmented scan over a negation
of this array over the unit-array to create the ``ss3`` vector
directly.

.. literalinclude:: src/sgm_streak.fut
   :lines: 31-38

Here is a derivation of how the segmented-scan based algorithm works:

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
a great abstraction.  However, for now, we have to get by with Futhark
not providing us with proper polymorphism.

Segmented Replication
---------------------

We shall now investigate how to replicate elements in a
one-dimensional data array according to natural numbers appearing in a
*replication* array of the same length. We shall call such an
operation a *segmented replicate* and we shall provide the replication
array as the first argument and the data vector as the second
argument. If we call the operation ``sgm_repl``, a call ``sgm_repl
[2,1,0,3,0] [5,6,9,8,4]`` should result in the array
``[5,5,6,8,8,8]``.

Here is code that implements the function ``sgm_repl`` and a more
general function ``repl_idx``, which returns an index array providing
replicating indexes into any argument array of the same length as the
argument array.

.. literalinclude:: src/sgm_repl.fut
   :lines: 13-22

An example evaluation of a call to the function ``repl_idx`` is
provided in below.  Notice that in order to use this Futhark code with
``futhark-opencl``, we need to prefix the array indexing in line 3,
line 4, and line 10 with the ``unsafe`` keyword.

+------------------+---+---+---+---+---+---+---+---+--+
| Args/Result      |   |   |   |   |   |   |   |   |  |
+==================+===+===+===+===+===+===+===+===+==+
| ``reps``         | = | 2 | 3 | 1 | 1 |   |   |   |  |
+------------------+---+---+---+---+---+---+---+---+--+
| ``s1``           | = | 2 | 5 | 6 | 7 |   |   |   |  |
+------------------+---+---+---+---+---+---+---+---+--+
| ``s2``           | = | 0 | 2 | 5 | 6 |   |   |   |  |
+------------------+---+---+---+---+---+---+---+---+--+
| ``replicate``    | = | 0 | 0 | 0 | 0 | 0 | 0 | 0 |  |
+------------------+---+---+---+---+---+---+---+---+--+
| ``tmp``          | = | 0 | 0 | 1 | 0 | 0 | 2 | 3 |  |
+------------------+---+---+---+---+---+---+---+---+--+
| ``flags``        | = | 0 | 0 | 1 | 0 | 0 | 1 | 1 |  |
+------------------+---+---+---+---+---+---+---+---+--+
| ``sgm_scan_add`` | = | 0 | 0 | 1 | 1 | 1 | 2 | 3 |  |
+------------------+---+---+---+---+---+---+---+---+--+

Line Drawing
------------

In this section we demonstrate how to use a flattening technique for
obtaining a work efficient line drawing routine that draws lines fully
in parallel :cite:`blelloch1990vector`. Given a number of line
segments, each defined by its end points :math:`(x_1,y_1)` and
:math:`(x_2,y_2)`, the algorithm will find the set of all points
constituting all the line segments.

We first present an algorithm that will find all points that
constitutes a single line segment. For computing this set, observe
that the number of points that make up the constituting set is the
maximum of :math:`|x_2-x_1|` and :math:`|y_2-y_1|`, the absolute
values of the difference in :math:`x`-coordinates and
:math:`y`-coordinates, respectively. Using this observation, the
algorithm can idependently compute the constituting set by first
calculating the proper direction and slope of a line, relative to a
particular starting point.

The simple line drawing routine is given as follows:

.. literalinclude:: src/lines_seq.fut
   :lines: 6-25

Futhark code that uses the ``linepoints`` function for drawing
concrete lines is shown below:

.. literalinclude:: src/lines_seq.fut
   :lines: 27-48

The function ``main`` sets up a grid and calls
the function ``drawlines``, which takes care of sequentially updating
the grid with constituting points for each line, computed using the
``linepoints`` function. The resulting points look like this:

.. image:: img/lines.svg
   :scale: 50%

An unfortunate problem with the line drawing routine shown above is
that it draws the lines sequentially and therefore makes only very
limited use of a GPU's parallel cores. There are various ways one may
mitigate this problem. One way could be to use ``map`` to draw lines
in parallel. However, such an approach will require some kind of
padding to ensure that the map function will compute data of the same
length, no matter the length of the line. A more resource aware
approach will apply a flattening technique for computing all points
defined by all lines simultaneously. The code for such an approach
looks as follows:

.. literalinclude:: src/lines_flat.fut
   :lines: 46-77

The function first computes a vector ``lens`` containing the lengths
of the lines. It then applies the ``repl_idx`` function, defined
above, to the ``lens`` vector to associate line information with each
point on the lines. After computing the direction and slope associated
with each line (variables ``dirs`` and ``sls``), the function uses the
``sgm_iota`` function for computing the line point number associated
with each point (variable ``is``). Based on the computed information,
the function can now establish the ``xs`` and ``ys`` vectors
containing coordinate information for each point on the
lines. Finally, the ``update`` function is called to update the
grid. Notice that due to the semantics of ``scatter``, a value of
``1`` is written to points for which lines cross.


Low-Discrepancy Sequences
-------------------------

Futhark comes with a library for generating Sobol sequences, which are
examples of so-called low-discrepancy sequences, sequences that, when
combined with Monte-Carlo methods, make numeric integration converge
faster than if ordinary pseudo-random numbers are used. Sobol
sequences may be multi-dimensional and a calculation of a sequence
depends on a set of direction-vectors, which are also provided by the
Futhark Sobol library.

As an example, we shall see how we can use Sobol sequences together
with Monte-Carlo simulation to compute the value of :math:`\pi`. We shall
also see that doing so will result in faster conversion towards the
true value of :math:`\pi` compared to if a simpler stratified sampling
approach is used.

To calculate an approximation to the value of :math:`\pi`, we will use
a simple dart-throwing approach. We will throw darts randomly at a 2
by 2 square, centered around the origin, and then establish the ratio between the number of darts
hitting within the unit circle with the number of darts hitting the
square. This ration multiplied with 4 will be our approximation of
:math:`\pi`. The more darts we throw, the better our approximation. To
calculate whether a particular dart, thrown at the point
:math:`(x,y)`, is within the unit circle, we can apply the standard
Pythagoras formula:

.. math::
   \pi ~~\approx~~ \frac{4}{N} \sum_{i=1}^N \left \{ \begin{array}{ll} 1 & \mbox{if} ~ x_i^2 + y_i^2 < 1 \\ 0 & \mbox{otherwise} \end{array} \right .

For the actual throwing of darts, we need to establish :math:`N` pairs of numbers, each
in the interval [-1;1]. We will need a two-dimensional Sobol sequence.

The Futhark library, as we shall see, makes essential use of the
formula for calculating the :math:`n`'th Sobol number. However, even
though such a formula is essential for achieving parallelism, it
performs poorly compared to the efficient recurrent formula, which
makes it possible to calculate the :math:`n`'th Sobol number if we
know the previous Sobol number.  The Futhark library makes essential
use of both formulas.

#. pseudo random numbers

#. trees

#. graphs
#. histograms

#. parenthesis matching
