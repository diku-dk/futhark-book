When Things Go Wrong
====================

Futhark is a much younger and more raw language than you may be
accustomed to, and many common language features are missing. It is
important to remember that Futhark is an *on-going research project*,
and you should not expect the same predictability and quality of error
messages that you may be used to from more mature languages. In general,
the limitations you will encounter will tend to fall in three different
categories:

Incidental
    limitations are those languages features that are missing for no
    reason other than insufficient development resources. For example,
    Futhark does not support user-defined polymorphic functions, sum
    types, nontrivial type inference, or any kind of higher-order
    functions. We know how to implement these, but simply have not
    gotten around to it yet.

Essential
    limitations touch upon fundamental restrictions in the target
    platform(s) for the Futhark compiler. For example, GPUs do not
    permit dynamic memory allocation inside GPU code. All memory must be
    pre-allocated before GPU programs are launched. This means that the
    Futhark compiler must be able to pre-compute the size of all
    intermediate arrays (symbolically), or compilation will fail.

Implementation
    limitations are weaknesses in the Futhark compiler that could
    reasonably be solved. Many implementation limitations, such as the
    inability to pre-compute some array sizes, or eliminate bounds
    checks inside parallel sections, will manifest themselves as
    essential limitations that could be worked around by a smarter
    compiler.

For example, consider this program:

::

    let main(n: i32): [][]i32 =
      map (\i ->
             let a = [0..<i]
             let b = [0..<n-i]
             in concat a b)
          [0..<n]

At the time of this writing, the ``futhark-opencl`` compiler will fail
with the not particularly illuminative error message
``Cannot allocate memory in kernel``. The reason is that the compiler is
trying to compile the to parallel code, which involves pre-allocating
memory for the ``a`` and ``b`` array. It is unable to do this, as the
sizes of these two arrays depend on values that are only known *inside*
the map, which is too late. There are various techniques the Futhark
compiler could use to estimate how much memory would be needed, but
these have not yet been implemented.

It is usually possible, sometimes with some pain, to come up with a
workaround. We could rewrite the program as:

::

    let main(n: i32): [][]i32 =
      let scratch = [0...<n]
      in map (\i ->
                let res = [0..<n]
                let res[i:n] = scratch[0:n-i]
                in res)
             [0..<n]

This exploits the fact that the compiler does not generate allocations
for array slices or in-place updates. The only allocation is of the
initial ``res``, the size of which can be computed before entering the .
