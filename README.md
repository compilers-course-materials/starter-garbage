# Garbage Snake...?

![A confused snake](https://drawception.com/pub/panels/2012/4-6/RXFXH6p2kY-12.png)

(Source: https://drawception.com/pub/panels/2012/4-6/RXFXH6p2kY-12.png)

Pick your favorite etymology:

1.  A [tentacled garbage disposal monster from Star Wars](http://starwars.wikia.com/wiki/Dianoga)
2.  A [device used to clean a drain](http://www.amazon.com/Turbo-Snake-TSNAKE-CD6-Drain-Opener/dp/B003ZHNQDS)

The Garbage language manages its memory automatically.  You will implement the
automated memory management.

A heads up – there aren't a ton of lines of code needed to complete the lab.
I wrote around 300 lines in `gc.c`.  But I also wrote some very complicated
tests in `gctest.c`, and probably spent more time on those than I did on the
collector itself.  So give yourself lots of time to carefully think through the
cases, and implement slowly.  Test `mark`, `forward`, and `compact`
individually and thoroughly.

## Language

Garbage (the language) is much the same as FDL.  It has two minor additions:

1. Pair _assignment_ with the `setfst` and `setsnd` operators,
2. `begin` blocks, which allow sequencing of expressions without hacks like
   `let unused = ... in ...`

There are some tests in `test.ml` that demonstrate these features and their
syntax.  Their implementation is provided for you.  At this point,
understanding those features will be straightforward for you, so the focus in 
this assignment is elsewhere.

## Memory Model


### Value Layout

The value layout is extended to keep track of information needed in garbage collection:

- `0xXXXXXXX[xxx0]` - Number
- `0xFFFFFFF[1111]` - True
- `0x7FFFFFF[1111]` - False
- `0xXXXXXXX[x001]` - Pair

  `[ tag ][ GC word ][ value ][ value ]`

- `0xXXXXXXX[x101]` - Closure

  `[ tag ][ GC word ][ varcount = N ][ arity ][ code ptr ][[ N vars' data ]][ maybe padding ]`


As before, pairs and closure are represented as tagged pointers.  On the heap,
each heap-allocated value has _two_ additional words.  The first holds the same
tag information as the value (so `001` for a pair and `101` for a closure).
The second is detailed below, and is used for bookkeeping during garbage
collection.

### Checking for Memory Usage, and the GC Interface

Before allocating a closure or a pair, the Garbage compiler checks that enough
space is available on the heap.  The instructions for this are implemented in
`reserve` in `compile.ml`.  If there is not enough room, the generated code
calls the `try_gc` function in `main.c` with the information needed to start
automatically reclaiming memory.

You don't need to edit these instructions, but you do need to understand them,
and how they correspond to the arguments to `try_gc`.

When the program detects that there isn't enough memory for the value it's
trying to create, it:

1. Calls `try_gc` with several values:

    - The current top of the stack
    - The current base pointer
    - The amount of memory it's trying to allocate
    - The current value of `ESI`

   These correspond to the arguments of `try_gc`.

2. Then expects that `try_gc` either:
   - Makes enough space for the value (via the algorithm described below), and
     returns a new address to use for `ESI`.
   - Terminates the program in an error if enough space cannot be made for the
     value.

There are a few other pieces of information that the algorithm needs, which the
runtime and `main.c` collaborate on setting up.

To run the mark/compact algorithm, we require:

  - The heap's starting location: This is stored in the global variable `HEAP`
    on startup.
  - The heap's ending location and size: These are stored in `HEAP_END` and
    `HEAP_SIZE` as global variables.  The generated instructions rely on
    `HEAP_END` to check for begin out of space.
  - Information about the shape of the stack: This is described below – we
    know a lot given our choice of stack layout with `EBP` and return pointers.
  - The beginning of the stack: This is stored in the `STACK_BOTTOM` variable.
    This is set by the instructions in the prelude of `our_code_starts_here`,
    using the initial value of `EBP`.  This is a useful value, because when
    traversing the stack we will consider the values between base pointers.
  - The end of the stack: This is known by our compiler, and always has the
    value `EBP + si`, where `si` is the current stack index.


