(       Title:  Complex Word Set Tests
         File:  complex-test.fs
       Author:  David N. Williams
      Version:  1.0.3b
      License:  LGPL
Last revision:  December 9, 2010
)
\ Copyright (C) 2002, 2003, 2005-2010 David N. Williams
(
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or at your option any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free
Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
MA 02111-1307 USA.

This code tests our revisions of Julian V. Noble's complex
arithmetic lexicon in complex.fs [FSL Algorithm #60] and
complex-kahan.fs, and our C version of the latter, which
implements pfe's COMPLEX-EXT module.

It is known to work when floats are doubles or extended doubles,
but has not been tested with singles.  In fact the tolerances
for fp comparisons used in this file are too small for singles.

The code is intended to test for formal correctness, not high
accuracy.  It does not include any tests involving IEEE 754
floating-point values for signed zero, NaN, or infinity.  A
separate file for such tests, complex-ieee-test.fs, may be found
here:

  http://www.umich.edu/~williams/archive/forth/complex/

In particular, that file uses signed zero to compare values for
complex elementary and inverse functions on their branch cuts to
explicit formulas worked out from their OpenMath principal
expressions.

"Gauge functions" are functions that we test against.  They are
defined independently here, sometimes in terms of already tested
functions.

Except for DEFER and IS, this code is compatible with ANS Forth,
with an environmental dependence on lower case.

Unattributed changes are by David N. Williams.  The last
revision date above may reflect cosmetic changes not logged
here.

Version 1.0.3b
25Dec10 * Adapted for unified data/fp stack systems -- km

Version 1.0.3
 9Dec10 * Revised library selection.
	* Added tests for:  COMPLEX COMPLEXES COMPLEX+
	* Added exception test for ZLITERAL.
24Dec10 * Made [ElSE] upper case. km

Version 1.0.2
17Nov10 * Made PRINCIPAL-ARG a value, to agree with complex.fs
	  1.0.2, and revised test logic accordingly.
 1Dec10 * Renamed COPYSIGN as FCOPYSIGN.

Version 1.0.1
14Aug09 * Replaced a holdover F-> by ->, discovered by Krishna
	  Myneni.
	* Added report for separate/integrated fp stack.
	* Made all reports conditional on VERBOSE, except
	  ABORT's.
	* Revised library selection logic.

Version 1.0 [Forth Scientific Library]
17May09 * Retired former complex-test.fs and renamed
	  complex-ttest.fs as complex-test.fs.
	* Added comment that no tests of IEEE special values are
	  included.
	* Revised conditional compilation logic.

Version 0.9.8
 4Mar09 * Temporarily renamed as "complex-ttest.fs".  Adapted
	  complex-test.fs to use Anton Ertl's ttester.fs instead
	  of tester.fs and ftester.fs.
	* Removed "(f:" and its redefinition here in favor of
	  "( f:", which hid an inadvertent use of it in
	  complex.fs, where it is not defined.

Version 0.9.7
 4Sep08	* Renamed Z-ROT as -ZROT, affecting only pfe
	  COMPLEX-EXT.
20Sep08 * Renamed F-ROT as -FROT.
	* Removed [DEFINED] conditional from ZROT and -ZROT
	  tests.
	* Added ZLITERAL tests.

Version 0.9.6
 6Sep06 * Really changed names of mixed argument words, not
	  actually done in 0.9.5.
	* Removed tests for FPI, F0.0, F1.0,Z=0, Z=1, Z=I, which
	  were already commented out.

Version 0.9.5
24Apr05 * Changed names of mixed argument words to use jvn's
          more telegraphic style.  Also removed parentheses to
          get -I*.  Made adjustments for submission of
          complex.fs 0.8.3 to the FSL.
 3Sep05 * Fixed a typo discovered by Dirk Busch, namely, DEFINED
          should have been [DEFINED].  It didn't cause a problem
          on our system because both pfe and gforth have both
          words, one an alias for the other.

Version 0.9.4
 7Feb05 * Started moving tests with Inf, -Inf, and NaN,
          including all tests of ZBOX, to complex-ieee-test.fs,
          which was formerly named complex-szero-test.fs.
        * Renamed ->}}F as }}F, and left existing }}F unchanged.
          The latter cases now do an extra test for changes in
          data stack input, a fail-safe that hurts nothing.
 8Feb05 * Finished moving tests to complex-ieee-test.fs.
        * Removed tests Z=0, etc., which we no longer define in
          complex-kahan.fs or complex-ext.c.  Those constants
          were already unused in this code.
 4Mar05 * Changed ZACOS, ZASIN, ZATAN, and ZACOT tests to avoid
          the cuts.  The cuts are tested in
          complex-ieee-test.fs.

Version 0.9.3
12Jan05 * Reordered some tests and added FZ*, FZ/, ZF*, ZF/,
          IFZ*, IFZ/, ZIF*, ZIF/.
        * Added #ERRORS output, requiring ftester.fs 1.1.3 or
          above.
14Jan05 * Added ZBOX.
15Jan05 * Revised to test for sign-conserving ZBOX.

Version 0.9.2
 5Mar03 * Removed signed zero and branch cut tests.  Now
          they're in complex-szero-test.fs.

Version 0.9.1
21Feb03 * Added principal branch cut definitions and tests.
28Feb03 * Rearranged conditional includes.

Version 0.9.0
12Dec02 * Start.
18Feb03 * Release.
)

[UNDEFINED] \\ [IF]
: \\  ( -- )  -1 parse 2drop BEGIN refill 0= UNTIL ; [THEN]

1 CONSTANT NOBLE
2 CONSTANT KAHAN
3 CONSTANT PFE

