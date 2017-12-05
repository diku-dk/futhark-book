.. Parallel Programming in Futhark documentation master file, created by
   sphinx-quickstart on Sun Dec  3 10:44:29 2017.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to "Parallel Programming in Futhark", an introductionary book
about the Futhark programming language.  Futhark is a data-parallel
array programming language that uses the vocabulary of functional
programming to provide a parallel programming model that is easy to
understand, yet can be compiled to very efficient code by an
optimising compiler.  Futhark is a *small* language - it is not
designed to replace general-purpose langages for application
programming.  The intended use case is that Futhark is only used for
relatively small but compute-intensive parts of an application, as the
Futhark compiler generates code that can be easily called from
non-Futhark code.

This book is written for a reader who already has some programming
experience.  Prior experience with functional programming is useful,
but not required.  We will be learning Futhark through small examples
that each aim to demonstrate some feature or facet of the language.
Furthermore, we will discusss some of the theorical background of
data-parallel programming, as well as elaborate on some of the
optimisations that can be expected from the compiler.

Parallel Programming in Futhark
===============================

.. toctree::
   :maxdepth: 2

   preface.rst
   introduction.rst
   language.rst
   benchmarking.rst
   interoperability.rst
   when-things-go-wrong.rst
   parallel-cost-model.rst
   soac-algebra.rst
   parallel-algorithms.rst
   zbibliography.rst

Indices and tables
==================

* :ref:`genindex`
* :ref:`search`
