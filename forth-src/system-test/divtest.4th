\    File:  divtest.4th
\   Title:  Multiple cell division tests
\  Author:  David N. Williams
\ License:  Public Domain
\ Started:  March 14, 2006
\ Revised:  March 15, 2006
\ Revised:  March 16, 2006
\ Revised:  March 20, 2006
\ Revised:  April 6, 2006
\ Revised:  April 8, 2006
\ Revised:  April 13, 2006
\ Revised:  September 21, 2009  km

s" ans-words" included
s" ttester"   included

\ Stack effects:

\ UTS/MOD   ( num.lo num.mi num.hi denom -- rem quo.lo quo.mi quo.hi )
\ STS/REM   ( num.lo num.mi num.hi denom -- rem quo.lo quo.mi quo.hi )
\ UTM/      ( num.lo num.mi num.hi denom -- quo.lo quo.mi )
\ UM/MOD    ( num.lo num.hi denom -- rem quo.lo )

\ These tests are an elaboration of the UM/MOD tests in John
\ Hayes' core.4th.  They were written to test the author's
\ PowerPC assembly language division subroutines, written
\ initially for Krishna Myneni's kForth.

\ Four underlying, restoring shift and subtract division
\ subroutines are used in the implementation, depending on the
\ number of significant bits in the numerator.  Each of these
\ subroutines also has two subcases, depending on whether the
\ numerator has full 32-bit significance in its most significant
\ cell or not.

\ The four basic routines are called by four driver routines
\ that handle signs and analyze cases, including whether to use
\ the normal ppc divwu assembly language op.

\ These tests attempt to cover the corners, plus the normal
\ stuff for the nonstandard words UTS/MOD and STS/REM.

\ Dependences:

\ UTS/MOD  udiv96by32
\ UTM/     udiv96by32
\ UM/MOD   udiv64by32
\ STS/REM  sdiv96by32
\ SM/REM   sdiv64by32
\ FM/MOD   sdiv64by32
\ */       sdiv64by32
\ */MOD    sdiv64by32

\ sdiv96by32   udiv96by32
\ sdiv64by32   udiv64by32
\ udiv96by32   udiv96by32to96, udiv96by32to64,
\              udiv64by32to64, udiv64by32to32
\ udiv64by32   udiv64by32to64, udiv64by32to32


\ from core.4th:
0 INVERT                 CONSTANT  maxuint
0 INVERT 1 RSHIFT        CONSTANT  maxint
0 INVERT 1 RSHIFT INVERT CONSTANT  minint

hex

TESTING UTS/MOD
\ driver: udiv96by32

\ ppc divwu

TESTING num.hi = num.mi = 0

t{  0  0  0       1 uts/mod -> 0  0  0  0 }t
t{  1  0  0       1 uts/mod -> 0  1  0  0 }t
t{  1  0  0       2 uts/mod -> 1  0  0  0 }t
t{  3  0  0       2 uts/mod -> 1  1  0  0 }t
t{ -1  0  0       1 uts/mod -> 0 -1  0  0 }t

\ udiv64by32to64

TESTING num.mi.sd >= denom.sd

t{ -1 -1  0       1 uts/mod -> 0 -1 -1 0 }t
t{ -2  1  0       1 uts/mod -> 0 -2  1 0 }t
t{ -2  3  0       2 uts/mod -> 0 -1  1 0 }t
t{ -1  3  0       2 uts/mod -> 1 -1  1 0 }t

TESTING   num.mi > denom, denom.sd = 32

t{ 1 -1 0        -2 uts/mod -> 3 1 1 0 }t
t{ 0 -1 0        -2 uts/mod -> 2 1 1 0 }t

TESTING   num.mi = denom, denom.sd = 32

t{ -1 -2 0 -2 uts/mod -> 1 1 1 0 }t
t{ -2 -2 0 -2 uts/mod -> 0 1 1 0 }t
t{ fffffffd -2 0 -2 uts/mod -> fffffffd 0 1 0 }t

TESTING   num.mi < denom, denom.sd = 32

t{ 2 -2 0        -1 uts/mod ->  1 -1 0 0 }t
t{ 1 -2 0        -1 uts/mod ->  0 -1 0 0 }t
t{ 0 -2 0        -1 uts/mod -> -2 -2 0 0 }t

\ udiv64by32to32

TESTING num.mi.sd < denom.sd

t{ -2 1 0   2 uts/mod -> 0 -1 0 0 }t
t{ -1 1 0   2 uts/mod -> 1 -1 0 0 }t
t{ fffffff0 3 0  10 uts/mod -> 0 3fffffff 0 0 }t
t{ fffffff8 3 0  10 uts/mod -> 8 3fffffff 0 0 }t
t{ -2 1 0   2 uts/mod -> 0 -1 0 0 }t

