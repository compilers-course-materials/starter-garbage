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

The memory model is extended to keep track of information needed in garbage collection:


- `0xXXXXXXX[xxx0]` - Number
- `0xFFFFFFF[1111]` - True
- `0x7FFFFFF[1111]` - False
- `0xXXXXXXX[x001]` - Pair

  `[ tag ][ GC word ][ value ][ value ]`

- 0xXXXXXXX[x101] - Closure

  `[ tag ][ GC word ][ varcount = N ][ arity ][ code ptr ][[ N vars' data ]][ maybe padding ]`

