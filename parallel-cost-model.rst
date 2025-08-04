.. _costmodel:

============================================
 A Parallel Cost Model for Futhark Programs
============================================

In this chapter we develop a more formal model for Futhark and provide
an ideal cost model for the language in terms of the concepts of work
and span. Before we present the cost model for the language, we
present a simple type system for Futhark and an evaluation
semantics. In the initial development, we shall not consider Futhark's
more advanced features such as loops and uniqueness types, but we
shall return to these constructs later in the chapter.

Futhark supports certain kinds of nested parallelism. For instance,
Futhark can in many cases map two nested maps into fully parallel
code. Consider the following Futhark function:

.. literalinclude:: src/multable.fut
   :lines: 10-13

In the case of this program, Futhark will flatten the code to make a
single flat kernel. We shall return to the concept of flattening in a
later chapter.

When we shall understand how efficient an algorithm is, we shall build
our analysis around the two concepts of `work and span`_. These
concepts are defined inductively over the various Futhark language
constructs and we may therefore argue about work and span in a
compositional way. For instance, if we want to know about the work
required to execute the ``multable`` function, we need to know about
how to compute the work for a call to the ``map`` SOAC, how to compute
the work for the ``iota`` operation, how to compute the work for the
multiply operation, and, finally, how to combine the work. The way to
determine the work for a ``map`` SOAC instance is to multiply the size
of the argument array with the work of the body of the argument
function. Thus, we have

.. math::
   W(\fop{map}~(\lamK{j}{i * j})~(\fop{iota}~n)) = n+1

Applying a similar argument to the outer map, we get

.. math::
   W(\fop{map}~(\lamK{i}{$\cdots$})~(\fop{iota}~\kw{$n$})) = (n+1)^2

Most often we are interested in finding the asymptotical complexity of
the algorithm we are analyzing, in which case we will simply write