\ USER-CONFIG: select complex library implementation
  NOBLE
\ KAHAN
\ PFE
  CONSTANT COMPLEX-TEST-LIB

: NOBLE? ( -- flag ) COMPLEX-TEST-LIB NOBLE = ;
: KAHAN? ( -- flag ) COMPLEX-TEST-LIB KAHAN = ;
: PFE?   ( -- flag ) COMPLEX-TEST-LIB PFE = ;

NOBLE? [IF]
(
The nonprincipal argument can be used only with complex.fs, and
then only for arg, log, and nonintegral powers.  Uncomment the
line below to override the complex.fs default, and use the
principal argument for those operations instead.
)
  s" complex.4th" included  \ defines PRINCIPAL-ARG  
\ true to PRINCIPAL-ARG
[THEN]

KAHAN? [IF]
  s" complex-kahan.4th" included
[THEN]

PFE? [IF] \ only for pfe
  s" COMPLEX-EXT" environment? [IF] ( version) drop
  [ELSE]
   cr .( COMPLEX-EXT not available.) cr ABORT
  [THEN]
[THEN]

[UNDEFINED] PRINCIPAL-ARG [IF] true VALUE PRINCIPAL-ARG [THEN]

s" ttester.4th" included
true verbose !
decimal
: z}t   rr}t ;
: zz}t  rrrr}t ;
: zzz}t  6 0 DO ftester LOOP ...}t ;


: ?s.       ( c-addr len -- )  verbose @ IF cr type ELSE 2drop THEN ;
: ?emit-cr  ( -- )             verbose @ IF cr THEN ;

: NONAME  ( lib.case -- )
  COMPLEX-TEST-LIB CASE
    NOBLE OF s" Testing complex.fs." ENDOF
    KAHAN OF s" Testing complex-kahan.fs." ENDOF
    PFE   OF s" Testing pfe complex words." ENDOF
    ABORT" ***No complex words loaded"
  ENDCASE ?s. ; NONAME

verbose @ [IF]
:noname  ( -- fp.separate? )
  depth >r 1e depth >r fdrop 2r> = ; execute
cr .( Floating-point stack is )
[IF] .( *separate*) [ELSE] .( *not separate*) [THEN]
.(  from the data stack.)
[THEN]

\ assume floats are doubles or extended doubles
: near-defaults  ( -- )
  1E-15 rel-near f!
  1E-15 abs-near f! ;
near-defaults

variable #errors   0 #errors !

:noname  ( c-addr u -- )
(
Display an error message followed by the line that had the
error.
)
  1 #errors +! error1 ;  error-xt !

 0.7853981633974483096157E0 FCONSTANT  pi/4
-0.7853981633974483096157E0 FCONSTANT -pi/4
 0.5497787143782138167310E1 FCONSTANT  7pi/4
[UNDEFINED] pi/2 [IF]
 0.1570796326794896619231E1 FCONSTANT  pi/2
[THEN]
-0.1570796326794896619231E1 FCONSTANT -pi/2
 0.4712388980384689857694E1 FCONSTANT  3pi/2

 0.2356194490192344928847E1 FCONSTANT  3pi/4
-0.2356194490192344928847E1 FCONSTANT -3pi/4
 0.3926990816987241548078E1 FCONSTANT  5pi/4

[UNDEFINED] pi [IF]
 0.3141592653589793238463E1 FCONSTANT  pi
[THEN]
[UNDEFINED] -pi [IF]
-0.3141592653589793238463E1 FCONSTANT -pi
[THEN]

 0.2718281828459045235360E1 FCONSTANT  e
-0.2718281828459045235360E1 FCONSTANT -e
 0.3678794411714423215955E0 FCONSTANT  1/e
-0.3678794411714423215955E0 FCONSTANT -1/e
[UNDEFINED] ln2 [IF]
 0.6931471805599453094172E0 FCONSTANT  ln2
[THEN]
-0.6931471805599453094172E0 FCONSTANT -ln2
 0.1414213562373095048802E1 FCONSTANT  rt2
-0.1414213562373095048802E1 FCONSTANT -rt2
 0.7071067811865475244008E0 FCONSTANT  1/rt2
-0.7071067811865475244008E0 FCONSTANT -1/rt2

\ only two choices
PRINCIPAL-ARG [IF]
s" arg output -pi < arg <= pi" ?s.
  -3pi/4 FCONSTANT 225arg
  -pi/2  FCONSTANT 270arg
  -pi/4  FCONSTANT 315arg
[ELSE]
s" arg output 0 <= arg < 2pi" ?s.
   5pi/4 FCONSTANT 225arg
   3pi/2 FCONSTANT 270arg
   7pi/4 FCONSTANT 315arg
[THEN] ?emit-cr

defer gauge
defer func
defer inverse

\ ZVARIABLE, Z!, and Z@ have to be tested before the next
\ words are used.

ZVARIABLE zatemp   ZVARIABLE zbtemp

: ?gauge  ( f: z -- )
(
Compare the functions whose xt's are in FUNC and GAUGE.
) 
  zdup zatemp z! gauge   ->   zatemp z@ func ;

: ?2gauge  ( f: z1 z2 -- )
(
Same as above with 2 complex arguments.
) 
  zbtemp z! zatemp z!
  zatemp z@ zbtemp z@ gauge   ->   zatemp z@ zbtemp z@ func ;

: ?inverse  ( f: z -- )
(
Check that INVERSE FUNCT, i.e., func[inverse], is the identity
mapping.
)
  zdup zatemp z! inverse func   ->   zatemp z@ ;

: -z   znegate ;


