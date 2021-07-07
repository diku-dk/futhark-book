.. _interoperability:

Interoperability
================

Futhark is a purely functional high-performance language incapable of
interacting with the outside world except through function parameters.
This makes it impossible to write full applications in Futhark, except
via the limited standard input-based interface that we used in the
preceding chapters.  In practice, this interface is too slow and too
inflexible to be useful.  Instead, the Futhark compiler is designed to
generate *libraries*, which can then be invoked by general-purpose
languages.  In this chapter we will see how to call Futhark from
Python and C, with particular attention paid to the former.

Calling Futhark from Python
---------------------------

Python is a language with many qualities, but few would claim that
performance is among them.  While libraries such as NumPy can be used,
they are not as flexible as being able to write code directly in a
high-performance language.  Unfortunately, writing the
performance-critical parts of a Python program in (say) C is not
always a good experience, and the interfacing between the Python code
and the C code can be awkward and inelegant (although to be fair, it
is still nicer in Python than in many other languages).  It would be
more convenient if we could compile a high-performance language
directly to a Python module that we could then ``import`` like any
other piece of Python code.  Of course, this entire exercise is only
worthwhile if the code in the resulting Python module executes much
faster than manually written Python.  Fortunately, when most of the
computation can be offloaded to the GPU via OpenCL, the Futhark
compiler is capable of this feat.

OpenCL works by having an ordinary program running on the CPU that
transmits code and data to the GPU (or any other *accelerator*, but
we'll stick to GPUs).  In the ideal case, the CPU-code is mostly glue
that performs bookkeeping and making API calls - in other words, not
resource-intensive, and exactly what Python is good at.  No matter the
language the CPU code is written in, the GPU code will be written in
OpenCL C and translated at program initialisation to whatever machine
code is needed by the concrete GPU.

This is what is exploited by the `PyOpenCL
<https://mathema.tician.de/software/pyopencl/>`_ backend in the
Futhark compiler.  Certainly, the CPU-level code is written in pure
Python and quite slow, but all it does is use the PyOpenCL library to
offload work to the GPU.  The fact that this offloading takes place is
hidden from the user of the generated code, who is provided a module
with functions that accept and produce ordinary NumPy arrays.

Consider our usual dot product program:

.. literalinclude:: src/dotprod.fut
   :lines: 5-

We can compile this to a Python module::

  $ futhark pyopencl --library dotprod.fut

The result is a file ``dotprod.py`` that we can import from within
Python::

  $ python
  >>> import dotprod

The ``dotprod.py`` module defines a class ``dotprod`` that we must
instantiate.  The class maintains various bits of bookkeeping
information, and exposes a method for every entry point in our program
(here just ``main``)::

  >>> o = dotprod.dotprod()

We will get an error if we try to pass Python lists to the entry
point, as lists are not arrays::

  >>> o.main([1,2,3], [4,5,6])
  Traceback (most recent call last):
    File "<stdin>", line 1, in <module>
    File "dotprod.py", line 2416, in main
      x_mem_3884_ext))
  TypeError: Argument #0 has invalid value
  Futhark type: []i32
  Argument has Python type <type 'list'> and value: [1, 2, 3]

Instead, we have to construct a properly typed NumPy array::

  >>> import numpy as np
  >>> o.main(np.array([1,2,3], dtype=np.int32),
             np.array([4,5,6], dtype=np.int32))
  32

The integer that is returned is a normal Python object of an
appropriate type (in this case it will have type ``np.int32``).  If an
array is returned, it is in the form of a `PyOpenCL array
<https://documen.tician.de/pyopencl/array.html>`_, which is mostly
compatible with NumPy arrays, except that the backing memory still
resides on the GPU, and is not copied over to the CPU unless
necessary.  This makes it efficient to take the output of one entry
point and pass it as the input to another.  PyOpenCL arrays contain a
``.get()`` method that can be used to construct an equivalent NumPy
array, if desired.

Calling Futhark from C
----------------------

Let us once again consider ``dotprod.fut``:

.. literalinclude:: src/dotprod.fut
   :lines: 5-

We can compile it with the ``futhark opencl`` compiler::

  $ futhark opencl --library dotprod.fut

This produces two files in the current directory: ``dotprod.c`` and
``dotprod.h``.  We can compile ``dotprod.c`` to a shared library like
this::

  $ gcc dotprod.c -o libdotprod.so -fPIC -shared

