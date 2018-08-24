.. _introduction:

Introduction
============

In 1965, Gordon E. Moore predicted a doubling every year in the number
of components in an integrated circuit :cite:`moore1965`. He revised
the prediction in 1975 to a doubling every two year :cite:`moore1975`
and later revisions suggest a slight decrease in the growth rate,
while the growth rate, here 50 years after Moore’s first prediction,
is not seriously predicted to fade out in the next decade. In the
first many years, the increase in components per chip area, as
predicted by “Moore’s law”, had a direct influence on processor
speed. The personal computer was getting popular and software
providers were happy beneficials of the so-called “free lunch”, which
made programs running on single Central Processing Units (CPUs) double
in speed whenever new processors hit the market.

The days of the “free lunches” for sequentially written programs is
over. The physical speed limit for sequential processing units has pretty
much been reached. Increases in processor clock frequency introduces
heat problems that are difficult to deal with and chip providers have
instead turned their focus on providing multiple cores in the same chip.
Thus, for programs to run faster on ever new architectures, programs
will have to make use of algorithms and data structures that benefit
from simultaneous, that is *parallel*, execution on multiple cores.
Newer architectures, such as Graphical Processing Units (GPUs), host a
high number of cores that are designed for parallel processing and over
the coming decade, we will see a drastic increase in the number of cores
hosted in each chip.

In this book we distinguish between the notions of parallelism and
concurrency. By *concurrency*, we refer to programming language controls
for coordinating work done by multiple virtual processes. Such processes
may in principle run on the same physical processor (using for instance
time slicing) or they may run on multiple processors. Controlling the
communication and dependencies between multiple processes turns out to
be immensely difficult and programmers need to deal with problems such
as unforeseen non-determinism and dead-locks, collectively named *race
conditions*, issues that emerge when two or more processes (and their
interaction with an external environment) interleave. By *parallelism*,
on the other hand, we simply refer to the notion of speeding up a
program by making it run on multiple processors. Given a program, we can
analyze the program to discover dependencies between units of
computation and as such, the program contains all the information there
is to know about to which degree the program can be executed in
parallel. We emphasize here the notion that a parallel program should
result in the same output given an input no-matter how many processors
are used for executing the program. On the other hand, we hope that
running the program in parallel with multiple processors will execute
faster than if only one processor is used. As we shall see, making
predictable models for determining whether a given program will run
efficiently on a parallel machine can be difficult, in particular in
cases where the program is inhomogeneously parallel at several levels,
simultaneously.

Parallelism can be divided into the notions of *task parallelism*,
which emphasizes the concept of executing multiple independent tasks
in parallel, and *data parallelism*, which focuses on executing the
same program on a number of different data objects in parallel. At the
hardware side, multiple instruction multiple data (MIMD) processor
designs, coined after Flynn’s taxonomy :cite:`Flynn1972`, directly
allow for different tasks to be executed in parallel. For such
designs, each processor is quite complex and in terms of fitting most
processors on a single chip, so as to increase overall throughput,
vendors have increasing success with simpler chip designs for which
compute units execute single instructions on multiple data
(SIMD). Such processor designs have turned out to be useful for a
large number of application domains, including graphics processing,
machine learning, image analysis, financial algorithms, and many
more. In particular, for graphics processing, chip designers have
since the 1970’es developed the concept of graphics processing units
(GPUs), which, in the later years, have turned into “general purpose”
graphics processing units (GPGPUs).

The notions of parallel processing and parallel programming are not new.
Concepts in these areas have emerged over a period of more than three
decades and today the notion of parallelism appears in many disguises.
For example, the internet as we know it can be understood as a giant
parallel processing unit and whenever some user is browsing and
searching the internet, a large number of processing units are working
in parallel to provide the user with the best information available on
the topic. At all levels, software engineers need to know how to exploit
the ever increasing amount of computational resources.

For many years, programmers and engineers have been accustomed to the
simple performance reasoning principles of the von Neumann machine
model :cite:`vonneumann1945`, which is also often referred to as the
sequential Random Access Machine (RAM) model.  With ever more complex
chip circuits, introducing speculative instruction scheduling and
advanced memory cache hierarchies for leveraging the far from
constant-time access to random memory, reasoning about performance has
become difficult even for programs running on sequential hardware. The
consequence is that, even for sequential programs, programmers and
engineers are requesting better models for predicting performance. For
programs designed to run on parallel hardware, the situation is often
worse. Understanding the performance aspects of executing a
task-parallel program on a MIMD architecture can quickly become an
immensely complex task in particular because the programmer can be
forced to reason about concurrency aspects of the program running on
the MIMD architecture. Machines are becoming more complex and the
abstractions provided by the simpler machine models seem broken as the
models no longer can be used to reason, in a predictable way, about
performance. One particular instance of this problem is the assumption
in the shared memory PRAM model, which assumes that all processors
have constant-time access to random memory.