\ *** NONSTANDARD FP WORDS

testing  S>F -FROT FNIP FTUCK 1/F F^2 F2* F2/

set-exact 
t{    0 s>f ->    0E r}t
t{  137 s>f ->  137E r}t
t{ -137 s>f -> -137E r}t

t{ 1E1 2E1 3E1 -frot -> 3E1 1E1 2E1 rrr}t
t{ 1E1 2E1     fnip  -> 2E1           r}t
t{ 1E1 2E1     ftuck -> 2E1 1E1 2E1 rrr}t

t{  2E 1/f ->  0.5E r}t
t{ -2E 1/f -> -0.5E r}t

t{  0E f^2 -> 0E r}t
t{  2E f^2 -> 4E r}t
t{ -2E f^2 -> 4E r}t

t{     0E   f2* ->     0E r}t
t{   128E   f2* ->   256E r}t
t{ -12.8E   f2* -> -25.6E r}t
set-near
t{  1/rt2   f2* ->  rt2 r}t
t{ -1/rt2   f2* -> -rt2 r}t

set-exact
t{     0E f2/ ->     0E   r}t
t{   256E f2/ ->   128E   r}t
t{ -25.6E f2/ -> -12.8E   r}t
set-near
t{  rt2   f2/ ->  1/rt2 r}t
t{ -rt2   f2/ -> -1/rt2 r}t

[DEFINED] fcopysign [IF]
testing  FCOPYSIGN

set-exact
t{  11E   3E fcopysign ->  11E r}t
t{  -7E   5E fcopysign ->   7E r}t
t{   5E  -7E fcopysign ->  -5E r}t
t{  -3E -11E fcopysign ->  -3E r}t
[THEN]


\ *** LOAD AND STORE

testing  ZCONSTANT ZVARIABLE ZLITERAL Z@ Z!

set-exact
t{ 1E 2E ZCONSTANT 1+i2 ->       }t
t{ 1+i2                 -> 1E 2E z}t
t{ : equ ZCONSTANT ;    ->       }t
t{ 1+i2 equ z=(1+i2)    ->       }t
t{ z=(1+i2)             -> 1+i2  z}t

 0E  0E ZCONSTANT  0+i0
 1E  0E ZCONSTANT  1+i0
-1E  0E ZCONSTANT -1+i0
 0E  1E ZCONSTANT  0+i1
 0E -1E ZCONSTANT  0-i1

t{ ZVARIABLE zv1 ->      }t
t{ 1+i2 zv1 z!   ->      }t
t{ zv1 z@        -> 1+i2 z}t

: lit-1+i0  ( f: -- 1+i0 )
  [ 1+i0 ] ZLITERAL ;

t{ lit-1+i0 -> 1+i0 z}t

