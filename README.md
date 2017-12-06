# Parallel Programming in Futhark

This material aims at introducing the reader to data-parallel
functional programming using the Futhark language.  It is
work-in-progress, but probably constitutes the best introduction to
Futhark programming.

## Reading the Book

The book is readable in HTML form at the following location:

http://futhark-book.readthedocs.io

There is currently no PDF version.

## Writing the Book

The book is written using [Sphinx](http://www.sphinx-doc.org), which
must be installed.  You may also need to run this command to install
further necessary dependencies:

    pip install -r requirements.txt --user

The document is compiled by typing `make html` and the embedded
Futhark code is compiled, executed, and tested by typing `make test`.