We can now link to ``libdotprod.so`` the same way we link with any
other shared library.  But before we get that far, let's take a look
at (parts of) the generated ``dotprod.h`` file.  We have written the
code generator to produce as simple header files as possible, with no
superfluous crud, in order to make them human-readable.  This is
particularly useful at the moment, since few explanatory comments are
inserted in the header file.

The first declarations are related to initialisation, which is based
on first constructing a *configuration* object, which can then be used
to obtain a *context*.  The context is used in all subsequent calls,
and contains GPU state and the like.  We elide most of the functions
for setting configuration properties, as they are not very
interesting::

  /*
   * Initialisation
  */

  struct futhark_context_config ;

  struct futhark_context_config *futhark_context_config_new();

  void futhark_context_config_free(struct futhark_context_config *cfg);

  void futhark_context_config_set_device(struct futhark_context_config *cfg,
                                         const char *s);

  ...

  struct futhark_context ;

  struct futhark_context *futhark_context_new(struct futhark_context_config *cfg);

  void futhark_context_free(struct futhark_context *ctx);

  int futhark_context_sync(struct futhark_context *ctx);

The above demonstrates a pervasive design decision in the API: the use
of pointers to *opaque structs*.  The struct ``futhark_context`` is
not given a definition, and the only way to construct it is via the
function ``futhark_context_new()``.  This means that we cannot
allocate it statically, which is contrary to how one would normally
design a C library.  The motivation behind this design is twofold:

  1. It keeps the header file readable, as it elides implementation
     details like struct members.

  2. It is easier to use from FFIs.  Most FFIs make it very easy to
     work with functions that only accept and produce pointers (and
     primitive types), but accessing and allocating structs is a little
     more involved.

The disadvantage is a little more boilerplate, and a little more
dynamic allocation.  However, relatively few objects of this kind are
used, so the performance impact should be nil.

The next part of the header file concerns itself with arrays - how
they are created and accessed::

  /*
   * Arrays
  */

  struct futhark_i32_1d ;

  struct futhark_i32_1d *futhark_new_i32_1d(struct futhark_context *ctx,
                                            int32_t *data,
                                            int dim0);

  int futhark_free_i32_1d(struct futhark_context *ctx,
                          struct futhark_i32_1d *arr);

  int futhark_values_i32_1d(struct futhark_context *ctx,
                            struct futhark_i32_1d *arr,
                            int32_t *data);

  int64_t *futhark_shape_i32_1d(struct futhark_context *ctx,
                                struct futhark_i32_1d *arr);

Again we see the use of pointers to opaque structs.  We can use
``futhark_new_i32_1d`` to construct a Futhark array from a C array,
and we can use ``futhark_values_i32_1d`` to read all elements from a
Futhark array.  The representation used by the Futhark array is
intentionally hidden from us - we do not even know (or care) whether
it is resident in CPU or GPU memory.  The code generator automatically
generates a struct and accessor functions for every distinct array
type used in the entry points of the Futhark program.

The single entry point is declared like this::

  int futhark_entry_main(struct futhark_context *ctx,
                         int32_t *out0,
                         const struct futhark_i32_1d *in0,
                         const struct futhark_i32_1d *in1);

As the original Futhark program accepted two parameters and returned
one value, the corresponding C function takes one *out* parameter and
two *in* parameters (as well as a context parameter).

We have now seen enough to write a small C program (with no error
handling) that calls our generated library::

  #include <stdio.h>

  #include "dotprod.h"

  int main() {
    int x[] = { 1, 2, 3, 4 };
    int y[] = { 2, 3, 4, 1 };

    struct futhark_context_config *cfg = futhark_context_config_new();
    struct futhark_context *ctx = futhark_context_new(cfg);

    struct futhark_i32_1d *x_arr = futhark_new_i32_1d(ctx, x, 4);
    struct futhark_i32_1d *y_arr = futhark_new_i32_1d(ctx, y, 4);

    int res;
    futhark_entry_main(ctx, &res, x_arr, y_arr);
    futhark_context_sync(ctx);

    printf("Result: %d\n", res);

    futhark_free_i32_1d(ctx, x_arr);
    futhark_free_i32_1d(ctx, y_arr);

    futhark_context_free(ctx);
    futhark_context_config_free(cfg);
  }