.. math::
   W(\fop{map}~(\lamK{i}{$\cdots$}) (\fop{iota}~n) = O(n^2)

In a similar way we can derive that the span of a call ``multable n``,
written :math:`S(\kw{multable n})`, is :math:`O(1)`.

.. _work and span: https://en.wikipedia.org/wiki/Analysis_of_parallel_algorithms

Futhark - the Language
======================

In this section we present a simplified version of the Futhark
language in terms of syntax, a type system for the language, and a
strict evaluation semantics.

We assume a countable infinite number of program variables, ranged
over by :math:`x` and :math:`f`. Binary infix scalar operators,
first-order built-in operations, and second order array combinators
are given as follows:

.. math::
   \id{binop} &::=~~ \fop{+} ~~|~~ \fop{-} ~~|~~ \fop{*} ~~|~~ \fop{/} ~~|~~ \cdots \\
   \\
   \id{op} &::=~~ \fop{-} ~~|~~ \fop{abs} ~~|~~ \fop{copy} ~~|~~ \fop{concat} ~~|~~ \fop{empty} \\
       &~~|~~ \fop{iota} ~~|~~ \fop{partition} ~~|~~ \fop{rearrange} \\
       &~~|~~ \fop{replicate} ~~|~~ \fop{reshape} \\
       &~~|~~ \fop{rotate} ~~|~~ \fop{shape} ~~|~~ \fop{scatter} \\
       &~~|~~ \fop{split} ~~|~~ \fop{transpose} ~~|~~ \fop{unzip} ~~|~~ \fop{zip} \\
   \\
   \id{soac} &::=~~ \fop{map} ~~|~~ \fop{reduce} \\
             &~~|~~ \fop{scan} ~~|~~ \fop{filter} ~~|~~ \fop{partition}

In the grammar for the Futhark language below, we have eluded both the
required explicit type annotations and the optional explicit type
annotations. Also for simplicity, we are considering only "unnested"
pattern matching and we do not, in this section, consider uniqueness
types.

.. math::
   p &::=~~ x ~~|~~ \kw{(}x_1,...,x_n\kw{)} \\
   \\
   \id{ps} &::=~~ p_1 \cdots p_n \\
   \\
   F &::=~~ \lam{ps}{e} ~~|~~  e~\id{binop}  ~~|~~  \id{binop}~e \\
   \\
   P &::=~~ \fw{let}~f~\id{ps}~\kw{=}~e ~~|~~  P_1 P_2 ~~|~~ \fw{let}~p~\kw{=}~e \\
   \\
   v &::=~~ \fop{true} ~~|~~  \fop{false} ~~|~~  n  ~~|~~  r \\
     &~~|~~ \kw{[}v_1,...,v_n\kw{]}  ~~|~~  \kw{(}v_1,...,v_n\kw{)} \\
   \\
   e &::=~~ x  ~~|~~  v  ~~|~~  \fw{let}~\id{ps}~\kw{=}~e~\fw{in}~e' \\
     &~~|~~  e\kw{[}e'\kw{]}  ~~|~~  e\kw{[}e'\kw{:}e''\kw{]} \\
     &~~|~~ \kw{[}e_1,...,e_n\kw{]}  ~~|~~  \kw{(}v_1,...,v_n\kw{)} \\
     &~~|~~ f e_1 ... e_n  ~~|~~  \id{op}~e_1 ... e_n  ~~|~~  e_1~\id{binop}~e_2 \\
     &~~|~~ \fw{loop}~ p_1\kw{=}e_1,\cdots,p_n\kw{=}e_n ~\fw{for}~ x \kw{<} e ~\fw{do}~ e' \\
     &~~|~~ \fw{loop}~ p_1\kw{=}e_1,\cdots,p_n\kw{=}e_n ~\fw{while}~ e ~\fw{do}~ e' \\
     &~~|~~ \id{soac}~F~e_1~\cdots~e_n

Futhark Type System
===================

Without considering Futhark's uniqueness type system, Futhark's type
system is simple. Types (:math:`\tau`) follow the following
grammar-slightly simplified:

.. math::
   \tau & ::=~~ \kw{i32} ~~|~~ \kw{f32} ~~|~~ \kw{bool} ~~|~~ \kw{[]}\tau \\
        & ~~|~~ \kw{(}\tau_1,\cdots,\tau_n\kw{)} ~~|~~ \tau \rarr \tau' ~~|~~ \alpha

We shall refer to the types ``i32``, ``f32``, and ``bool``
as *basic types*. Futhark supports more basic types than those
presented here; consult :numref:`baselang` for a complete list.

In practice, Futhark requires a programmer to provide explicit
parameter types and an explicit result type for top-level function
declarations. Similarly, in practice, Futhark requires explicit types
for top-level ``let`` bindings. In such explicit types, type variables
are not allowed; at present, Futhark does not allow for a programmer
to declare polymorphic functions.

Futhark's second order array combinators and some of its primitive
operations do have *polymorphic* types, which we specify by
introducing the concept of *type schemes*, ranged over by
:math:`\sigma`, which are basically quantified types with
:math:`\alpha` and :math:`\beta` ranging over ordinary types. When
:math:`\sigma=\forall\vec{\alpha}.\tau` is some type scheme, we say
that :math:`\tau'` is an instance of :math:`\sigma`, written
:math:`\sigma \geq \tau'` if there exists a substitution
:math:`[\vec{\tau}/\vec{\alpha}]` such that
:math:`\tau[\vec{\tau}/\vec{\alpha}] = \tau'`. We require all
substitutions to be *simple* in the sense that substitutions do not
allow for function types, product types, or type variables to be
substituted. Other restrictions may apply, which will be specified
using a *type variable constraint* :math:`\alpha \triangleright T`,
where :math:`T` is a set of basic types.

The type schemes for Futhark's second-order array combinators are as
follows:

.. math::
    \id{soac} & ~~:~~  \mathrm{TypeOf}(\id{soac}) \\ \hline
 \fop{filter} & ~~:~~  \forall \alpha. (\alpha \rarr \mathtt{bool}) \rarr []\alpha \rarr []\alpha\\
    \fop{map} & ~~:~~  \forall \alpha_1\cdots\alpha_n\beta. (\alpha_1\rarr\cdots\rarr\alpha_n \rarr \beta) \\
              & ~~~~~  \rarr []\alpha_1 \rarr\cdots\rarr []\alpha_n \rarr []\beta\\
 \fop{reduce} & ~~:~~  \forall \alpha. (\alpha \rarr \alpha \rarr \alpha) \rarr \alpha \rarr []\alpha \rarr \alpha\\
   \fop{scan} & ~~:~~  \forall \alpha. (\alpha \rarr \alpha \rarr \alpha) \rarr \alpha \rarr []\alpha \rarr []\alpha\\

The type schemes for Futhark's built-in first-order operations are as
follows:

.. math::

         \id{op} & ~~:~~  \mathrm{TypeOf}(\id{op}) \\ \hline
    \fop{concat} & ~~:~~  \forall \alpha. []\alpha \rarr \cdots \rarr []\alpha \rarr []\alpha \\
     \fop{empty} & ~~:~~  \forall \alpha. []\alpha \\
      \fop{iota} & ~~:~~  \kw{int} \rarr []\kw{int} \\
 \fop{replicate} & ~~:~~  \forall \alpha. \kw{int} \rarr \alpha \rarr []\alpha\\
    \fop{rotate} & ~~:~~  \forall \alpha. \kw{int} \rarr []\alpha \rarr []\alpha\\
 \fop{transpose} & ~~:~~  \forall \alpha. [][]\alpha \rarr [][]\alpha\\
     \fop{unzip} & ~~:~~  \forall \alpha_1\cdots\alpha_n. [](\alpha_1,\cdots,\alpha_n) \\
                 & ~~~~~  \rarr ([]\alpha_1,\cdots,[]\alpha_n) \\
   \fop{scatter} & ~~:~~  \forall \alpha. []\alpha \rarr []\kw{int} \rarr []\alpha \rarr []\alpha \\
       \fop{zip} & ~~:~~  \forall \alpha_1\cdots\alpha_n. []\alpha_1\rarr\cdots\rarr[]\alpha_n \\
                 & ~~~~~  \rarr [](\alpha_1,\cdots,\alpha_n)

The type schemes for Futhark's built-in infix scalar operations are as
follows:

.. math::

   \id{binop} & ~~:~~ \mathrm{TypeOf}(\id{binop}) \\ \hline
     \kw{+},\kw{-},\kw{*},\kw{/},\cdots & ~~:~~  \forall \alpha \triangleright \{\kw{i32},\kw{f32}\}. \alpha \rarr \alpha \rarr \alpha \\
     \kw{==},\kw{!=},\kw{<},\kw{<=},\kw{>},\kw{>=} & ~~:~~  \forall \alpha \triangleright \{\kw{i32},\kw{f32}\}. \alpha \rarr \alpha \rarr \kw{bool}

We use :math:`\Gamma` to range over *type environments*, which are
finite maps mapping variables to types. We use :math:`\{\}` to denote
the empty type environment and :math:`\{x:\tau\}` to denote a singleton
type environment. When :math:`\Gamma` is some type environment, we write
:math:`\Gamma,x:\tau` to denote the type environment with domain
:math:`\Dom(\Gamma) \cup \{x\}` and values
:math:`(\Gamma,x:\tau)(y) = \tau` if :math:`y=x` and :math:`\Gamma(y)`,
otherwise. Moreover, when :math:`\Gamma` and :math:`\Gamma'` are type
environments, we write :math:`\Gamma + \Gamma'` to denote the type
environment with domain :math:`\Dom(\Gamma) \cup \Dom(\Gamma')` and
values :math:`(\Gamma + \Gamma')(x) = \Gamma'(x)` if
:math:`x \in \Dom(\Gamma')` and :math:`\Gamma(x)`, otherwise.

Type judgments for values take the form :math:`\vd v : \tau`, which are
read “the value :math:`v` has type :math:`\tau`.” Type judgments for
expressions take the form :math:`\Gamma \vd e : \tau`, which are read
“in the type environment :math:`\Gamma`, the expression :math:`e` has
type :math:`\tau`.” Finally, type judgments for programs take the form
:math:`\Gamma \vd P : \Gamma'`, which are read “in the type environment
:math:`\Gamma`, the program :math:`P` has type environment
:math:`\Gamma'`.”

.. rubric:: Values :math:`~~\sembox{ \vd v : \tau}`

.. math:: \fraccc{}{\vd r : \kw{f32}} \\[2mm]

.. math:: \fraccc{}{\vd n : \kw{i32}} \\[2mm]

.. math:: \fraccc{}{\vd \fop{true} : \kw{bool}} \\[2mm]

.. math:: \fraccc{}{\vd \fop{false} : \kw{bool}} \\[2mm]

.. math:: \fraccc{\vd v_i : \tau_i ~~~i = [1;n]}{\vd \kw{(}v_1,\cdots,v_n\kw{)} : \kw{(}\tau_1,\cdots,\tau_n\kw{)}} \\[2mm]

.. math:: \fraccc{\vd v_i : \tau ~~~i = [1;n]}{\vd \kw{[}v_1,\cdots,v_n\kw{]} : \kw{[]}\tau}

.. rubric:: Expressions :math:`~~\sembox{\Gamma \vd e : \tau}`

.. math:: \fraccc{\Gamma(x) = \tau}{\Gamma \vd x : \tau} \\[2mm]

.. math:: \fraccc{\Gamma \vd e : []\tau ~~~~\Gamma \vd e_i : \kw{int}~~i=[1,2]}{ \Gamma \vd e\kw{[}e_1:e_2\kw{]} : []\tau} \\[2mm]

.. math:: \fraccc{\Gamma \vd e : \tau ~~~~ \Gamma, x:\tau \vd e' : \tau'}{\Gamma \vd \fw{let}~x~\kw{=} ~e~ \fw{in}~e' : \tau'} \\[2mm]

.. math:: \fraccc{\Gamma \vd e : \kw{(}\tau_1,\cdots,\tau_n\kw{)} \\
             \Gamma, x_1:\tau_1,\cdots,x_n:\tau_n \vd e' : \tau}{\Gamma \vd \fw{let}~\kw{(}x_1,\cdots,x_n\kw{)} ~\kw{=} ~e~ \fw{in}~e' : \tau} \\[2mm]

.. math:: \fraccc{\Gamma \vd e_i : \tau_i ~~~i = [1;n]}{\Gamma \vd \kw{(}e_1,\cdots,e_n\kw{)} : \kw{(}\tau_1,\cdots,\tau_n\kw{)}} \\[2mm]

.. math:: \fraccc{\Gamma \vd e_i : \tau ~~~i = [1;n]}{\Gamma \vd \kw{[}e_1,\cdots,e_n\kw{]} : \kw{[]}\tau} \\[2mm]

.. math:: \fraccc{\vd v : \tau}{\Gamma \vd v : \tau} \\[2mm]

.. math:: \fraccc{\Gamma(f) = \kw{(}\tau_1,\cdots,\tau_n\kw{)} \rarr \tau ~~~~ \Gamma \vd e_i : \tau_i ~~ i = [1;n]}{\Gamma \vd f~e_1\cdots e_n : \tau} \\[2mm]

.. math:: \fraccc{\Gamma \vd e_i : \tau_i ~~ i = [1;2] \\
     \mathrm{TypeOf}(\id{binop}) \geq \tau ~~~~ \tau = \tau_1 \rarr \tau_2 \rarr \tau'}{\Gamma \vd e_1 ~\id{binop}_\tau~ e_2 : \tau'
     } \\[2mm]

.. math:: \fraccc{\Gamma \vd e_i : \tau_i ~~ i = [1;n] \\
     \mathrm{TypeOf}(\id{op}) \geq \tau \\ \tau =  \tau_1 \rarr \cdots \rarr \tau_n \rarr \tau'}{\Gamma \vd \id{op}_\tau~ e_1~\cdots~e_n : \tau'
     } \\[2mm]

.. math:: \fraccc{\Gamma \vd e : []\tau ~~~~~~\Gamma \vd e' : \kw{int}}{ \Gamma \vd e\kw{[}e'\kw{]} : \tau} \\[2mm]

