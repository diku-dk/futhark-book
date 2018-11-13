.. _fusion:

Fusion and List Homomorphisms
=============================

In this chapter, we outline the general SOAC reasoning principles that
lie behind both the philosophy of programming with arrays in Futhark
and the techniques used for allowing certain programs to have
efficient parallel implementations. We shall discuss the reasoning
principles in terms of Futhark constructs but introduce a few
higher-order concepts that are important for the reasoning.

We first discuss the concept of *fusion*, which aims at eliminating
intermediate arrays while still allowing the Futhark programmer to
express an algorithm using simple SOACs and their associated reasoning
principles.

We then introduce the concept of list homomorphism through a few
examples.

Fusion
------

Fusion aims at reducing the overhead of unnecessary repeated
control-flow or unnecessary temporary storage. In essence, fusion is
defined in terms of a number of *fusion rules*, which specify how a
Futhark (intermedidate) expression can be transformed into a
semantically equivalent expression.

The rules make use of the auxiliary higher-order functions for, for
instance, function composition, presented in
:ref:`higher-order-functions`.

The *first fusion rule*, :math:`F1`, which says that the result of
mapping an arbitrary function ``f`` over the result of mapping another
arbitrary function ``g`` over some array ``a`` is identical to mapping
the composed function ``f <-< g`` over the array ``a``. The first
fusion rule is also called map-map fusion and can simply be written

    ``map f <-< map g``  =  ``map (f <-< g)``

Given that ``f`` and ``g`` denote the Futhark functions ``\x -> e``
and ``\y -> e'``, respectively (possibly after renaming of bound
variables), the *function product* of ``f`` and ``g``, written ``f <*>
g``, is defined as ``\(x,y) -> (f x, g y)``.

Now, given functions ``f:a->b`` and ``g:a->c``, the *second fusion
rule*, :math:`F2`, which denotes horizontal fusion, is given by the
following equation:

    ``(map f <*> map g) <-< dup``  =  ``map ((f <*> g) <-< dup)``

Here ``dup`` is the Futhark function ``\x -> (x,x)``.

The fusion rules that we have presented here generalise to functions
that take multiple arguments by applying zipping, unzipping, currying,
and uncurrying strategically. Notice that due to Futhark's strategy of
automatically transforming arrays of tuples into tuples of arrays, the
applications of zipping, unzipping, currying, and uncurring have no
effect at runtime.

Futhark applies a number of other fusion rules, which are based on the
fundamental property that Futhark's internal representation is based
on a number of composed constructs (e.g., named ``scanomap`` and
``redomap``). These constructs turn out to fuse well with ``map``.

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

Radix Sort Revisited
--------------------

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

.. _finding-the-longest-streak:

Finding the Longest Streak
--------------------------

In this section, we shall demonstrate how to write a function for
finding the longest streak of increasing numbers. Here is one possible
implementation of the function:

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

In :ref:`finding-the-longest-streak-segmented-scan` we present a
simpler algorithm, which builds directly on the concept of a so-called
segmented scan.