We hard-code the input data here, but we could just as well have read
it from somewhere.  The call to ``futhark_context_new()`` is where the
GPU is initialised (is applicable) and OpenCL kernel code is compiled
and uploaded to the device.  This call might be relatively slow.
However, subsequent calls to entry point functions
(``futhark_dotprod()``) will be efficient, as they re-use the already
initialised context.

Note the use of ``futhark_context_sync()`` after calling the entry
point: Futhark does not guarantee that the final results have been
written until we synchronise explicitly.  Note also that we free the
two arrays ``x_arr`` and ``y_arr`` once we are done with them - memory
management is entirely manual.

If we save this program as ``luser.c``, we can compile and run it like
this::

  $ gcc luser.c -o luser -lOpenCL -lm -ldotprod
  $ ./luser
  Result: 24

You may need to set ``LD_LIBRARY_PATH=.`` before the dynamic linker
can find ``libdotprod.so``.  Also, this program will only work if the
default OpenCL device is usable on your system, since we did not
request any specific device.  For testing on a system that does not
support OpenCL, simply use ``futhark c`` instead of
``futhark opencl``.  The generated API will be the same.

Handling Awkward Futhark Types
------------------------------

Our dot product function uses only types that map easily to NumPy and
C: primitives and arrays of primitives.  But what happens if we have
an entry point that involves abstract types with hidden definitions,
or types with no clear analogue in C, such as records or arrays of
tuples?  In this case, the generated API defines structs for *opaque
types* that support very few operations.

Consider the following contrived program, ``pack.fut``, which contains
two entry points::

  entry pack (xs: []i32) (ys: []i32): [](i32,i32) = zip xs ys

  entry unpack (zs: [](i32,i32)): ([]i32,[]i32) = unzip zs

The ``pack`` function turns two arrays into one array of pairs, and
the ``unpack`` function reverses the operation.  If compiled to
Python, the ``pack`` function will return a special "opaque" object
whose contents cannot be inspected.  If compiled to C, ``pack.h``
contains the following definitions::

  struct futhark_opaque_z31U814583239044437263 ;

  int futhark_free_opaque_z31U814583239044437263(struct futhark_context *ctx,
                                                 struct futhark_opaque_z31U814583239044437263 *obj);

  int futhark_pack(struct futhark_context *ctx,
                   struct futhark_opaque_z31U814583239044437263 **out0,
                   struct futhark_i32_1d *in0,
                   struct futhark_i32_1d *in1);

  int futhark_unpack(struct futhark_context *ctx,
                     struct futhark_i32_1d **out0,
                     struct futhark_i32_1d **out1,
                     struct futhark_opaque_z31U814583239044437263 *in0);

The unfortunately named struct,
``futhark_opaque_z31U814583239044437263``, represents an array of
tuples.  There is nothing we can do with it except for freeing it, or
passing it back to an entry point.  In fact, the name is not even
stable - it's a hash of the internal representation.  If you try the
above example, you may see a different name.

Opaque types typically occur when you are writing a Futhark program
that keeps some kind of state that you don't want the user modifying
or reading directly, but you need access to for each call to an entry
point.  Since Futhark programs are purely functional (and therefore
stateless), having the user to manually pass back the state returned
by the previous call is the only way to accomplish this.  Fortunately,
we can assign these opaque types somewhat more readable names by type
abbreviations::

  type~ array_of_pairs = [](i32,i32)

  entry pack (xs: []i32) (ys: []i32): array_of_pairs = zip xs ys

  entry unpack (zs: array_of_pairs): ([]i32,[]i32) = unzip zs

Now, when compiled to C, we obtain a somewhat more readable name for
the opaque type::

  struct futhark_opaque_array_of_pairs ;

  int futhark_free_opaque_array_of_pairs(struct futhark_context *ctx,
                                         struct futhark_opaque_array_of_pairs *obj);

  int futhark_entry_pack(struct futhark_context *ctx,
                         struct futhark_opaque_array_of_pairs **out0, const
                         struct futhark_i32_1d *in0, const
                         struct futhark_i32_1d *in1);

  int futhark_entry_unpack(struct futhark_context *ctx,
                           struct futhark_i32_1d **out0,
                           struct futhark_i32_1d **out1, const
                           struct futhark_opaque_array_of_pairs *in0);

We have to be careful to use the type abbreviation everywhere, as the
compiler will generate the hash-named opaque in any place that we miss.