.. math:: \fraccc{\Gamma \vd F : \tau_\mathrm{f} ~~~ \Gamma \vd e_i : \tau_i ~~ i = [1;n] \\
     \mathrm{TypeOf}(\id{soac}) \geq \tau_\mathrm{f} \rarr \tau_1 \rarr \cdots \rarr \tau_n \rarr \tau}{
       \Gamma \vd \id{soac} ~F~e_1~\cdots~e_n : \tau
     }

.. rubric:: Functions :math:`~~\sembox{\Gamma \vd F : \tau}`

.. math::
   \fraccc{\Gamma,x_1:\tau_1~\cdots~x_n:\tau_n \vd e : \tau}{
       \Gamma \vd \lam{x_1:\tau_1~\cdots~x_n:\tau_n}{e} : \tau_1 \rarr \cdots \rarr \tau_n \rarr \tau
     } \\[2mm]

.. math::
   \fraccc{\Gamma \vd e : \tau_1 \\
     \mathrm{TypeOf}(\id{binop}) \geq \tau_1 \rarr \tau_2 \rarr \tau}{\Gamma \vd e ~\id{binop} : \tau_2 \rarr \tau
     } \\[2mm]

.. math::
   \fraccc{\Gamma \vd e : \tau_2 \\
     \mathrm{TypeOf}(\id{binop}) \geq \tau_1 \rarr \tau_2 \rarr \tau}{\Gamma \vd \id{binop}~e : \tau_1 \rarr \tau
     }

