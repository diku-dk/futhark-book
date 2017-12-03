.. _soac-algebra:

Algebraic Properties of SOACs
=============================

We shall now discuss the general SOAC reasoning principles that lies
behind both the philosophy of programming with arrays in Futhark and
the techniques used for making Futhark programs run efficiently in
practice on parallel hardware such as GPUs. We shall discuss all the
reasoning principles in terms of Futhark constructs but introduce a
few higher-order concepts that are important for the reasoning.

Fusion
------

Fusion aims at reducing the overhead of unnecessary repeated
control-flow or unnecessary temporary storage.

The first higher-order concept that we shall need is the concept of
function composition. Whenever :math:`f` and :math:`g` denote some
Futhark functions :math:`\backslash{} x_1\cdots x_n~\texttt{->}~e` and
:math:`\backslash{} y_1\cdots y_m~\texttt{->}~e'`, respectively, the
*composition* of :math:`f` and :math:`g`, written as :math:`(f \circ
g)`, is defined as :math:`\backslash y_1\cdots
y_m~\texttt{->}~\texttt{let}~(x_1,\cdots,x_n)~\texttt{=}~e'~\texttt{in}~e`.

Using, the notion of function composition, we can present the *first
fusion rule*, :math:`F1`, which says that the result of mapping an
arbitrary function :math:`f` over the result of mapping another
arbitrary function :math:`g` over some array :math:`a` is identical to
mapping the composed function :math:`f\circ g` over the array
:math:`a`. The first fusion rule is also called map-map fusion and can
simply be written

.. math::
   \texttt{map}~f~(\texttt{map}~g~\texttt{a}) = \texttt{map}~(f \circ g)~\texttt{a}

Given that :math:`f` and :math:`g` denote the Futhark functions
:math:`\backslash x_1\cdots x_n~\texttt{->}~e` and :math:`\backslash
y_1\cdots y_m~\texttt{->}~e'`, , respectively (possibly after renaming
of bound variables), the *function product* of :math:`f` and
:math:`g`, written :math:`f \otimes g`, is defined as
:math:`\backslash (x_1,\cdots,x_n)
(y_1,\cdots,y_m)~\texttt{->}~(e,e')`.

Now, the *second fusion rule*, :math:`F2`, which denotes horizontal
fusion, specifies that::

   let x = map f a in
   let y = map g a in
   e

is equivalent to::

   let (x,y) = unzip (map ((f ⊗ g) ∘ dup) a) in e

Here ``dup`` is the Futhark function ``\x -> (x,x)``.

Flattening
----------

The flattening rules that we shall introduce here allows the Futhark
compiler to generate parallel kernels for various code block patterns.

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
