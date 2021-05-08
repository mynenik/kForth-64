\           File:  regress.4th
\          Title:  Regression tests
\         Author:  David N. Williams
\        License:  Public Domain, except for GPL in D+ and D- tests
\  Starting date:  March 22, 2006
\        Revised:  August 1, 2007
\        Revised:  March 16, 2008  km; removed "include ans-words"
\        Revised:  September 26, 2009  km; include ttester.4th instead of 
\                   tester.4th
\        Revised:  November 25, 2009  km; integrated tests for WITHIN from
\                    separate test file.
\        Revised:  April 23, 2010  km; replaced floating point number
\                    comparison tests using FNEARLY with standard method
\                    of testing provided by ttester.4th; tests for M*/
\                    with a negative third argument are commented out
\                    since this condition is ambiguous per DPANS94.
\        Revised:  April 16, 2017  km; fixed mispelling, FFLOOR to FLOOR
\                    in comment line.
\        Revised:  January 26, 2020  km; fixed DU< tests for 64-bit.
\        Revised:  January 29, 2020  km; added tests for UW@ SW@ UL@ SL@ L!
\        Revised:  February 13, 2020 km; added tests for NUMBER? 
s" ans-words.4th" included
s" ttester.4th" included

: 64bit? 1 cells 8 = ;