.. rubric:: Programs :math:`~~\sembox{\Gamma \vd P : \Gamma'}`

.. math::
   \fraccc{\Gamma \vd e : \tau ~~~~~ x \not \in \Dom(\Gamma)}{\Gamma \vd \fw{let}~x~\kw{=} ~e : \{x:\tau\}} \\[2mm]

.. math::
   \fraccc{\Gamma \vd P_1 : \Gamma_1 ~~~~ \Gamma + \Gamma_1 \vd P_2 : \Gamma_2}
            {\Gamma \vd P_1~P_2 : \Gamma_1 + \Gamma_2} \\[2mm]

.. math::
   \fraccc{\Gamma,x_1:\tau_1,\cdots,x_n:\tau_n \vd e : \tau  ~~~~~ f \not \in \Dom(\Gamma)}
            {\Gamma \vd \fw{let}~f~\kw{(}x_1,\cdots,x_n\kw{)}~\kw{=} ~e : \{f:\kw{(}\tau_1,\cdots,\tau_n\kw{)} \rarr \tau\}}

For brevity, we have eluded some of the typing rules and we leave it
to the reader to create typing rules for ``rearrange``, ``shape``,
``reshape``, ``loop-for``, ``loop-while``, and array ranging (``e[i:j:o]``).

Futhark Evaluation Semantics
============================

