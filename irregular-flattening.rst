.. _irregular-flattening:

Irregular Flattening
====================

In this chapter, we investigate a number of challenging irregular
algorithms, which cannot be dealt with directly using Futhark's
moderate flattening technique discussed in :numref:`moderate-flattening`.

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
process each particular object. It turns out that, in many
cases, there is a simple approach to implement such flattening, using, as we
shall see, a technique called *expansion*, which will take care of all
the knitty gritty details of the flattening. The expansion approach is
centered around a function that we shall call ``expand``, which, as
the name suggests, expands a source array into a longer target array,
by expanding each individual source element into multiple target
elements, which can then be processed in parallel.

For implementing the ``expand`` function using only parallel
operations, we shall make use of the segmented helper functions
defined in :numref:`regular-flattening`. In particular, we shall make use of
the functions ``replicated_iota``, ``segmented_replicate``, and
``segmented_iota``.

Here is the generic type of the ``expand`` function:

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
algorithm can independently compute the constituting set by first
calculating the proper direction and slope of a line, relative to a
particular starting point.

The simple line drawing routine is given as follows:

.. literalinclude:: src/lines_seq.fut
   :lines: 4-26

Futhark code that uses the ``linepoints`` function for drawing
concrete lines is shown below:

.. literalinclude:: src/lines_seq.fut
   :lines: 28-48

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
   :lines: 28-49

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
   :lines: 62-63

The second function we need to pass to the ``expand`` function is
somewhat more involved. We first define a function ``dxdy``, which
computes the inverse slope of a line between two points:

.. literalinclude:: src/triangles.fut
   :lines: 65-69

We can now define the function that, given a triangle and the
horizontal line number in the triangle (counted from the top), returns
the corresponding line:

.. literalinclude:: src/triangles.fut
   :lines: 71-85

The function distinguishes between whether the line to compute resides
in the upper or the lower subtriangle. Finally, we can define a
parallel, work-efficient function that converts a number of triangles
into lines:

.. literalinclude:: src/triangles.fut
   :lines: 87-91

To see the code in action, here is a function that draws three
triangles on a grid of height 30 and width 62:

.. literalinclude:: src/triangles.fut
   :lines: 91-97

The function makes use of both the ``lines_of_triangles`` function
that we have defined here and the work efficient ``drawlines``
function defined previously. Here is a plot of the result:

.. only:: latex

   .. image:: img/triangles_grid.pdf
      :width: 600px

.. only:: html

   .. image:: img/triangles_grid.svg

.. _primes-by-expansion:

Primes by Expansion
-------------------

We saw earlier in :numref:`counting-primes` how we could implement a
parallel algorithm for finding the number of primes below a given
number. We also found, however, that the algorithm presented was not
work-efficient. It is possible to implement a work-efficient algorithm
using the ``expand`` function. We will leave the task as an exercise
for the reader.

.. Cosmin is using "flattening of primes" as an exercise for PMPH - we
.. can include the example sometime in the future...
..
.. We now present a work-efficient algorithm using the
.. concept of flattening-by-expansion. Here is the algorithm:
..
.. .. literalinclude:: src/primes_expand.fut
..    :lines: 6-21
..
.. There are a number of points to note about the code:
..
.. 1. When computing ``c2``, we are careful not to introduce overflow by
..    not calculating ``c*c`` unless ``c`` is less than the quare root of
..    ``n+1``.
..
.. 2. We use the ``expand`` function to calculate and flatten the
..    sieves. For each prime ``p`` and upper limit ``c2`` we can compute
..    the number of contributions in the sieve (the function ``sz``).
..
.. 3. For each prime ``p`` and sieve index ``i``, we can compute the
..    sieve contribution (the function ``get``).
..
.. 4. Using a ``scatter``, a ``map``, and a ``filter``, we can now
..    compute the new primes in the interval ``c`` to ``c2``.
..
.. We shall not here prove that the algorithm is work efficient but just
.. postulate that the algorithm has work complexity
.. :math:`O(n\,\log\,\log\,n)` and span complexity
.. :math:`O(\log\,\log\,n)`.


Complex Flattening
------------------

Unfortunately, the flattening-by-expansion technique does not suit all
irregular problems. We shall now investigate how we can flatten a
highly irregular algorithm such as quick-sort. The Quick-sort
algorithm can be presented very elegantly in a functional
language. The function ``qsort`` that we will define has the following
type:

::

    val qsort 't [n] : (t -> t -> bool) -> [n]t -> [n]t

Given a comparison function (``<=``) and an array of elements ``xs``,
``qsort (<=) xs`` returns an array with the elements in ``xs`` sorted
according to ``<=``. Consider the following pseudo-code, which,
unfortunately, is not immediately Futhark code:

::

    def qsort (<=) xs =
      if length xs < 2 then xs
      else let (left,middle,right) = partition (<=) xs[length xs / 2] xs
           in qsort (<=) left ++ middle ++ qsort (<=) right

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
simultaneously, where each segment comprises a part of the
array. Notice that we are interested in supporting a notion of
*partial segmentation*, for which the segments of interest are
disjoint but do not necessarily together span the entire array. In
particular, the algorithm does not need to sort segments containing
previously chosen pivot values. Such segments are already located in
the correct positions, which means that they need not be moved around
by the segmented quick sort implementation.

We first define a type ``sgm`` that specifies a segment of an
underlying one-dimensional array of values:

.. literalinclude:: src/quick_sort.fut
   :lines: 25-25

At top-level, the function ``qsort`` is defined as follows, assuming a
function ``step`` of type ``(t -> t -> bool) -> *[n]t -> []sgm ->
(*[n]t,[]sgm)``:

.. literalinclude:: src/quick_sort.fut
   :lines: 89-93

The ``step`` function is called initially with the array to be sorted
as argument together with a singleton array containing a segment
denoting the entire array to be sorted. The ``step`` function is
called iteratively until the returned array of segments is empty. The
job of the ``step`` function is to divide each segment into three new
segments based on pivot values found for each segment. After the step
function has reordered the values in the segments, the middle segment
(containing values equal to a pivot) need not be dealt with again in
the further process. A new array of segment descriptors is then
defined and after removing empty segment descriptors, the resulting
array of non-empty segment descriptors is returned by the ``step``
function together with the reordered value array.

Before we can define the ``step`` function, we first define a few
helper functions.  Using the functions ``segmented_iota`` and
``segmented_replicate``, defined earlier, we can define a function for
finding all the indexes represented by an array of segments:

.. literalinclude:: src/quick_sort.fut
   :lines: 28-33

We also define a function ``info`` that, given an ordering function
and two elements, returns ``-1`` if the first element is less than the
second element, ``0`` if the elements are identical, and ``1`` if the
first element is greater than the second element:

.. literalinclude:: src/quick_sort.fut
   :lines: 14-16

The following two functions ``tripit`` and ``tripadd`` are used for
converting the classification of elements into subsegments:

.. literalinclude:: src/quick_sort.fut
   :lines: 18-23

We can now define the function ``step`` that, besides from an ordering
function, takes as arguments (1) the array containing values and (2) an
array of segments to be sorted. The function returns a pair of a
reordered array of values and a new array of segments to be
sorted:

.. literalinclude:: src/quick_sort.fut
   :lines: 35-79

The algorithm has best case work complexity :math:`O(n)` (when all
elements are identical), worst case work complexity :math:`O(n^2)`,
and an average case work complexity of :math:`O(n \log n)`. It has
best depth complexity :math:`O(1)`, worst depth complexity
:math:`O(n)` and average depth complexity :math:`O(\log n)`.