: cell-  ( n -- n' )  1 cells - ;

\ from core.4th:
0 INVERT                 CONSTANT  maxuint
0 INVERT 1 RSHIFT        CONSTANT  maxint
0 INVERT 1 RSHIFT INVERT CONSTANT  minint

minint   1 RSHIFT        CONSTANT  minint/2
minint/2 NEGATE          CONSTANT -minint/2 

create pad 512 allot

testing 0<> 0> <> U>

hex
t{  5 0<> -> true }t
t{  0 0<> -> false }t
t{ -1 0<> -> true }t
t{ maxint 0>  -> true }t
t{ -1 0>  -> false }t
t{  0 0>  -> false }t
t{  0  1 <>  -> true  }t
t{  0  0 <>  -> false }t
t{ -1 -2 u> -> true  }t
t{ -1 -1 u> -> false }t
t{  1  1 u> -> false }t
t{  1  0 u> -> true  }t
t{ -1  0 u> -> true  }t

testing WITHIN

t{  0  0  0  within  ->  false }t
t{  2  6  5  within  ->  true  }t
t{  2  6  2  within  ->  false }t
t{  2  6  6  within  ->  false }t
t{ -6 -2 -4  within  ->  true  }t
t{ -2 -6 -4  within  ->  false }t
t{ -6 -2 -2  within  ->  false }t
t{ -6 -2 -6  within  ->  false }t
t{ -1  2  1  within  ->  true  }t
t{ -1  2  2  within  ->  false }t
t{ -1  2 -1  within  ->  false }t
t{  0 -1  1  within  ->  true  }t

testing UW@ SW@ W! UL@ SL@ L!

2variable scratch

t{ 1ffff scratch w! -> }t
t{ scratch uw@ -> ffff }t
t{ scratch sw@ -> -1 }t
t{ 0 s>d scratch 2! ->  }t
t{ -1 scratch w! -> }t
t{ scratch sw@ -> -1 }t
t{ scratch 2+ uw@ -> 0 }t
t{ scratch 2+ sw@ -> 0 }t
t{ 7fff scratch w! scratch sw@ -> 7fff }t

t{ ffffffff scratch l! -> }t
t{ 1 scratch 4 + l! -> }t
t{ scratch ul@ -> ffffffff }t
t{ scratch sl@ -> -1 }t
t{ scratch 2+ ul@ -> 1ffff }t
t{ scratch 2+ sl@ -> 1ffff }t
t{ 0 s>d scratch 2! -> }t
t{ -1 scratch l! -> }t
t{ scratch sl@ -> -1 }t
t{ scratch 4 + ul@ -> 0 }t
t{ scratch 4 + sl@ -> 0 }t

testing <= >= -ROT 2ROT

t{ -1  0 <= -> true  }t
t{  0  0 <= -> true  }t
t{  1  0 <= -> false }t
t{ -2 -1 <= -> true  }t
t{ -1 -1 <= -> true  }t
t{  0 -1 <= -> false }t

t{ -1  0 >= -> false }t
t{  0  0 >= -> true  }t
t{  1  0 >= -> true  }t
t{ -2 -1 >= -> false }t
t{ -1 -1 >= -> true  }t
t{  0 -1 >= -> true  }t

t{ 1 2 3 -rot -> 3 1 2 }t

t{ 1 2 3 4 5 6 2rot -> 3 4 5 6 1 2 }t

testing 2+ 2-

t{  3 2+ ->  5 }t
t{ -1 2+ ->  1 }t
t{ -2 2+ ->  0 }t
t{  3 2- ->  1 }t
t{  2 2- ->  0 }t
t{  1 2- -> -1 }t

\ testing DNEGATE
\ testing D<
comment Need tests for DNEGATE D< besides Gforth

\ testing DU<

decimal
t{     2 0    3 0 du< -> true  }t
t{     3 0    3 0 du< -> false }t
t{     4 0    3 0 du< -> false }t
t{     2 0 5000 1 du< -> true  }t
t{     2 1 5000 1 du< -> true  }t
t{     2 2 5000 1 du< -> false }t
t{ 20000 1 5000 1 du< -> false }t
t{  5000 1 5000 1 du< -> false }t
t{  4999 1 5000 1 du< -> true  }t

hex
t{ -1 maxint 0 -1 du< -> true }t
t{ -1 minint 0 -1 du<  -> true }t
64bit? [IF]
t{ -1 minint 0 9000000000000000 du< -> true }t
[ELSE]
t{ -1 minint 0 90000000 du< -> true }t
[THEN]

testing CMOVE  CMOVE>  FILL  ERASE

decimal

: ?chars  ( addr u char -- )
  -rot ( char addr u) over >r + r>
  ( char addr+u addr)
  DO i c@ over <> abort" ***character doesn't match" LOOP
  drop ;

0 pad c!   0 pad 511 + c!
t{ pad 1+ 510 21 fill -> }t
t{ pad c@ pad 511 + c@ -> 0 0 }t
pad 1+ 510 21 ?chars

3 pad c!   3 pad 511 + c!
t{ pad 0 5 fill pad c@ -> 3 }t

t{ pad 1+ 510 erase -> }t
t{ pad c@ pad 511 + c@ -> 3 3 }t
pad 1+ 510 0 ?chars

t{ pad 0 erase pad c@ -> 3 }t

: upper-pad-fill  ( char -- )  pad 256 rot fill ;
: lower-pad-fill  ( char -- )  pad 256 + 256 rot fill ;

3 upper-pad-fill   0 lower-pad-fill
t{ pad 1+ pad 257 + 254 cmove -> }t
t{ pad 256 + c@ pad 511 + c@ -> 0 0 }t
pad 257 + 254 3 ?chars

0 lower-pad-fill
t{ pad 1+ pad 257 + 254 cmove> -> }t
t{ pad 256 + c@ pad 511 + c@ -> 0 0 }t
pad 257 + 254 3 ?chars

5 0 DO i 1+ pad i + c! LOOP  \ PAD chars: 1 2 3 4 5
pad pad 1+ 4 cmove
t{ pad 5 +  pad DO i c@ LOOP -> 1 1 1 1 1 }t

5 0 DO i 1+ pad i + c! LOOP  \ PAD chars: 1 2 3 4 5
pad pad 5 cmove>
t{ pad 5 +  pad DO i c@ LOOP -> 1 2 3 4 5 }t

testing SP@  RP@  SP!  RP!  2R@  2>R  2R>

t{ 33 sp@ @ = -> true }t  \ not airtight
t{ 35 sp@ @ = -> true }t  \ but this makes it almost certain

: RP@1  ( n -- n )  >r rp@ @ r> drop ;
t{ 33 RP@1 -> 33 }t
t{ 35 RP@1 -> 35 }t  \ overkill

: 2R@1  ( n1 n2 -- n1 n2 )
  ( n2) >r ( n1) >r ( r: n2 n1) 2r@ ( n2 n1) swap
  r> drop r> drop ;
t{ 5 6 2R@1 -> 5 6 }t

: 2>R1  ( n1 n2 -- n1 n2 )
  2>r ( r: n1 n2) r> ( n2) r> ( n2 n1) swap ;
t{ 5 6 2>R1 -> 5 6 }t

: 2R>1  ( n1 n2 -- n1 n2 )
  ( n2) >r ( r: n2) ( n1) >r ( r: n2 n1) 2r> ( n2 n1) swap ;
t{ 5 6 2R>1 -> 5 6 }t

t{ 33 34 sp@ cell+ sp! -> 33 }t
t{ 33 >r 34 >r rp@ cell+ rp! r> -> 33 }t
t{ sp@ cell- dup scratch ! sp! sp@ nip -> scratch @ }t
t{ rp@ cell- dup scratch ! rp! rp@ dup cell+ rp! -> scratch @ }t

testing NIP TUCK PICK ROLL

t{ 1 2     nip -> 2 }t
t{ 1 2     tuck -> 2 1 2 }t
t{ 0 1 2 0 pick -> 0 1 2 2 }t
t{ 0 1 2 1 pick -> 0 1 2 1 }t
t{ 0 1 2 2 pick -> 0 1 2 0 }t
t{ 1 0     roll -> 1 }t
t{ 1 2 3 2 roll -> 2 3 1 }t

0 INVERT CONSTANT MAX-UINT

testing UDM* DABS M/ M*/ DS*

\ hex
t{  0  0  0 udm* ->  0  0  0 }t
t{  2  0  3 udm* ->  6  0  0 }t
t{  0 -1  2 udm* ->  0 -2  1 }t
t{ -1  0  2 udm* -> -2  1  0 }t
t{ -1  0 -1 udm* ->  1 -2  0 }t
t{  0 -1 -1 udm* ->  0  1 -2 }t
t{ -1 -1 -1 udm* ->  1 -1 -2 }t
t{ minint minint  1 udm* -> minint minint  0 }t
t{ minint minint  4 udm* ->  0  2  2 }t

t{  0  0 dabs ->  0 0 }t
t{  1  0 dabs ->  1 0 }t
t{ -1  0 dabs -> -1 0 }t
t{ -1 -1 dabs ->  1 0 }t
t{ -3 -1 dabs ->  3 0 }t
t{  0 -1 dabs ->  0 1 }t
t{  1 -1 dabs -> -1 0 }t
t{  minint 0 dabs ->  minint 0 }t
t{ -1 maxint dabs -> -1 maxint }t

t{  0  0  0 ds* ->  0  0  0 }t
t{  1  0  0 ds* ->  0  0  0 }t
t{ -1  0  0 ds* ->  0  0  0 }t
t{  0 -1  0 ds* ->  0  0  0 }t
t{ -1 -1  0 ds* ->  0  0  0 }t

t{  1  0  1 ds* ->  1  0  0 }t
t{ -1  0  1 ds* -> -1  0  0 }t
t{ -1 -1  1 ds* -> -1 -1 -1 }t

t{  1  0 -1 ds* -> -1 -1 -1 }t
t{ -1  0 -1 ds* ->  1 -1 -1 }t

t{  0  0 0 1 m*/ ->  0  0 }t
t{  0  0 1 1 m*/ ->  0  0 }t
t{  1  0 0 1 m*/ ->  0  0 }t
t{  2  0 1 2 m*/ ->  1  0 }t
t{ -2 -1 1 2 m*/ -> -1 -1 }t

t{  0  0  1 m/ ->  0 }t
t{  1  0  1 m/ ->  1 }t
t{  1  0  2 m/ ->  0 }t
t{  2  0  2 m/ ->  1 }t
t{  0  0 -1 m/ ->  0 }t
t{  1  0 -1 m/ -> -1 }t
t{  1  0 -2 m/ ->  0 }t
t{  2  0 -2 m/ -> -1 }t
t{ -1  0  2 m/ ->  maxint }t
t{ -1 -1  1 m/ -> -1 }t
t{ -1 -1 -1 m/ ->  1 }t

\ Uncommenting one of the commented lines should result in an
\ error.

\ Uncomment one of the following lines to test divide by zero.
\ t{  0  0  0  0 m*/ -> 0 }t
\ t{  1  0  1  0 m*/ -> 0 }t
\ t{  0  2  2  0 m*/ -> 0 }t
\ t{ -1 -1  1  0 m*/ -> 0 }t

\ Tests with negative third argument for M*/ are commented out,
\ since DPANS94 states that this is an ambiguous condition.  km 2010-04-23
\ t{ 0 minint/2  1 -1 m*/ ->  0 -minint/2 }t
\ t{ 0 minint/2  4 -4 m*/ ->  0 -minint/2 }t

\ To test precision overflow, leave the next lines uncommented.
\ They should not overflow.
t{ 0 minint/2  1  1 m*/ ->  0  minint/2 }t
t{ 0 minint/2 -1  1 m*/ ->  0 -minint/2 }t
t{ 0 minint/2  4  4 m*/ ->  0  minint/2 }t
t{ 0 minint/2 -4  2 m*/ ->  0  minint }t

\ But uncomment one of the following lines.
\ t{  0 minint/2  4  1  m*/ -> 0 }t
\ t{  0 maxint maxint 3 m*/ -> 0 }t
\ t{ -1 maxint 2  1     m*/ -> 0 }t
\ t{  0 minint  2  1    m*/ -> 0 }t
\ t{  0 minint -2 -1    m*/ -> 0 }t
\ t{  0 minint/2  4  2  m*/ -> 0 }t

\ Uncomment one of the following lines to test divide by zero.
\ t{  0  0  0 m/ -> 0 }t
\ t{  1  0  0 m/ -> 0 }t
\ t{  0  2  0 m/ -> 0 }t 
\ t{ -1 -1  0 m/ -> 0 }t

\ Uncomment the following line to test positive number overflow.
\ t{ 0 minint -1 m/ -> 0 }t

\ Uncomment one of the following lines to test double precision
\ overflow.
\ t{  0  2  1 m/ ->  0 }t
\ t{  0 -1  1 m/ ->  0 }t
\ t{ -1  0  1 m/ -> -1 }t

\ Uncomment one of the following lines to test divide by zero.
\ t{  0  0  / -> 0 }t
\ t{  1  0  / -> 0 }t
\ t{  2  0  / -> 0 }t
\ t{ -1  0  / -> 0 }t

\ Uncomment the following line to test positive number overflow.
\ t{ minint -1 / -> 0 }t

\ Uncomment one of the following lines to test divide by zero.
\ t{  0  0  mod -> 0 }t
\ t{  1  0  mod -> 0 }t
\ t{  2  0  mod -> 0 }t
\ t{ -1  0  mod -> 0 }t

\ Uncomment the following line to test positive number overflow.
\ t{ minint -1 mod -> 0 }t

\ Error tests for /MOD omitted, because the kForth error code is
\ so similar to that of / and MOD.

\ Uncomment one of the following lines to test divide by zero.
\ t{  0  0  0 */ -> 0 }t
\ t{  1  0  0 */ -> 0 }t
\ t{  2  0  0 */ -> 0 }t
\ t{ -1 -1  0 */ -> 0 }t
\ t{  0  0  0 */mod -> 0 }t
\ t{  1  0  0 */mod -> 0 }t
\ t{  2  0  0 */mod -> 0 }t
\ t{ -1 -1  0 */mod -> 0 }t

\ To test precision overflow, leave the next lines uncommented.
\ They should not overflow.
t{ minint/2  1  1 */ ->  minint/2 }t
t{ minint/2  1 -1 */ -> -minint/2 }t
t{ minint/2 -1  1 */ -> -minint/2 }t
t{ minint/2  1  1 */mod -> 0  minint/2 }t
t{ minint/2  1 -1 */mod -> 0 -minint/2 }t
t{ minint/2 -1  1 */mod -> 0 -minint/2 }t

\ But uncomment one of the following lines.
\ t{ minint/2  4  1    */ -> 0 }t
\ t{ maxint maxint  3  */ -> 0 }t
\ t{ minint  2  1      */ -> 0 }t
\ t{ minint -2 -1      */ -> 0 }t
\ t{ minint/2  4  2    */ -> 0 }t
\ t{ minint/2  4  1    */mod -> 0 }t
\ t{ maxint  maxint  3 */mod -> 0 }t
\ t{ minint  2  1      */mod -> 0 }t
\ t{ minint -2 -1      */mod -> 0 }t
\ t{ minint/2  4  2    */mod -> 0 }t

\ There's no way to get positive number overflow with */ or */MOD.

testing DMAX DMIN

\ Based on core.4th.
t{  0  0  1  0 dmax ->  1  0 }t
t{  1  0  2  0 dmax ->  2  0 }t
t{ -1 -1 -1 -1 dmax -> -1 -1 }t
t{ -1 -1  1  0 dmax ->  1  0 }t
t{  0  0  0  0 dmax ->  0  0 }t
t{  1  0  1  0 dmax ->  1  0 }t
t{  1  0  0  0 dmax ->  1  0 }t
t{  2  0  1  0 dmax ->  2  0 }t
t{  0  0 -1 -1 dmax ->  0  0 }t
t{  1  0 -1 -1 dmax ->  1  0 }t
t{  0 minint  0  0     dmax ->  0  0 }t
t{  0  0 -1 maxint     dmax -> -1 maxint }t
t{  0  0  0 minint     dmax ->  0  0 }t
t{ -1 maxint  0 minint dmax -> -1 maxint }t
t{ -1 maxint  0  0     dmax -> -1 maxint }t

\ to catch use of D-, which overflows
t{  0 minint -1 maxint dmax -> -1 maxint }t

\ to catch failure to use low word unsigned compare
t{  0  3 -1 2 dmax ->  0  3 }t
t{  0  3 -1 3 dmax -> -1  3 }t
t{ -1 2  0  3 dmax ->  0  3 }t
t{ -1 3  0  3 dmax -> -1  3 }t

\ Based on core.4th.
t{  0  0  1  0 dmin ->  0  0 }t
t{  1  0  2  0 dmin ->  1  0 }t
t{ -1 -1 -1 -1 dmin -> -1 -1 }t
t{ -1 -1  1  0 dmin -> -1 -1 }t
t{  0  0  0  0 dmin ->  0  0 }t
t{  1  0  1  0 dmin ->  1  0 }t
t{  1  0  0  0 dmin ->  0  0 }t
t{  2  0  1  0 dmin ->  1  0 }t
t{  0  0 -1 -1 dmin -> -1 -1 }t
t{  1  0 -1 -1 dmin -> -1 -1 }t
t{  0 minint  0  0     dmin ->  0 minint }t
t{  0  0 -1 maxint     dmin ->  0  0 }t
t{  0  0  0 minint     dmin ->  0 minint }t
t{ -1 maxint  0 minint dmin ->  0 minint }t
t{ -1 maxint  0  0     dmin ->  0  0 }t

\ to catch use of D-, which overflows
t{  0 minint -1 maxint dmin ->  0 minint }t

\ to catch failure to use low word unsigned compare
t{  0  3 -1  2 dmin -> -1  2 }t
t{  0  3 -1  3 dmin ->  0  3 }t
t{ -1  2  0  3 dmin -> -1  2 }t
t{ -1  3  0  3 dmin ->  0  3 }t

hex
testing NUMBER?
64bit? [IF]
t{ c" FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" number? -> -1 s>d true }t
t{ c" ABBA00FACADEBABACAFE" number? -> facadebabacafe abba true }t
t{ c" abba00facadebabacafe" number? -> facadebabacafe abba true }t  
[ELSE]
t{ c" FFFFFFFFFFFFFFFF" number? -> -1 s>d true }t
t{ c" FACADEBABACAFE" number?  ->  babacafe facade true }t
t{ c" facadebabacafe" number?  ->  babacafe facade true }t
[THEN]
t{ c" 5G" number?  ->  5 s>d false }t
t{ c" G5" number?  ->  0 s>d false }t
decimal

COMMENT Uncomment lines in regress.4th to test errors.

\ Use stolerance for single precision floating point 
\ nearness comparisons, and tolerance for double precision
\ fp number comparisons.   2010-04-22 km

1e-7  fconstant stolerance  \ tolerance for single precision fp
1e-15 fconstant tolerance

: -frot  ( F: x y z -- z x y )  frot frot ;

\ t{ 1e 2e 3e 4e 5e 6e -frot -> 5e 6e 1e 2e 3e 4e }t

: fwithin ( -- flag ) ( F: x y z -- )
(
Assume y < z.  Leave flag = [y<=x<z].
)
  -frot fover       ( F: z x y x)
  f<= ( [y<=x]) >r  ( F: z x)
  f> ( [z>x]) r> and
;

t{ 1e .5e  2e fwithin -> true  }t
t{ 1e  1e  2e fwithin -> true  }t
t{ 2e  .5e 2e fwithin -> false }t
t{ .5e 1e  2e fwithin -> false }t
t{ 3e  1e  2e fwithin -> false }t

0e rel-near f!
tolerance abs-near f!
SET-NEAR
t{ 1e -> 1e }t
t{ 1e tolerance 2e f/ f-  -> 1e  r}t
t{ 1e tolerance 2e f/ f+  -> 1e  r}t
t{ 1e tolerance 2e f* f- 1e fnearly= -> false }t
t{ 1e tolerance 2e f* f+ 1e fnearly= -> false }t

testing F= F<> F< F> F<= F>= F0= F0< F0>

t{  1e  2e f=  -> false }t
t{  1e  1e f=  -> true  }t
t{  1e  2e f<> -> true  }t
t{  1e  1e f<> -> false }t
t{ -1e  0e f<  -> true  }t
t{  0e -1e f<  -> false }t
t{  3e  3e f<  -> false }t
t{ -1e  0e f>  -> false }t
t{  0e -1e f>  -> true  }t
t{  3e  3e f>  -> false }t
t{ -1e  0e f<= -> true  }t
t{  0e -1e f<= -> false }t
t{  3e  3e f<= -> true  }t
t{ -1e  0e f>= -> false }t
t{  0e -1e f>= -> true  }t
t{  3e  3e f<= -> true  }t
t{  5e f0= -> false }t
t{  0e f0= -> true  }t
t{  5e f0< -> false }t
t{  0e f0< -> false }t
t{ -1e f0< -> true  }t
t{  5e f0> -> true  }t
t{  0e f0> -> false }t
t{ -1e f0> -> false }t

testing S>F D>F F>D FROUND>S FTRUNC>S SF@ SF! DF@ DF!
SET-EXACT
t{  3 s>f ->  3e r}t
t{  0 s>f ->  0e r}t
t{ -3 s>f -> -3e r}t

t{  3  0         d>f ->  3e r}t
t{  0  0         d>f ->  0e r}t
t{ -3 -1         d>f -> -3e r}t

64bit? invert [IF]
t{  0  1         d>f ->  4294967296e r}t
t{  0  1 dnegate d>f -> -4294967296e r}t
[THEN]
.s
hex
[DEFINED] FDEPTH [IF]  \ has fp stack

comment Skipping all F>D tests

[ELSE]
-1 43dfffff           fconstant  maxftod.f
maxftod.f fnegate     fconstant -maxftod.f
0 40900000            fconstant  2^10.f
1 a lshift 0          2constant  2^10.d
fffffc00 7fffffff     2constant  maxftod.d
maxftod.d dnegate     2constant -maxftod.d
-1 maxint             2constant  maxdint
maxdint dnegate       2constant -maxdint
-1 433fffff           fconstant  maxnoshift.f
maxnoshift.f fnegate  fconstant -maxnoshift.f
-1 1fffff             2constant  maxnoshift.d
maxnoshift.d dnegate  2constant -maxnoshift.d
-1 3fefffff           fconstant  1.0-2^[-53]
1.0-2^[-53] fnegate   fconstant -1.0+2^[-53]

decimal
\ underflow
t{    0e        f>d ->  0  0 }t
t{   .5e        f>d ->  0  0 }t
t{  -.5e        f>d ->  0  0 }t
comment Skipping some F>D tests
(
t{  1.0-2^[-53] f>d ->  0  0 }t
t{ -1.0+2^[-53] f>d ->  0  0 }t
)
\ right shift
t{  1e          f>d ->  1  0 }t
t{ -1e          f>d -> -1 -1 }t
t{  1.9e        f>d ->  1  0 }t
t{ -1.9e        f>d -> -1 -1 }t
\ no shift
(
t{  maxnoshift.f f>d ->  maxnoshift.d }t
t{ -maxnoshift.f f>d -> -maxnoshift.d }t
\ left shift
t{  maxftod.f  2^10.f f- f>d ->  maxftod.d 2^10.d d- }t
t{ -maxftod.f  2^10.f f+ f>d -> -maxftod.d 2^10.d d+ }t
t{  maxftod.f            f>d ->  maxftod.d }t	 
t{ -maxftod.f            f>d -> -maxftod.d }t
\ overflow
t{  maxftod.f  2^10.f f+ f>d ->  maxdint }t	 
t{ -maxftod.f  2^10.f f- f>d -> -maxdint }t	 
t{  1e  0e f/            f>d ->  maxdint }t  \  Inf
t{ -1e  0e f/            f>d -> -maxdint }t  \ -Inf
t{  0e  0e f/            f>d ->  maxdint }t  \  NaN
t{  0e  0e f/ fnegate    f>d -> -maxdint }t  \ -NaN
)
[THEN]

decimal
SET-EXACT
t{  1.8e fround>s ->  2 }t
t{  1.5e fround>s ->  2 }t
t{  1.2e fround>s ->  1 }t
t{    0e fround>s ->  0 }t
t{ -1.2e fround>s -> -1 }t
t{ -1.5e fround>s -> -2 }t
t{ -1.8e fround>s -> -2 }t

t{  1.8e ftrunc>s ->  1 }t
t{  1.5e ftrunc>s ->  1 }t
t{  1.2e ftrunc>s ->  1 }t
t{    0e ftrunc>s ->  0 }t
t{ -1.2e ftrunc>s -> -1 }t
t{ -1.5e ftrunc>s -> -1 }t
t{ -1.8e ftrunc>s -> -1 }t

stolerance rel-near f!
0e abs-near f!
SET-NEAR
variable fsingle
t{ 1.2e fsingle sf! -> }t
t{ fsingle sf@ -> 1.2e r}t

SET-EXACT
fvariable fdouble
t{ 1.2e fdouble df! -> }t
t{ fdouble df@ -> 1.2e r}t

testing DEG>RAD RAD>DEG
0.572957795130823208769e2  fconstant 180/pi
0.174532925199432957692e-1 fconstant pi/180
0.157079632679489661923e1  fconstant pi/2
0.104719755119659774615e1  fconstant pi/3
0.523598775598298873077e0  fconstant pi/6
1e 2e fsqrt f/             fconstant 1/sqrt2

tolerance rel-near f!
0e abs-near f!
SET-NEAR
t{ 1e deg>rad -> pi/180 r}t
t{ 1e rad>deg -> 180/pi r}t
t{ pi/180 rad>deg -> 180/pi deg>rad r}t
t{ 180/pi rad>deg deg>rad -> 180/pi r}t
t{ pi/180 rad>deg deg>rad -> pi/180 r}t

testing DFLOATS DFLOAT+ F+ F- F* F/ FABS FNEGATE

t{  0 dfloats ->   0 }t
t{  3 dfloats ->  24 }t
t{ -3 dfloats -> -24 }t

t{  0  dfloat+ ->  8 }t
t{ -15 dfloat+ -> -7 }t

SET-EXACT
t{  5e 3e f+ ->  8e r}t
t{  5e 3e f- ->  2e r}t
t{  5e 3e f* -> 15e r}t
t{  6e 3e f/ ->  2e r}t
t{  5e fabs -> 5e r}t
t{ -5e fabs -> 5e r}t
t{  5e fnegate -> -5e r}t
t{ -5e fnegate ->  5e r}t

testing FROUND FLOOR FTRUNC
SET-EXACT
t{  4e   fround ->  4e r}t
t{  3.8e fround ->  4e r}t
t{  3.5e fround ->  4e r}t
t{  3.3e fround ->  3e r}t
t{  0e   fround ->  0e r}t
t{ -3.3e fround -> -3e r}t
t{ -3.5e fround -> -4e r}t
t{ -3.8e fround -> -4e r}t
t{ -4e   fround -> -4e r}t

t{  4e   floor ->  4e r}t
t{  3.8e floor ->  3e r}t
t{  3.5e floor ->  3e r}t
t{  3.3e floor ->  3e r}t
t{  0e   floor ->  0e r}t
t{ -3.3e floor -> -4e r}t
t{ -3.5e floor -> -4e r}t
t{ -3.8e floor -> -4e r}t
t{ -4e   floor -> -4e r}t

t{  4e   ftrunc ->  4e r}t
t{  3.8e ftrunc ->  3e r}t
t{  3.5e ftrunc ->  3e r}t
t{  3.3e ftrunc ->  3e r}t
t{  0e   ftrunc ->  0e r}t
t{ -3.3e ftrunc -> -3e r}t
t{ -3.5e ftrunc -> -3e r}t
t{ -3.8e ftrunc -> -3e r}t
t{ -4e   ftrunc -> -4e r}t

testing FSQRT FCOS FSIN FATAN2 FSINCOS
SET-EXACT
t{  4e fsqrt -> 2e r}t
t{  0e fsqrt -> 0e r}t

tolerance rel-near f!
0e abs-near f!
SET-NEAR
t{ .5e fsqrt -> 1/sqrt2 r}t

SET-EXACT
t{ 0e   fcos -> 1e r}t

tolerance rel-near f!
tolerance abs-near f!
SET-NEAR
t{ pi/2 fcos -> 0e   r}t
t{ pi/3 fcos -> 0.5e r}t

SET-EXACT
t{ 0e   fsin -> 0e r}t
t{ pi/2 fsin -> 1e r}t

tolerance rel-near f!
0e abs-near f!
SET-NEAR
t{ pi/6 fsin -> 0.5e r}t

SET-EXACT
t{ 1e 1e fatan2 rad>deg -> 45e r}t
t{ 1e 0e fatan2 rad>deg -> 90e r}t
t{ 0e 1e fatan2 rad>deg ->  0e r}t

tolerance rel-near f!
tolerance abs-near f!
SET-NEAR
t{ 0e   fsincos -> 0e 1e rr}t
t{ pi/2 fsincos -> 1e 0e rr}t
t{ 45e deg>rad fsincos ->  1/sqrt2  1/sqrt2  rr}t