In this section we develop a simple evaluation semantics for Futhark
programs. The semantics is presented as a *big step* evaluation function
that takes as parameter an expression and gives as a result a value. A
*soundness property* states that if a program :math:`P` is well-typed
and contains a function *main* of type :math:`() \rightarrow
\tau`, then, if evaluation of the program results in a value :math:`v`,
the value :math:`v` has type :math:`\tau`.

To ease the presentation, we treat the evaluation function as being
implicitly parameterised by the program :math:`P`.

The semantics of types yields their natural set interpretations:

.. math::

   \Eval{\kw{i32}} & =~~ \Z \\
   \Eval{\kw{f32}} & =~~ \R \\
   \Eval{\kw{bool}} & =~~ \{\fop{true},\fop{false}\} \\
   \Eval{\kw{(}\tau_1,\cdots,\tau_n\kw{)}} & =~~ \Eval{\tau_1} \times \cdots \times \Eval{\tau_n} \\
   \Eval{\kw{[]}\tau} & =~~ \N \rightarrow \Eval{\tau} \\
   \Eval{\tau_1 \rightarrow \tau_2} & =~~ \Eval{\tau_1} \rightarrow \Eval{\tau_2}

For ease of presentation, we consider a syntactic vector value
:math:`\kw{[}v_1,\cdots,v_n\kw{]}` equal to the projection function on
the vector, returning a default value of the underlying type for
indexes greater than :math:`n-1` (zero-based interpretation).

For built-in operators :math:`\id{op}_\tau`, annotated with their type
instance :math:`\tau` according to the typing rules, we assume a
semantic function :math:`\Eval{\id{op}_\tau} : \Eval{\tau}`. As an
examples, we assume
:math:`\Eval{\kw{+}_{\kw{i32}\rightarrow\kw{i32}\rightarrow\kw{i32}}}
: \Z \rightarrow \Z \rightarrow \Z`.

When :math:`e` is some expression, we write
:math:`e[v_1/x_1,\cdots,v_n/x_n]` to denote the simultaneous
substitution of :math:`v_1,\cdots,v_n` for :math:`x_1,\cdots,x_n`
(after appropriate renaming of bound variables) in :math:`e`.

Evaluation of an expression :math:`e` is defined by an evaluation
function :math:`\Eval{\cdot} : \mathrm{Exp} \rightarrow \mathrm{Val}`.
The function is defined in a mutually recursive fashion with an
auxiliary utility function :math:`\extractF{F}` for extracting SOAC
function parameters. We first give the definition for
:math:`\Eval{\cdot}`:

.. math::

     \Eval{f~e_1~\cdots~e_n} & =~~ \Eval{e[\Eval{e_1}/x_1\cdots \Eval{e_n}/x_n]} \\
       & ~ ~~~~~ \mathrm{where}~\fw{let}~f~x_1~ \cdots x_n ~\kw{=}~ e \in P \\
     \Eval{v} & =~~ v \\
     \Eval{e\kw{[}e'\kw{]}} & =~~ \Eval{e}(\Eval{e'}) \\
     \Eval{\fw{let}~x~\kw{=}~e~\fw{in}~e'} & =~~ \Eval{e'[\Eval{e}/x]} \\
     \Eval{\fw{let}~\kw{(}x_1,\cdots,x_n\kw{)}~\kw{=}~e~\fw{in}~e'} & =~~ \Eval{e'[v_1/x_1\cdots v_n/x_n]} \\
        & ~ ~~~~~ \mathrm{where}~ \Eval{e} = \kw{(}v_1,\cdots,v_n\kw{)} \\
     \Eval{\kw{[}e_1,\cdots,e_n\kw{]}} & =~~ \kw{[}\Eval{e_1},\cdots,\Eval{e_n}\kw{]} \\
     \Eval{\kw{(}e_1,\cdots,e_n\kw{)}} & =~~ \kw{(}\Eval{e_1},\cdots,\Eval{e_n}\kw{)} \\
     \Eval{e_1~\id{binop}_\tau~e_2} & =~~ \sem{\id{binop}_\tau}~\Eval{e_1}~\Eval{e_2} \\
     \Eval{\id{op}_\tau~e_1\cdots e_n} & =~~ \sem{\id{op}_\tau}~\Eval{e_1}~\cdots~\Eval{e_n} \\
     \Eval{\fop{map}~F~e_1\cdots e_m} & =~~ \Eval{\kw{[}e'[v_1^1/x_1\cdots v_1^m/x_m],\cdots,e'[v_n^1/x_n\cdots v_n^m/x_m]\kw{]}} \\
       & ~ ~~~~~\mathrm{where}~\lambda x_1\cdots x_m . e' = \extractF{F} \\
       & ~ ~~~~~\mathrm{and}~ \kw{[}v_1^i,\cdots,v_n^i\kw{]} = \Eval{e_i} ~~~ i=[1..m]