PFE? 0= [IF]
\ uncomment to see compile only exception:
\ 1+i0 ZLITERAL
\ t{ 1+i0 ' ZLITERAL CATCH zdrop -> -14 }t
t{ 1+i0 ' ZLITERAL CATCH -> 1+i0 -14 rrx}t  \ for unified stack
[ELSE]  \ pfe version is noop when interpreting
t{ 1+i0 ZLITERAL -> 1+i0 z}t
[THEN]

testing  COMPLEX COMPLEXES COMPLEX+

t{    COMPLEX   -> 2 floats }t
t{  0 COMPLEXES -> 0 }t
t{  3 COMPLEXES -> COMPLEX 3 * }t
t{ -1 COMPLEXES -> COMPLEX negate }t
t{  1 COMPLEX+  -> 1 COMPLEX + }t


\ *** COMPLEX STACK MANIPULATION

testing  ZDROP ZDUP ZSWAP ZOVER ZNIP ZTUCK ZROT -ZROT

set-exact
t{ 0+i0      zdrop ->                }t
t{ 1+i0      zdup  -> 1+i0 1+i0      zz}t
t{ 0+i0 1+i0 zswap -> 1+i0 0+i0      zz}t
t{ 0+i0 1+i0 zover -> 0+i0 1+i0 0+i0 zzz}t
t{ 0+i0 1+i0 znip  -> 1+i0           z}t
t{ 0+i0 1+i0 ztuck -> 1+i0 0+i0 1+i0 zzz}t
t{ 0+i0 1+i0 0+i1  zrot -> 1+i0 0+i1 0+i0 zzz}t
t{ 0+i0 1+i0 0+i1 -zrot -> 0+i1 0+i0 1+i0 zzz}t


\ *** COMPLEX ALGEBRA

testing  REAL IMAG CONJG Z*F  Z/F Z* Z/ Z+ Z-

set-exact
t{ 1+i0  real  -> 1E r}t
t{ 0+i1  imag  -> 1E r}t
t{ 1E 2E conjg -> 1E -2E z}t

set-near  \ true also works in pfe
t{ 1E 2E 3E    z*f ->  3E  6E z}t
t{ 3E 6E 3E    z/f ->  1E  2E z}t
t{ 1E 2E 3E 4E z*  -> -5E 10E z}t
t{ 1E 2E 1+i0  z*  ->  1E  2E z}t
t{ 1E 2E 0+i1  z*  -> -2E  1E z}t
t{ 1E 1E 3E 4E z/  ->  7E 25E f/ -1E 25E f/ z}t
t{ 1E 1E 4E 3E z/  ->  7E 25E f/  1E 25E f/ z}t
t{ 1E 2E 3E 4E z+  ->  4E  6E z}t
t{ 1E 2E 3E 4E z-  -> -2E -2E z}t

testing  ZNEGATE Z2* Z2/ I* -I*

set-near  \ ignore signed zero
t{  0+i0 -z  ->  0+i0 z}t
t{  0+i0 z2* ->  0+i0 z}t
t{  0+i0 z2/ ->  0+i0 z}t
t{  0+i0 i*  ->  0+i0 z}t
t{  0+i0 -i* ->  0+i0 z}t

set-exact
t{   1E   -2E  -z  ->  -1E    2E  z}t
t{  40E1 -20E1 z2* ->  80E1 -40E1 z}t
t{ -40E1  20E1 z2* -> -80E1  40E1 z}t
t{  50E1 -30E1 z2/ ->  25E1 -15E1 z}t
t{ -50E1  30E1 z2/ -> -25E1  15E1 z}t
t{  40E1 -20E1 i*  ->  20E1  40E1 z}t
t{ -40E1  20E1 i*  -> -20E1 -40E1 z}t
t{  40E1 -20E1 -i* -> -20E1 -40E1 z}t
t{ -40E1  20E1 -i* ->  20E1  40E1 z}t


\ *** MINIMAL (MIXED) OPERATIONS

testing  X+ X- Y+ Y-

set-exact
t{ 1E 2E 3E x+ ->  4E 2E z}t
t{ 1E 2E 3E x- -> -2E 2E z}t
t{ 1E 2E 4E y+ ->  1E  6E z}t
t{ 1E 2E 4E y- ->  1E -2E z}t

[DEFINED] i*f/z [IF]
testing  Z*>REAL Z*>IMAG  Z*F Z/F F*Z F/Z Z*I*F -I*Z/F I*FZ* I*F/Z

set-exact
t{ 1E 2E 3E 4E z*>real -> -5E z}t
t{ 1E 2E 3E 4E z*>imag -> 10E z}t
t{ -1E  2E 3E z*f -> -1E  2E  3E 0E z* z}t
t{ -3E -6E 3E z/f -> -3E -6E  3E 0E z/ z}t
t{  3E  1E 2E f*z ->  3E  0E  1E 2E z* z}t
set-near  \ pfe works with exact
t{  3E  6E 3E f/z  ->  3E  0E  6E 3E  z/ z}t
set-exact
t{ -1E  2E 3E  z*i*f -> -1E  2E  0E 3E z* z}t
t{ -3E -6E 3E -i*z/f -> -3E -6E  0E 3E z/ z}t
t{  3E  1E 2E  i*f*z ->  0E  3E  1E 2E z* z}t
t{  3E  6E 3E  i*f/z ->  0E  3E  6E 3E z/ z}t
[THEN]


\ *** ALGEBRAIC FUNCTIONS

testing  |Z| |Z|^2 1/Z Z^2 Z^N

set-exact
t{  0+i0   |z|   -> 0E r}t
t{  0+i0   |z|^2 -> 0E r}t
t{  0+i0   z^2   -> 0+i0 z}t

set-near
t{  3E  4E |z|   ->  5E r}t
t{ -3E  4E |z|   ->  5E r}t
t{  3E -4E |z|   ->  5E r}t
t{  3E  4E |z|^2 -> 25E r}t
t{ -3E  4E |z|^2 -> 25E r}t
t{  3E -4E |z|^2 -> 25E r}t
t{  3E  4E 1/z   ->  3E  25E f/ -4E 25E f/ z}t
t{ -3E  4E 1/z   -> -3E  25E f/ -4E 25E f/ z}t
t{  3E -4E 1/z   -> -3E -25E f/  4E 25E f/ z}t
t{  1+i0   1/z   ->  1+i0 z}t
t{  3E  4E z^2   -> -7E  24E z}t
t{ -3E  4E z^2   -> -7E -24E z}t
t{  3E -4E z^2   -> -7E -24E z}t
t{ -3E -4E z^2   -> -7E  24E z}t

set-exact
t{  0+i0     0 z^n ->  1+i0 z}t
t{  1+i0     0 z^n ->  1+i0 z}t
t{ -1+i0     0 z^n ->  1+i0 z}t
t{  0+i1     0 z^n ->  1+i0 z}t
t{  0-i1     0 z^n ->  1+i0 z}t
t{  rt2  rt2 0 z^n ->  1+i0 z}t
t{  rt2 -rt2 0 z^n ->  1+i0 z}t
t{ -rt2  rt2 0 z^n ->  1+i0 z}t
t{ -rt2 -rt2 0 z^n ->  1+i0 z}t

t{  0+i0     1 z^n ->  0+i0 z}t
t{  1+i0     1 z^n ->  1+i0 z}t
t{ -1+i0     1 z^n -> -1+i0 z}t
t{  0+i1     1 z^n ->  0+i1 z}t
t{  0-i1     1 z^n ->  0-i1 z}t
t{  rt2  rt2 1 z^n ->  rt2  rt2 z}t
t{  rt2 -rt2 1 z^n ->  rt2 -rt2 z}t
t{ -rt2  rt2 1 z^n -> -rt2  rt2 z}t
t{ -rt2 -rt2 1 z^n -> -rt2 -rt2 z}t

t{  0+i0     2 z^n ->  0+i0 z}t
t{  1+i0     2 z^n ->  1+i0 z}t
t{ -1+i0     2 z^n ->  1+i0 z}t
t{  0+i1     2 z^n -> -1+i0 z}t
set-near \ avoid signed zero discrepancy
t{  0-i1     2 z^n -> -1+i0 z}t
set-exact
t{  3E  4E   2 z^n -> -7E  24E z}t
t{ -3E  4E   2 z^n -> -7E -24E z}t
t{  3E -4E   2 z^n -> -7E -24E z}t
t{ -3E -4E   2 z^n -> -7E  24E z}t

t{  0+i0     5 z^n ->  0+i0 z}t
t{  1+i0     5 z^n ->  1+i0 z}t
t{ -1+i0     5 z^n -> -1+i0 z}t
t{  0+i1     5 z^n ->  0+i1 z}t
t{  0-i1     5 z^n ->  0-i1 z}t
t{  2E  2E   5 z^n -> -128E -128E z}t
t{  2E -2E   5 z^n -> -128E  128E z}t
t{ -2E  2E   5 z^n ->  128E -128E z}t
t{ -2E -2E   5 z^n ->  128E  128E z}t


\ *** ELEMENTARY FUNCTIONS

testing  ARG >POLAR POLAR> ZSQRT ZLN ZEXP Z^

set-exact
t{  0+i0     arg -> 0E     r}t
t{  1+i0     arg -> 0E     r}t
t{  0+i1     arg -> pi/2   r}t
t{  0-i1     arg -> 270arg r}t
t{ -1+i0     arg -> pi     r}t
set-near
t{  2E  2E   arg -> pi/4   r}t
t{  3E -3E   arg -> 315arg r}t
set-exact
t{ -rt2  rt2 arg -> 3pi/4  r}t
t{ -rt2 -rt2 arg -> 225arg r}t

rt2 f2*   FCONSTANT 2rt2
rt2 3E f* FCONSTANT 3rt2

set-exact
t{  0+i0     >polar -> 0+i0     rr}t
t{  1+i0     >polar -> 1+i0     rr}t
t{  0+i1     >polar -> 1E pi/2   rr}t
t{  0-i1     >polar -> 1E 270arg rr}t
t{ -1+i0     >polar -> 1E pi     rr}t
set-near
t{  2E   2E  >polar -> 2rt2 pi/4   rr}t
t{  3E  -3E  >polar -> 3rt2 315arg rr}t
t{ -rt2  rt2 >polar -> 2E   3pi/4  rr}t
t{ -rt2 -rt2 >polar -> 2E   225arg rr}t

set-exact
t{ 0+i0        polar> ->  0+i0 z}t
t{ 1+i0        polar> ->  1+i0 z}t
set-near
t{ 1E    pi/2  polar> ->  0+i1 z}t \ Re(f) = -6.123234E-17
t{ 1E   -pi/2  polar> ->  0-i1 z}t \ Re(f) = 6.123234E-17
t{ 1E    pi    polar> -> -1+i0 z}t \ Im(f) = 1.224647E-16
t{ 2rt2  pi/4  polar> ->  2E   2E  z}t
t{ 3rt2 -pi/4  polar> ->  3E  -3E  z}t
t{ 2E    3pi/4 polar> -> -rt2  rt2 z}t
t{ 2E   -3pi/4 polar> -> -rt2 -rt2 z}t

: gsqrt  ( f: z -- exp[[ln|z|+iarg[z]]/2] )
  zln z2/ zexp ; 

' zsqrt is func   ' gsqrt is gauge
set-near
t{ 0+i0 zsqrt -> 0+i0 z}t
t{  2E   0E  ?gauge z}t
t{ -2E   0E  ?gauge z}t \ Re(g) = 8.659561E-17
t{  0E   2E  ?gauge z}t
t{  0E  -2E  ?gauge z}t
t{  rt2  rt2 ?gauge z}t
t{  rt2 -rt2 ?gauge z}t
t{ -rt2  rt2 ?gauge z}t
t{ -rt2 -rt2 ?gauge z}t

set-exact
t{  1+i0     zln -> 0+i0      z}t
t{  0+i1     zln -> 0E pi/2   z}t
t{  0-i1     zln -> 0E 270arg z}t
t{ -1+i0     zln -> 0E pi     z}t
set-near
t{ -2E   0E  zln -> ln2 pi     z}t
t{  rt2  rt2 zln -> ln2 pi/4   z}t
t{  rt2 -rt2 zln -> ln2 315arg z}t
t{ -rt2  rt2 zln -> ln2 3pi/4  z}t
t{ -rt2 -rt2 zln -> ln2 225arg z}t

 1/rt2 f2/      FCONSTANT  1/2rt2
 1/2rt2 fnegate FCONSTANT -1/2rt2

set-exact
t{  0+i0       zexp ->  1+i0 z}t
t{  ln2  0E    zexp ->  2E   0E z}t
set-near
t{ -ln2  0E    zexp ->  0.5E 0E z}t
t{  0E   pi    zexp -> -1+i0    z}t \ Im(f) = 1.224647E-16
t{  0E   pi/2  zexp ->  0+i1    z}t \ Re(f) =6.123234E-17
t{  0E  -pi/2  zexp ->  0+i1 conjg z}t \ Re(f) = 6.123234E-17
t{  0E   pi/4  zexp ->  1/rt2   1/rt2  z}t
t{  0E  -pi/4  zexp ->  1/rt2  -1/rt2  z}t
t{  0E   3pi/4 zexp -> -1/rt2   1/rt2  z}t
t{  0E  -3pi/4 zexp -> -1/rt2  -1/rt2  z}t
t{  ln2  pi/4  zexp ->  rt2     rt2    z}t
t{  ln2 -pi/4  zexp ->  rt2    -rt2    z}t
t{ -ln2  3pi/4 zexp -> -1/2rt2  1/2rt2 z}t
t{ -ln2 -3pi/4 zexp -> -1/2rt2 -1/2rt2 z}t

set-exact
t{  1+i0     0+i0  z^ ->  1+i0 z}t
t{ -1+i0     0+i0  z^ ->  1+i0 z}t
t{  0+i1     0+i0  z^ ->  1+i0 z}t
t{  0-i1     0+i0  z^ ->  1+i0 z}t
t{  rt2  rt2 0+i0  z^ ->  1+i0 z}t
t{  rt2 -rt2 0+i0  z^ ->  1+i0 z}t
t{ -rt2  rt2 0+i0  z^ ->  1+i0 z}t
t{ -rt2 -rt2 0+i0  z^ ->  1+i0 z}t

: identical  ( f: z -- z )  ;

: z^(z=1)   1+i0 z^ ;

' z^(z=1) is func   ' identical is gauge
set-near
t{  1+i0     ?gauge z}t
t{ -1+i0     ?gauge z}t \ Im(f) = 1.224647E-16
t{  0+i1     ?gauge z}t \ Re(f) = 6.123234E-17
t{  0-i1     ?gauge z}t \ Re(f) = 6.123234E-17
t{  rt2  rt2 ?gauge z}t
t{  rt2 -rt2 ?gauge z}t
t{ -rt2  rt2 ?gauge z}t
t{ -rt2 -rt2 ?gauge z}t

:noname  ( f: z -- z^(1+i2)  1+i2 z^ ;           is func
:noname  ( f: z -- z^(1+i2)  zln 1+i2 z* zexp ;  is gauge
t{  1+i0     ?gauge z}t
t{ -1+i0     ?gauge z}t
t{  0+i1     ?gauge z}t
t{  0-i1     ?gauge z}t
t{  rt2  rt2 ?gauge z}t
t{  rt2 -rt2 ?gauge z}t \ pfe 1
t{ -rt2  rt2 ?gauge z}t
t{ -rt2 -rt2 ?gauge z}t \ pfe 2

testing  ZCOSH ZSINH ZTANH ZCOTH ZCOS ZSIN ZTAN ZCOT

e 1/e f+ f2/ FCONSTANT ch1
e 1/e f- f2/ FCONSTANT sh1
      ch1 0E ZCONSTANT zch1
      sh1 0E ZCONSTANT zsh1
  sh1 ch1 f/ FCONSTANT th1
  ch1 sh1 f/ FCONSTANT cth1
      th1 0E ZCONSTANT zth1
     cth1 0E ZCONSTANT zcth1

ch1 sh1 rt2 z/f ZCONSTANT zC1
      zC1 conjg ZCONSTANT zC2
sh1 ch1 rt2 z/f ZCONSTANT zC3
      zC3 conjg ZCONSTANT zC4 

set-exact
t{  0+i0     zcosh -> 1+i0 z}t
set-near
t{  1+i0     zcosh -> zch1 z}t
t{ -1+i0     zcosh -> zch1 z}t
t{  0E  pi/2 zcosh -> 0+i0 z}t \ Re(f) = 6.123234E-17
t{  0E -pi/2 zcosh -> 0+i0 z}t \ Re(f) = 6.123234E-17
t{  1E  pi/4 zcosh -> zC1  z}t
t{  1E -pi/4 zcosh -> zC2  z}t
t{ -1E  pi/4 zcosh -> zC2  z}t
t{ -1E -pi/4 zcosh -> zC1  z}t

set-exact
t{  0+i0     zsinh -> 0+i0 z}t
set-near
t{  1+i0     zsinh -> zsh1 z}t
t{ -1+i0     zsinh -> sh1 fnegate 0E z}t
t{  0E  pi/2 zsinh -> 0+i1 z}t
t{  0E -pi/2 zsinh -> 0+i1 conjg z}t
t{  1E  pi/4 zsinh -> zC3  z}t
t{  1E -pi/4 zsinh -> zC4  z}t
t{ -1E  pi/4 zsinh -> zC4 -z z}t
t{ -1E -pi/4 zsinh -> zC3 -z z}t

1E  pi/4 zdup zsinh zswap zcosh z/ ZCONSTANT ztanhA
1E -pi/4 zdup zsinh zswap zcosh z/ ZCONSTANT ztanhB
ztanhA 1/z ZCONSTANT zcothA
ztanhB 1/z ZCONSTANT zcothB

set-exact
t{  0+i0     ztanh -> 0+i0 z}t
set-near
t{  1+i0     ztanh -> zth1 z}t
t{ -1+i0     ztanh -> zth1 -z z}t
t{  0E  pi/4 ztanh -> 0+i1 z}t
t{  0E -pi/4 ztanh -> 0+i1 conjg z}t
t{  1E  pi/4 ztanh -> ztanhA z}t
t{  1E -pi/4 ztanh -> ztanhB z}t
t{ -1E  pi/4 ztanh -> ztanhB -z  z}t
t{ -1E -pi/4 ztanh -> ztanhA -z  z}t

set-near
t{  1+i0     zcoth -> zcth1 z}t
t{ -1+i0     zcoth -> zcth1 -z  z}t
t{  0E  pi/4 zcoth -> 0+i1 conjg z}t
t{  0E -pi/4 zcoth -> 0+i1 z}t
t{  1E  pi/4 zcoth -> zcothA z}t
t{  1E -pi/4 zcoth -> zcothB z}t
t{ -1E  pi/4 zcoth -> zcothB -z z}t
t{ -1E -pi/4 zcoth -> zcothA -z z}t

:noname  -i* zcos ;  is func
' zcosh is gauge
set-exact
t{  0+i0     ?gauge z}t
t{  1+i0     ?gauge z}t
t{ -1+i0     ?gauge z}t
t{  0E  pi/2 ?gauge z}t
t{  0E -pi/2 ?gauge z}t
t{  1E  pi/4 ?gauge z}t
t{  1E -pi/4 ?gauge z}t
t{ -1E  pi/4 ?gauge z}t
t{ -1E -pi/4 ?gauge z}t

:noname  i* zsin ;   is func
:noname  zsinh i* ;  is gauge
set-near
t{  0+i0     ?gauge z}t
t{  1+i0     ?gauge z}t
t{ -1+i0     ?gauge z}t
t{  0E  pi/2 ?gauge z}t
t{  0E -pi/2 ?gauge z}t
t{  1E  pi/4 ?gauge z}t
t{  1E -pi/4 ?gauge z}t
t{ -1E  pi/4 ?gauge z}t
t{ -1E -pi/4 ?gauge z}t

:noname  i* ztan ;  is func
:noname  ztanh i* ; is gauge
set-near
t{  0+i0     ?gauge z}t
t{  1+i0     ?gauge z}t
t{ -1+i0     ?gauge z}t
t{  0E  pi/4 ?gauge z}t
t{  0E -pi/4 ?gauge z}t
t{  1E  pi/4 ?gauge z}t
t{  1E -pi/4 ?gauge z}t
t{ -1E  pi/4 ?gauge z}t
t{ -1E -pi/4 ?gauge z}t

:noname  i* zcot ;     is func
:noname  zcoth -i* ;   is gauge
set-near
t{  1+i0     ?gauge z}t
t{ -1+i0     ?gauge z}t
t{  0E  pi/4 ?gauge z}t
t{  0E -pi/4 ?gauge z}t
t{  1E  pi/4 ?gauge z}t
t{  1E -pi/4 ?gauge z}t
t{ -1E  pi/4 ?gauge z}t
t{ -1E -pi/4 ?gauge z}t


\ *** INVERSE FUNCTIONS

true to PRINCIPAL-ARG

testing  ZASINH ZACOSH ZATANH ZACOTH

\ Inverse hyperbolic gauges.  Note that in the principal
\ expressions for the gauges here, and in GACOS in the next
\ section, it is important to use "1E x+" instead of "1+i0 z+"
\ to preserve the sign of zero on the branch cuts.  That is
\ not tested in this file (see complex-ieee-test.fs).

: gasinh   ( z -- [ln[z+sqrt[z^2+1]]] )
  zdup z^2 1E x+ zsqrt z+ zln ;

: gacosh   ( z -- 2ln[sqrt[[z+1]/2]+sqrt[[z-1]/2] )
  zdup 1E x- z2/ zsqrt   zswap 1E x+ z2/ zsqrt
  z+ zln z2* ;

: gatanh   ( z -- [ln[1+z]-ln[1-z]]/2 )
  zdup 1E x+ zln   zswap -z 1E x+ zln   z- z2/ ;

: gacoth  ( z = [ln[-1-z]-ln[1-z]]/2 )
(
Use -1E 0E Z+ instead of 1+i0 Z- so -0 doesn't give the wrong
value on the ZLN principal branch cut.
)
  -z zdup -1+i0 z+ zln   zswap 1+i0 z+ zln   z- z2/ ;

\ Check that the gauges are inverses.  The order func(inverse)
\ used here, e.g., ZACOSH COSH in Forth reverse polish, should
\ work for all branches of the inverse when func is meromorphic.

' gasinh is inverse   ' zsinh is func
set-near
t{ 0+i0       ?inverse z}t
t{ zsh1       ?inverse z}t
t{ zsh1 -z    ?inverse z}t
t{ 0+i1       ?inverse z}t
t{ 0+i1 conjg ?inverse z}t
t{ zC3        ?inverse z}t
t{ zC4        ?inverse z}t
t{ zC4 -z     ?inverse z}t
t{ zC3 -z     ?inverse z}t

' zasinh is func   ' gasinh is gauge
set-near
t{ 0+i0       ?gauge z}t
t{ zsh1       ?gauge z}t
t{ zsh1 -z    ?gauge z}t
t{ 0+i1       ?gauge z}t
t{ 0+i1 conjg ?gauge z}t
t{ zC3        ?gauge z}t
t{ zC4        ?gauge z}t
t{ zC4 -z     ?gauge z}t
t{ zC3 -z     ?gauge z}t

' gacosh is inverse   ' zcosh  is func
set-near
t{ 1+i0 ?inverse z}t
t{ zch1 ?inverse z}t
t{ 0+i0 ?inverse z}t \ Re(f^-1 f) = 6.123234E-17, Im((f^-1 f) = 4.440892E-16
t{ zC1  ?inverse z}t
t{ zC2  ?inverse z}t

' zacosh is func   ' gacosh is gauge   
set-near
t{ 1+i0 ?gauge z}t
t{ zch1 ?gauge z}t
t{ 0+i0 ?gauge z}t \ Re(g) = 2.220446E-16
t{ zC1  ?gauge z}t
t{ zC2  ?gauge z}t

' gatanh is inverse   ' ztanh is func
set-near
t{ 0+i0       ?inverse z}t
t{ zth1       ?inverse z}t
t{ zth1 -z    ?inverse z}t
t{ 0+i1       ?inverse z}t
t{ 0+i1 conjg ?inverse z}t
t{ ztanhA     ?inverse z}t
t{ ztanhB     ?inverse z}t
t{ ztanhB -z  ?inverse z}t
t{ ztanhA -z  ?inverse z}t

' zatanh is func   ' gatanh is gauge
set-near
t{  0+i0       ?gauge z}t
t{  0+i1       ?gauge z}t
t{  1E  1E     ?gauge z}t
t{  1E -1E     ?gauge z}t
t{ -1E  1E     ?gauge z}t
t{ -1E -1E     ?gauge z}t
t{  0+i1 conjg ?gauge z}t
t{ zth1        ?gauge z}t
t{ zth1 -z     ?gauge z}t
t{ ztanhA      ?gauge z}t
t{ ztanhB      ?gauge z}t
t{ ztanhB -z   ?gauge z}t
t{ ztanhA -z   ?gauge z}t

' gacoth is inverse   ' zcoth is func
set-near
t{ zcth1      ?inverse z}t
t{ zcth1 -z   ?inverse z}t
t{ 0+i1 conjg  ?inverse z}t
t{ 0+i1        ?inverse z}t
t{ zcothA     ?inverse z}t
t{ zcothB     ?inverse z}t
t{ zcothB -z  ?inverse z}t
t{ zcothA -z  ?inverse z}t

[DEFINED] zacoth [IF]
' zacoth is func   ' gacoth is gauge
set-near
t{ zcth1      ?gauge z}t
t{ zcth1 -z   ?gauge z}t
t{ 0+i1 conjg ?gauge z}t
t{ 0+i1       ?gauge z}t
t{ zcothA     ?gauge z}t
t{ zcothB     ?gauge z}t
t{ zcothB -z  ?gauge z}t
t{ zcothA -z  ?gauge z}t
[THEN]

testing  ZASIN ZACOS ZATAN ZACOT

\ Inverse trigonometric gauges.  GACOS is uncouth in the sense
\ of Corless, Davenport, Jeffrey, and Watt, i.e., not related to
\ the inverse hyperbolic counterpart by the naive identity.

: gacos   ( f: z -- -2iln[sqrt[[1+z]/2]+isqrt[[1-z]/2]] )
  zdup 1E x+ z2/ zsqrt   zswap -z 1E x+ z2/ zsqrt
  i* z+ zln z2* -i*  ;

: gasin   i*  gasinh -i* ;
: gatan   i*  gatanh -i* ;
: gacot   -i* gacoth -i* ;

\ We've checked that the inverse hyperbolic gauges are inverses,
\ so where they're couthly related, it's sufficient to check one
\ case of each inverse trigonometric gauge, where both input and
\ output are full complex numbers.  We checked by hand that zC1
\ works.

' gacos is inverse   ' zcos is func
set-near
t{ zC1 ?inverse z}t
t{ zC2 ?inverse z}t
t{ zC3 ?inverse z}t
t{ zC4 ?inverse z}t
t{ zC1 gasin zsin -> zC1 z}t
t{ zC1 gatan ztan -> zC1 z}t
t{ zC1 gacot zcot -> zC1 z}t

' zacos is func
' gacos is gauge
\ stay off the cut |x| >= 1
set-near
t{  0E   0E    ?gauge z}t \ Im(g) = -4.440892E-16
t{  pi/4  0E   ?gauge z}t \ Im(g) = 2.220446E-16
t{ -pi/4  0E   ?gauge z}t \ Im(g) = 2.220446E-16
t{  0E    pi/4 ?gauge z}t
t{  0E   -pi/4 ?gauge z}t
t{  0E    pi/2 ?gauge z}t
t{  0E   -pi/2 ?gauge z}t
t{  pi/2  pi/4 ?gauge z}t
t{  pi/2 -pi/4 ?gauge z}t
t{ -pi/2  pi/4 ?gauge z}t
t{ -pi/2 -pi/4 ?gauge z}t

' zasin is func
' gasin is gauge
\ stay off the cut |x| >= 1
set-near
t{  0E   0E    ?gauge z}t
t{  pi/4  0E   ?gauge z}t \ Im(g) = -1.348379E-17
t{ -pi/4  0E   ?gauge z}t \ Im(g) = -1.348379E-17
t{  0E    pi/4 ?gauge z}t
t{  0E   -pi/4 ?gauge z}t
t{  0E    pi/2 ?gauge z}t
t{  0E   -pi/2 ?gauge z}t
t{  pi/2  pi/4 ?gauge z}t
t{  pi/2 -pi/4 ?gauge z}t
t{ -pi/2  pi/4 ?gauge z}t
t{ -pi/2 -pi/4 ?gauge z}t

' zatan is func
' gatan is gauge
\ stay off the cut |y| >= 1
set-near
t{  0E   0E    ?gauge z}t
t{  pi/4  0E   ?gauge z}t
t{ -pi/4  0E   ?gauge z}t
t{  0E    pi/4 ?gauge z}t
t{  0E   -pi/4 ?gauge z}t
t{  pi/2  0E   ?gauge z}t
t{ -pi/2  0E   ?gauge z}t
t{  pi/2  pi/4 ?gauge z}t
t{  pi/2 -pi/4 ?gauge z}t
t{ -pi/2  pi/4 ?gauge z}t
t{ -pi/2 -pi/4 ?gauge z}t

[DEFINED] zacot [IF]
' zacot is func
' gacot is gauge
\ stay off the cut |y| <= 1
set-near
t{  pi/2  0E   ?gauge z}t
t{ -pi/2  0E   ?gauge z}t
t{  0E    pi/2 ?gauge z}t
t{  0E   -pi/2 ?gauge z}t
t{  pi    0E   ?gauge z}t
t{ -pi    0E   ?gauge z}t
t{  pi/4  pi/2 ?gauge z}t
t{  pi/4 -pi/2 ?gauge z}t
t{ -pi/4  pi/2 ?gauge z}t
t{ -pi/4 -pi/2 ?gauge z}t
[THEN]

verbose @ [IF] .( #ERRORS: ) #errors @ . cr [THEN]