TESTING   num.mi < denom, denom.sd = 32

t{ -2 1 0              -1 uts/mod -> 0  2  0  0 }t
t{ 10000001 efffffff 0 -1 uts/mod -> 1 f0000000 0 0 }t
t{ 10000000 efffffff 0 -1 uts/mod -> 0 f0000000 0 0 }t
t{ 0fffffff efffffff 0 -1 uts/mod -> -2 efffffff 0 0 }t

\ udiv96by32to96

TESTING num.hi.sd >= denom.sd

t{ -1 -1 -1       1 uts/mod -> 0 -1 -1 -1 }t
t{ -2 -1  1       1 uts/mod -> 0 -2 -1  1 }t
t{ -2 -1  3       2 uts/mod -> 0 -1 -1  1 }t
t{ -1 -1  3       2 uts/mod -> 1 -1 -1  1 }t
t{  0  1 -2      -1 uts/mod -> 0  0 -1  0 }t

\ udiv96by32to64

TESTING num.hi.sd < denom.sd

t{ -2 -1 1  2 uts/mod -> 0 -1 -1 0 }t
t{ -1 -1 1  2 uts/mod -> 1 -1 -1 0 }t
t{ fffffff0 -1 3 10 uts/mod -> 0 -1 3fffffff 0 }t
t{ fffffff8 -1 3 10 uts/mod -> 8 -1 3fffffff 0 }t
t{ -2 -1 1  2 uts/mod -> 0 -1 -1  0 }t
t{  0 -2 1 -1 uts/mod -> 0  0  2  0 }t

TESTING STS/REM

\ Because it's based on the same underlying unsigned division
\ code as UTS/MOD, we just adapt the core.4th SM/REM tets, and
\ check most positive number overflow.

t{  0  0  0  1 sts/rem ->  0  0  0  0 }t
t{  1  0  0  1 sts/rem ->  0  1  0  0 }t
t{  2  0  0  1 sts/rem ->  0  2  0  0 }t
t{ -1 -1 -1  1 sts/rem ->  0 -1 -1 -1 }t
t{ -2 -1 -1  1 sts/rem ->  0 -2 -1 -1 }t
t{  0  0  0 -1 sts/rem ->  0  0  0  0 }t
t{  1  0  0 -1 sts/rem ->  0 -1 -1 -1 }t
t{  2  0  0 -1 sts/rem ->  0 -2 -1 -1 }t
t{ -1 -1 -1 -1 sts/rem ->  0  1  0  0 }t
t{ -2 -1 -1 -1 sts/rem ->  0  2  0  0 }t
t{  2  0  0  2 sts/rem ->  0  1  0  0 }t
t{ -1 -1 -1 -1 sts/rem ->  0  1  0  0 }t
t{ -2 -1 -1 -2 sts/rem ->  0  1  0  0 }t
t{  7  0  0  3 sts/rem ->  1  2  0  0 }t
t{  7  0  0 -3 sts/rem ->  1 -2 -1 -1 }t
t{ -7 -1 -1  3 sts/rem -> -1 -2 -1 -1 }t
t{ -7 -1 -1 -3 sts/rem -> -1  2  0  0 }t
t{ -1 maxint  1  1 sts/rem -> 0 -1 maxint 1 }t
t{  0 minint  0  1 sts/rem -> 0 0 minint 0 }t
t{  0 maxint  0  1 sts/rem -> 0 0 maxint 0 }t
t{  minint   -1 -1 minint sts/rem -> 0 1 0 0 }t
t{ -1  1  0  4 sts/rem ->  3 maxint  0  0 }t
t{  2  0  minint ds* 2 sts/rem ->  0 minint -1 -1 }t
t{  2  0  minint ds* minint sts/rem ->  0  2  0  0 }t
t{  2  0  maxint ds* 2 sts/rem ->  0  maxint  0  0 }t
t{  0 minint minint ds* minint sts/rem ->  0  0 minint -1 }t
t{  0 minint maxint ds* minint sts/rem ->  0  0 maxint  0 }t
t{  0 minint maxint ds* maxint sts/rem ->  0  0 minint -1 }t
t{ -1 maxint maxint ds* maxint sts/rem ->  0 -1 maxint  0 }t

