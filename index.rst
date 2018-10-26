.. Parallel Programming in Futhark documentation master file, created by
   sphinx-quickstart on Sun Dec  3 10:44:29 2017.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Parallel Programming in Futhark
===============================

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
non-Futhark code.  The language was originally developed in Denmark,
and is therefore named after `the Runic alphabet
<https://en.wikipedia.org/wiki/Elder_Futhark>`_.

This book is written for a reader who already has some programming
experience.  Prior experience with functional programming is useful,
but not required.  We will be learning Futhark through small examples
that each aim to demonstrate some feature or facet of the language.
Furthermore, we will discuss some of the theorical background of
data-parallel programming, as well as elaborate on some of the
optimisations that can be expected from the compiler.

Contributing to the book
------------------------

The book is Open Source, maintained on Github, and distributed under
the Creative Commons Attribution (By) 4.0 license. All code snippets
in the book, including code in the book’s repository directory is
distributed under the ISC license.  We will appreciate pull-requests
for fixing any kinds of typos and errors in the text and in the
enclosed programs, or making any other improvement. The book’s main
repository is https://github.com/diku-dk/futhark-book.

Acknowledgments
---------------

This work has been partially supported by the Danish Strategic
Research Council, Program Committee for Strategic Growth Technologies,
for the research center *HIPERFIT: Functional High Performance
Computing for Financial Information Technology* (`hiperfit.dk
<hiperfit.dk>`__) under contract number 10-092299.  The work has also
been supported by `Independent Research Fund Denmark
<https://dff.dk/>`_ as part of the project *Functional Technology for
High-performance Architectures (FUTHARK)*.

When citing this work, please use `this BibTeX entry
<_static/book.bib>`_.

Table of contents
-----------------

.. toctree::
   :maxdepth: 2

   introduction.rst
   language.rst
   testing.rst
   benchmarking.rst
   interoperability.rst
   when-things-go-wrong.rst
   parallel-cost-model.rst
   soac-algebra.rst
   parallel-algorithms.rst
   zbibliography.rst

Indices and tables
------------------

* :ref:`genindex`
* :ref:`search`
