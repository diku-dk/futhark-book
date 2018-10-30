.. _segmentation-and-flattening:

Segmented Operations and Irregular Flattening
=============================================

In this chapter, we present a number of tools for implementing
irregular nested data-parallel algorithms. We will first
present a number of segmented operations, which, as it turns out, can
be implemented using Futhark's standard SOAC parallel array
combinators. In particular, it turns out that the ``scan`` operator is
of critical importance. In fact, we shall develop the notion of a
*segmented scan* operation, which, as we shall see, can be implemented
using Futhark’s ``scan`` operator, and which in its own right is
essential to many of the later algorithms.

Based on the segmented scan operator and the other Futhark SOAC
operations, but before investigating more challenging irregular
algorithms, we also present a set of utility functions as well as
their parallel implementations.

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

Flattening by Expansion
-----------------------

For dealing with large non-regular problems, we need ways to
regularise the problems so that they become tractable with the regular
parallel techniques that we have seen demonstrated previously. One way
to regularise a problem is by *padding* data such that the data fits a
regular parallel schema. However, by doing so, we run the risk that
the program will use too many parallel resources for computations on
the padding data. This problem will arise, in particular, if the data
is very irregular. As a simple, and also visualisable, example,
consider the task of determining the points that make up a number of
line segments given by sets of two points in a 2D grid. Whereas we may
easily devise an algorithm for determining the grid points that make
up a single line segment, it is not immediately obvious how we can
efficiently regularise the problem of drawing multiple line segments,
as each line segment will end up being represented by a different
number of points. If we choose to implement a padding regularisation
scheme by introducing a notion of ''an empty point'', each line can be
represented as the same number of points, which will allow us to map
over an array of such line points for processing the lines using
regular parallelism. However, the cost we pay is that even the
smallest line will be represented as the same number of points as the
longest line.

Another strategy for regularisation is to *flatten* the irregular
parallelism into regular parallelism and use segmented operations to
process each particular object. It turns out that there, in many
cases, is a simple approach to implement such flattening, using, as we
shall see, a technique called *expansion*, which will take care of all
the knitty gritty details of the flattening. The expansion approach is
centered around a function that we shall call ``expand``, which, as
the name suggests, expands a source array into a longer target array,
by expanding each individual source element into multiple target
elements, which can then be processed in parallel.

For implementing the ``expand`` function, we first need to define a
few helper functions.

Replicated Iota and Segmented Iota
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The first helper function that we need is called
``replicated_iota``. Given an array of natural numbers specifying
repetitions, the function returns an array of weakly increasing
indices (starting from 0) and with each index repeated according to
the repetition array. As an example, ``replicated_iota [2,3,1,1]``
returns the array ``[0,0,1,1,1,2,3]``. The function is defined in terms of
other parallel operations, including ``scan``, ``map``, ``scatter``,
and ``segmented_scan``:

.. literalinclude:: src/segmented.fut
   :lines: 44-49

An example evaluation of a call to the function ``replicated_iota`` is
provided below.  Notice that in order to use this Futhark code with
``futhark-opencl``, we need to prefix the array indexing in line 3 and
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

An example application of ``replicated_iota`` is for defining a
function for replicating elements in a one-dimensional data array
according to natural numbers appearing in a *replication* array of the
same length. We shall call this operation a *segmented replicate* and
we shall provide the replication array as the first argument and the
data vector as the second argument. If we call the operation
``segmented_replicate``, a call ``segmented_replicate [2,1,0,3,0]
[5,6,9,8,4]`` should result in the array ``[5,5,6,8,8,8]``. Here is
the code that implements the function ``segmented_replicate``:

.. literalinclude:: src/sgm_repl.fut
   :lines: 20-22

Notice the use of the ``unsafe`` keyword in the last line; it is
necessary because Futhark cannot prove that the index ``i`` will
always be within bounds of the array ``vs``.

The second helper function that we need for defining the ``expand``
function is called ``segmented_iota``. Given a flags array, the
function returns an array of index sequences, each of which is reset
according to the flags array. As an example, the expression

::

    segmented_iota [false,false,false,true,false,false,false]

returns the array ``[0,1,2,0,1,2,3]``. This function
``segmented_iota`` can be implemented with the use of a simple call to
``segmented_scan`` followed by a call to ``map``:

.. literalinclude:: src/segmented.fut
   :lines: 57-59

Expansion
~~~~~~~~~

The generic expansion function that we set out to construct is now
somewhat simple to implement using only parallel operations. Here is
the generic type of the function:

::

    val expand 'a 'b : (sz: a -> i32) -> (get: a -> i32 -> b) -> []a -> []b

The function expands a source array into a target array given (1) a
function that determines, for each source element, how many target
elements it expands to and (2) a function that computes a particular
target element based on a source element and the target element number
associated with the source. As an example, the expression ``expand
(\x->x) (*) [2,3,1]`` returns the array ``[0,2,0,3,6,0]``. The
function is defined as follows:

.. literalinclude:: src/segmented.fut
   :lines: 69-73


Drawing Lines
-------------

