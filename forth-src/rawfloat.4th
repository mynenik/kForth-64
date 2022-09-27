(     Title:  Convert among binary floating-point raw,
              memory, and stack formats
       File:  rawfloat.fs
  Test file:  rawfloat-test.fs
    Version:  0.9.1-c
    Revised:  Aug 03, 2009
     Author:  David N. Williams
    License:  LGPL

Version 0.9.1-c
26Sep22 * fixed some bugs which only manifest when running under 64-bit
          Forth  km

Version 0.9.1-b
03Aug09 * adapted for kForth: changed immediate constant [LITTLE-ENDIAN] to 
          non-immediate constant LITTLE-ENDIAN; misc. minor changes km

Version 0.9.1
30Jul09 * Started revision to allow 64-bit cells.
        * Removed the shift words and their tests.
        * Used bytes, not cells, in QFPAD bits/float
          calculation.
        * Testing with 64-bit intel gforth revealed bugs.
31Jul09 * Fixed 64-bit little-endian bugs -- 64-bit big-endian
          untested.
01Aug09 * Listed QFPAD as a user word.

Version 0.9.0
24Jul09 * Extracted rawfloat.fs and rawfloat-test.fs from
          version 0.9.0 of mixfloat.fs and mixfloat-test.fs.
25Jul09 * Added missing ABORT for cells not 32 bits and for
          bits/float not 32, 64, 80, or 128.
        * Added conditionals to avoid redundancy with
          mixfloat.fs and rawhex.fs.
28Jul09 * Removed [IF] from behind a comment.
        * Released.
29Jul09 * Removed HEX20>F and F>HEX20, inadvertently left in,
          and hidden behind XF@ conditional compilation.

We believe any of this code derived from other authors to be
either in the public domain or otherwise compatible with the
LGPL.  For the sake of the LGPL, the rest is
)
\ Copyright (C) 2003, 2005, 2009  David N. Williams
(
This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or at your option any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

If you take advantage of the option in the LGPL to put a
particular version of this library under the GPL, the author[s]
would regard it as polite if you would put any direct
modifications under the LGPL as well, and include this paragraph
in your license notice.  A direct modification is
one that enhances or extends the library in line with its
original concept, as opposed to developing a distinct
application or library which might use it.

This code works with either 32- or 64-bit cells.

The library converts among several floating-point formats based
on the binary part of the IEEE 754-2008 standard, the "raw"
formats, raw32, raw64, raw80, and raw128, on the data stack, the
corresponding binary32, binary64, binary80, and binary128
formats in memory, and the default Forth float format on the
floating-point stack.

The raw formats give an application access to the bits of
floating-point encodings in a portable way.  The numbers in
their names are the storage widths in bits.  With one exception,
they occupy the high bits of enough cells on the data stack to
contain them, with the most significant cell topmost, the next
most significant just below it, and so on, towards the bottom of
the stack.  The exception is the raw32 format in 64-bit Forths,
where the data occupies the low 32 bits of its stack cell, in
order to conform with the common Forth convention for narrow
data on the stack.

The raw32, raw64, and raw128 formats correspond to IEEE 754-2008
interchange formats, binary32, binary64, and binary128, which
all have an implicit leading integer bit for normal and
subnormal numbers.  IEEE does not define a binary interchange
format for intel 80-bit floating-point numbers, and that seems
to be deliberate.  The raw80 format defined here has an explicit
leading integer bit, to simplify interaction with the intel
80-bit format, which corresponds to an IEEE extended binary
format.

The memory formats correspond to the Forth words SF!, SF@, DF!,
and DF@, and their not yet existing extensions to binary80 and
binary128, XF!, XF@, QF!, and QF@.  These formats are
implementation dependent, presumably determined by the cpu
floating-point load and store instructions, when they exist.

The library works with both big- and little-endian systems, as
long as the memory representation is totally one or the other,
and integers and floating-point numbers have the same
endianness.

Upon inspection, neither here nor in rawfloat-test.fs do we see
words with mixed data/float inputs, outputs, or intermediate
calculations.  Everything should work whether or not the
floating-point stack is separate from the data stack, and has
been checked with both options in pfe.  See the section
"ENVIRONMENT" for how to select an integrated stack in pfe.

There is an environmental dependence on lower case.

The library refuses to load if cells are not 32 bits or 64 bits,
chars are not 8 bits and 1 address unit, or the default float is
not 32, 64, 80, or 128 bits.
)

\ *** USER WORDS

\ UTILITY
\   qfaligned  qfalign  qfpad

\ ENVIRONENTAL CONSTANTS
\   bits/au  bits/cell  bits/float  LITTLE-ENDIAN