Given a SOAC function parameter :math:`F`, we define the utility
*extraction function*, :math:`\extractF{F}`, as follows:

.. math::

     \extractF{\lam{x_1\cdots x_n}{e}} & =~~ \lambda x_1 \cdots x_n . e \\
     \extractF{\id{binop}~e} & =~~ \lambda x . x~\id{binop}~v \\
       & ~ ~~~~~\mathrm{where}~v = \Eval{e} \\
     \extractF{e~\id{binop}} & =~~ \lambda x . v~\id{binop}~x \\
       & ~ ~~~~~\mathrm{where}~v = \Eval{e}

Type soundness is expressed by the following proposition:

.. rubric:: Proposition: Futhark Type Soundness

If :math:`~\vd P : \Gamma` and :math:`\Gamma(\id{main}) = ()
\rightarrow \tau` and :math:`\Eval{\id{main}~\kw{()}} = v` then
:math:`~\vd v : \tau`.

Notice that we have glanced over the concept of bounds checking by
assuming that arrays with elements of type :math:`\tau` are
implemented as total functions from :math:`N` to :math:`\Eval{\tau}`.

Work and Span
=============

In this section we give a cost model for Futhark in terms of functions
for determining the total *work* done by a program, in terms of
operations done by the big-step evaluation semantics, and the *span*
of the program execution, in terms of the maximum depth of the
computation, assuming an infinite amount of parallelism in the SOAC
computations. The functions for work and span, denoted by :math:`W :
\mathrm{Exp} \rightarrow \N` and :math:`S : \mathrm{Exp} \rightarrow
\N` are given below.  The functions are defined independently,
although they make use of the evaluation function
:math:`\Eval{\cdot}`. We have given the definitions for the essential
SOAC functions, namely ``map`` and ``reduce``.  The definitions for
the remaining SOACs follow the same lines as the definitions for
``map`` and ``reduce``.

.. rubric:: Work (:math:`W`)