\ Uncomment a line to test divide by zero.
\ t{  0 0 0 0 sts/rem -> 0 }t
\ t{ -1 0 0 0 sts/rem -> 0 }t
\ t{  0 -1  0  0 sts/rem -> 0 }t
\ t{  0  0 -1  0 sts/rem -> 0 }t
\ t{  1  2  3  0 sts/rem -> 0 }t

\ Uncomment the line to test postive number overflow.
\ t{ 0 0 minint -1 sts/rem -> 0 }t

1 [IF]
TESTING UTM/
\ driver: udiv96by32

\ ppc divwu

TESTING num.hi = num.mi = 0

t{  0  0  0       1 utm/ ->  0  0 }t
t{  1  0  0       1 utm/ ->  1  0 }t
t{  1  0  0       2 utm/ ->  0  0 }t
t{  3  0  0       2 utm/ ->  1  0 }t
t{ -1  0  0       1 utm/ -> -1  0 }t

\ udiv64by32to64

TESTING num.mi.sd >= denom.sd

t{ -1 -1  0        1 utm/ -> -1 -1 }t
t{ -2  1  0        1 utm/ -> -2  1 }t
t{ -2  3  0        2 utm/ -> -1  1 }t
t{ -1  3  0        2 utm/ -> -1  1 }t

TESTING   num.mi > denom, denom.sd = 32

t{ 1 -1 0        -2 utm/ -> 1 1 }t
t{ 0 -1 0        -2 utm/ -> 1 1 }t

TESTING   num.mi = denom, denom.sd = 32

t{ -1 -2 0 -2 utm/ -> 1 1 }t
t{ -2 -2 0 -2 utm/ -> 1 1 }t
t{ fffffffd -2 0 -2 utm/ -> 0 1 }t

TESTING   num.mi < denom, denom.sd = 32

t{ 2 -2 0        -1 utm/ -> -1 0 }t
t{ 1 -2 0        -1 utm/ -> -1 0 }t
t{ 0 -2 0        -1 utm/ -> -2 0 }t

\ udiv64by32to32

TESTING num.mi.sd < denom.sd

t{ -2 1 0   2 utm/ -> -1 0 }t
t{ -1 1 0   2 utm/ -> -1 0 }t
t{ fffffff0 3 0  10 utm/ -> 3fffffff 0 }t
t{ fffffff8 3 0  10 utm/ -> 3fffffff 0 }t
t{ -2 1 0   2 utm/ -> -1 0 }t

TESTING   num.mi < denom, denom.sd = 32

t{ -2 1 0        -1 utm/ ->  2  0 }t
t{ 10000001 efffffff 0 -1 utm/ -> f0000000 0 }t
t{ 10000000 efffffff 0 -1 utm/ -> f0000000 0 }t
t{ 0fffffff efffffff 0 -1 utm/ -> efffffff 0 }t

\ udiv96by32to96

TESTING num.hi.sd >= denom.sd

t{ 0 1 -2        -1 utm/ -> 0 -1 }t

\ Uncomment individual lines to test divide by zero.
\ t{ 0 0 0  0 utm/ -> 0 }t
\ t{ 1 0 0  0 utm/ -> 0 }t
\ t{ 0 1 0  0 utm/ -> 0 }t
\ t{ 0 0 1  0 utm/ -> 0 }t

\ Uncomment individual lines to test division overflow into the
\ third cell:
\ t{ -1 -1 -1  1 utm/ -> -1 -1 }t \ -1
\ t{ -2 -1  1  1 utm/ -> -2 -1 }t \ 1
\ t{ -2 -1  3  2 utm/ -> -1 -1 }t \ 1
\ t{ -1 -1  3  2 utm/ -> -1 -1 }t \ 1

\ udiv96by32to64

TESTING num.hi.sd < denom.sd

t{ -2 -1 1  2 utm/ -> -1 -1 }t
t{ -1 -1 1  2 utm/ -> -1 -1 }t
t{ fffffff0 -1 3 10 utm/ -> -1 3fffffff }t
t{ fffffff8 -1 3 10 utm/ -> -1 3fffffff }t
t{ -2 -1 1  2 utm/ -> -1 -1 }t
t{ 0 -2 1  -1 utm/ -> 0  2 }t
[THEN]

\ TESTING UM/MOD FM/MOD
comment Use core.4th for UM/MOD FM/MOD nonexception tests.
\ drivers: udiv64by32 and sdiv64by32

\ Copied from core.4th:
0 [IF]
t{ 0 0 1 UM/MOD -> 0 0 }t
t{ 1 0 1 UM/MOD -> 0 1 }t
t{ 1 0 2 UM/MOD -> 1 0 }t
t{ 3 0 2 UM/MOD -> 1 1 }t
t{ -1  2 UM*       2 UM/MOD -> 0 -1 }t
t{ -1  2 UM*      -1 UM/MOD -> 0  2 }t
t{ -1 -1 UM*      -1 UM/MOD -> 0 -1 }t
[THEN]

