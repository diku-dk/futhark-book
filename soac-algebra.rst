.. _soac-algebra:

Algebraic Properties of SOACs
=============================

We shall now discuss the general SOAC reasoning principles that lie
behind both the philosophy of programming with arrays in Futhark and
the techniques used for making Futhark programs run efficiently in
practice on parallel hardware such as GPUs. We shall discuss the
reasoning principles in terms of Futhark constructs but introduce a
few higher-order concepts that are important for the reasoning.

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

Now, given functions ``f:a->b`` and ``g:a->c``, the *second fusion rule*, :math:`F2`, which denotes horizontal
fusion, is given by the following equation:

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

Moderate Flattening
-------------------

The flattening rules that we shall introduce here allows the Futhark
compiler to generate parallel kernels for various code block
patterns. In contrast to the general concept of flattening as
introduced by Blelloch :cite:`blelloch1994implementation`, Futhark applies a technique called
*moderate flattening* :cite:`Henriksen:2017:FPF:3062341.3062354` that
does not cover arbitrary nested parallelism, but which covers well
many regular nested parallel patterns. We shall come back to the issue of
flattening irregular nested parallelism in
:ref:`segmentation-and-flattening`.

In essence, moderate flattening works by matching compositions of
fused constructs against a number of flattening rules, which we shall
describe in the following.

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

#. general reasoning principles

#. assumptions

#. fusion rules

#. list homomorphism theorem

#. let the compiler do the fusion (how to reason)

#. general reasoning principles

#. assumptions

#. fusion rules

#. list homomorphism theorem

#. let the compiler do the fusion (how to reason)
