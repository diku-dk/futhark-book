.. _modules:

Modules
=======

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

Each source file is implicitly a module, but we can also define
modules inside a file via the *module language*.  This means we are
actually defining nested modules - nested inside the module defined by
the file itself.  To understand how modules work, it is useful to
ignore their relation to files at first - in contrast to most other
languages, it is mostly incidental, as files are *not* the foundation
of the Futhark module system.

Simple Modules
--------------

At the most basic level, a *module* (called a *structure* in Standard ML)
is a collection of declarations::

  module add_i32 = {
    type t = i32
    def add (x: t) (y: t): t = x + y
    def zero: t = 0
  }

Declarations are value bindings, type bindings, module bindings, and a
few other things that are allowed to occur at the top level.

After the module binding above, ``add_i32.t`` is an alias for the type
``i32``, and ``add_i32.add`` is a function that adds two values of
type ``i32``. The only peculiar thing about this notation is the equal
sign before the opening brace.  The declaration above is actually a
combination of a *module binding*

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

Now every name defined in ``add_i32`` is also available in the module
``foo``. At compile-time, only a single version of the ``add``
function is defined, so there is no overhead involved.

As a starting point, every name defined by a declaration inside of a
module will be visible outside that module.  We can make a declaration
invisible to users of the module by prefixing it with ``local``::

  module m = {
    local def helper x = x + 2
    def f x = helper (helper x)
  }

In this contrived example, ``m.f`` will be visible, but ``m.helper``
will not.  Do not use ``local`` to hide the definitions of types - it
will not work.  In :numref:`module-types` we'll see facilities for
making types abstract.

To make the names of a module available without having to prefix the
module name, you can use the ``open`` declaration.  For example, after
the definition above, we can use ``open m`` to make the function ``f``
available in the rest of the current module *and to users of the
current module*.  This is an important but somewhat subtle detail::

  module m2 = {
    open m
  }

This makes ``m2.f`` available because ``m`` exposes a binding ``f``.
If you don't want this behaviour, use ``local open``.

.. _other-files:

Modules and files
-----------------

While Futhark's module system is not file oriented, there is still a
close interaction.  You can access code in other files as follows::

  import "module"

The above declaration will include all non-``local`` top-level
definitions from ``module.fut`` and make them available in the current
module, but will *not* make them available to users of the module.
The ``.fut`` extension is implied.

You can also include files from subdirectories:::

  import "path/to/a/file"

The above will include the file ``path/to/a/file.fut`` relative to the
including file.

If we are defining a top-level function (or any other top-level
construct) that we do not want to be visible outside the current file,
we can prefix it with ``local``::

  local def i_am_hidden x = x + 2

The above uses ``import`` as a declaration.  We can also use it as a
module expression.  This makes qualified imports possible::

  module M = import "module"

In fact, a plain ``import "module"`` declaration is equivalent to::

  local open import "module"

This declaration opens ``"module"`` in the current file, but does not
propagate its contents to modules that in turn ``import`` the current
file.  If we wish to re-export names bound in another file, we would
say::

  local open import "module"

.. _module-types:

Module Types
------------

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
------------------

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
