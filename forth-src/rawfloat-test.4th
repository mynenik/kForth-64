(    Title:  Test rawfloat.fs user words
      File:  rawfloat-test.fs
   Version:  0.9.1-b
   Revised:  August 03, 2009
    Author:  David N. Williams
   License:  LGPL

Version 0.9.1-b
03Aug09 * adapted for kForth by km

)
\ Copyright (C) 2005, 2009  David N. Williams
(
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or at your option any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

This code is intended to be ANS Forth compatible up to case
sensitivity.

Certain tests will be omitted if the nonstandard words XF@ and
QF@ are undefined.
)

include ans-words
include rawfloat
include ttester
true verbose !
set-exact
decimal
variable #errors   0 #errors !

:noname  ( c-addr u -- )
(
Display an error message followed by the line that had the
error.
)
  1 #errors +! error1 ; 
error-xt !

bits/cell 32 = [IF] true [ELSE] false [THEN] constant 32BITS?

verbose @ [IF]
cr
LITTLE-ENDIAN [IF] .( Floats in memory are little-endian.)
              [ELSE] .( Floats in memory are big-endian.) [THEN]
cr .( An address unit is ) bits/au . .( bits.)
cr .( There are ) bits/cell . .( bits/cell.)
cr .( There are ) bits/float . .( bits/float.)

:noname  ( -- fp.separate? )
  depth >r 1e depth >r fdrop 2r> = ; 
execute
cr .( Floating-point stack is )
[IF] .( *separate*) [ELSE] .( *not separate*) [THEN]
.(  from the data stack.)
[THEN]
cr
testing  RAW32!  RAW64!  RAW80!  RAW128@  RAW32@  RAW64@  RAW80@  RAW128@

: qf-fill  ( -- )  qfpad 17 [char] U fill ;

: #fbytes  ( -- #bytes )
  0 17 0
  DO drop i qfpad i + c@ [char] U = IF LEAVE THEN LOOP ;

: qf-bytes=  ( s -- flag )  qfpad over compare 0= ;


HEX

\ raw32
qf-fill
t{ 30313233 qfpad raw32! #fbytes -> 4 }t
t{ qfpad raw32@ -> 30313233 }t
LITTLE-ENDIAN [IF]
  t{ s" 3210" qf-bytes= -> true }t
[ELSE]
  t{ s" 0123" qf-bytes= -> true }t
[THEN]

\ raw64
qf-fill 32BITS?
[IF]    \ 32 BITS
  t{ 34353637 30313233 qfpad raw64! #fbytes -> 8 }t
  t{ qfpad raw64@ -> 34353637 30313233 }t

[ELSE]  \ 64 BITS
  t{ 3031323334353637 qfpad raw64! #fbytes -> 8 }t
  t{ qfpad raw64@ -> 3031323334353637 }t
[THEN]

LITTLE-ENDIAN [IF]
  t{ s" 76543210" qf-bytes= -> true }t
[ELSE]
  t{ s" 01234567" qf-bytes= -> true }t
[THEN]

\ raw80
qf-fill 32BITS?
[IF]    \ 32 BITS
  t{ 38390000 34353637 30313233 qfpad raw80! #fbytes -> A }t
  t{ qfpad raw80@ -> 38390000 34353637 30313233 }t

[ELSE]  \ 64 BITS
  t{ 3839000000000000 3031323334353637 qfpad raw80! #fbytes -> A }t
  t{ qfpad raw80@ -> 3839000000000000 3031323334353637 }t
[THEN]

LITTLE-ENDIAN [IF]
  t{ s" 9876543210" qf-bytes= -> true }t
[ELSE]
  t{ s" 0123456789" qf-bytes= -> true }t
[THEN]

\ raw128
qf-fill 32BITS?
[IF]    \ 32 BITS
  t{ 32333435 38393031 34353637 30313233 qfpad raw128! #fbytes -> 10 }t
  t{ qfpad raw128@ -> 32333435 38393031 34353637 30313233 }t

[ELSE]  \ 64 BITS
  t{ 3839303132333435 3031323334353637 qfpad raw128! #fbytes -> 10 }t
  t{ qfpad raw128@ -> 3839303132333435 3031323334353637 }t
[THEN]

LITTLE-ENDIAN [IF]
  t{ s" 5432109876543210" qf-bytes= -> true }t
[ELSE]
  t{ s" 0123456789012345" qf-bytes= -> true }t
[THEN]

testing  RAW32>F  RAW64>F  F>RAW32  F>RAW64

\ In the rest of this file, one test for each word is
\ sufficient, since we need only see that its simple
\ composition is right.

32BITS? [IF]
[UNDEFINED] 3constant [IF]
  : 3constant >r 2>r : 2r> postpone 2literal r>
    postpone literal postpone ; ; [THEN]

[UNDEFINED] 4constant [IF]
  : 4constant 2>r 2>r : 2r> postpone 2literal 2r>
    postpone 2literal postpone ; ; [THEN]
[THEN]

\ In the following, "-sr", "-dr", "-xr", and "-qr", indicate
\ single, double, intel extended, and quad raw formats.

\ raw32
0         constant  0-sr
3F800000 constant  1-sr

32BITS?
[IF]    \ 32 BITS
  \ raw64
  0 0         2constant  0-dr
  0 3FF00000  2constant  1-dr

  \ raw80
  0 0 0         3constant  0-xr
  0 0 3FFF8000  3constant  1-xr

  \ raw128
  0 0 0 0         4constant  0-qr
  0 0 0 3FFF0000  4constant  1-qr

[ELSE]  \ 64 BITS
  \ raw64
  0                 constant  0-dr
  3FF0000000000000  constant  1-dr

  \ raw80
  0 0                 2constant  0-xr
  0 3FFF800000000000  2constant  1-xr

  \ raw128
  0 0                 2constant  0-qr
  0 3FFF000000000000  2constant  1-qr
[THEN]

DECIMAL 

t{ 1-sr raw32>f -> 1e }t
t{ 1-dr raw64>f -> 1e }t

t{ 1e   f>raw32 -> 1-sr }t
t{ 1e   f>raw64 -> 1-dr }t

[DEFINED] XF@ [IF]
testing  RAW80>F  F>RAW80
  t{ 1-xr raw80>f -> 1e }t
  t{ 1e   f>raw80 -> 1-xr }t
[THEN]

[DEFINED] QF@ [IF]
testing  RAW128>F  F>RAW128
  t{ 1-qr raw128>f -> 1e }t
  t{ 1e   f>raw128 -> 1-qr }t
[THEN]

false  \ change to TRUE to inspect word defaults
verbose @ and [IF]
see raw!   see raw@   see raw>f   see f>raw
cr [THEN]

verbose @ [IF]
.( #ERRORS: ) #errors @ . cr
[THEN]