.. math::

      W(v) &=~~ 1 \\
      W(\fw{let}~x~\kw{=}~e~\fw{in}~e') &=~~ W(e) + W(e'[\Eval{e}/x]) + 1 \\
      W(\fw{let}~(x_1,...,x_n)~\kw{=}~e~\fw{in}~e') &=~~ \Let~[v_1,...,v_n] = \Eval{e} \\
       & ~ ~~ \In~W(e) + W(e'[v_1/x_1,\cdots,v_n/x_n]) + 1 \\
      W(\kw{[}e_1,\cdots,e_n\kw{]}) &=~~ W(e_1) + \ldots + W(e_n) + 1 \\
      W(\kw{(}e_1,\cdots,e_n\kw{)}) &=~~ W(e_1) + \ldots + W(e_n) + 1 \\
      W(f~e_1 \cdots e_n) &=~~ W(e_1) + \ldots + W(e_n) + W(e[\Eval{e_1}/x_1,\cdots \Eval{e_n}/x_n]) + 1 \\
      & ~ ~~ \quad \mathrm{where} (\fw{let}~f~x_1~\cdots~x_n~=~e) ~\in~ P \\
      W(e_1 \id{binop} e_2) &=~~ W(e_1) + W(e_2) + 1 \\
      W(\fop{map}~F~e) &=~~ \Let~[v_1,\cdots,v_n] = \Eval{e} \\
      & ~ ~~ \quad \lambda x. e' = \extractF{F} \\
      & ~ ~~ \In~W(e) + W(e'[v_1/x]) + \ldots + W(e'[v_n/x]) \\
      W(\fop{reduce}~F~e'~e'') &=~~ \Let~[v_1,\cdots,v_n] = \Eval{e''} \\
      & ~ ~~ \quad \lambda x~x'. e = \extractF{F} \\
      & ~ ~~ \In~W(e') + W(e'') + W(e[v_1/x,v_n/x']) \times n + 1 \\
      & ~ ~~ \quad \mathrm{assuming} ~ W(e[v_1/x,v_n/x']) ~\mathrm{indifferent~to} ~v_1~ \mathrm{and} ~v_n \\
      W(\fop{iota}~e) &=~~ W(e) + n \quad \mathrm{where} ~ n = \Eval{e}

.. rubric:: Span (:math:`S`)

.. math::

     S(v) &=~~ 1 \\
     S(\fw{let}~x~=~e~\fw{in}~e') &=~~ S(e) + S(e'[\Eval{e}/x]) + 1 \\
     S(\fw{let}~(x_1,...,x_n)~=~e~\fw{in}~e') &=~~ \Let~[v_1,...,v_n] = \Eval{e} \\
       & ~ ~~ \In~S(e) + S(e'[v_1/x_1,\cdots,v_n/x_n]) \\
     S([e_1,\cdots,e_n]) &=~~ S(e_1) + \ldots + S(e_n) + 1 \\
     S((e_1,\cdots,e_n)) &=~~ S(e_1) + \ldots + S(e_n) + 1 \\
     S(f e_1 \cdots e_n) &=~~ S(e_1) + \ldots + S(e_n) + S(e[\Eval{e_1}/x_1,\cdots \Eval{e_n}/x_n]) + 1 \\
       & ~ ~~ \quad \mathrm{where}~(\fw{let}~f~x_1~\cdots~x_n~=~e) ~\in~ P \\
     S(e_1~\id{binop}~e_2) &=~~ S(e_1) + S(e_2) + 1 \\
     S(\fop{map}~F~e) &=~~
       \Let~[v_1,\cdots,v_n] = \Eval{e} \\
       &~ ~~ \quad \lambda x. e' = \extractF{F} \\
       &~ ~~ \In~S(e) + \id{max}(S(e'[v_1/x]), \ldots , S(e'[v_n/x])) + 1 \\
     S(\fop{reduce}~F~e'~e'') &=~~
       \Let~[v_1,\cdots,v_n] = \Eval{e''} \\
       & ~ ~~ \quad \lambda x~x'. e = \extractF{F} \\
       & ~ ~~ \In~S(e') + S(e'') + W(e[v_1/x,v_n/x']) \times \mathrm{ln}\,n + 1 \\
       & ~ ~~ \quad \mathrm{assuming} ~ W(e[v_1/x,v_n/x']) ~\mathrm{indifferent~to} ~v_1~ \mathrm{and} ~v_n \\
     S(\fop{iota}~ e) &=~~ S(e) + 1

Note how the rule for ``reduce`` makes it explicit that Futhark does not promise
to exploit any parallelism inside the reduction operator.

Reduction by Contraction
========================

In this section, we shall investigate an implementation of reduction
using the general concept of *contraction*, which is the general
algorithmic trick of solving a particular problem by first making a
*contraction step*, which simplifies the problem size, and then
repeating the contraction algorithm until a final result is reached
:cite:`algdesign:parseq2016`.

The reduction algorithm that we shall implement assumes an associative
reduction operator :math:`\oplus : A \rightarrow A \rightarrow A`, a
neutral element of type :math:`A`, and a vector :math:`v` of size
:math:`2^n`, containing elements of type :math:`A`. If
:math:`\mathrm{size}(v) = 1`, the algorithm returns the single element.
Otherwise, the algorithm performs a contraction by splitting the vector
in two and applies the reduction operator elementwise on the two
subvectors, thereby obtaining a contracted vector, which is then used as
input to a recursive call to the algorithm. In Futhark, the function can
be implemented as follows:

.. literalinclude:: src/reduce_contract.fut
   :lines: 13-17

The function specializes the reduction operator :math:`\oplus` to be
``+`` and the neutral element to be ``0``. The function first pads the
argument vector ``xs`` with neutral elements to ensure that its size
is a power of two. It then implements a sequential loop with the
contraction step as its loop body, implemented by a parallel
:math:`\fop{map}` over an appropriately split input vector.

The auxiliary function for padding the input vector is implemented by
the following code:

.. literalinclude:: src/reduce_contract.fut
   :lines: 4-10

Determining Work and Span
-------------------------

To determine the work and span of the algorithm ``red``, we first
determine the work and span for ``padpow2``, for which we again need
to determine the work and span for ``nextpow2``. From simple
inspection we have :math:`W(\kw{nextpow2 n}) = S(\kw{nextpow2 n}) =
O(\mathrm{log}\,\kw{n})`. Now, from the definition of :math:`W` and
:math:`S` and because :math:`\kw{nextpow2 n} \leq 2\,\kw{n}`, we have

.. math::
   W(\kw{padpow2 ne v}) = W(\fop{concat}~v~\kw{(}\fop{replicate}~\kw{(nextpow2 n - n) ne)}) = O(\kw{n})

and

.. math:: S(\kw{padpow2 ne v}) = O(\log\,\kw{n})

where :math:`\kw{n} = \size~\kw{v}`.

Each loop iteration in has span :math:`O(1)`. Because the loop is
iterated at-most :math:`\log(2\,\kw{n})` times, we have (where
:math:`\kw{n} =
\size\,\kw{v}`)

.. math::

     W(\kw{red v}) & =~~ O(\kw{n}) + O(\kw{n/2}) + O(\kw{n/4}) + \cdots + O(1) ~~=~~ O(\kw{n}) \\
     S(\kw{red v}) & =~~ O(\log\,\kw{n})

It is an exercise for the reader to compare the performance of the
reduction code to the performance of Futhark’s built-in ``reduce``
SOAC (see :numref:`benchmarking`).

Radix-Sort by Contraction
=========================

Another example of a contraction-based algorithm is radix-sort.
Radix-sort is a non-comparison based sorting routine, which implements
sorting by iteratively moving elements with a particular bit set to the
beginning (or end) in the array. It turns out that this move of elements
with the same bit set can be parallelised. Thus, for arrays containing
32-bit unsigned integers, the sorting routine needs only 32
loop-iterations to sort the array. A central property of each step is
that elements with identical bit values will not shift position.
Depending on whether the algorithm consistently moves elements with the
bit set to the end of the array or to the beginning of the array results
in the array being sorted in either ascending or descending order.

.. _radixsort:

Radix-Sort in Futhark
---------------------

A radix-sort algorithm that sorts the argument vector in ascending order
is shown below:

.. literalinclude:: src/rsort.fut
   :lines: 20-33

The function ``rsort_step`` implements the contraction step that takes
care of moving all elements with the ``bitn`` set to the end of the
array. The main function ``rsort`` takes care of iterating the
contraction step until the array is sorted (i.e., when the contraction
step has been executed for all bits.) To appreciate the purpose of
each data-parallel operation in the function, the table below
illustrates how ``rsort_step`` takes care of moving elements with a
particular bit set (bit 1) to the end of the array. The example
assumes the current array (``xs``) contains the array
``[2,0,6,4,2,1,5,9]``.  Notice that the last three values all have
their 0-bit set whereas the first five values have not. The values
of ``xs`` marked with :math:`\dagger` are the ones with bit 1 set.

.. csv-table::
   :header: "Variable"

   ``xs``, :math:`2^\dagger`, 0, :math:`2^\dagger`, 4, :math:`2^\dagger`, 1, 5, 9
   ``bits1``, 1, 0, 1, 0, 1, 0, 0, 0
   ``bits0``, 0, 1, 0, 1, 0, 1, 1, 1
   ``scan (+) 0 bits0``, 0, 1, 1, 2, 2, 3, 4, 5
   ``idxs0``, 0, 1, 0, 2, 0, 3, 4, 5
   ``idxs1``, 1, 1, 2, 2, 3, 3, 3, 3
   ``idxs1'``, 6, 6, 7, 7, 8, 8, 8, 8
   ``idxs1''``, 6, 0, 7, 0, 8, 0, 0, 0
   ``idxs``, 6, 1, 7, 2, 8, 3, 4, 5
   ``map (-1) idxs``, 5, 0, 6, 1, 7, 2, 3, 4


By a straightforward analysis, we can argue that
:math:`W(\kw{rsort}~\kw{v})
= O(\kw{n})`, where :math:`n = \length\,\kw{v}`; each of the operations in
has work :math:`O(\kw{n})` and ``rsort_step`` is called a
constant number of times (i.e., 32 times). Similarly, we can argue that
:math:`S(\kw{rsort}~\kw{v}) = O(\log\,\kw{n})`, dominated by the SOAC
calls in ``rsort_step``.

.. _counting-primes:

Counting Primes
===============

A variant of a contraction algorithm is an algorithm that first solves a
smaller problem, recursively, and then uses this result to provide a
solution to the larger problem. One such algorithm is a version of the
Sieve of Eratosthenes that, to find the primes smaller than some
:math:`n`, first calculates the primes smaller than :math:`\sqrt n`. It
then uses this intermediate result for sieving away the integers in the
range :math:`\sqrt n` up to :math:`n` that are multiples of the primes smaller than
:math:`\sqrt n`.

Unfortunately, Futhark does not presently support recursion, thus, one
needs to use a :math:`\fw{loop}` construct instead to implement the sieve. A Futhark
program calculating the number of primes below some number :math:`n`,
also denoted in the literature as the :math:`\pi` function, is shown
below:

.. literalinclude:: src/primes.fut
   :lines: 18-

Notice that the algorithm applies a parallel sieve for each step,
using a combination of maps and reductions. The best known sequential
algorithm for finding the number of primes below some :math:`n` takes
time :math:`O(n\,\log\,\log\,n)`. Although the present algorithm is
quite efficient in practice, it is not work effcient, since the work
inside the loop is super-linear. The loop itself introduces a span
with a :math:`\log\,\log\,n` factor because the size of the problem is
squared at each step, which is identical to doubling the exponent size
at each step (i.e., the sequence :math:`2^2, 2^4, 2^8, 2^{16}, \ldots,
n`, where :math:`n=2^{2^m}`, for some positive :math:`m`, has :math:`m
= \log\,\log\,n` elements.)

In :numref:`primes-by-expansion` we discuss the possibility of using a
flattening approach to implement a work-efficient parallel
Sieve-of-Erastothenes algorithm.