In this section we demonstrate how to apply the
flattening-by-expansion technique for obtaining a work efficient line
drawing routine that draws lines fully in parallel. The technique
resembles the development by Blelloch :cite:`blelloch1990vector` with
the difference that it makes use of the ``expand`` function defined in
the previous section. Given a number of line segments, each defined by its
end points :math:`(x_1,y_1)` and :math:`(x_2,y_2)`, the algorithm will
find the set of all points constituting all the line segments.

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
   :lines: 6-28

Futhark code that uses the ``linepoints`` function for drawing
concrete lines is shown below:

.. literalinclude:: src/lines_seq.fut
   :lines: 30-50

The function ``main`` sets up a grid and calls the function
``drawlines``, which takes care of sequentially updating the grid with
constituting points for each line, computed using the ``linepoints``
function. The resulting points look like this:

.. only:: latex

   .. image:: img/lines_grid.pdf
      :width: 600px

.. only:: html

   .. image:: img/lines_grid.svg

An unfortunate problem with the line drawing routine shown above is
that it draws the lines sequentially, one by one, and therefore makes
only very limited use of a GPU's parallel cores. There are various
ways one may mitigate this problem. One way could be to use ``map`` to
draw lines in parallel. However, such an approach will require some
kind of padding to ensure that the map function will compute data of
the same length, no matter the length of the line. A more resource
aware approach will apply a flattening technique for computing all
points defined by all lines simultaneously. Using the ``expand``
function defined in the previous section, all we need to do to
implement this approach is to provide (1) a function that determines
for a given line, the number of points that make up the line and (2) a
function that determines the ``n``'th point of a particular line, given
the index ``n``. The code for such an approach looks as follows:

.. literalinclude:: src/lines_flat2.fut
   :lines: 29-50

Notice that the function ``get_point_in_line`` distinguishes between
whether the number of points in the line is counted by the x-axis or
the y-axis. Notice also that the flattening technique can be applied
only because all lines have the same color. Otherwise, when two lines
intersect, the result would be undefined, due to the fact that
``scatter`` results in undefined behaviour when multiple values are
written into the same location of an array.

Drawing Triangles
-----------------

Another example of an algorithm worthy of flattening is an algorithm
for drawing triangles. The algorithm that we present here is based on
the assumption that we already have a function for drawing multiple
horizontal lines in parallel. Luckily, we have such a function! The
algorithm is based on the property that any triangle can be split into
an *upper triangle* with a horizontal baseline and a *lower triangle*
with a horizontal ceiling. Just as the algorithm for drawing lines
makes use of the ``expand`` function defined earlier, so will the
flattened algorithm for drawing triangles. A triangle is defined by
the three points representing the corners of the triangle:

::

    type triangle = (point, point, point)

We shall make the assumption that the three points that define the
triangle have already been sorted according to the y-axis. Thus, we can
assume that the first point is the top point, the third point is the
lowest point, and the second point is the middle point (according to
the y-axis).

The first function we need to pass to the ``expand`` function is a
function that determines the number of horizontal lines in the triangle:

.. literalinclude:: src/triangles.fut
   :lines: 63-64

The second function we need to pass to the ``expand`` function is
somewhat more involved. We first define a function ``dxdy``, which
computes the inverse slope of a line between two points:

.. literalinclude:: src/triangles.fut
   :lines: 66-70

We can now define the function that, given a triangle and the
horizontal line number in the triangle (counted from the top), returns
the corresponding line:

.. literalinclude:: src/triangles.fut
   :lines: 72-86

The function distinguishes between whether the line to compute resides
in the upper or the lower subtriangle. Finally, we can define a
parallel, work-efficient function that converts a number of triangles
into lines:

.. literalinclude:: src/triangles.fut
   :lines: 88-90

To see the code in action, here is a function that draws three
triangles on a grid of height 30 and width 62:

.. literalinclude:: src/triangles.fut
   :lines: 92-98

The function makes use of both the ``lines_of_triangles`` function
that we have defined here and the work efficient ``drawlines``
function defined previously. Here is a plot of the result:

.. only:: latex

   .. image:: img/triangles_grid.pdf
      :width: 600px

.. only:: html

   .. image:: img/triangles_grid.svg


Complex Flattening
------------------

Unfortunately, the flattening-by-expansion technique does not suit all
irregular problems. We shall now investigate how we can flatten a
highly irregular algorithm such as quick-sort. The Quick-sort
algorithm can be presented very elegantly in a functional
language. Consider the following pseudo-code, which, unfortunately, is
not immediately Futhark code:

::

    let quicksort xs =
      if length xs < 2 then xs
      else let (left,middle,right) = partition xs[length xs / 2] xs
           in quicksort left ++ middle ++ quicksort right

Here the function ``partition`` returns three arrays with the first
array containing elements smaller than the *pivot* element ``xs[length xs
/ 2]``, the second array containing elements equal to the pivot
element, and the third array containing elements that are greater than
the pivot element.  There are multiple problems with this code. First,
the code makes use of recursion, which is not supported by
Futhark. Second, the kind of recursion used is not tail-recursion,
which means that it is not directly obvious how to eliminate the
recursion. Third, it is not clear how the code can avoid using an
excessive amount of memory instead of making use of inplace-updates
for the sorting. Finally, it seems that the code is inherently
task-parallel in nature and not particularly data-parallel.

The solution is to solve a slightly more general problem. More
precisely, we shall set out to sort a number of segments,
simultaneously, where each segment comprises a part of the array.