\ RAW FETCH/STORE
\   raw32!  raw64!  raw80!  raw128!
\   raw32@  raw64@  raw80@  raw128@
\   raw!  raw@

\ RAW/FLOAT CONVERSIONS
\   raw32>f  raw64>f  raw80>f  raw128>f
\   f>raw32  f>raw64  f>raw80  f>raw128
\   raw>f  f>raw

[UNDEFINED] raw>f [IF]  \ BEGIN mixfloat.fs not loaded

\ *** UTILITY

decimal

[UNDEFINED] bits/cell [IF]
\ s" ADDRESS-UNIT-BITS" environment? 0=
\ [IF] cr .( ***can't determine ADDRESS-UNIT-BITS) ABORT [THEN]
8                 constant bits/au
bits/au 1 cells * constant bits/cell
[THEN]

[UNDEFINED] QFALIGNED [IF]
  : qfaligned  ( addr -- addr' )  127 + [ 127 invert ] literal and ;
[THEN]

[UNDEFINED] QFALIGN [IF]
\  : qfalign  ( -- )  here qfaligned here - allot ;
: qfalign ;
[THEN]

\ *** ENVIRONMENT
(
This code assumes the default float format to be
either totally big- or little-endian in memory, and that when
floats are little-endian, so are cells.  The tests in
rawfloat-test.fs should catch the failure of the latter
assumption.
)
decimal
[UNDEFINED] floats [IF] : floats dfloats ; [THEN]

bits/au 1 chars * 8 <> [IF] cr
  .( ***1 CHARS is not 8 bits.) ABORT [THEN]
bits/cell 32 <> bits/cell 64 <> and [IF] cr
  .( ***bits/cell must be 32 or 64) ABORT [THEN]

1 floats 16 >
[IF] cr .( ***1 FLOATS is too big) ABORT [THEN]

[UNDEFINED] qfpad [IF] 
qfalign create qfpad 24 allot  \ enough for 3 64-bit cells
[THEN]

qfpad 17 char U fill  \ 16+1 bytes

: #fbytes  ( -- #bytes )
  0 17 0
  DO drop i qfpad i + c@ [char] U = IF LEAVE THEN LOOP ;

1E qfpad f! #fbytes ( #bytes) bits/au * ( bits/float)
[UNDEFINED] bits/float

qfpad c@ 0= ( lendian?)
[UNDEFINED] LITTLE-ENDIAN

[IF] constant LITTLE-ENDIAN             [ELSE] drop [THEN]
[IF] constant bits/float                [ELSE] drop [THEN]

bits/float 32 <>      bits/float 64 <>  and
bits/float 80 <> and  bits/float 128 <> and
[IF] cr
  .( ***unrecognized float format, bits/float = )
  bits/float . ABORT [THEN]

\ *** RAW FETCH/STORE

: raw32@  ( sf-addr -- raw32 )
  @ [ bits/cell 64 = ] [IF] 
  [ HEX FFFFFFFF DECIMAL ] literal and [THEN] ;

: raw32!  ( raw32 sf-addr -- )
  [ bits/cell 32 = ]
  [IF]   ! 
  [ELSE] >r [ HEX FFFFFFFF DECIMAL ] literal and
         r@ @ [ HEX FFFFFFFF DECIMAL invert ] literal and or r> ! [THEN] ;

: raw64@  ( df-addr -- raw64 )
  [ bits/cell 32 = ]
  [IF]  2@ [ LITTLE-ENDIAN ] [IF] swap [THEN]
  [ELSE] @ [THEN] ;

: raw64!  ( raw64 df-addr -- )
  [ bits/cell 32 = ]
  [IF]   [ LITTLE-ENDIAN ] [IF] >r swap r> [THEN] 2!
  [ELSE] ! [THEN] ;

: lo16@  ( a-addr -- lo16 ) @  [ HEX FFFF DECIMAL ] literal and ;

: hi16@  ( a-addr -- hi16 )  \ fetch hi 16 to hi 16
  @ [ HEX FFFF DECIMAL bits/cell 16 - lshift ] literal and ;

: raw80@  ( xf-addr -- raw80 )
   >r [ LITTLE-ENDIAN ]
  [IF]
    r@ @ dup [ bits/cell 16 - ] literal lshift swap 16 rshift
    [ bits/cell 32 = ]
    [IF]
      r> cell+ dup >r
      @ dup >r 16 lshift or r> 16 rshift
    [THEN]
    r> cell+ lo16@ [ bits/cell 16 - ] literal lshift or
  [ELSE]  \ BIG-ENDIAN
    r@ 8 + hi16@ r>
    [ bits/cell 32 = ] [IF] 2@ [ELSE] @ [THEN]
  [THEN] ;

: lo16!  ( u a-addr -- )
  >r [ HEX FFFF DECIMAL ] literal and
  r@ @ [ HEX FFFF DECIMAL invert ] literal and or r> ! ;

: hi16!  ( u a-addr -- )  \ store hi 16 to hi 16
  >r [ HEX FFFF DECIMAL bits/cell 16 - lshift ] literal and
  r@ @ [ HEX FFFF DECIMAL bits/cell 16 - lshift invert ] literal and or r> ! ; 

: raw80!  ( raw80 xf-addr -- )
  >r [ LITTLE-ENDIAN ]
  [IF]    \ LITTLE-ENDIAN
    dup [ bits/cell 16 - ] literal rshift r@ 8 + lo16!
    [ bits/cell 32 = ]
    [IF] 16 lshift over 16 rshift or r@ 4 + ! [THEN]
    16 lshift swap [ bits/cell 16 - ] literal rshift or r> !
  [ELSE]  \ BIG-ENDIAN
    r@ ! [ bits/cell 32 = ] [IF] r> cell+ >r r@ ! [THEN]  
    r> cell+ hi16!
  [THEN] ;

: raw128@  ( qf-addr -- raw128 )
  [ bits/cell 32 = ]
  [IF]
    >r r@ 2@ [ LITTLE-ENDIAN ]
    [IF]   swap r> 8 + 2@ swap
    [ELSE] r> 8 + 2@ 2swap [THEN]
  [ELSE]
    2@ [ LITTLE-ENDIAN ] [IF] swap [THEN]
  [THEN] ;

: raw128!  ( raw128 qf-addr -- )
  >r
  [ bits/cell 32 = ]
  [IF]    \ 32 BITS
    [ LITTLE-ENDIAN ]
    [IF]   2swap swap r@ 2! swap r> 8 +
    [ELSE] r@ 2! r> 8 +
    [THEN]
  [ELSE]  \ 64 BITS
    [ LITTLE-ENDIAN ] [IF] swap [THEN] r>
  [THEN] 2! ;

: raw@  ( f-addr -- raw )
  [ bits/float 32 = ]  [IF] raw32@ [ELSE]
  [ bits/float 64 = ]  [IF] raw64@ [ELSE]
  [ bits/float 80 = ]  [IF] raw80@ [ELSE]
  [ bits/float 128 = ] [IF] raw128@ [THEN] [THEN] [THEN] [THEN] ;

: raw!  ( raw f-addr -- )
  [ bits/float 32 = ]  [IF] raw32! [ELSE]
  [ bits/float 64 = ]  [IF] raw64! [ELSE]
  [ bits/float 80 = ]  [IF] raw80! [ELSE]
  [ bits/float 128 = ] [IF] raw128! [THEN] [THEN] [THEN] [THEN] ;

\ *** RAW/FLOAT CONVERSIONS

: raw32>f  ( raw32 -- f: r )      qfpad raw32! qfpad sf@ ;
: raw64>f  ( raw64 -- f: r )      qfpad raw64! qfpad df@ ;
: f>raw32  ( f: r -- s: raw32 )   qfpad sf! qfpad raw32@ ;
: f>raw64  ( f: r -- s: raw64 )   qfpad df! qfpad raw64@ ;

[DEFINED] XF@ [IF]  \ assume XF! defined, too
: raw80>f  ( raw80 -- f: r )      qfpad raw80! qfpad xf@ ;
: f>raw80  ( f: r -- s: raw80 )   qfpad xf! qfpad raw80@ ;
[THEN]

[DEFINED] QF@ [IF]  \ assume QF! defined, too
: raw128>f  ( raw128 -- f: r )    qfpad raw128! qfpad qf@ ;
: f>raw128  ( f: r -- s: raw128 ) qfpad qf! qfpad raw128@ ;
[THEN]

: raw>f  ( raw.default -- f: r )
  [ bits/float  32 = ]  [IF] raw32>f [ELSE]
  [ bits/float  64 = ]  [IF] raw64>f [ELSE]
  [ bits/float  80 = ]  [IF] raw80>f [ELSE]
  [ bits/float  128 = ] [IF] raw128>f [THEN] [THEN] [THEN] [THEN] ;

: f>raw  ( f: r -- s: raw.default )
  [ bits/float  32 = ]  [IF] f>raw32 [ELSE]
  [ bits/float  64 = ]  [IF] f>raw64 [ELSE]
  [ bits/float  80 = ]  [IF] f>raw80 [ELSE]
  [ bits/float  128 = ] [IF] f>raw128 [THEN] [THEN] [THEN] [THEN] ;

\ END mixfloat.fs not loaded
[THEN]