Low-level languages and frameworks that more or less directly mirror
their parallel target architectures include OpenCL :cite:`opencl2011`
and CUDA :cite:`Nickolls:2008:SPP:1365490.1365500` for data-parallel
GPU programming. More abstract approaches to target parallel hardware
include library-based approaches, such as CUBLAS for GPU-targeted
linear algebra routines, and annotation-based approaches, such as
OpenAcc for targeting GPUs and OpenMP for targeting multi-core
platforms.

Instead of requiring programmers to reason about programs based on a
particular machine model, an alternative is to base performance
reasoning on more abstract *language based cost models*, which are
models that emphasize higher-level programming language concepts and
functionalities. By introducing such an abstraction layer, programmers
will no longer need to “port” their performance reasoning whenever a new
parallel machine is targeted. It will instead be up to the language
implementor to port the language to new architectures.

The introduction of language based cost models is of course not a
silver bullet, but they may help isolate the assumptions under which
performance reasoning is made. Guy Blelloch’s seminal work on NESL
:cite:`blelloch1990vector,blelloch1994implementation` introduces a
cost model based on the concept of *work*, which, in abstract terms,
defines a notion of the total work done by a program, and the concept
of *steps*, which defines a notion of the number of dependent parallel
steps that the program will take, assuming an infinite number of
processors.

In this book we shall make use of a performance cost model for a
subset of a data-parallel language and discuss benefits and
limitations of the approach. The cost model is based on the
language-based cost model developed for NESL, but in contrary to the
cost model for NESL, we shall not base our reasoning on an automatic
flattening technique for dealing with nested parallelism. Instead, we
shall require the programmer to perform certain kinds of flattening
manually. The cost model developed for Futhark has been adapted from
the cost model developed for the SPARC parallel functional programming
language developed for the Carnegie Mellon University (CMU) Fall 2016
course “15-210: Parallel and Sequential Data Structures and
Algorithms” :cite:`algdesign:parseq2016`.

We shall primarily look at parallelism from a data-parallel functional
programming perspective. The development in the book is made through
the introduction of the Futhark data-parallel functional language
:cite:`henriksen2014size,henriksen2016design,henriksen2014bounds,henriksen2013t2`,
which readily will generate GPU-executable code for a Futhark program
by compiling the program into a number of OpenCL kernels and
coordinating host code for spawning the kernels. Besides the OpenCL
backend, Futhark also features a C backend and Futhark has been
demonstrated to compile quite complex data-parallel programs into
well-performing GPU code :cite:`finpar,apltofuthark2016`.

Structure of the Book
---------------------

The book is organised into several parts. In :ref:`futlang`, we
introduce the Futhark language, including its basic syntax, the
semantics of the core language, and the built-in array second-order
array combinators and their parallel semantics. We also describe how
to compile and execute Futhark programs using both the sequential C
backend and the parallel GPU backend. Finally, we describe Futhark's
module system, which allows for programmers to organise code into
reusable components that carry no overhead whatsoever, due to
Futhark's aggressive strategy of eliminating all module system
constructs at compile time. We also describe Futhark's support for
parametric polymorphism and restricted form of higher-order functions,
which provide programmers with excellent tooling for writing abstract
reusable code.

In :ref:`costmodel`, we introduce an “ideal”
cost model for the Futhark language based on the notions of work and
span. In :ref:`soac-algebra`, we present to the reader the underlying
algebraic reasoning principles that lie behind the Futhark internal
fusion technology. In particular, we introduce the reader to the
list-homomorphism theorem, which forms the basis of map-reduce reasoning
and which turns out to play an important role in the fusion engine of
Futhark.

In :ref:`parallel-algorithms`, we present a number of parallel
algorithms that can be used as building blocks for programming more
complex parallel programs. Some of these algorithms have made it into
Futhark libraries, which may be organised, managed, and documented
using Futhark's package manager and Futhark's documentation
tool. These tools are described in the Futhark User's Guide available
at https://futhark.readthedocs.io/en/latest/.
