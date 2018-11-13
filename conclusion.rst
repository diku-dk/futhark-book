.. _conclusion:

Conclusion
==========

In this book, we have aimed at providing a practical guide to writing
data-parallel programs in Futhark. Futhark is quite an extensive
language even though its semantics is pure. It does however have
limitations. In particular, Futhark does not currently support
recursion and it has no built-in support for algebraic
datatypes. Support for some of these concepts are currently being
investigated

On the performance side, there are, of course, always room for
improvements. In particular, a number of low-level optimisations, such
as register tiling, could turn out helpful for certain kinds of
applications. However, even with the current performance level,
Futhark may turn out fruitful for serious prototying and quick
time-to-market development.

The Futhark web site at http://futhark-lang.org contains a list of
research papers, which will serve as a suggestion for further reading.
