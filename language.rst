.. _futlang:

The Futhark Language
====================

Futhark is a pure functional data-parallel array language. It is both
syntactically and conceptually similar to established functional
languages, such as Haskell and Standard ML. In contrast to these
languages, Futhark focuses less on expressivity and elaborate type
systems, and more on compilation to high-performance parallel code.
Futhark programs are written with bulk operations on arrays, called
*Second-Order Array Combinators* (SOACs), that mirror the higher-order
functions found in conventional functional languages: ``map``,
``reduce``, ``filter``, and so forth.  In Futhark, the parallel SOACs
have sequential semantics but permit parallel execution, and will
typically be compiled to parallel code.

The primary idea behind Futhark is to design a language that has enough
expressive power to conveniently express complex programs, yet is also
amenable to aggressive optimisation and parallelisation. The tension is
that as the expressive power of a language grows, the difficulty of
efficient compilation rises likewise. For example, Futhark supports
nested parallelism, despite the complexities of efficiently mapping it
to the flat parallelism supported by hardware, as many algorithms are
awkward to write with just flat parallelism. On the other hand, we do
not support non-regular arrays, as they complicate size analysis a great
deal. The fact that Futhark is purely functional is intended to give an
optimising compiler more leeway in rearranging the code and performing
high-level optimisations.

Programming in Futhark feels similar to programming in other
functional languages. If you know languages such as Haskell, OCaml,
Scala, or Standard ML, you will likely be able to read and modify most
Futhark code. For example, this program computes the dot product
:math:`\Sigma_{i} x_{i}\cdot{}y_{i}` of two vectors of integers:

::

    def main (x: []i32) (y: []i32): i32 =
      reduce (+) 0 (map2 (*) x y)

In Futhark, the notation for an array of element type ``t`` is
``[]t``. The program defines a function called ``main`` that takes two
arguments, both integer arrays, and returns an integer. The ``main``
function first computes the element-wise product of its two arguments,
resulting in an array of integers, then computes the sum of the
elements in this new array.

If we save the program in a file ``dotprod.fut``, then we can compile
it to a binary ``dotprod`` (or ``dotprod.exe`` on Windows) by running:

.. code-block:: none

    $ futhark c dotprod.fut

A Futhark program compiled to an executable will read the arguments to
its ``main`` function from standard input, and will print the result to
standard output:

.. code-block:: none

    $ echo [2,2,3] [4,5,6] | ./dotprod
    36i32

In Futhark, an array literal is written with square brackets surrounding
a comma-separated sequence of elements. Integer literals can be suffixed
with a specific type. This is why ``dotprod`` prints ``36i32``, rather
than just ``36`` - this makes it clear that the result is a 32-bit
integer. Later we will see examples of when these suffixes are useful.

The ``futhark c`` compiler we used above translates a Futhark program
into sequential code running on the CPU. This can be useful for testing,
and will work on most systems, even those without GPUs. However, it
wastes the main potential of Futhark: fast parallel execution. We can
instead use the ``futhark opencl`` compiler to generate an executable
that offloads execution via the OpenCL framework. In principle, this
allows offloading to any kind of device, but the ``futhark opencl``
compilation pipelines makes optimisation assumptions that are oriented
towards contemporary GPUs. Use of ``futhark opencl`` is simple, assuming
your system has a working OpenCL setup:

.. code-block:: none

    $ futhark opencl dotprod.fut

Execution is just as before:

.. code-block:: none

    $ echo [2,2,3] [4,5,6] | ./dotprod
    36i32

In this case, the workload is small enough that there is little
benefit in parallelising the execution. In fact, it is likely that for
this tiny dataset, the OpenCL startup overhead results in several
orders of magnitude slowdown over sequential execution. See
:numref:`benchmarking` for information on how to measure execution times.

The ability to compile Futhark programs to executables is useful for
testing, but it should be noted that it is not how Futhark is intended
to be used in practice. As a pure functional array language, Futhark
is not capable of reading input or managing a user interface, and as
such cannot be used as a general-purpose language. Futhark is intended
to be used for small, performance-sensitive parts of larger
applications, typically by compiling a Futhark program to a *library*
that can be imported and used by applications written in conventional
languages. See :numref:`interoperability` for more information.

As compiled Futhark executables are intended for testing, they take a
range of command line options to manipulate their behaviour and print
debugging information. These will be introduced as needed.

For most of this book, we will be making use of the interactive
Futhark *interpreter*, ``futhark repl``, which provides a Futhark REPL
into which you can enter arbitrary expressions and declarations:

.. code-block:: none

    $ futhark repl
    |// |\    |   |\  |\   /
    |/  | \   |\  |\  |/  /
    |   |  \  |/  |   |\  \
    |   |   \ |   |   | \  \
    Version 0.15.0.
    Copyright (C) DIKU, University of Copenhagen, released under the ISC license.

    Run :help for a list of commands.

    [0]> 1 + 2
    3i32
    [1]>

The prompts are numbered to permit error messages to refer to previous
inputs.  We will generally elide the numbers in this book, and just
write the prompt as ``>`` (do not confuse this with the Unix prompt,
which we write as ``$``).

``futhark repl`` supports a variety of commands for inspecting and
debugging Futhark code.  These will be introduced as necessary, in
particular in :numref:`testing`.  There is also a batch-mode
counterpart to ``futhark repl``, called ``futhark run``, which
non-interactively executes the given program in the interpreter.

.. _baselang:

Basic Language Features
-----------------------

As a functional or *value-oriented* language, the semantics of Futhark
can be understood entirely by how values are constructed, and how
expressions transform one value to another. As a statically typed
language, all Futhark values are classified by their *type*. The
primitive types in Futhark are the signed integer types ``i8``,
``i16``, ``i32``, ``i64``, the unsigned integer types ``u8``, ``u16``,
``u32``, ``u64``, the floating-point types ``f32``, ``f64``, and the
boolean type ``bool``. An ``f32`` is always a single-precision float
and a ``f64`` is a double-precision float.

Numeric literals can be suffixed with their intended type. For
example, ``42i8`` is of type ``i8``, and ``1337e2f64`` is of type
``f64``. If no suffix is given, the type is inferred by the context.
In case of ambiguity, integral literals are given type ``i32`` and
decimal literals are given ``f64``.  Boolean literals are written as
``true`` and ``false``.

.. admonition:: Note: converting between primitive values

   Futhark provides a collection of functions for performing
   straightforward conversions between primitive types.  These are all
   of the form ``to.from``.  For example, ``i32.f64`` converts a value
   of type ``f64`` (double-precision float) to a value of type ``i32``
   (32-bit signed integer), by truncating the fractional part::

     > i32.f64 2.1
     2

     > f64.i32 2
     2.0

   Technically, ``i32.f64`` is not the name of the function.  Rather,
   this is a reference to the function ``f64`` in the module ``i32``.
   We will not discuss modules further until :numref:`modules`, so for
   now it suffices to think of ``i32.f64`` as a function name.  The
   only wrinkle is that if a variable with the name ``i32`` is in
   scope, the entire ``i32`` module becomes inaccessible by shadowing.

   Futhark provides shorthand for the most common conversions::

     r32 == f32.i32
     t32 == i32.f32
     r64 == f64.i32
     t64 == i64.f32

All values can be combined in tuples and arrays. A tuple value or type
is written as a sequence of comma-separated values or types enclosed in
parentheses. For example, ``(0, 1)`` is a tuple value of type
``(i32,i32)``. The elements of a tuple need not have the same type – the
value ``(false, 1, 2.0)`` is of type ``(bool, i32, f64)``. A tuple
element can also be another tuple, as in ``((1,2),(3,4))``, which is of
type ``((i32,i32),(i32,i32))``. A tuple cannot have just one element,
but empty tuples are permitted, although they are not very useful — these
are written ``()`` and are of type ``()``. *Records* exist as syntactic
sugar on top of tuples, and will be discussed in :numref:`records`.

An array value is written as a sequence of comma-separated values
enclosed in square brackets: ``[1,2,3]``. An array type is written as
``[d]t``, where ``t`` is the element type of the array, and ``d`` is
an integer indicating the size. We often elide ``d``, in which case
the size will be inferred. As an example, an array of three integers
could be written as ``[1,2,3]``, and has type ``[3]i32``.  An empty
array is written simply as ``[]``, although the context must make the
type of an empty array unambiguous.

