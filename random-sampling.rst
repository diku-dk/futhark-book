.. _random-sampling:

Pseudo-Random Numbers and Monte Carlo Sampling Methods
======================================================

Pseudo-random number generation and Monte Carlo sampling are concepts
that apply to a large number of application areas. In a data-parallel
setting, these concepts require special treatment beyond the usual
sequential methods. In this chapter, we first present a Futhark
package, called ``cpprandom`` for generating pseudo-random numbers in
parallel. We then present a Futhark package, called ``sobol``, for
generating Sobol sequences, which are examples of so-called
low-discrepancy sequences, sequences that make numerical
multi-dimensional integration converge faster than if pseudo-random
numbers were used.

Generating Pseudo-Random Numbers
--------------------------------

The ``cpprandom`` package is inspired by the C++ library ``<random>``,
which is very elaborate, but also very flexible. Due to Futhark's
purity, it is up to the programmer to explicitly manage the state of
the pseudo-random number engine (the RNG state). In particular, it is
the programmer's responsibility to ensure that the same state is not
used more than once (unless that is what is desired).

The following program constructs a uniform distribution of single precision
floats using ``minstd_rand`` as the underlying RNG engine.

::

    module dist = uniform_real_distribution f32 minstd_rand

    let rng = minstd_rand.rng_from_seed [123]
    let (rng, x) = dist.rand (1,6) rng

The ``dist`` module is constructed at the program top level, while we
use it at the expression level.  We use the ``minstd_rand`` module for
initialising the random number state using a seed, and then we pass
that state to the ``rand`` function in the generated distribution
module, along with a description of the distribution we desire.  We
get back not just the random number, but also the new state of the
engine.

The ``dist.rand`` function, coming from ``uniform_real_distribution``,
simply takes a pair of numbers describing the range.  Consider instead the following code:

::

    module norm_dist = normal_distribution f32 minstd_rand

    let (rng, y) = norm_dist.rand {mean=50, stddev=25} rng

In contrast to ``dist.rand``, the ``norm_dist.rand`` function, coming
from ``normal_distribution`` takes a record specifying the mean and
the standard deviation. Since both ``dist`` and ``norm_dist`` have
been initialised with the same underlying ``rng_engine``, we can reuse
the same RNG state.  Such reuse is often convenient when a program
needs to generate random numbers from several different distributions,
as we still only have to manage a single RNG state.

Parallel random numbers
~~~~~~~~~~~~~~~~~~~~~~~

Random number generation is inherently sequential.  The ``rand``
functions take an RNG state as input and produce a new RNG state.
This dependence creates challenges when we wish to ``map`` a function
``f`` across some array ``xs``, and each application of the function
must produce some random numbers.  We generally don't want to pass the
exact same state to every application, as that means each element will
see the exact same stream of random numbers. The common procedure is
to use ``split_rng``, which creates any number of RNG states from one,
and then pass one to each application of ``f``:

::

    let rngs = minstd_rand.split_rng n rng
    let (rngs, ys) = unzip (map2 f rngs xs)
    let rng = minstd.rand.join_rng rngs

We assume here that the function ``f`` returns not just the result,
but also the new RNG state.  Generally, all functions that accept
random number states should behave like this.  We subsequently use
``join_rng`` to combine all resulting states back into a single state.
Thus, parallel programming with random numbers involves frequently
splitting and rejoining RNG states.  For most RNG engines, these
operations are generally very cheap.


Low-Discrepancy Sequences
-------------------------

The Futhark package ``sobol`` is a package for generating Sobol
sequences, which are examples of so-called *low-discrepancy
sequences*, sequences that, when combined with Monte-Carlo methods,
make numeric integration converge faster than if ordinary
pseudo-random numbers are used and are more flexible than if uniform
sampling techniques are used. Sobol sequences may be multi-dimensional
and a key property of using Sobol sequences is that we can freely
choose the number of points that should span the multi-dimensional
space. In contrast, if we set out to use a simpler uniform sampling
technique for spanning two dimensions, we can only span the space
properly if we choose the number of points to be on the form
:math:`x^2`, for some natural number :math:`x`. This spanning problem
becomes worse for higher dimensions.

As an example, we shall see how we can use Sobol sequences together
with Monte-Carlo simulation to compute the value of :math:`\pi`. We
shall also see that doing so will result in faster convergence towards
the true value of :math:`\pi` compared to if pseudo-random numbers are
used.

To calculate an approximation to the value of :math:`\pi`, we will use
a simple dart-throwing approach. We will throw darts at a 2 by 2
square, centered around the origin, and then establish the ratio
between the number of darts hitting within the unit circle with the
number of darts hitting the square. This ratio multiplied with 4 will
be our approximation of :math:`\pi`. The more darts we throw, the
better our approximation, assuming that the darts we throw hit the
board somewhat evenly. To calculate whether a particular dart, thrown
at the point :math:`(x,y)`, is within the unit circle, we can apply
the standard Pythagoras formula:

.. math::
   \pi ~~\approx~~ \frac{4}{N} \sum_{i=1}^N \left \{ \begin{array}{ll} 1 & \mbox{if} ~ x_i^2 + y_i^2 < 1 \\ 0 & \mbox{otherwise} \end{array} \right .

For the actual throwing of darts, we need to establish :math:`N` pairs
of numbers, each in the interval [-1;1]. Now, it turns out that it
matters significantly how we choose to throw the darts. Some obvious
choices would be to throw the darts in a regular grid (i.e., *uniform
sampling*), or to choose points using a pseudo-random number
generator.

The Futhark package makes essential use of an *independent formula*
for calculating, independently, the :math:`n`'th Sobol
number. However, even though such a formula is essential for achieving
parallelism, it performs poorly compared to the more efficient
*recurrent formula*, which makes it possible to calculate the
:math:`n`'th Sobol number if we know the previous Sobol number.  The
Futhark package makes essential use of both formulas. The calculation
of a sequence of Sobol numbers depends on a set of direction vectors,
which are also provided by the package.

The key functionality of the package comes in the form of a
higher-order module `Sobol`, which takes as arguments a direction
vector module and a module specifying the dimensionality of the
generated Sobol numbers:

::

    module type sobol_dir  = { ... }
    module sobol_dir       : sobol_dir  -- file sobol-dir-50, e.g.

    module type sobol = {
      val D : i32
      val norm : f64
      val independent : i32 -> [D]u32
      val recurrent   : i32 -> [D]u32 -> [D]u32
      val sobol       : (n: i32) -> [n][D]f64
    }
    module Sobol : (DM : sobol_dir) -> (X : { val D : i32 }) -> sobol

For estimating the value of :math:`\pi`, we will need a
two-dimensional Sobol sequence, thus we apply the `Sobol` higher-order
module to the direction vector module that works for up-to 50
dimensions and a module specifying a dimensionality of two:

.. literalinclude:: src/pi.fut
   :lines: 1-4

We can now complete the program by writing a `main` function that
computes an array of Sobol numbers of a size given by the parameter
given to `main` and feed this array into a function that will compute
the estimation of :math:`\pi` using the function shown above:

.. literalinclude:: src/pi.fut
   :lines: 6-17

The use of Sobol numbers for estimating :math:`\pi` turns out to be
about three times slower than using a uniform grid on a standard
GPU. However, it converges towards :math:`\pi` equally well (with
increasing :math:`N`) and is superior for larger dimensions
:cite:`futhark:fhpc18`. In general, there are other good reasons to
avoid uniform sampling in relation to Monte-Carlo methods.
