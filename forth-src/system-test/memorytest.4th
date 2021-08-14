\ To test the ANS Forth Memory-Allocation word set

\ This program was written by Gerry Jackson in 2006, with contributions from
\ others where indicated, and is in the public domain - it can be distributed
\ and/or modified in any way but please retain this notice.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

\ The tests are not claimed to be comprehensive or correct 

\ ------------------------------------------------------------------------------
\ Version 0.11 25 April 2015 Now checks memory region is unchanged following a
\              RESIZE. @ and ! in allocated memory.
\         0.8 10 January 2013, Added CHARS and CHAR+ where necessary to correct
\             the assumption that 1 CHARS = 1
\         0.7 1 April 2012  Tests placed in the public domain.
\         0.6 30 January 2011 CHECKMEM modified to work with ttester.fs
\         0.5 30 November 20009 <false> replaced with FALSE
\         0.4 9 March 2009 Aligned test improved and data space pointer tested
\         0.3 6 March 2009 { and } replaced with T{ and }T
\         0.2 20 April 2007  ANS Forth words changed to upper case
\         0.1 October 2006 First version released

\ ------------------------------------------------------------------------------
\ The tests are based on John Hayes test program for the core word set

\ Words tested in this file are:
\     ALLOCATE FREE RESIZE
\     
\ ------------------------------------------------------------------------------
\ Assumptions, dependencies and notes:
\     - ttester.4th has been included prior to this file
\     - the Core word set is available and tested
\     - that 'addr -1 ALLOCATE' and 'addr -1 RESIZE' will return an error
\     - testing FREE failing is not done as it is likely to crash the
\       system
\ ------------------------------------------------------------------------------

\ ==== kForth preliminaries ==========
s" ans-words.4th" included
s" ttester.4th" included
\ ==== end of kForth preliminaries ===

TESTING Memory-Allocation word set

DECIMAL

\ ------------------------------------------------------------------------------

TESTING ALLOCATE FREE RESIZE

VARIABLE addr1
VARIABLE datsp

COMMENT Skipping tests involving HERE
( *************
HERE datsp !
T{ 100 ALLOCATE SWAP addr1 ! -> 0 }T
T{ addr1 a@ ALIGNED -> addr1 a@ }T   \ Test address is aligned
T{ HERE -> datsp a@ }T            \ Check data space pointer is unchanged
T{ addr1 a@ FREE -> 0 }T
************** )

T{ 99 ALLOCATE SWAP addr1 ! -> 0 }T
T{ addr1 a@ ALIGNED -> addr1 a@ }T
T{ addr1 a@ FREE -> 0 }T

T{ 50 ALLOCATE SWAP addr1 ! -> 0 }T

: writemem 0 DO I 1+ OVER C! CHAR+ LOOP DROP ;	( ad n -- )

\ CHECKMEM is defined this way to maintain compatibility with both
\ tester.4th and ttester.4th which differ in their definitions of T{

: checkmem  ( ad n --- )
   0
   DO
      >R
      T{ R@ C@ -> R> I 1+ SWAP >R }T
      R> CHAR+
   LOOP
   DROP
;

addr1 a@ 50 writemem addr1 a@ 50 checkmem

T{ addr1 a@ 28 RESIZE SWAP addr1 ! -> 0 }T
addr1 a@ 28 checkmem

T{ addr1 a@ 200 RESIZE SWAP addr1 ! -> 0 }T
T{ addr1 a@ 28 checkmem

\ ------------------------------------------------------------------------------
[DEFINED] _WIN32_ [IF]
COMMENT Skipping failure of RESIZE and ALLOCATE tests on Win32
[ELSE]
TESTING failure of RESIZE and ALLOCATE (unlikely to be enough memory)

\ This test relies on the previous test having passed

VARIABLE RESIZE-OK
T{ addr1 a@ -1 CHARS RESIZE 0= DUP RESIZE-OK ! -> addr1 a@ FALSE }T

\ Check unRESIZEd allocation is unchanged following RESIZE failure 
: MEM?  RESIZE-OK @ 0= IF ADDR1 a@ 28 CHECKMEM THEN ;   \ Avoid using [IF]
MEM?

T{ addr1 a@ FREE -> 0 }T  \ Tidy up

T{ -1 ALLOCATE SWAP DROP 0= -> FALSE }T		\ Memory allocate failed
[THEN]

\ ------------------------------------------------------------------------------
TESTING @  and ! work in ALLOCATEd memory (provided by Peter Knaggs)

: WRITE-CELL-MEM ( ADDR N -- )
  1+ 1 DO I OVER ! CELL+ LOOP DROP
;

: CHECK-CELL-MEM ( ADDR N -- )
  1+ 1 DO
    I SWAP >R >R
    T{ R> ( I ) -> R@ ( ADDR ) @ }T
    R> CELL+
  LOOP DROP
;

\ Cell based access to the heap

T{ 50 CELLS ALLOCATE SWAP ADDR1 ! -> 0 }T
ADDR1 a@ 50 WRITE-CELL-MEM
ADDR1 a@ 50 CHECK-CELL-MEM

\ ------------------------------------------------------------------------------

\ MEMORY-ERRORS SET-ERROR-COUNT

CR .( End of Memory-Allocation word tests) CR