Multi-dimensional arrays are supported in Futhark, but they must be
*regular*, meaning that all inner arrays have the same shape. For
example, ``[[1,2], [3,4], [5,6]]`` is a valid array of type
``[3][2]i32``, but ``[[1,2], [3,4,5], [6,7]]`` is not, because there
we cannot determine integers ``m`` and ``n`` such that ``[m][n]i32``
is the type of the array. The restriction to regular arrays is rooted
in low-level concerns about efficient compilation, but we can
understand it in language terms by the inability to write a type with
consistent dimension sizes for an irregular array value. In a Futhark
program, all array values, including intermediate (unnamed) arrays,
must be typeable. We will return to the implications of this
restriction in later chapters.

Simple Expressions
~~~~~~~~~~~~~~~~~~

The Futhark expression syntax is mostly conventional ML-derived
syntax, and supports the usual binary and unary operators, with few
surprises.  Futhark does not have syntactically significant
indentation, so feel free to put white space whenever you like. This
section will not try to cover the entire Futhark expression language
in complete detail. See the `reference manual
<http://futhark.readthedocs.io>`_ for a comprehensive treatment.

Function application is via juxtaposition. For example, to apply a
function ``f`` to a constant argument, we write:

::

    f 1.0

We will discuss defining our own functions in
:numref:`function-declarations`.

A let-expression can be used to give a name to the result of an expression:

::

    let z = x + y
    in body

Futhark is eagerly evaluated (unlike Haskell), so the expression for
``z`` will be fully evaluated before ``body``. The keyword ``in`` is optional
when it precedes another ``let``. Thus, instead of writing:

::

    let a = 0 in
    let b = 1 in
    let c = 2 in
    a + b + c

we can write

::

    let a = 0
    let b = 1
    let c = 2
    in a + b + c

The final ``in`` is still necessary. In examples, we will often skip the body
of a let-expression if it is not important. A limited amount of pattern matching is
supported in let-bindings, which permits tuple components to be extracted:

::

    let (x,y) = e      -- e must be of some type (t1,t2)

This feature also demonstrates the Futhark line comment syntax — two
dashes followed by a space. Block comments are not supported.

Two-way if-then-else is the main branching construct in Futhark:

::

    if x < 0 then -x else x

Pattern matching with the ``match`` keyword will be discussed later.

Arrays are indexed using conventional row-major notation, as in the
expression ``a[i1, i2, i3, ...]``. All array accesses are checked at
runtime, and the program will terminate abnormally if an invalid
access is attempted. Indices are of type ``i64``, though any signed
type is permitted in an index expression (it will be casted to an ``i64``).

White space is used to disambiguate indexing from application to array
literals. For example, the expression ``a b [i]`` means “apply the
function ``a`` to the arguments ``b`` and ``[i]``”, while ``a b[i]``
means “apply the function ``a`` to the argument ``b[i]``”.

Futhark also supports array *slices*. The expression ``a[i:j:s]``
returns a slice of the array ``a`` from index ``i`` (inclusive) to ``j``
(exclusive) with a stride of ``s``. If the stride is positive, then ``i <= j``
must hold, and if the stride is negative, then ``j <= i`` must hold.
Slicing of multiple dimensions can be done by separating with commas,
and may be intermixed freely with indexing. Note that unlike array
indices, slice indices can only be of type ``i64``.

Some syntactic sugar is provided for concisely specifying arrays of intervals of
integers. The expression ``x...y`` produces an array of the integers
from ``x`` to ``y``, both inclusive. The upper bound can be made
exclusive by writing ``x..<y``. For example:

::

    > 1...3
    [1i32, 2i32, 3i32]
    > 1..<3
    [1i32, 2i32]

It is usually necessary to enclose a range expression in parentheses,
because they bind very loosely.  A stride can be provided by writing
``x..y...z``, with the interpretation "first ``x``, then ``y``, up to
``z``". For example:

::

    > 1..3...7
    [1i32, 3i32, 5i32, 7i32]
    > 1..3..<7
    [1i32, 3i32, 5i32]

The element type of the produced array is the same as the type of the
integers used to specify the bounds, which must all have the same type
(but need not be constants). We will be making frequent use of this
notation throughout this book.

.. admonition:: Note: structural equality

   The Futhark equality and inequality operators ``==`` and ``!=`` are
   overloaded operators, just like ``+``. They work for types built
   from basic types (e.g., ``i32``), array types, tuple types, and
   record types. The operators are not allowed on values containing
   sub-values of abstract types or function types.

   Notice that Futhark does not support a notion of type classes
   :cite:`Peterson:1993:ITC:155090.155112` or equality types
   :cite:`Els98`. Allowing the equality and inequality operators to
   work on values of abstract types could potentially violate
   abstraction properties, which is the reason for the special
   treatment of equality types and equality type variables in the
   Standard ML programming language.

.. _function-declarations:

Top-Level Definitions
~~~~~~~~~~~~~~~~~~~~~

A Futhark program consists of a sequence of top-level definitions, which
are primarily *function definitions* and *value definitions*. A function
definition has the following form:

::

    def name params... : return_type = body

A function may optionally declare its return type and the types of its
parameters.  If type annotations are not provided, the types are
inferred.  As a concrete example, here is the definition of the
Mandelbrot set iteration step :math:`Z_{n+1} = Z_{n}^{2} + C`, where
:math:`Z_n` is the actual iteration value, and :math:`C` is the
initial point. In this example, all operations on complex numbers are
written as operations on pairs of numbers.  In practice, we would use
a library for complex numbers.

::

    def mandelbrot_step ((Zn_r, Zn_i): (f64, f64))
                        ((C_r, C_i): (f64, f64))
                      : (f64, f64) =
      let real_part = Zn_r*Zn_r - Zn_i*Zn_i + C_r
      let imag_part = 2.0*Zn_r*Zn_i + C_i
      in (real_part, imag_part)

Or equivalently, without specifying the types:

::

    def mandelbrot_step (Zn_r, Zn_i)
                        (C_r, C_i) =
      let real_part = Zn_r*Zn_r - Zn_i*Zn_i + C_r
      let imag_part = 2.0*Zn_r*Zn_i + C_i
      in (real_part, imag_part)

It is generally considered good style to specify the types of the
parameters and the return value when defining top-level functions.
Type inference is mostly used for local and anonymous functions, which
we will get to later.

We can define a constant with very similar notation:

::

    def name: value_type = definition

For example:

::

    def physicists_pi: f64 = 4.0

Top-level definitions are declared in order, and a definition may
refer *only* to those names that have been defined before it
occurs. This means that circular and recursive definitions are not
permitted. We will return to function definitions in
:numref:`size-types` and :numref:`polymorphism`, where we will look at
more advanced features, such as parametric polymorphism and implicit
size parameters.

.. admonition:: Note: Loading files into ``futhark repl``

   At this point you may want to start writing and applying functions.
   It is possible to do this directly in ``futhark repl``, but it quickly
   becomes awkward for multi-line functions.  You can use the
   ``:load`` command to read declarations from a file:

   .. code-block:: none

      > :load test.fut
      Loading test.fut

   The ``:load`` command will remove any previously entered
   declarations and provide you with a clean slate.  You can reload
   the file by running ``:load`` without further arguments:

   .. code-block:: none

      > :load
      Loading test.fut

   Emacs users may want to consider `futhark-mode
   <https://github.com/diku-dk/futhark-mode>`_, which is able to load
   the file being edited into ``futhark repl`` with ``C-c C-l``, and
   provides other useful features as well.

.. admonition:: Exercise: Simple Futhark programming
   :class: exercise

   This is a good time to make sure you can actually write and run a
   Futhark program on your system.  Write a program that contains a
   function ``main`` that accepts as input a parameter ``x : i32``,
   and returns ``x`` if ``x`` is positive, and otherwise the negation
   of ``x``.  Compile your program with ``futhark c`` and verify that
   it works, then try with ``futhark opencl``.

   .. only:: html

   .. admonition:: Solution (click to show)
      :class: solution

      ::

         def main (x: i32): i32 = if x < 0 then -x else x

.. _type-abbreviations:

Type abbreviations
^^^^^^^^^^^^^^^^^^

The previous definition of ``mandelbrot_step`` accepted arguments and
produced results of type ``(f64,f64)``, with the implied understanding
that such pairs of floats represent complex numbers. To make this
clearer, and thus improve the readability of the function, we can use a
*type abbreviation* to define a type ``complex``:

::

    type complex = (f64, f64)

We can now define ``mandelbrot_step`` as follows:

::

    def mandelbrot_step ((Zn_r, Zn_i): complex)
                        ((C_r, C_i): complex)
                      : complex =
        let real_part = Zn_r*Zn_r - Zn_i*Zn_i + C_r
        let imag_part = 2.0*Zn_r*Zn_i + C_i
        in (real_part, imag_part)

Type abbreviations are purely a syntactic convenience — the type
``complex`` is fully interchangeable with the type ``(f64, f64)``::

  > type complex = (f64, f64)
  > def f (x: (f64, f64)): complex = x
  > f (1,2)
  (1.0f64, 2.0f64)

For abstract types, that hide their definition, we have to use the
module system discussed in :numref:`modules`.

Array Operations
----------------

Futhark provides various combinators for performing bulk
transformations of arrays. Judicious use of these combinators is key
to getting good performance. There are two overall categories:
*first-order array combinators*, like ``zip``, that always perform the
same operation, and *second-order array combinators* (*SOAC*\ s), like
``map``, that take a *functional argument* indicating the operation to
perform. SOACs are the basic parallel building blocks of Futhark
programming. While they are designed to resemble familiar higher-order
functions from other functional languages, they have some restrictions
to enable efficient parallel execution.

We can use ``zip`` to transform two arrays to a single array of
pairs:

::

    > zip [1,2,3] [true,false,true]
    [(1i32, true), (2i32, false), (3i32, true)]

Notice that the input arrays may have different types. We can use
``unzip`` to perform the inverse transformation:

::

    > unzip [(1,true),(2,false),(3,true)]
    ([1i32, 2i32, 3i32], [true, false, true])

The ``zip`` function requires the two input arrays to have the same
length.  This is verified statically, by the type checker, using rules
we will discuss in :numref:`size-types`.

Transforming between arrays of tuples and tuples of arrays is common
in Futhark programs, as many array operations accept only one array as
input.  Due to a clever implementation technique, ``zip`` and
``unzip`` usually have no runtime cost (they are fused into other
operations), so you should not shy away from using them out of
efficiency concerns.  For operating on arrays of tuples with more than
two elements, there are ``zip``/``unzip`` variants called ``zip3``,
``zip4``, etc, up to ``zip5``/``unzip5``.

Now let’s take a look at some SOACs.

Map
~~~

The simplest SOAC is probably ``map``. It takes two arguments: a
function and an array. The function argument can be a function name,
or an anonymous function. The function is applied to every element of
the input array, and an array of the result is returned. For example:

::

    > map (\x -> x + 2) [1,2,3]
    [3i32, 4i32, 5i32]

Anonymous functions need not define their parameter- or return types,
but you are free to do so in cases where it aids readability:

::

    > map (\(x:i32): i32 -> x + 2) [1,2,3]
    [3i32, 4i32, 5i32]

The functional argument can also be an operator, which must be enclosed
in parentheses:

::

    > map (!) [true, false, true]
    [false, true, false]

Partially applying operators is also supported using so-called
*operator sections*, with a syntax taken from Haskell:

::

    > map (+2) [1,2,3]
    [3i32, 4i32, 5i32]

    > map (2-) [1,2,3]
    [1i32, 0i32, -1i32]

However, note that the following will *not* work::

    [0]> map (-2) [1,2,3]
    Error at [0]> :1:5-1:8:
    Cannot unify `t2' with type `a0 -> x1' (must be one of i8, i16, i32, i64, u8, u16, u32, u64, f32, f64 due to use at [0]> :1:7-1:7).
    When matching type
      a0 -> x1
    with
      t2

This is because the expression ``(-2)`` is taken as negative number
``-2`` encloses in parentheses.  Instead, we have to write it with an
explicit lambda::

  > map (\x -> x-2) [1,2,3]
  [-1i32, 0i32, 1i32]

There are variants of ``map``, suffixed with an integer, that permit
simultaneous mapping of multiple arrays, which must all have the same
size.  This is supported up to ``map5``. For example, we can perform
an element-wise sum of two arrays:

::

    > map2 (+) [1,2,3] [4,5,6]
    [5i32, 7i32, 9i32]

A combination of ``map`` and ``zip`` can be used to handle arbitrary
numbers of simultaneous arrays.

Be careful when writing ``map`` expressions where the function returns
an array.  Futhark requires regular arrays, so this is unlikely to go
well:

::

    map (\n -> 1...n) ns

Unless the array ``ns`` consists of identical values, this expression
will fail at runtime.

We can use ``map`` to duplicate many other language constructs. For
example, if we have two arrays ``xs:[n]i32`` and ``ys:[m]i32`` — that
is, two integer arrays of sizes ``n`` and ``m`` — we can concatenate
them using:

::

      map (\i -> if i < n then xs[i] else ys[i-n])
          (0..<n+m)

However, it is not a good idea to write code like this, as it hinders
the compiler from using high-level properties to do
optimisation. Using ``map`` with explicit indexing is usually only
necessary when solving complicated irregular problems that cannot be
represented directly.

Scan and Reduce
~~~~~~~~~~~~~~~

While ``map`` is an array transformer, the ``reduce`` SOAC is an array
aggregator: it uses some function of type ``t -> t -> t`` to combine
the elements of an array of type ``[]t`` to a value of type ``t``. In
order to perform this aggregation in parallel, the function must be
*associative* and have a *neutral element* (in algebraic terms,
constitute a `monoid <https://en.wikipedia.org/wiki/Monoid>`_):

-  A function :math:`f` is associative if
   :math:`f(x,f(y,z)) = f(f(x,y),z)` for all :math:`x,y,z`.

-  A function :math:`f` has a neutral element :math:`e` if
   :math:`f(x,e) = f(e,x) = x` for all :math:`x`.

Many common mathematical operators fulfill these laws, such as addition:
:math:`(x+y)+z=x+(y+z)` and :math:`x+0=0+x=x`. But others, like
subtraction, do not. In Futhark, we can use the addition operator and
its neutral element to compute the sum of an array of integers:

::

    > reduce (+) 0 [1,2,3]
    6i32

It turns out that combining ``map`` and ``reduce`` is both powerful
and has remarkable optimisation properties, as we will discuss in
:numref:`fusion`. Many Futhark programs are primarily
``map``-``reduce`` compositions. For example, we can define a function
to compute the dot product of two vectors of integers:

::

    def dotprod (xs: []i32) (ys: []i32): i32 =
      reduce (+) 0 (map2 (*) xs ys)

A close cousin of ``reduce`` is ``scan``, often called *generalised
prefix sum*. Where ``reduce`` produces just one result, ``scan``
produces one result for every prefix of the input array. This is
perhaps best understood with an example:

::

    scan (+) 0 [1,2,3] == [0+1, 0+1+2, 0+1+2+3] == [1, 3, 6]

Intuitively, the result of ``scan`` is an array of the results of
calling ``reduce`` on increasing prefixes of the input array. The last
element of the returned array is equivalent to the result of calling
``reduce``. Like with ``reduce``, the operator given to ``scan`` must
be associative and have a neutral element.

There are two main ways to compute scans: *exclusive* and *inclusive*.
The difference is that the empty prefix is considered in an exclusive
scan, but not in an inclusive scan. Computing the exclusive ``+``-scan
of ``[1,2,3]`` thus gives ``[0,1,3]``, while the inclusive
``+``-scan is ``[1,3,6]``. The ``scan`` in Futhark is inclusive, but
it is easy to generate a corresponding exclusive scan simply by
prepending the neutral element and removing the last element.

While the idea behind ``reduce`` is probably familiar, ``scan`` is a
little more esoteric, and mostly has applications for handling
problems that do not seem parallel at first glance. Several examples
are discussed in the following chapters.

Filtering
~~~~~~~~~

We have seen ``map``, which permits us to change all the elements of
an array, and we have seen ``reduce``, which lets us collapse all the
elements of an array.  But we still need something that lets us remove
some, but not all, of the elements of an array. This SOAC is
``filter``, which keeps only those elements of an array that satisfy
some predicate.

::

    > filter (<3) [1,5,2,3,4]
    [1i32, 2i32]

The use of ``filter`` is mostly straightforward, but there are some
patterns that may appear subtle at first glance. For example, how do
we find the *indices* of all nonzero entries in an array of integers?
Finding the values is simple enough:

::

    > filter (!=0) [0,5,2,0,1]
    [5i32, 2i32, 1i32]

But what are the corresponding indices? We can solve this using a
combination of ``indices``, ``zip``, ``filter``, and ``unzip``:

::

    > def indices_of_nonzero (xs: []i32): []i32 =
        let xs_and_is = zip xs (indices xs)
        let xs_and_is' = filter (\(x,_) -> x != 0) xs_and_is
        let (_, is') = unzip xs_and_is'
        in is'
    > indices_of_nonzero [1, 0, -2, 4, 0, 0]
    [0i32, 2i32, 3i32]

Be aware that ``filter`` is a somewhat expensive SOAC, corresponding
roughly to a ``scan`` plus a ``map``.

The expression ``indices xs`` gives us an array of the same size as
``xs``, whose elements are the indices of ``xs`` starting at 0::

  > indices [5,3,1]
  [0i32, 1i32, 2i32]


.. _size-types:

Size Types
----------

Functions on arrays typically impose constraints on the shape of their
parameters, and often the shape of the result depends on the shape of
the parameters.  Futhark has direct support for expressing simple
instances of such constraints in the type system.  Size types have an
impact on almost all other language features, so even though this
section will introduce the most important concepts, features, and
restrictions, the interactions with other features, such as parametric
polymorphism, will be discussed when those features are introduced.

As a simple example, consider a function that packs a single ``i32``
value in an array::

    def singleton (x: i32): [1]i32 = [x]

We explicitly annotate the return type to state that this function
returns a single-element array.  Even if we did not add this
annotation, the compiler would infer it for us.

For expressing constraints among the sizes of the parameters, Futhark
provides *size parameters*. Consider the definition of dot product we
have used so far::

    def dotprod (xs: []i32) (ys: []i32): i32 =
      reduce (+) 0 (map2 (*) xs ys)

The ``dotprod`` function assumes that the two input arrays have the
same size, or else the ``map2`` will fail. However, this constraint is
not visible in the written type of the function (although it will have
been inferred). Size parameters allow us to make this explicit::

    def dotprod [n] (xs: [n]i32) (ys: [n]i32): i32 =
      reduce (+) 0 (map2 (*) xs ys)

The ``[n]`` preceding the *value parameters* (``xs`` and ``ys``) is
called a *size parameter*, which lets us assign a name to the dimensions
of the value parameters. A size parameter must be used at least once in
the type of a value parameter, so that a concrete value for the size
parameter can be determined at runtime. Size parameters are *implicit*,
and need not an explicit argument when the function is called. For
example, the ``dotprod`` function can be used as follows::

    > dotprod [1,2] [3,4]
    11i32

As with ``singleton``, even if we did not explicitly add a size
parameter, the compiler would still automatically infer its existence
(*any* array must have a size), and furthermore infer that ``xs`` and
``ys`` must have the *same* size, as they are passed to ``map2``.

A size parameter is in scope in both the body of a function and its
return type, which we can use, for instance, for defining a function
for computing averages::

    def average [n] (xs: [n]f64): f64 =
      reduce (+) 0 xs / r64 n

Size parameters are always of type ``i64``, and in fact, *any*
``i64``-typed variable in scope can be used as a size annotation. This feature
lets us define a function that replicates an integer some number of
times::

    def replicate_i32 (n: i64) (x: i32): [n]i64 =
      map (\_ -> x) (0..<n)

In :numref:`polymorphism` we will see how to write a polymorphic
``replicate`` function that works for any type.

As a more complicated example of using size parameters, consider
multiplying two matrices ``x`` and ``y``.  This is only permitted if
the number of columns in ``x`` equals the number of rows in ``y``.  In
Futhark, we can encode this as follows::

    def matmult [n][m][p] (x: [n][m]i32, y: [m][p]i32): [n][p]i32 =
      map (\xr -> map (dotprod xr) (transpose y)) x

Three sizes are involved, ``n``, ``m``, and ``p``.  We indicate that
the number of columns in ``x`` must match the number of columns in
``y``, and that the size of the returned matrix has the same number of
rows as ``x``, and the same number of columns as ``y``.

Presently, only variables and constants are legal as size annotations.
This restriction means that the following function definition is not
valid::

    def dup [n] (xs: [n]i32): [2*n]i32 =
      map (\i -> xs[i/2]) (0..<n*2)

Instead, we will have to write it as::

    def dup [n] (xs: [n]i32): []i32 =
      map (\i -> xs[i/2]) (0..<n*2)

``dup`` is an instance of a function whose return size is *not*
equal to the size of one of its inputs.  You have seen such functions
before - the most interesting being ``filter``.  When we apply a
function that returns an array with such an *anonymous* size, the type
checker will invent a new name (called a *size variable*) to stand in
for the statically unknown size.  This size variable will be different
from any other size in the program.  For example, the following
expression would not type check::

  [1]> zip (dup [1,2,3]) (dup [3,2,1])
  Error at [1]> :1:24-41:
  Dimensions "ret₇" and "ret₁₂" do not match.

  Note: "ret₇" is unknown size returned by "doubleup" at 1:6-21.

  Note: "ret₁₂" is unknown size returned by "doubleup" at 1:25-40.

Even though *we* know that the two applications of ``dup`` will
have the same size at run-time, the type checker assumes that each
application will produce a distinct size.  However, the following
works::

  let xs = dup [1,2,3] in zip xs xs

Size types have an escape hatch in the form of *size coercions*, which
allow us to change the size of an array to an arbitrary new size, with
a run-time check that the two sizes are actually equivalent.  This
allows us to force the previous example to type check::

  > zip (dup [1,2,3] :> [6]i32) (dup [3,2,1] :> [6]i32)
  [(1i32, 3i32), (1i32, 3i32), (2i32, 2i32),
   (2i32, 2i32), (3i32, 1i32), (3i32, 1i32)]

The expression ``e :> t`` can be seen as a kind of "dynamic cast" to
the desired array type.  The element type and dimensionality must be
unchanged - only the size is allowed to differ.

.. admonition:: Exercise: Why two coercions?
   :class: exercise

   Do we need *two* size coercions?  Would ``zip (dup [1,2,3]) (dup
   [3,2,1] :> [6]i32)`` be sufficient?

   .. only:: html

   .. admonition:: Solution (click to show)
      :class: solution

      *No*.  Each call to ``dup`` produces a *distinct* size that is
      different from *all* other sizes (in type theory jargon, it is
      "rigid"), which implies it is not equal to the specific size
      ``6``.

.. admonition:: Exercise: implement ``i32_indices``
   :class: exercise

   Using size parameters, and the knowledge that ``0..<x`` produces an
   array of size ``x``, implement a function ``i32_indices`` that
   works as ``indices``, except that the input array must have
   elements of type ``i32``?  (If you have read ahead to
   :ref:`polymorphism`, feel free to make it polymorphic as well.)


   .. only:: html

   .. admonition:: Solution (click to show)
      :class: solution

      ::

         def i32_indices [n] (xs: [n]i32) : [n]i64 =
           0..<n

Sizes and type abbreviations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Size parameters are also permitted in type abbreviations. As an example,
consider a type abbreviation for a vector of integers::

    type intvec [n] = [n]i32

We can now use ``intvec [n]`` to refer to integer vectors of size ``n``::

    def x: intvec [3] = [1,2,3]

A type parameter can be used multiple times on the right-hand side of
the definition; perhaps to define an abbreviation for square matrices::

    type sqmat [n] = [n][n]i32

The brackets surrounding ``[n]`` and ``[3]`` are part of the notation,
not the parameter itself, and are used for disambiguating size
parameters from the *type parameters* we shall discuss in
:numref:`polymorphism`.

Parametric types must always be fully applied. Using ``intvec`` by
itself (without a size argument) is an error.

The definition of a type abbreviation must not contain any anonymous
sizes.  This is illegal::

  type vec = []i32

If this was allowed, then we could write a type such as ``[2]vec``,
which would hide the fact that there is an inner size, and thus
subvert the restriction to regular arrays.  If for some reason we *do*
wish to hide inner types, we can define a *size-lifted* type with the
``type~`` keyword::

  type~ vec = []i32

This is convenient when we want it to be an implementation detail that
the type may contain an array (and is most useful after we introduce
abstract types in :numref:`modules`).  Size-lifted types come with a
serious restriction: they may not be array elements.  If we write down
the type ``[2]vec``, the compiler will complain.  Ordinary type
abbreviations, defined with ``type``, will sometimes be called
*non-lifted types*.  This distinction is not very important for type
abbreviations, but becomes more important when we discuss polymorphism
in :numref:`polymorphism`.

.. _causality:

The causality restriction
~~~~~~~~~~~~~~~~~~~~~~~~~

Anonymous sizes have subtle interactions with size inference, which
leads to some non-obvious restrictions.  This is a relatively advanced
topic that will not show up in simple programs, so you can skip this
section for now and come back to it later.

To see the problem, consider the following function definition::

  def f (b: bool) (xs: []i32) =
    let a = [] : [][]i32
    let b = [filter (>0) xs]
    in a[0] == b[0]

The comparison on the last line forces the row size of ``a`` and ``b``
to be the same, let's say ``n``.  Further, while the empty array
literal can be given any row size, that ``n`` must be the size of
whatever array is produced by the ``filter``.  But now we have a
problem: *constructing* the empty array requires us to know the
specific value of ``n``, but it is not computed until later!  This is
called a *causality violation*: we need a value before it is
available.

This particular case is trivial, and can be fixed by flipping the
order in which ``a`` and ``b`` are bound, but the ultimate purpose of
the *causality restriction* is to ensure that the program does not
contain circular dependencies on sizes.  To make the rules simpler,
causality checking uses a specified evaluation order to determine that
a size is always *computed* before it is *used*.  The evaluation order
is mostly intuitive:

1. Function arguments are evaluated before function values.

2. For ``let``-bindings, the bound expression is evaluated before the body.

3. For binary operators, the left operand is evaluated before the
   right operand.

Since Futhark is a pure language, this evaluation order does not have
any effect on the result of programs, and may differ from what
actually happens at runtime.  It is used merely as a piece of type
checking fiction to ensure that *some* straightforward evaluation
order exists, where all anonymous sizes have been computed before
their value is needed.

We will see a more realistic example of the impact of the causality
restriction in :numref:`causality-and-piping`, when we get to
higher-order functions.

.. _records:

Records
-------

Semantically, a record is a finite map from labels to values. These are
supported by Futhark as a convenient syntactic extension on top of
tuples. A label-value pairing is often called a *field*. As an example,
let us return to our previous definition of complex numbers:

::

    type complex = (f64, f64)

We can make the role of the two floats clear by using a record instead.

::

    type complex = {re: f64, im: f64}

We can construct values of a record type with a *record expression*, which
consists of field assignments enclosed in curly braces:

::

    def sqrt_minus_one = {re = 0.0, im = -1.0}

The order of the fields in a record type or value does not matter, so
the following definition is equivalent to the one above:

::

    def sqrt_minus_one = {im = -1.0, re = 0.0}

In contrast to most other programming languages, record types in Futhark
are *structural*, not *nominal*. This means that the name (if any) of a
record type does not matter. For example, we can define a type
abbreviation that is equivalent to the previous definition of
``complex``:

::

    type another_complex = {re: f64, im: f64}

The types ``complex`` and ``another_complex`` are entirely
interchangeable. In fact, we do not need to name record types at all;
they can be used anonymously:

::

    def sqrt_minus_one: {re: f64, im: f64} = {re = 0.0, im = -1.0}

However, for readability purposes it is usually a good idea to use type
abbreviations when working with records.

There are two ways to access the fields of records. The first is by
*field projection*, which is done by dot notation known from most other
programming languages. To access the ``re`` field of the
``sqrt_minus_one`` value defined above, we write ``sqrt_minus_one.re``.

The second way of accessing field values is by pattern matching, just
like we do with tuples. A record pattern is similar to a record
expression, and consists of field patterns enclosed in curly braces. For
example, a function for adding complex numbers could be defined as::

    def complex_add ({re = x_re, im = x_im}: complex)
                    ({re = y_re, im = y_im}: complex)
                  : complex =
      {re = x_re + y_re, im = x_im + y_im}

As with tuple patterns, we can use record patterns in both function
parameters, ``let``-bindings, and ``loop`` parameters.

As a special syntactic convenience, we can elide the ``= pat`` part of a
record pattern, which will bind the value of the field to a variable of
the same name as the field. For example::

    def conj ({re, im}: complex): complex =
      {re = re, im = -im}

This convenience is also present in tuple expressions. If we elide the
definition of a field, the value will be taken from the variable in
scope with the same name::

    def conj ({re, im}: complex): complex =
      {re, im = -im}

Tuples as a Special Case of Records
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In Futhark, tuples are merely records with numeric labels starting from
0. For example, the types ``(i32,f64)`` and ``{0:i32,1:f64}`` are
indistinguishable. The main utility of this equivalence is that we can
use field projection to access the components of tuples, rather than
using a pattern in a ``let``-binding. For example, we can say ``foo.0``
to extract the first component of a tuple.

Notice that the fields of a record must constitute a prefix of the
positive numbers for it to be considered a tuple. The record type
``{0:i32,2:f64}`` does not correspond to a tuple, and neither does
``{1:i32,2:f64}`` (but ``{1:f64,0:i32}`` is equivalent to the tuple
``(i32,f64)``, because field order does not matter).

.. _polymorphism:

Parametric Polymorphism
-----------------------

Consider the replication function we wrote earlier::

    def replicate_i32 (n: i64) (x: i32): [n]i32 =
      map (\_ -> x) (0..<n)

This function works only for replicating values of type ``i32``.  If
we wanted to replicate, say, a boolean value, we would have to write another
function::

    def replicate_bool (n: i64) (x: bool): [n]bool =
      map (\_ -> x) (0..<n)

This duplication is not particularly nice.  Since the only difference
between the two functions is the type of the ``x`` parameter, and we
don't actually use any ``i32``-specific operations in
``replicate_i32``, or ``bool``-specific operations in
``replicate_bool``, we ought to be able to write a single function
that is *parameterised* over the element type.  In some languages,
this is done with *generics*, or *template functions*.  In ML-derived
languages, including Futhark, we use *parametric polymorphism*.  Just
like the size parameters we saw earlier, a Futhark function may have
*type parameters*.  These are written as a name preceded by an
apostrophe.  As an example, this is a polymorphic version of
``replicate``::

    def replicate 't (n: i64) (x: t): [n]t =
      map (\_ -> x) (0..<n)

Notice how the type parameter binding is written as ``'t``; we use just
``t`` to refer to the parametric type in the ``x`` parameter and the
function return type.  Type parameters may be freely intermixed with
size parameters, but must precede all ordinary parameters.  Just as
with size parameters, we do not need to explicitly pass the types when
we call a polymorphic function; they are automatically deduced from
the concrete parameters.

We can also use type parameters when defining type abbreviations::

    type triple 't = [3]t

And of course, these can be intermixed with size parameters::

    type vector 't [n] = [n]t

In contrast to function definitions, the order of parameters in a type
*does* matter.  Hence, ``vector i32 [3]`` is correct, and ``vector [3]
i32`` would produce an error.

We might try to use parametric types to further refine our previous
definition of complex numbers, by making it polymorphic in the
representation of scalar numbers::

    type complex 't = {re: t, im: t}

This type abbreviation is fine, but we will find it difficult to write
useful functions with it.  Consider an attempt to define complex
addition::

    def complex_add 't ({re = x_re, im = x_im}: complex t)
                       ({re = y_re, im = y_im}: complex t)
                  : complex t =
      {re = ?, im = ?}

How do we perform an addition ``x_re`` and ``y_re``?  These are both
of type ``t``, of which we know nothing.  For all we know, they might
be instantiated to something that is not numeric at all.  Hence, the
Futhark compiler will prevent us from using the ``+`` operator.  In
some languages, such as Haskell, facilities such as *type classes* may be used to
support a notion of restricted polymorphism, where we can require that an
instantiation of a type variable supports certain operations (like
``+``).  Futhark does not have type classes, but it does support
programming with certain kinds of higher-order functions and it does
have a powerful module system. The support for higher-order functions
in Futhark and the module system are the subjects of the following
sections.

.. _higher-order-functions:

Higher-Order Functions
----------------------

Futhark supports certain kinds of higher-order functions. For
performance reasons, certain restrictions apply, which means that
Futhark can eliminate higher-order functions at compile time through a
technique called *defunctionalisation* :cite:`hovgaard18thesis,tfp18hovgaard`. From
a programmer's point-of-view, the main restrictions are the following:

1. Functions may not be stored inside arrays.
2. Functions may not be returned from branches in conditional
   expressions.
3. Functions are not allowed in loop parameters.

Whereas these restrictions seem daunting, functions may still be
grouped in records and tuples and such structures may be passed to
functions and even returned by functions. In effect, quite a few
functional design patterns may be applied, ranging from defining
polymorphic higher-order functions, for the purpose of obtaining a
high degree of abstraction and code reuse (e.g., for defining program
libraries), to specific uses of higher-order functions for
representing various concepts as functions. Examples of such uses
include a library for type-indexed compact serialisation (and
deserialisation) of Futhark values
:cite:`tfp05elsman,functional-pearl-pickler-combinators` and encoding
of Conal Elliott's functional images :cite:`Elliott03:FOP`.

We have seen earlier how anonymous functions may be constructed and
passed as arguments to SOACs. Here is an example anonymous function
that takes parameters ``x``, ``y``, and ``z``, returns a value of type ``t``, and
has body `e`:

::

    \x y z: t -> e

Futhark allows for the programmer to specify so-called *sections*,
which provide a way to form implicit eta-expansions of partially
applied operations. Sections are encapsulated in parentheses. Assuming
``binop`` is a binary operator, such as ``+``, the section ``(binop)``
is equivalent to the expression ``\x y -> x binop y``. Similarly, the
section ``(x binop)`` is equivalent to the expression ``\y -> x binop
y`` and the section ``(binop y)`` is equivalent to the expression ``\x
-> x binop y``.

For making it easy to select fields from records (and tuples), a
select-section may be used. An example is the section ``(.a.b.c)``,
which is equivalent to the expression ``\y -> y.a.b.c``. Similarly,
the example section ``(.[i])``, for indexing into an array, is
equivalent to the expression ``\y -> y[i]``.

At a high level, Futhark functions are values, which can be used as
any other values. However, to ensure that the Futhark compiler is able
to compile the higher-order functions efficiently via
defunctionalisation, certain type-driven restrictions exist on how
functions can be used, as described earlier. Moreover, for Futhark to
support higher-order polymorphic functions, type variables, when
bound, are divided into non-lifted (bound with an apostrophe,
e.g. ``'t``), and lifted (bound with an apostrophe and a hat,
e.g. ``'^t``). Only lifted type parameters may be instantiated with a
functional type. Within a function, a lifted type parameter is treated
as a functional type. All abstract types declared in modules (see
:numref:`modules`) are considered non-lifted, and may not be functional.

Uniqueness typing (see :numref:`in-place-updates`) generally interacts
poorly with higher-order functions. The issue is that there is no way
to express, in the type of a function, how many times a function
argument is applied, or to what, which means that it will not be safe
to pass a function that consumes its argument. The following two
conservative rules govern the interaction between uniqueness types and
higher-order functions:

1. In the expression ``let p = e in ...``, if any in-place update
   takes place in the expression ``e``, the value bound by ``p`` must
   not be or contain a function.
2. A function that consumes one of its arguments may not be passed as
   a higher-order argument to another function.

A number of higher-order utility functions are available at
top-level. Amongst these are the following quite useful functions:

::

    val const '^a '^b  : a -> b -> a          -- constant function
    val id    '^a      : a -> a               -- identity function
    val |>    '^a '^b  : a -> (a -> b) -> b   -- pipe right
    val <|    '^a '^b  : (a -> b) -> a -> b   -- pipe left

    val >->     '^a '^b '^c : (a -> b) -> (b -> c) -> a -> c
    val <-<     '^a '^b '^c : (b -> c) -> (a -> b) -> a -> c

    val curry   '^a '^b '^c : ((a,b) -> c) -> a -> b -> c
    val uncurry '^a '^b '^c : (a -> b -> c) -> (a,b) -> c

.. _causality-and-piping:

Causality and piping
~~~~~~~~~~~~~~~~~~~~

The causality restriction discussed in :numref:`causality` has
significant interaction with higher-order functions, particularly the
pipe operators.  Programmers familiar with other languages, in
particular Haskell, may wish to use the ``<|`` operator frequently,
due to its similarity to Haskell's ``$`` operator.  Unfortunately, it
has pitfalls due to causality.  Consider this expression::

  length <| filter (>0) [1,-2,3]

This is a causality violation.  The reason is that ``length`` has the
following type scheme::

  val length [n] 't : [n]t -> i64

This means that whenever we use ``length``, the type checker must
*instantiate* the size variable ``n`` with some specific size, which
must be *available* at the place ``length`` itself occurs.  In the
expression above, this specific size is whatever anonymous size
variable the ``filter`` application produces.  However, since the rule
for binary operators is left-to-right evaluation, ``length`` function
is instantiated (but not applied!) *before* the ``filter`` runs.  The
distinction between *instantiation*, which is when a polymorphic value
is given its concrete type, and *application*, which is when a
function is provided with an argument, is crucial here.  The end
result is that the compiler will complain::

  > length <| filter (>0) [1,-2,3]
  Error at [1]> :1:1-6:
  Causality check: size "ret₁₁" needed for type of "length":
    [ret₁₁]i32 -> i64
  But "ret₁₁" is computed at 1:11-30.
  Hint: Bind the expression producing "ret₁₁" with 'let' beforehand.

The compiler suggests binding the ``filter`` expression with a
``let``, which forces it to be evaluated first, but there are neater
solutions in this case.  For example, we can exploit that function
arguments are evaluated before function is instantiated::

  > length (filter (>0) [1,-2,3])
  2i64

Or we can use the left-to-right piping operator::

  > filter (>0) [1,-2,3] |> length
  2i64

.. _sequential-loops:

Sequential Loops
----------------

Futhark does not directly support recursive functions, but instead
provides syntactical sugar for expressing the equivalent of certain
tail-recursive functions. Consider the following hypothetical
tail-recursive formulation of a function for computing the Fibonacci
numbers

::

    def fibhelper(x: i32, y: i32, n: i32): i32 =
      if n == 1 then x else fibhelper(y, x+y, n-1)

    def fib(n: i32): i32 = fibhelper(1,1,n)

We cannot write this directly in Futhark, but we can express the same
idea using the ``loop`` construct:

::

    def fib(n: i32): i32 =
      let (x, _) = loop (x, y) = (1,1) for i < n do (y, x+y)
      in x

The semantics of this loop is precisely as in the tail-recursive
function formulation. In general, a loop

::

    loop pat = initial for i < bound do loopbody

has the following semantics:

#. Bind ``pat`` to the initial values given in ``initial``.

#. Bind ``i`` to 0.

#. While ``i < bound``, evaluate ``loopbody``, rebinding ``pat`` to be
   the value returned by the body. At the end of each iteration,
   increment ``i`` by one.

#. Return the final value of ``pat``.

Semantically, a loop-expression is completely equivalent to a call to its
corresponding tail-recursive function.

For example, denoting by ``t`` the type of ``x``, the loop

::

    loop x = a for i < n do
      g(x)

has the semantics of a call to the following tail-recursive function:

::

    def f(i: i32, n: i32, x: t): t =
      if i >= n then x
      else f(i+1, n, g(x))

    -- the call
    let x = f(i, n, a)
    in body

The syntax shown above is actually just syntactical sugar for a common
special case of a *for-in* loop over an integer range, which is written
as:

::

    loop pat = initial for xpat in xs do loopbody

Here, ``xpat`` is an arbitrary pattern that matches an element of the
array ``xs``. For example:

::

    loop acc = 0 for (x,y) in zip xs ys do
      acc + x * y

The purpose of the loop syntax is partly to render some sequential computations slightly
more convenient, but primarily to express certain very specific forms of
recursive functions, specifically those with a fixed iteration count.
This property is used for analysis and optimisation by the Futhark
compiler. In contrast to most functional languages, Futhark does not
properly support recursion, and users are therefore required to use the loop syntax
for sequential loops.

Apart from ``for``-loops, Futhark also supports ``while``-loops. These loops
do not provide as much information to the compiler, but can be used
for convergence loops, where the number of iterations cannot be
predicted in advance. For example, the following program doubles a
given number until it exceeds a given threshold value:

::

    def main (x: i32, bound: i32): i32 =
      loop x while x < bound do x * 2

In all respects other than termination criteria, ``while``-loops
behave identically to ``for``-loops.

For brevity, the initial value expression can be elided, in which case
an expression equivalent to the pattern is implied. This feature is
easier to understand with an example. The loop

::

    def fib (n: i32): i32 =
      let x = 1
      let y = 1
      let (x, _) = loop (x, y) = (x, y) for i < n do (y, x+y)
      in x

can also be written:

::

    def fib (n: i32): i32 =
      let x = 1
      let y = 1
      let (x, _) = loop (x, y) for i < n do (y, x+y)
      in x

This style of code can sometimes make imperative code look more natural.

.. admonition:: Note: Type-checking with ``futhark repl``

   If you are uncertain about the type of some Futhark expression, the
   ``:type`` command (or ``:t`` for short) can help.  For example::

     > :t 2
     2 : i32

     > :t (+2)
     (+ 2) : i32 -> i32

   You will also be informed if the expression is ill-typed::

     [1]> :t true : i32
     Error at [1]> :1:1-1:10:
     Couldn't match expected type `i32' with actual type `bool'.
     When matching type
       i32
     with
       bool

.. _in-place-updates:

In-Place Updates
----------------

While Futhark is an uncompromisingly pure functional language, it may
occasionally prove useful to express certain algorithms in an
imperative style. Consider a function for computing the :math:`n`
first Fibonacci numbers:

::

    def fib (n: i64): [n]i32 =
      -- Create "empty" array.
      let arr = replicate n 1
      -- Fill array with Fibonacci numbers.
      in loop (arr) for i < n-2 do
           arr with [i+2] = arr[i] + arr[i+1]

The notation ``arr with [i+2] = arr[i] + arr[i+1]`` produces an array
equivalent to ``arr``, but with a new value for the element at
position ``i+2``.  A shorthand syntax is available for the common
case where we immediately bind the array to a variable of the same
name::

  let arr = arr with [i+2] = arr[i] + arr[i+1]

  -- Can be shortened to:

  let arr[i+2] = arr[i] + arr[i+1]

If the array ``arr`` were to be copied for each iteration of the loop,
we would spend a lot of time moving around data, even though it is
clear in this case that the ”old” value of ``arr`` will never be used
again. Precisely, what should be an algorithm with complexity
:math:`O(n)` would become :math:`O(n^2)`, due to copying the size
:math:`n` array (an :math:`O(n)` operation) for each of the :math:`n`
iterations of the loop.

To prevent this copying, Futhark updates the array *in-place*, that
is, with a static guarantee that the operation will not require any
additional memory allocation, or copying the array. An *in-place
update* can modify the array in time proportional to the elements
being updated (:math:`O(1)` in the case of the Fibonacci function),
rather than time proportional to the size of the final array, as would
the case if we perform a copy. In order to perform the update without
violating referential transparency, Futhark must know that no other
references to the array exists, or at least that such references will
not be used on any execution path following the in-place update.

In Futhark, this is done through a type system feature called
*uniqueness types*, similar to, although simpler than, the uniqueness
types of the programming language Clean.  Alongside a (relatively)
simple aliasing analysis in the type checker, this extension is sufficient to
determine at compile time whether an in-place modification is safe,
and signal a compile time error if in-place updates are used in a way
where safety cannot be guaranteed.

The simplest way to introduce uniqueness types is through examples. To
that end, let us consider the following function definition.

::

    def modify (a: *[]i32) (i: i64) (x: i32): *[]i32 =
      a with [i] = a[i] + x

The function call ``modify a i x`` returns :math:`a`, but where the
element at index ``i`` has been increased by :math:`x`. Notice the
asterisks: in the parameter declaration ``(a: *[i32])``, the asterisk
means that the function ``modify`` has been given “ownership” of the
array :math:`a`, meaning that any caller of ``modify`` will never
reference array :math:`a` after the call again. In particular,
``modify`` can change the element at index ``i`` without first copying
the array, i.e.  ``modify`` is free to do an in-place
modification. Furthermore, the return value of ``modify`` is also
unique - this means that the result of the call to ``modify`` does not
share elements with any other visible variables.

Let us consider a call to ``modify``, which might look as follows.

::

    let b = modify a i x

Under which circumstances is this call valid? Two things must hold:

#. The type of ``a`` must be ``*[]i32``, of course.

#. Neither ``a`` or any variable that *aliases* ``a`` may be used on any
   execution path following the call to ``modify``.

When a value is passed as a unique-typed argument in a function call, we
say that the value is *consumed*, and neither it nor any of its
*aliases* (see below) can be used again. Otherwise, we would break the
contract that gives the function liberty to manipulate the argument
however it wants. Notice that it is the type in the argument declaration
that must be unique - it is permissible to pass a unique-typed variable
as a non-unique argument (that is, a unique type is a subtype of the
corresponding nonunique type).

A variable :math:`v` aliases :math:`a` if they may share some elements,
for instance by an overlap in memory. As the most trivial case, after evaluating the
binding ``b = a``, the variable ``b`` will alias ``a``. As another
example, if we extract a row from a two-dimensional array, the row will
alias its source:

::

    let b = a[0] -- b is aliased to a
                 -- (assuming a is not one-dimensional)

Most array combinators produce fresh arrays that initially alias no
other arrays in the program. In particular, the result of ``map f a``
does not alias ``a``. One exception is array slicing, where the result
is aliased to the original array.

Let us consider the definition of a function returning a unique array::

  def f(a: []i32): *[]i32 = e

Notice that the argument, ``a``, is non-unique, and hence we cannot modify
it inside the function. There is another restriction as well: ``a`` must
not be aliased to our return value, as the uniqueness contract requires
us to ensure that there are no other references to the unique return
value. This requirement would be violated if we permitted the return
value in a unique-returning function to alias its (non-unique)
parameters.

To summarise: *values are consumed by being the source in a in-place
binding, or by being passed as a unique parameter in a function
call*. We can crystallise valid usage in the form of three principal
rules:

**Uniqueness Rule 1**
    When a value is consumed — for example, by being passed in the place
    of a unique parameter in a function call, or used as the source in a
    in-place expression, neither that value, nor any value that aliases
    it, may be used on any execution path following the function call. A
    violation of this rule is as follows::

      let b = a with [i] = 2 -- Consumes 'a'
      in f(b,a) -- Error: a used after being consumed


**Uniqueness Rule 2**
    If a function definition is declared to return a unique value, the
    return value (that is, the result of the body of the function) must
    not share memory with any non-unique arguments to the function. As a
    consequence, at the time of execution, the result of a call to the
    function is the only reference to that value. A violation of this
    rule is as follows::

      def broken (a: [][]i32, i: i64): *[]i32 =
        a[i] -- Error: Return value aliased with 'a'.

**Uniqueness Rule 3**
    If a function call yields a unique return value, the caller has
    exclusive access to that value. At *the point the call returns*, the
    return value may not share memory with any variable used in any
    execution path following the function call. This rule is
    particularly subtle, but can be considered a rephrasing of
    Uniqueness Rule 2 from the “calling side”.

It is worth emphasising that everything related to uniqueness types is
implemented as a static analysis. *All* violations of the uniqueness
rules will be discovered at compile time (during type-checking), leaving
the code generator and runtime system at liberty to exploit them for
low-level optimisation.

When To Use In-Place Updates
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you are used to programming in impure languages, in-place updates
may seem a natural and convenient tool that you may use
frequently. However, Futhark is a functional array language, and
should be used as such.  In-place updates are restricted to simple
cases that the compiler is able to analyze, and should only be used
when absolutely necessary. Most Futhark programs are written without
making use of in-place updates at all.

Typically, we use in-place updates to efficiently express sequential
algorithms that are then mapped on some array. Somewhat
counter-intuitively, however, in-place updates can also be used for
expressing irregular nested parallel algorithms (which are otherwise
not expressible in Futhark), albeit in a low-level way. The key here
is the array combinator ``scatter``, which writes to several positions
in an array in parallel. Suppose we have an array ``is`` of type
``[n]i32``, an array ``vs`` of type ``[n]t`` (for some ``t``), and an
array ``as`` of type ``[m]t``. Then the expression ``scatter as is
vs`` morally computes

.. code-block:: none

      for i in 0..n-1:
        j = is[i]
        v = vs[i]
        if ( j >= 0 && j < length as )
	then { as[j] = v }
	else { }

and returns the modified ``as`` array. The old ``as`` array is marked
as consumed and may not be used anymore. Notice that writing outside
the index domain of the target array has no effect.

Moreover, identical indices in ``is`` (that are valid indices into the
target array) are required to map to identical values; otherwise, the
result is unspecified.  In particular, it is not guaranteed that one
of the duplicate writes will complete atomically; they may be
interleaved. Futhark features a function, called ``reduce_by_index``
(a generalised histogram operation), which can handle this case
deterministically.  The parallel ``scatter`` operation can be used,
for instance, to implement efficiently the radix sort algorithm, as
demonstrated in :numref:`radixsort`.

.. _modules:

Modules
-------

When most programmers think of module systems, they think of rather
utilitarian systems for namespace control and splitting programs
across multiple files. And in most languages, the module system is
indeed little more than this. But in Futhark, we have adopted an
ML-style higher-order module system that permits *abstraction* over
modules :cite:`Elsman:2018:SIH:3243631.3236792`. The module system is
not just a method for organising Futhark programs, it is also a
powerful facility for writing generic code. Most importantly, all
module language constructs are eliminated from the program at compile
time, using a technique called static interpretation
:cite:`elsman99,Annenkov:phdthesis`. As a consequence, from a
programmer's perspective, there is no overhead involved with making
use of module language features.

Simple Modules
~~~~~~~~~~~~~~

At the most basic level, a *module* (called a *structure* in Standard ML)
is merely a collection of declarations

::

    module add_i32 = {
      type t = i32
      def add (x: t) (y: t): t = x + y
      def zero: t = 0
    }

Now, ``add_i32.t`` is an alias for the type ``i32``, and ``add_i32.add``
is a function that adds two values of type ``i32``. The only peculiar
thing about this notation is the equal sign before the opening brace.
The declaration above is actually a combination of a *module binding*

::

    module add_i32 = ...

and a *module expression*

::

    {
      type t = i32
      def add (x: t) (y: t): t = x + y
      def zero: t = 0
    }

In this case, the module expression encapsulates a number of
declarations enclosed in curly braces. In general, as the name
suggests, a module expression is an expression that returns a
module. A module expression is syntactically and conceptually distinct
from a regular value expression, but serves much the same purpose. The
module language is designed such that evaluation of a module
expression can always be done at compile time.

Apart from a sequence of declarations, a module expression can also be
merely the name of another module

::

    module foo = add_i32

Now every name defined in ``add_i32`` is also available in ``foo``. At
compile-time, only a single version of the ``add`` function is defined.

Module Types
~~~~~~~~~~~~

What we have seen so far is nothing more than a simple namespace
mechanism. The ML module system only becomes truly powerful once we
introduce module types and parametric modules (in Standard ML, these
are called *signatures* and *functors*).

A module type is the counterpart to a value type. It describes which
names are defined, and as what. We can define a module type that
describes ``add_i32``:

::

    module type i32_adder = {
      type t = i32
      val add : t -> t -> t
      val zero : t
    }

As with modules, we have the notion of a *module type expression*. In
this case, the module type expression is a sequence of *specifications* enclosed
in curly braces. A specification specifies how a name must be
defined: as a value (including functions) of some type, as a type
abbreviation, or as an abstract type (which we will return to later).

We can assert that some module implements a specific module type via a
*module type ascription*:

::

    module foo = add_i32 : i32_adder

Syntactic sugar lets us move the module type to the left of the equal
sign:

::

    module add_i32: i32_adder = {
      ...
    }

When we are ascribing a module with a module type, the module type
functions as a filter, removing anything not explicitly mentioned in the
module type:

::

    module bar = add_i32 : { type t = i32
                             val zero : t }

An attempt to access ``bar.add`` will result in a compilation error,
as the ascription has hidden it. This is known as an *opaque*
ascription, because it obscures anything not explicitly mentioned in
the module type. The module system in Standard ML supports both opaque
and *transparent* ascription, but in Futhark we support only opaque
ascription.  This example also demonstrates the use of an anonymous
module type.  Module types are structural (just like value types), and
are named only for convenience.

We can use type ascription with abstract types to hide the definition of
a type from the users of a module:

::

    module speeds: { type thing
                     val car : thing
                     val plane : thing
                     val futhark : thing
                     val speed : thing -> i32 } = {
      type thing = i32

      def car: thing = 0
      def plane: thing = 1
      def futhark: thing = 2

      def speed (x: thing): i32 =
        if      x == car     then 120
        else if x == plane   then 800
        else if x == futhark then 10001
        else                      0 -- will never happen
    }

The (anonymous) module type asserts that a distinct type ``thing``
must exist, but does not mention its definition. There is no way for a
user of the ``speeds`` module to do anything with a value of type
``speeds.thing`` apart from passing it to ``speeds.speed``. The
definition is entirely abstract. Furthermore, no values of type
``speeds.thing`` exists except those that are created by the ``speeds``
module.

.. _parametric-modules:

Parametric Modules
~~~~~~~~~~~~~~~~~~

While module types serve some purpose for namespace control and
abstraction, their most interesting use is in the definition of
parametric modules. A parametric module is conceptually equivalent to a
function. Where a function takes a value as input and produces a value,
a parametric module takes a module and produces a module. For example,
given a module type

::

    module type monoid = {
      type t
      val add : t -> t -> t
      val zero : t
    }

We can define a parametric module that accepts a module satisfying the
``monoid`` module type, and produces a module containing a function for
collapsing an array

::

    module sum (M: monoid) = {
      def sum (a: []M.t): M.t =
        reduce M.add M.zero a
    }

There is an implied assumption here, which is not captured by the type
system: The function ``add`` must be associative and have ``zero`` as
its neutral element. These constraints come from the parallel semantics
of ``reduce``, and the algebraic concept of a *monoid*. Notice that in
``monoid``, no definition is given of the type ``t``---we only assert
that there must be some type ``t``, and that certain operations are
defined for it.

We can use the parametric module ``sum`` as follows:

::

      module sum_i32 = sum add_i32

We can now refer to the function ``sum_i32.sum``, which has type
``[]i32 -> i32``. The type is only abstract inside the definition of the
parametric module. We can instantiate ``sum`` again with another module,
this time an anonymous module:

::

    module prod_f64 = sum {
      type t = f64
      def add (x: f64) (y: f64): f64 = x * y
      def zero: f64 = 1.0
    }

The function ``prod_f64.sum`` has type ``[]f64 -> f64``, and computes
the product of an array of numbers (we should probably have picked a
more generic name than ``sum`` for this function).

Operationally, each application of a parametric module results in its
definition being duplicated and references to the module parameter
replace by references to the concrete module argument. This is quite
similar to how C++ templates are implemented. Indeed, parametric modules
can be seen as a simplified variant with no specialisation, and with
module types to ensure rigid type checking. In C++, a template is
type-checked when it is instantiated, whereas a parametric module is
type-checked when it is defined.

Parametric modules, like other modules, can contain more than one
declaration. This feature is useful for giving related functionality a
common abstraction, for example to implement linear algebra operations
that are polymorphic over the type of scalars. The following example
uses an anonymous module type for the module parameter and the
``open`` declaration for bringing the names from a module into the
current scope:

::

      module linalg(M : {
        type scalar
        val zero : scalar
        val add : scalar -> scalar -> scalar
        val mul : scalar -> scalar -> scalar
      }) = {
        open M

        def dotprod [n] (xs: [n]scalar) (ys: [n]scalar)
          : scalar =
          reduce add zero (map2 mul xs ys)

        def matmul [n] [p] [m] (xss: [n][p]scalar)
                               (yss: [p][m]scalar)
          : [n][m]scalar =
          map (\xs -> map (dotprod xs) (transpose yss)) xss
      }

.. _other-files:

Importing other files
~~~~~~~~~~~~~~~~~~~~~

While Futhark's module system is not directly file-oriented, there is
still a close interaction.  You can access code in other files as
follows::

  import "module"

The above will include all non-``local`` top-level definitions from
``module.fut`` and make them available in the current Futhark
program.  The ``.fut`` extension is implied.

You can also include files from subdirectories:::

  import "path/to/a/file"

The above will include the file ``path/to/a/file.fut`` relative to the
including file.

If we are defining a top-level function (or any other top-level
construct) that we do not want to be visible outside the current file,
we can prefix it with ``local``::

  local def i_am_hidden x = x + 2

Qualified imports are possible, where a module is created for the
file:::

  module M = import "module"

In fact, a plain ``import "module"`` is equivalent to::

  local open import "module"

This declaration opens ``"module"`` in the current file, but does not
propagate its contents to modules that in turn ``import`` the current
file.