\ Uncomment a line to test divide by zero.
\ t{ 0 0 0 um/mod -> 0 }t
\ t{ 1 0 0 um/mod -> 0 }t
\ t{ 0 1 0 um/mod -> 0 }t

\ Uncomment a line to test division overflow into the second
\ cell.
\ t{ -1 -1       1 UM/MOD -> 0 }t \ -1 -1
\ t{ -2  1       1 UM/MOD -> 0 }t \ -2 1
\ t{ -2  3       2 UM/MOD -> 0 }t \ -1 1
\ t{ -1  3       2 UM/MOD -> 1 }t \ -1 1

\ Because there are so many, we do not copy the core.4th FM/MOD
\ tests.

\ Uncomment a line to test divide by zero.
\ t{ 0 0 0 fm/mod -> 0 }t
\ t{ 1 0 0 fm/mod -> 0 }t
\ t{ 0 1 0 fm/mod -> 0 }t

\ Uncomment the line to test postive number overflow.
\ t{ 0 minint -1 fm/mod -> 0 }t

\ Uncomment a line to test division overflow into the second
\ cell.
\ t{ -1  0  1 fm/mod -> 0 }t \ -1 0
\ t{ 3fffffff  1  1 fm/mod -> 0 }t \ 3fffffff 1
\ t{ 3fffffff -1  1 fm/mod -> 0 }t \ 3fffffff -1
\ t{ -2  3 -2 fm/mod -> 0 }t \ 1 -2
\ t{  0  3 -2 fm/mod -> 1 }t \ minint -2

testing SM/REM

t{  0  0  1 sm/rem ->  0  0 }t
t{  1  0  1 sm/rem ->  0  1 }t
t{  2  0  1 sm/rem ->  0  2 }t
t{ -1 -1  1 sm/rem ->  0 -1 }t
t{ -2 -1  1 sm/rem ->  0 -2 }t
t{  0  0 -1 sm/rem ->  0  0 }t
t{  1  0 -1 sm/rem ->  0 -1 }t
t{  2  0 -1 sm/rem ->  0 -2 }t
t{ -1 -1 -1 sm/rem ->  0  1 }t
t{ -2 -1 -1 sm/rem ->  0  2 }t
t{  2  0  2 sm/rem ->  0  1 }t
t{ -1 -1 -1 sm/rem ->  0  1 }t
t{ -2 -1 -2 sm/rem ->  0  1 }t
t{  7  0  3 sm/rem ->  1  2 }t
t{  7  0 -3 sm/rem ->  1 -2 }t
t{ -7 -1  3 sm/rem -> -1 -2 }t
t{ -7 -1 -3 sm/rem -> -1  2 }t
t{ maxint  0  1 sm/rem -> 0 maxint }t
t{ minint -1  1 sm/rem -> 0 minint }t
t{ minint -1 minint sm/rem -> 0 1 }t
t{ -1  1  4 sm/rem ->  3 maxint }t
t{  2  minint m* 2 sm/rem ->  0 minint }t
t{  2  minint m* minint sm/rem ->  0  2 }t
t{  2  maxint m* 2 sm/rem ->  0  maxint }t
t{  minint minint m* minint sm/rem ->  0 minint }t
t{  minint maxint m* minint sm/rem ->  0 maxint }t
t{  minint maxint m* maxint sm/rem ->  0 minint }t
t{  maxint maxint m* maxint sm/rem ->  0 maxint }t

\ Uncomment a line to test divide by zero.
\ t{ 0 0 0 sm/rem -> 0 }t
\ t{ 1 0 0 sm/rem -> 0 }t
\ t{ 0 1 0 sm/rem -> 0 }t

\ Uncomment the line to test postive number overflow.
\ t{ 0 minint -1 sm/rem -> 0 }t

\ Uncomment a line to test division overflow into the second
\ cell.
\ t{ -1  0  1 sm/rem ->  0 }t \ -1 0
\ t{ 3fffffff  1  1 sm/rem ->  0 }t \ 3fffffff 1
\ t{ 3fffffff -1  1 sm/rem ->  0 }t \ 3fffffff -1
\ t{ -2  3 -2 sm/rem ->  0 }t \ 1 -2
\ t{ -1  0  1 sm/rem -> -1 }t \ -1 -1

comment Uncomment lines in divtest.4th to test error reports.

