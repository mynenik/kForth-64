\ test some double primitives

\ Copyright (C) 1996,1998,1999,2000,2003 Free Software Foundation, Inc.

\ Modified for kForth by David N. Williams, March 30, 2006.
\ Revised: 2009-06-05 km; removed unneeded include of ans-words; 
\                         use T{ ... }T for tests
\ Revised: 2017-03-17 km; uncommented tests for D0< .
\ This file is part of Gforth.

\ Gforth is free software; you can redistribute it and/or
\ modify it under the terms of the GNU General Public License
\ as published by the Free Software Foundation; either version 2
\ of the License, or (at your option) any later version.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
\ GNU General Public License for more details.

\ You should have received a copy of the GNU General Public License
\ along with this program; if not, write to the Free Software
\ Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

s" ans-words" included
s" ttester"   included
\ include coretest.4th
decimal

\ dnw, from core.4th
0 INVERT			CONSTANT MAX-UINT
0 INVERT 1 RSHIFT		CONSTANT MAX-INT
0 INVERT 1 RSHIFT INVERT	CONSTANT MIN-INT

\ fm/mod, sm/rem, um/mod, s>d, m*, um* already covered in coretest.fs

testing M+ D+ D- DNEGATE

t{ 0 0 0 m+ -> 0 0 }t
t{ 0 0 1 m+ -> 1 0 }t
t{ 0 0 -1 m+ -> -1 -1 }t
t{ 1 0 -1 m+ -> 0 0 }t
t{ MAX-UINT 0 1 m+ -> 0 1 }t
t{ MAX-UINT MAX-UINT 1 m+ -> 0 0 }t

t{ 0 0 0 0 d+ -> 0 0 }t
t{ 1 0 -1 -1 d+ -> 0 0 }t
t{ -1 -1 1 0 d+ -> 0 0 }t
t{ -1 -1 -1 -1 d+ -> -2 -1 }t
t{ MAX-UINT 0 2dup d+ -> MAX-UINT 1- 1 }t
t{ MAX-UINT 1 1 1 d+ -> 0 3 }t

t{ 0 0 0 0 d- -> 0 0 }t
t{ 0 0 1 0 d- -> -1 -1 }t
t{ 0 0 -1 -1 d- -> 1 0 }t
t{ 1 0 0 0 d- -> 1 0 }t
t{ 1 0 1 0 d- -> 0 0 }t
t{ -1 -1 -1 -1 d- -> 0 0 }t
t{ 1 0 -1 -1 d- -> 2 0 }t
t{ -1 -1 1 0 d- -> -2 -1 }t
t{ 0 2 1 0 d- -> MAX-UINT 1 }t

t{ 0 0 dnegate -> 0 0 }t
t{ 1 0 dnegate -> -1 -1 }t
t{ -2 -1 dnegate -> 2 0 }t
t{ 0 1 dnegate -> 0 -1 }t
t{ 1 1 dnegate -> MAX-UINT -2 }t

testing D2* D2/

t{ 1 0 d2* -> 2 0 }t
t{ -10 -1 d2* -> -20 -1 }t
t{ MAX-UINT 1 d2* -> MAX-UINT 1- 3 }t

t{ 0 0 d2/ -> 0 0 }t
t{ 1 0 d2/ -> 0 0 }t
t{ -1 -1 d2/ -> -1 -1 }t
t{ MAX-UINT 3 d2/ -> MAX-UINT 1 }t


testing D= D<

t{ 0 0 0 0 d= -> true }t
t{ 0 0 1 0 d= -> false }t
t{ 0 1 0 0 d= -> false }t
t{ 1 1 0 0 d= -> false }t

t{ 1 0 1 0 d< -> false }t
t{ 0 0 1 0 d< -> true }t
t{ 1 0 0 1 d< -> true }t
t{ 0 1 1 0 d< -> false }t
t{ -1 -1 0 0 d< -> true }t

\ added by dnw:
t{  0  3 -1  2 d< -> false }t
t{ -1  2  0  3 d< -> true }t
t{ -1  2 -1  2 d< -> false }t
\ to catch use of D-, which overflows
t{  0 MIN-INT -1 MAX-INT d< -> true }t
t{  0  3 dnegate ->  0 -3 }t
t{  1  2 dnegate -> -1 -3 }t
\ to catch failure to use low word unsigned compare
t{  0  3 -1  3 d< -> true }t
t{  0 -3 -1 -3 d< -> true }t
t{ -1  3  0  3 d< -> false }t
t{ -1 -3  0 -3 d< -> false }t

comment Skipping D<> D> D>= D<=
(
t{ 0 0 0 0 d<> -> false }t
t{ 0 0 1 0 d<> -> true }t
t{ 0 1 0 0 d<> -> true }t
t{ 1 1 0 0 d<> -> true }t

t{ 1 0 1 0 d> -> false }t
t{ 0 0 1 0 d> -> false }t
t{ 1 0 0 1 d> -> false }t
t{ 0 1 1 0 d> -> true }t
t{ -1 -1 0 0 d> -> false }t

t{ 1 0 1 0 d>= -> true }t
t{ 0 0 1 0 d>= -> false }t
t{ 1 0 0 1 d>= -> false }t
t{ 0 1 1 0 d>= -> true }t
t{ -1 -1 0 0 d>= -> false }t

t{ 1 0 1 0 d<= -> true }t
t{ 0 0 1 0 d<= -> true }t
t{ 1 0 0 1 d<= -> true }t
t{ 0 1 1 0 d<= -> false }t
t{ -1 -1 0 0 d<= -> true }t
)

\ Since the d-comparisons, the du-comparisons, and the d0-comparisons
\ are generated from the same source, we only test the ANS words in
\ the following.

testing D0= D0< DU<

t{ 0 0 d0= -> true }t
t{ 1 0 d0= -> false }t
t{ 0 1 d0= -> false }t
t{ 1 1 d0= -> false }t
t{ -1 -1 d0= -> false }t

t{ 0 0 d0< -> false }t
t{ -1 -1 d0< -> true }t
t{ -1 0 d0< -> false }t
t{ 0 min-int d0< -> true }t

t{ 1 0 1 0 du< -> false }t
t{ 0 0 1 0 du< -> true }t
t{ 1 0 0 1 du< -> true }t
t{ 0 1 1 0 du< -> false }t
t{ -1 -1 0 0 du< -> false }t


