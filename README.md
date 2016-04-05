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

## Runtime and Memory Model


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
    value of `ESP` at the point of garbage collection.

All of this has been set up for you, but you do need to understand it.  So
study `try_gc` (which you'll make one minor edit to), the new variables in
`main.c`, and the code in `compile.ml` that relates to allocating and storing
values (especially the `reserve` function and the instructions it generates).

We discuss the three phases in more detail next.

#### Mark



## Managing Memory

Your work in this assignment is all in managing memory.  You do _not_ need to
write any OCaml code for this assignment.  You will only need to edit one file
for code—`gc.c`—and you will write tests in both `gctest.c` and `test.ml`.
Fundamentally, you will implement a mark/compact algorithm that reclaims space
by rearranging memory.

### Mark/Compact

The algorithm works in three phases:

1. **Mark** – Starting from all the references on the stack, all of the
reachable data on the heap is _marked_ as live.  Marking is done by setting the
least-significant bit of the GC word to 1.
2. **Forward** – For each live value on the heap, a new address is calculated
and stored.  These addresses are calculated to compact the data into the front
of the heap with no gaps.  The forwarded addresses, which are stored in the
remainder of the GC word, are then used to update all the values on the stack
and the heap to point to the new locations.  Note that this step does not yet
move any data, just set up forwarding pointers.
3. **Compact** – Each live value on the heap is copied to its forwarding
location, and has its GC word zeroed out for future garbage collections.

The end result is a heap that stores only the data reachable from the heap, in
as little space as possible (given our heap layout).  Allocation can proceed
from the end of the compacted space by resetting `ESI` to the final address.

Here's a running example.  The `HEAP_SIZE` is 20 (so 80 total bytes), and we
consider the snapshot in time where the `f` function has just been called.

![https://github.swarthmore.edu/raw/cs75-s16/starter-garbage/master/notes_page001.svg?token=AAAAF_W4bPscwxLUW5p9eInL4t1YWGqBks5XDFZLwA%3D%3D](an example)

### Testing

This lab has you write tests both of the language and of the underlying garbage
collection algorithm.

**Testing the Language** – This works mostly as before, except that there are
a few additional forms for checking things relative to the garbage collector.
The main program is parameterized over an integer argument that allows you to
select the size of the heap in terms of (4-byte) words.  This is exposed
through the testing library as well, so you can write:

```
tgc "gctest" 10 "(1, 2)" "(1, 2)"
```

and this will run the test with a heap size of 10.

You can also test for specific errors, for example in the case that there will
never be enough memory to fit the required data:

```
tgcerr "gctest" 10 "(1, (3, (4, 5)))" "Out of memory"
```

Finally, you can use `tvgc` to run a `tgc` test with `valgrind`, to improve
errors on segfaults and check memory.

**Testing The Collector** – You can write tests for the garbage collector
implementation itself in `gctest.c`, and run them with:

```
> make gctest
> ./gctest
```

This uses the [CuTest](http://cutest.sourceforge.net/) testing framework for C,
augmented with a testing procedure for arrays.  You can read the given example
to see how a test is set up:  You can add new tests by creating a function of
the same shape as `TestMark`, and adding it with a call to `SUITE_ADD_TEST` at
the bottom.

The given test works by allocating arrays to represent the stack and heap, and
calling `mark`, `forward`, and `compact` on them.  The results are checked by
building separate arrays to compare against the heap as it is altered after
each step, with the `CuAssertArrayEquals` function.  This function takes a test
context (necessary boilerplate for the testing library), two arrays, and a
length, and compares indices up to that length for equality.  Be aware that it
only reports one mismatch in the output.

Feel free to augment this function, or use the other testing functions in
CuTest (see cutest-1.5/README.txt in the repo for the other functions) to test
more.

Note that the given test will fail until you implement some of mark, forward,
and compact, as they don't change the heap at all in their initial stubbed-out
versions.

**Printing** – There's a helper, `print_heap`, defined for you in `gc.c` that
takes an array and a number of elements to print, and prints them one per line
like so:

```
  0/0x100df0: 0x5 (5)
  1/0x100df4: 0x0 (0)
  ...
  23/0x100e4c: 0x4 (4)
  24/0x100e50: 0xcab005e (212533342)
```

The first number is the 0-based index from the start of the array, and the
second is the memory address.  After the colon is the value, in hex form and in
decimal form (in parentheses).  This is a useful layout of information to have
at a glance for interpreting the structure of the heap.

While automated testing and a debugger are both invaluable, sometimes there's
just no substitute for pretty-printing the heap after each phase in a
complicated test.


