\ From: mhx@iae.nl (Marcel Hendrix)
\ Subject: Generic matrix multiplication benchmark
\ Newsgroups: comp.lang.forth
\ Message-ID: <18143211163563@frunobulax.edu>
\ Date: Mon, 12 Jul 2004 21:10:46 GMT
\
\ Here is Mark Smotherman's matrix multiply code, ported from iForth
\ to VFX, SwiftForth, gForth and Win32Forth. This is an attempt to write a 
\ generic, non-trivial floating-point benchmark. This benchmark is designed 
\ to compare Forths, but IMHO it is also allowed to compare Forth execute 
\ times to those of compiled C.
\
\ Special features of iForth are left out of the code as much as 
\ possible. I used the VFX benchm framework to allow setting 
\ up all Forths to some basic level of functionality. However, I 
\ probably extended the fsl_util files of the Forths on my system 
\ at some long forgotten time (e.g. the gForth files were completely
\ wrong), so minor editing might still be necessary.
\
\ If any problems are found, or if people can make mmu.frt successfully 
\ run on other systems, please report here. Note that fsl_util.xx files
\ have a very large influence on runtimes and should be optimized by the
\ Forth vendor. The iForth timings are with the fsl_util.frt from the 
\ ./include directory. (This works because the FSL's "&" operator is 
\ commented out in the prologue.)

\ -marcel
\ -- mmu.frt ---------------------------
( *
  * LANGUAGE    : ANS Forth
  * PROJECT     : Forth Environments
  * DESCRIPTION : Matrix Multiplication
  * CATEGORY    : Benchmark
  * AUTHOR      : Mark Smotherman <mark@cs.clemson.edu>
  * LAST CHANGE : June 12, 2000, Marcel Hendrix
  * REVISED     : July 19, 2004, Krishna Myneni, Adapted for integrated stack Forths,
  *                 and kForth in particular.
  * )

\ ============ needed for kForth 1.2.x ==================
include ans-words
\ ========================================================

BASE @ DECIMAL

\ ************************************************
\ Select system to be tested, set FORTHSYSTEM
\ to value of selected target.
\ Set SPECIFICS false to avoid system dependencies.
\ Set SPECIFICS true to show off implementation tricks.
\ Set HACKING false to use the base source code.
\ Set HACKING true to optimise the source code.
\ ************************************************

1  constant VfxForth3		\ MPE VFX Forth v3.x
2  constant Pfw22		\ MPE ProForth 2.2
3  constant SwiftForth20	\ FI SwiftForth 2.0
4  constant SwiftForth15	\ FI SwiftForth 1.5
5  constant Win32Forth		\ Win32Forth 4.2
6  constant BigForth		\ BigForth 11 July 1999
7  constant BigForth-Linux	\ BigForth 11 July 1999
8  constant iForth		\ iForth 1.12 5 Aug 2001
9  constant iForth20		\ iForth 2.0 8 June 2002
10 constant gForth		\ gForth 0.6.x
11 constant kForth              \ kForth 1.2.x

\    VfxForth3 constant ForthSystem	\ select system to test
\     iForth20 constant ForthSystem
\ SwiftForth20 constant ForthSystem
\   Win32Forth constant ForthSystem
\       gForth constant ForthSystem
	kForth constant ForthSystem

 false constant specifics	\ true to use system dependent code
 false constant hacking		\ true to use "guru" level code that
				\ makes assumptions of an optimising compiler.
 true  constant ANSSystem	\ Some Forth 83 systems cannot compile
				\ all the test examples without carnal
				\ knowledge, especially if the compiler
				\ checks control structures.

: .specifics	\ -- ; display trick state
  ."  using"  specifics 0=
  if  ."  no"  then
  ."  extensions"
;

: .hacking	\ -- ; display hack state
  ."  using"  hacking 0=
  if  ."  no"  then
  ."  hackery"
;

: .testcond	\ -- ; display test conditions
  .specifics ."  and" .hacking
;


\ *****************************
\ VFX Forth for Windows harness
\ *****************************

VfxForth3 ForthSystem = 
[IF]  CR .( VFX Forth ) CR
\ +idata		\ enable P4 data options

true constant ndp?	\ -- flag ; true if NDP stack version

S" ../../lib/ndp387.fth" INCLUDED

  char . dp-char !			\ select ANS number conversion
  char . fp-char !

-short-branches				\ disable short forward branches
S" VfxUtil" INCLUDED                    \ FSL harness for ProForth VFX 3.0

: DFVARIABLE	#16 buffer:  ;

	CODE TICKS-GET ( -- d )
		SUB EBP, 8
		MOV 4 [EBP], EBX
	( 1 )   MOV 0 [EBP], EAX
	( 2 )   $0F C, $31 C, \ RDTSC
		MOV EBX, EDX
		RET
	END-CODE

#166 VALUE PROCESSOR-CLOCK  	\ this will be calibrated, no need to change
2VARIABLE _ticks_  		\ counts clock ticks

extern: DWORD PASCAL GetTickCount( void )

: HTAB        ( n -- ) out @ - spaces ; 	\ step to position n
: MS         ( ms -- ) Sleep ; 
: d*100   ( d1 -- d2 ) #100. D* ; 
: TICKS-RESET   ( -- ) TICKS-GET _ticks_ 2! ;
: TICKS>US ( d -- ud ) PROCESSOR-CLOCK UM/MOD NIP  0 ;
: TICKS?     ( -- ud ) TICKS-GET _ticks_ 2@  D- ;
: US?        ( -- ud ) TICKS?  TICKS>US ;
: CALIBRATE     ( -- ) TICKS-RESET  #1000 MS  TICKS? #1000000 UM/MOD NIP  TO PROCESSOR-CLOCK ;

: GENERIC() ( -- ) CR ."  (not available)" ;


[THEN]

\ ******************************
\ iForth 2.0 for Windows harness
\ ******************************
iForth20 ForthSystem = 
  [IF]  CR .( iForth20 ) CR
	NEEDS -miscutil
	NEEDS -fsl_util
	NEEDS -gaussj   ( iForth only; performance test generic matrix words )

	\ Adjust iForth's extended fsl_util to accepts "&" for }}malloc and }}free.
	: & ; IMMEDIATE

	: GENERIC() ( -- ) 
		EVAL" SHHT? 0= IF  CR N 0 .R 'x' EMIT N 0 .R .~  mm - generic mat*~ 54 HTAB ENDIF "
		EVAL" INIT-RESULT "
		EVAL" a{{ b{{ c{{ mat* "
		EVAL" .RESULT " ; IMMEDIATE

	: d*100  #100 1 M*/ ; ( d1 -- d2 )
[THEN]


\ **********************
\ SwiftForth 2.0 harness
\ **********************
SwiftForth20 ForthSystem = 
  [IF]  CR .( SwiftForth20 ) CR
	include C:\Program Files\ForthInc\SwiftForth\Lib\Options\fpmath.f
	include C:\Program Files\ForthInc\SwiftForth\Unsupported\FSLib\Library\fsl-util.f

	\ uses EDX:EAX
	CODE TICKS-GET ( -- d )
		8 # EBP SUB
		EBX 4 [EBP] MOV
		$0F C, $31 C, \ RDTSC
		EAX 0 [EBP] MOV
		EDX EBX MOV
		RET
	END-CODE

#166 VALUE PROCESSOR-CLOCK  	\ this will be calibrated, no need to change
2VARIABLE _ticks_  		\ counts clock ticks

: HTAB        ( n -- ) GET-XY NIP AT-XY ;
: TICKS-RESET   ( -- ) TICKS-GET _ticks_ 2! ;
: TICKS>US ( d -- ud ) PROCESSOR-CLOCK UM/MOD NIP  0 ;
: TICKS?     ( -- ud ) TICKS-GET _ticks_ 2@  D- ;
: US?        ( -- ud ) TICKS?  TICKS>US ;
: CALIBRATE     ( -- ) TICKS-RESET  #1000 MS  TICKS? #1000000 UM/MOD NIP  TO PROCESSOR-CLOCK ;

\ Removed some defs here
: GENERIC() ( -- ) CR ."  (not available)" ;

: d*100  #100 1 M*/ ; ( d1 -- d2 )

[THEN]


\ **********************
\ Win32Forth harness
\ **********************
Win32Forth ForthSystem = 
  [IF]
CR .( Win32Forth )
	include fsl_util.f

	CODE TICKS-GET ( -- d )
		push    ebx
		mov 	ebx, edx
		rdtsc   ( edx:eax )
		push	eax
		xchg	ebx, edx
		next 	c;

166 VALUE PROCESSOR-CLOCK  	\ this will be calibrated, no need to change
2VARIABLE _ticks_  		\ counts clock ticks

: HTAB        ( n -- ) ROWS AT-XY ;
: TICKS-RESET   ( -- ) TICKS-GET _ticks_ 2! ;
: TICKS>US ( d -- ud ) PROCESSOR-CLOCK UM/MOD NIP  0 ;
: TICKS?     ( -- ud ) TICKS-GET _ticks_ 2@  D- ;
: US?        ( -- ud ) TICKS?  TICKS>US ;
: CALIBRATE     ( -- ) TICKS-RESET  1000 MS  TICKS? 1000000 UM/MOD NIP  TO PROCESSOR-CLOCK ;

: GENERIC() ( -- ) CR ."  (not available)" ;

: d*100  100 1 M*/ ; ( d1 -- d2 )

: [UNDEFINED] 	DEFINED NIP 0= ;

[THEN]

\ **************
\ gForth harness
\ **************
gForth ForthSystem = 
  [IF]
CR .( gForth )
	INCLUDE fsl_utilgf.fs
	INCLUDE dynmem.fs

: DFVARIABLE CREATE 0e F, ;
: 3DUP     ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )  2 PICK 2 PICK 2 PICK ;


166 VALUE PROCESSOR-CLOCK  	\ this will NOT be calibrated, change this for ticks/flop to be correct
2VARIABLE _ticks_  		\ counts clock ticks

: TICKS-GET   ( -- d ) utime PROCESSOR-CLOCK 1 M*/ ;
: HTAB        ( n -- ) DROP 20 SPACES ;
: TICKS-RESET   ( -- ) TICKS-GET _ticks_ 2! ;
: TICKS>US ( d -- ud ) PROCESSOR-CLOCK UM/MOD NIP  0 ;
: TICKS?     ( -- ud ) TICKS-GET _ticks_ 2@  D- ;
: US?        ( -- ud ) TICKS?  TICKS>US ;
: CALIBRATE     ( -- ) ;
: GENERIC()     ( -- ) CR ."  (not available)" ;
: d*100   ( d1 -- d2 ) 100 1 M*/ ; 

[THEN]

\ **************
\ kForth harness
\ **************
kForth ForthSystem = 
  [IF]
CR .( kForth )
	INCLUDE fsl/fsl-util.4th
	INCLUDE fsl/dynmem.4th

: ptr ( a <name> -- | create an address constant ) 
        create 1 cells ?allot ! does> a@ ;        \ address constants are special in kForth

: DFVARIABLE FVARIABLE ;
: 3DUP     ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )  2 PICK 2 PICK 2 PICK ;
: BOUNDS OVER + SWAP ;

330 VALUE PROCESSOR-CLOCK  	\ this will NOT be calibrated, change this for ticks/flop to be correct
2VARIABLE _ticks_  		\ counts clock ticks

: TICKS-GET   ( -- d ) MS@ S>D ;
: HTAB        ( n -- ) DROP 20 SPACES ;
: TICKS-RESET   ( -- ) MS@ S>D _ticks_ 2! ;
: TICKS>US ( d -- ud ) DROP 1000 * S>D ;
: TICKS?     ( -- ud ) TICKS-GET _ticks_ 2@  D- ;
: US?        ( -- ud ) TICKS?  TICKS>US ;
: CALIBRATE     ( -- )  ;
: GENERIC()     ( -- ) CR ."  (not available)" ;
: d*100   ( d1 -- d2 ) 100 1 M*/ ; 

[THEN]

0 [IF] ===========================================================================================
 matrix multiply tests -- C language, version 1.0, May 1993

 compile with -DN=<size>

 I usually run a script file
   time.script 500 >500.times
 where the script file contains
   cc -O -DN=$1 mm.c
   a.out -n             (I suggest at least two runs per method to
   a.out -n             alert you to variations.  Five or ten runs
   a.out -t             each, giving avg. and std dev. of times is
   a.out -t             best.)
     ...

 Contact Mark Smotherman (mark@cs.clemson.edu) for questions, comments,
 and to report results showing wide variations.  E.g., a wide variation
 appeared on an IBM RS/6000 Model 320 with "cc -O -DN=500 mm.c" (xlc compiler):
  500x500 mm - normal algorithm                     utime     230.81 secs
  500x500 mm - normal algorithm                     utime     230.72 secs
  500x500 mm - temporary variable in loop           utime     231.00 secs
  500x500 mm - temporary variable in loop           utime     230.79 secs
  500x500 mm - unrolled inner loop, factor of  8    utime     232.09 secs
  500x500 mm - unrolled inner loop, factor of  8    utime     231.84 secs
  500x500 mm - pointers used to access matrices     utime     230.74 secs
  500x500 mm - pointers used to access matrices     utime     230.45 secs
  500x500 mm - blocking, factor of  32              utime      60.40 secs
  500x500 mm - blocking, factor of  32              utime      60.57 secs
  500x500 mm - interchanged inner loops             utime      27.36 secs
  500x500 mm - interchanged inner loops             utime      27.40 secs
  500x500 mm - 20x20 subarray (from D. Warner)      utime       9.49 secs
  500x500 mm - 20x20 subarray (from D. Warner)      utime       9.50 secs
  500x500 mm - 20x20 subarray (from T. Maeno)       utime       9.10 secs
  500x500 mm - 20x20 subarray (from T. Maeno)       utime       9.05 secs

 The algorithms can also be sensitive to TLB thrashing.  On a 600x600
 test an IBM RS/6000 Model 30 showed variations depending on relative
 location of the matrices.  (The model 30 has 64 TLB entries organized
 as 2-way set associative.)

 600x600 mm - 20x20 subarray (from T. Maeno)       utime      19.12 secs
 600x600 mm - 20x20 subarray (from T. Maeno)       utime      19.23 secs
 600x600 mm - 20x20 subarray (from D. Warner)      utime      18.87 secs
 600x600 mm - 20x20 subarray (from D. Warner)      utime      18.64 secs
 600x600 mm - 20x20 btranspose (Warner/Smotherman) utime      17.70 secs
 600x600 mm - 20x20 btranspose (Warner/Smotherman) utime      17.76 secs
 
 Changing the declaration to include 10000 dummy entries between the
 b and c matrices (suggested by T. Maeno), i.e.,

 double a[N][N],b[N][N],dummy[10000],c[N][N],d[N][N],bt[N][N];

 600x600 mm - 20x20 subarray (from T. Maeno)       utime      16.41 secs
 600x600 mm - 20x20 subarray (from T. Maeno)       utime      16.40 secs
 600x600 mm - 20x20 subarray (from D. Warner)      utime      16.68 secs
 600x600 mm - 20x20 subarray (from D. Warner)      utime      16.67 secs
 600x600 mm - 20x20 btranspose (Warner/Smotherman) utime      16.97 secs
 600x600 mm - 20x20 btranspose (Warner/Smotherman) utime      16.98 secs

 I hope to add other algorithms (e.g., Strassen-Winograd) in the near future.

P5-166 MHz, 48 MB, Win32Forth 3.5  Build: 0085, double-precision
CLK 165 MHz
	120x120 mm - normal algorithm                            0.92 MFlops, 178.07 ticks/flop,   3.729 s
	120x120 mm - blocking, factor of 20                      0.56 MFlops, 291.36 ticks/flop,   6.102 s
	120x120 mm - transposed B matrix                         0.87 MFlops, 188.09 ticks/flop,   3.939 s
	120x120 mm - Robert's algorithm                          0.91 MFlops, 180.53 ticks/flop,   3.781 s
	120x120 mm - T. Maeno's algorithm, subarray 20x20        0.46 MFlops, 355.63 ticks/flop,   7.448 s
	120x120 mm - D. Warner's algorithm, subarray 20x20       0.57 MFlops, 288.12 ticks/flop,   6.034 s ok

P5-166 MHz, 48 MB, VFX 3.40, April 2002, double-precision
CLK 167 MHz
	120x120 mm - normal algorithm                            8.67 MFlops,  19.24 ticks/flop,   0.398 s
	120x120 mm - blocking, factor of 20                      7.76 MFlops,  21.51 ticks/flop,   0.445 s
	120x120 mm - transposed B matrix                         9.56 MFlops,  17.45 ticks/flop,   0.361 s
	120x120 mm - Robert's algorithm                          9.60 MFlops,  17.37 ticks/flop,   0.359 s
	120x120 mm - T. Maeno's algorithm, subarray 20x20        6.99 MFlops,  23.85 ticks/flop,   0.493 s
	120x120 mm - D. Warner's algorithm, subarray 20x20       7.76 MFlops,  21.52 ticks/flop,   0.445 s ok

P5-166 MHz, 48 MB, SwiftForth 2.2.2 May 2001, double-precision
CLK 165 MHz
	120x120 mm - normal algorithm                            5.45 MFlops,  30.23 ticks/flop,   0.633 s
	120x120 mm - blocking, factor of 20                      4.79 MFlops,  34.39 ticks/flop,   0.720 s
	120x120 mm - transposed B matrix                         5.44 MFlops,  30.29 ticks/flop,   0.634 s
	120x120 mm - Robert's algorithm                          5.68 MFlops,  29.01 ticks/flop,   0.607 s
	120x120 mm - T. Maeno's algorithm, subarray 20x20        2.99 MFlops,  55.14 ticks/flop,   1.154 s
	120x120 mm - D. Warner's algorithm, subarray 20x20       3.52 MFlops,  46.79 ticks/flop,   0.980 s ok

P5-166 MHz, 48 MB, gForth 0.6.1, double-precision, NT 4.0
CLK 166 MHz
	120x120 mm - normal algorithm                            3.74 MFlops,  44.38 ticks/flop,   0.924 s
	120x120 mm - blocking, factor of 20                      2.31 MFlops,  71.68 ticks/flop,   1.492 s
	120x120 mm - transposed B matrix                         3.61 MFlops,  45.98 ticks/flop,   0.957 s
	120x120 mm - Robert's algorithm                          3.77 MFlops,  43.94 ticks/flop,   0.915 s
	120x120 mm - T. Maeno's algorithm, subarray 20x20        1.96 MFlops,  84.34 ticks/flop,   1.756 s
	120x120 mm - D. Warner's algorithm, subarray 20x20       2.58 MFlops,  64.12 ticks/flop,   1.335 s ok

P5-166 MHz, 48 MB, iForth 1.11, double-precision, NT 4.0
CLK 165 MHz
	120x120 mm - normal algorithm                           26.02 MFlops,   6.34 ticks/flop,   0.132 s
	120x120 mm - blocking, factor of 20                     15.57 MFlops,  10.59 ticks/flop,   0.221 s
	120x120 mm - transposed B matrix                        28.53 MFlops,   5.78 ticks/flop,   0.121 s
	120x120 mm - Robert's algorithm                         29.29 MFlops,   5.63 ticks/flop,   0.117 s
	120x120 mm - T. Maeno's algorithm, subarray 20x20       13.09 MFlops,  12.60 ticks/flop,   0.263 s
	120x120 mm - D. Warner's algorithm, subarray 20x20      15.30 MFlops,  10.78 ticks/flop,   0.225 s
	120x120 mm - generic mat*                               64.21 MFlops,   2.56 ticks/flop,   0.053 s ok
========================================================================================================== [THEN]

\ TOOLS ================================================================================================== 
kForth ForthSystem = [IF]  0 ptr [S]
[ELSE]  0 VALUE [S]  [THEN]
0 VALUE [T]

\ Not portable. 
[UNDEFINED] DEC.     [IF] : DEC.  ( n -- ) BASE @ >R DECIMAL . R> BASE ! ;	  [THEN]
[UNDEFINED] ENDIF    [IF] : ENDIF	   POSTPONE THEN ; IMMEDIATE		  [THEN]
[UNDEFINED] F<>      [IF] : F<>	( F: r -- ) ( -- bool ) F= 0= ;			  [THEN]
[UNDEFINED] DFLOAT[] [IF] : DFLOAT[] ( addr ix -- addr' ) DFLOATS + ;		  [THEN]
[UNDEFINED] U>D      [IF]   0 CONSTANT U>D  [THEN]

kForth ForthSystem = [IF]
: DF@+   ( addr -- addr' r )  DUP DFLOAT+ SWAP DF@ ;
: DF!+   ( r addr -- addr' )  DUP >R DF! R> DFLOAT+ ;
: DF+!+  ( r addr -- addr' )  DUP >R DF@ F+ R> DF!+ ;
: DF+!   ( r addr -- )        DUP >R DF@ F+ R> DF! ;
[ELSE]
  [UNDEFINED] DF@+     [IF] : DF@+  ( addr -- addr' ) ( F: -- r ) DUP DF@ DFLOAT+ ; [THEN]
  [UNDEFINED] DF!+     [IF] : DF!+  ( addr -- addr' ) ( F: r -- ) DUP DF! DFLOAT+ ; [THEN]
  [UNDEFINED] DF+!+    [IF] : DF+!+ ( addr -- addr' ) ( F: r -- ) DUP DF@ F+ DF!+ ; [THEN]
  [UNDEFINED] DF+!     [IF] : DF+!  ( addr -- )       ( F: r -- ) DUP DF@ F+ DF!  ; [THEN]
[THEN]

kForth ForthSystem = [IF]
VARIABLE inc1
VARIABLE inc2
DFVARIABLE ddot-sum
: DDOT ( addr1 inc1 addr2 inc2 count -- r )
                SWAP DFLOATS >R ROT DFLOATS R> inc2 ! inc1 !
		0e ddot-sum DF!
		0 ?DO  SWAP DUP DF@ 2>R inc1 @ +  
			  SWAP DUP DF@ 2R> F* ddot-sum DF@ F+ 
			  ddot-sum DF! 
			  inc2 @ +    
	    	    LOOP  2DROP ddot-sum DF@ ;
[ELSE]
  [UNDEFINED] DDOT
  [IF] : DDOT ( addr1 inc1 addr2 inc2 count -- ) ( F: -- n )
		SWAP DFLOATS >R  ROT DFLOATS R> LOCALS| inc2 inc1 |
		0e 0 ?DO  SWAP DUP DF@ inc1 +  
			  SWAP DUP DF@ inc2 +  
		  	  F* F+   
	    	    LOOP  2DROP ;
  [THEN]
[THEN]

kForth ForthSystem = [IF]
DFVARIABLE daxpy-scale
: DAXPY  ( addr1 inc1 addr2 inc2 count r -- )
                daxpy-scale DF!
		SWAP DFLOATS >R  ROT DFLOATS R>  inc2 ! inc1 !
		0 ?DO 
			SWAP DUP DF@ daxpy-scale DF@ F* 2>R inc1 @ +  
			SWAP DUP 2R> ROT DF+!   inc2 @ +  
		 LOOP  	2DROP ;
[ELSE]
  [UNDEFINED] DAXPY
  [IF]	: DAXPY ( addr1 inc1 addr2 inc2 count -- ) ( F: a -- )
		SWAP DFLOATS >R  ROT DFLOATS R> LOCALS| inc2 inc1 |
		0 ?DO  	FDUP 
			SWAP DUP DF@ F* inc1 +  
			SWAP DUP DF+!   inc2 +  
		 LOOP  	2DROP FDROP ;	
  [THEN]		  
[THEN]

[UNDEFINED] 2^x	    [IF] : 2^x  ( x -- 2^x ) 1 SWAP 0 ?DO  1 LSHIFT  LOOP ; 	[THEN]

CHAR x CONSTANT 'x'
CHAR n CONSTANT	'n'
CHAR v CONSTANT	'v'
CHAR u CONSTANT	'u'
CHAR p CONSTANT	'p'
CHAR t CONSTANT	't'
CHAR i CONSTANT	'i'
CHAR b CONSTANT	'b'
CHAR m CONSTANT	'm'
CHAR r CONSTANT	'r'
CHAR w CONSTANT	'w'
CHAR s CONSTANT	's'
CHAR g CONSTANT 'g'
CHAR . CONSTANT	'.'
CHAR , CONSTANT	','
CHAR : CONSTANT	':'
                  
\ ===================================================================================== 

FALSE VALUE SHHT?
   0  VALUE FLOPS
   0  VALUE t/flops
   0  VALUE msecs
  80  VALUE N


1 DFLOATS CONSTANT DFLOAT1
4 DFLOATS CONSTANT DFLOAT4
8 DFLOATS CONSTANT DFLOAT8

DOUBLE DMATRIX  a{{
DOUBLE DMATRIX  b{{
DOUBLE DMATRIX  c{{
DOUBLE DMATRIX  d{{
DOUBLE DMATRIX bt{{

	TICKS-RESET


: ?# ( d -- d )   2DUP OR 0= IF  BL HOLD  ELSE  #  ENDIF ;
: .FLOPS ( n -- ) U>D <# BL HOLD # # '.' HOLD # ?# ?# ?# #> TYPE ." MFlops" ;
: .TICKS ( n -- ) U>D <# BL HOLD # # '.' HOLD # ?# ?# BL HOLD ',' HOLD #> TYPE ." ticks/flop" ;
: .SECS  ( n -- ) U>D <# 's' HOLD BL HOLD # # # '.' HOLD # ?# ?# BL HOLD ',' HOLD #> TYPE ;
: INIT-RESULT	  S" TICKS-RESET 0 TO [T]" EVALUATE POSTPONE BEGIN ; IMMEDIATE

: (.RES) ( n -- ) 
	DUP N * N * N * 2* 1 OR  TICKS? ( -- n fl dti )
	3DUP TICKS>US DROP 1 OR DUP >R  100 SWAP */ TO FLOPS
	d*100 ROT UM/MOD NIP TO t/flops
	R> SWAP 1000 * / TO msecs
	SHHT? IF  EXIT  ENDIF
	FLOPS .FLOPS  t/flops .TICKS msecs .SECS ;

: .RESULT	  S" [T] 1+ TO [T] US? 2000000 S>D D> " EVALUATE 
                  POSTPONE UNTIL POSTPONE [T] POSTPONE (.RES) ; IMMEDIATE

\ Set coefficients so that result matrix should have row entries equal to (1/2)*n*(n-1)*i in row i
: SET-COEFFICIENTS ( -- )  N 0 ?DO  N 0 ?DO  J S>F FDUP b{{ J I }} DF!  a{{ J I }} DF!  LOOP LOOP ;
: FLUSH-CACHE 	   ( -- )  N 0 ?DO  N 0 ?DO  0e d{{ J I }} DF!  LOOP LOOP ;

FVARIABLE row_sum
FVARIABLE sum

: CHECK-RESULT ( -- )
	FLOPS 0= IF  SHHT? 0= IF CR ." algorithm aborted" ENDIF EXIT  ENDIF
	0e row_sum F!
	N N 1- * 2/ S>F sum F!
	N 0 ?DO  I S>F sum F@ F* row_sum F!
		 N 0 ?DO c{{ J I }} DF@ row_sum F@ F<> IF  CR ." error in result entry c{{ " J DEC. I DEC. ." }}: " c{{ J I }} DF@ F. ." <> " row_sum F@ F. UNLOOP UNLOOP EXIT  ENDIF
			 a{{ J I }} DF@     J S>F  F<> IF  CR ." error in result entry a{{ " J DEC. I DEC. ." }}: " a{{ J I }} DF@ F. ." <> " J S>F      F. UNLOOP UNLOOP EXIT  ENDIF
			 b{{ J I }} DF@     J S>F  F<> IF  CR ." error in result entry b{{ " J DEC. I DEC. ." }}: " b{{ J I }} DF@ F. ." <> " J S>F      F. UNLOOP UNLOOP EXIT  ENDIF
		    LOOP	
	   LOOP	;	

kForth ForthSystem = [IF]
: NORMAL() ( -- )
	SHHT? 0= IF  CR N 3 .R 'x' EMIT N . ."  mm - normal algorithm" 54 HTAB ENDIF
	INIT-RESULT
	N 0 ?DO c{{ I 0 }} 
	        a{{ I 0 }} TO [S]
		b{{ 0 0 }} N DFLOATS BOUNDS
		?DO  [S] 1  I N  N DDOT ROT DF!+  DFLOAT1 +LOOP  
		DROP
	   LOOP
	.RESULT ;
[ELSE]
: NORMAL() ( -- )
	SHHT? 0= IF  CR N 0 .R 'x' EMIT N 0 .R ."  mm - normal algorithm" 54 HTAB ENDIF 
	INIT-RESULT
	N 0 ?DO c{{ I 0 }} 
		a{{ I 0 }} TO [S]
		b{{ 0 0 }} N DFLOATS BOUNDS
		?DO  [S] 1  I N  N DDOT DF!+  DFLOAT1 +LOOP  
		DROP
	   LOOP 
	.RESULT ;
[THEN]


kForth ForthSystem = [IF]
: TRANSPOSE() ( -- )
	SHHT? 0= IF  CR N 3 .R 'x' EMIT N . ."  mm - transposed B matrix" 54 HTAB  ENDIF 
	INIT-RESULT
	N 0 ?DO  N 0 ?DO  b{{ J I }} DF@  bt{{ I J }} DF!  LOOP LOOP
	N 0 ?DO  c{{ I 0 }}  N 0 ?DO  a{{ J 0 }} 1  bt{{ I 0 }} 1  N DDOT ROT DF!+  LOOP DROP LOOP
	.RESULT ;
[ELSE]
: TRANSPOSE() ( -- )
	SHHT? 0= IF  CR N 0 .R 'x' EMIT N 0 .R ."  mm - transposed B matrix" 54 HTAB  ENDIF 
	INIT-RESULT
	N 0 ?DO  N 0 ?DO  b{{ J I }} DF@  bt{{ I J }} DF!  LOOP LOOP
	N 0 ?DO  c{{ I 0 }}  N 0 ?DO  a{{ J 0 }} 1  bt{{ I 0 }} 1  N DDOT DF!+  LOOP DROP LOOP
	.RESULT ;
[THEN]


\ from Monica Lam ASPLOS-IV paper 
kForth ForthSystem = [IF]
VARIABLE kk
VARIABLE jj
VARIABLE step
DFVARIABLE temp

: TILING() ( step -- )
	DUP 4 N 1+ WITHIN 0= IF  SHHT? 0= IF CR ."  mm - blocking step size of " DUP DEC. ." is unreasonable" ENDIF DROP EXIT ENDIF
	SHHT? 0=  IF  CR N 3 .R 'x' EMIT N . ."  mm - blocking, factor of " DUP DEC. 54 HTAB  ENDIF
	0 0 kk ! jj ! step ! \ LOCALS| kk jj step |
	INIT-RESULT
	N 0 ?DO  N 0 ?DO  0e c{{ J I }} DF!  LOOP LOOP
	   N 0 ?DO  I kk !	  
		       N 0 ?DO  I jj !
				N 0 ?DO   a{{ I kk @ }}  
					  kk @ step @ + N MIN  
					  kk @ ?DO  DF@+  temp DF!  
					          b{{ I jj @ }} 1  c{{ J jj @ }} 1
					  	  jj @ step @ + N MIN  jj @ - 
						  temp DF@ DAXPY
					    LOOP  DROP	
				   LOOP
		    step @ +LOOP	
	step @ +LOOP
	.RESULT ;
[ELSE]
: TILING() ( step -- )
	DUP 4 N 1+ WITHIN 0= IF  SHHT? 0= IF CR ."  mm - blocking step size of " DUP DEC. ." is unreasonable" ENDIF DROP EXIT ENDIF
	SHHT? 0=  IF  CR N 0 .R 'x' EMIT N 0 .R ."  mm - blocking, factor of " DUP DEC. 54 HTAB  ENDIF
	0 0 LOCALS| kk jj step |
	INIT-RESULT
	N 0 ?DO  N 0 ?DO  0e c{{ J I }} DF!  LOOP LOOP
	   N 0 ?DO  I TO kk	  
		       N 0 ?DO  I TO jj
				N 0 ?DO   a{{ I kk }}  
					  kk step + N MIN  
					  kk ?DO  DF@+  b{{ I jj }} 1  c{{ J jj }} 1
					  	  jj step + N MIN  jj - DAXPY
					    LOOP  DROP	
				   LOOP
		    step +LOOP	
	step +LOOP
	.RESULT ;
[THEN]

	
\ ********************************************
\ * Contributed by Robert Debath 26 Nov 1995 *
\ * rdebath@cix.compulink.co.uk              *
\ ********************************************
kForth ForthSystem = [IF]
: ROBERT() ( -- )
	SHHT? 0=  IF  CR N 3 .R 'x' EMIT N . ."  mm - Robert's algorithm" 54 HTAB  ENDIF
	INIT-RESULT
	N 0 ?DO  N 0 ?DO  b{{ J I }} DF@  bt{{ I J }} DF!  LOOP LOOP
	a{{ 0 0 }} TO [S] 
	N 0 ?DO   bt{{ 0 0 }} 
		   c{{ I 0 }} 
		  N 0 ?DO  [S] 1  3 PICK 1  N DDOT  ROT DF!+  SWAP N DFLOAT[] SWAP  LOOP 
		  2DROP
		  N DFLOATS [S] + TO [S] 
	   LOOP
	.RESULT ;
[ELSE]
: ROBERT() ( -- )
	SHHT? 0=  IF  CR N 0 .R 'x' EMIT N 0 .R ."  mm - Robert's algorithm" 54 HTAB  ENDIF
	INIT-RESULT
	N 0 ?DO  N 0 ?DO  b{{ J I }} DF@  bt{{ I J }} DF!  LOOP LOOP
	a{{ 0 0 }} TO [S] 
	N 0 ?DO   bt{{ 0 0 }} 
		   c{{ I 0 }} 
		  N 0 ?DO  [S] 1  3 PICK 1  N DDOT  DF!+  SWAP N DFLOAT[] SWAP  LOOP 
		  2DROP
		  N DFLOATS [S] + TO [S] 
	   LOOP
	.RESULT ;
[THEN]


0 [IF] ===========================================================================
 * Matrix Multiply by Dan Warner, Dept. of Mathematics, Clemson University
 *
 *    mmbu2.f multiplies matrices a and b
 *    a and b are n by n matrices
 *    nb is the blocking parameter.
 *    the tuning guide indicates nb = 50 is reasonable for the
 *    ibm model 530 hence 25 should be reasonable for the 320 
 *    since the 320 has 32k rather than 64k of cache.      
 *    Inner loops unrolled to depth of 2
 *    The loop functions without clean up code at the end only
 *    if the unrolling occurs to a depth k which divides into n
 *    in this case n must be divisible by 2.
 *    The blocking parameter nb must divide into n if the
 *    multiply is to succeed without clean up code at the end. 
 *
 * converted to c by Mark Smotherman
 * note that nb must also be divisible by 2 => cannot use 25, so use 20
=========================================================================== [THEN]

DFVARIABLE s10
DFVARIABLE s00
DFVARIABLE s01
DFVARIABLE s11

kForth ForthSystem = [IF]
VARIABLE 'a
VARIABLE 'b
VARIABLE ii
VARIABLE jj
VARIABLE kk
VARIABLE nb

: WARNER() ( nb -- )
	0 0 0 0 0  'a ! 'b ! ii ! jj ! kk ! nb !        \ LOCALS| 'a 'b ii jj kk nb |
	SHHT? 0= IF  CR N 3 .R 'x' EMIT N .  ENDIF
	N nb @ MOD  N 2 MOD OR IF SHHT? 0= IF 
	  ."  mm - Warner's algorithm, the matrix size " 
	  N DEC. ." must be divisible both by the block size " nb @ DEC. ." and 2." ENDIF EXIT ENDIF
	nb @ 2 MOD IF  SHHT? 0= IF 
	  ."  mm - block size for Warner method must be evenly divisible by 2" ENDIF EXIT ENDIF
	SHHT? 0= IF  ."  mm - D. Warner's algorithm, subarray " nb @ .
	 'x' EMIT nb @ . SPACE  54 HTAB  ENDIF
	INIT-RESULT
	 N 0 ?DO  I ii ! 
	   N 0 ?DO I jj !
		  nb @ ii @ + ii @ ?DO  nb @ jj @ + jj @ ?DO  0e c{{ J I }} DF!  
	 LOOP  LOOP
	 N 0 ?DO  I kk !
	   nb @ ii @ + ii @ ?DO 
	     nb @ jj @ + jj @ ?DO 
	       c{{ J     I    }} DUP	DF@+ s00 DF!
					DUP DF@  s01 DF!
	       c{{ J 1+  I    }} DUP DF@+ s10 DF!
				 DUP DF@  s11 DF!
	       a{{ J    kk @ }} 'a !
	       b{{ kk @   I }}  'b !
	       nb @ kk @ + kk @ ?DO  'a a@
				DUP DF@ 2>R 'b a@ DF@+	2R> F* s00 DF+!
				SWAP DF@ 2>R  DF@  2R>  F* s01 DF+!
				'a a@ N DFLOAT[] DUP  DF@ 2>R 'b a@ DF@+ 2R> F* s10 DF+!
				SWAP DF@  2>R  DF@ 2R> F* s11 DF+!
				DFLOAT1   'a	a@ + 'a !
				N DFLOATS 'b 	a@ + 'b !
		LOOP
		s11 DF@ ROT DF!
		s10 DF@ ROT DF!
		s01 DF@ ROT DF!
		s00 DF@ ROT DF!
	      2 +LOOP
	    2 +LOOP
	  nb @ +LOOP
        nb @ +LOOP
	nb @ +LOOP
	.RESULT ;
[ELSE]
: WARNER() ( nb -- )
	0 0 0 0 0 LOCALS| 'a 'b ii jj kk nb |
	SHHT? 0= IF  CR N 0 .R 'x' EMIT N 0 .R  ENDIF
	N nb MOD  N 2 MOD OR IF SHHT? 0= IF ."  mm - Warner's algorithm, the matrix size " N DEC. ." must be divisible both by the block size " nb DEC. ." and 2." ENDIF EXIT ENDIF
	nb 2 MOD IF  SHHT? 0= IF ."  mm - block size for Warner method must be evenly divisible by 2" ENDIF EXIT ENDIF
	SHHT? 0= IF  ."  mm - D. Warner's algorithm, subarray " nb 0 .R 'x' EMIT nb 0 .R SPACE  54 HTAB  ENDIF
	INIT-RESULT
	 N 0 ?DO  I TO ii 
		  N 0 ?DO I TO jj
		  	  nb ii + ii ?DO  nb jj + jj ?DO  0e c{{ J I }} DF!  LOOP  LOOP
			  N 0 ?DO  I TO kk
				   nb ii + ii ?DO 
				   nb jj + jj ?DO c{{ J     I    }} DUP DF@+ s00 DF!
						  		    DUP DF@  s01 DF!
						  c{{ J 1+  I    }} DUP DF@+ s10 DF!
						  		    DUP DF@  s11 DF!
						  a{{ J    kk }} TO 'a
						  b{{ kk    I }} TO 'b
						  nb kk + kk ?DO  'a		 DUP DF@  'b DF@+ F* s00 DF+!
								    	        SWAP DF@     DF@  F* s01 DF+!
								  'a N DFLOAT[] DUP  DF@  'b DF@+ F* s10 DF+!
								                SWAP DF@     DF@  F* s11 DF+!
								  DFLOAT1   'a + TO 'a
								  N DFLOATS 'b + TO 'b
							    LOOP
						  s11 DF@ DF!
						  s10 DF@ DF!
						  s01 DF@ DF!
						  s00 DF@ DF! 
					  2 +LOOP
					  2 +LOOP
			 nb +LOOP
		 nb +LOOP
	nb +LOOP
	.RESULT ;
[THEN]

0 [IF] =========================================================================== 
Matrix Multiply tuned for SS-10/30;
 *                      Maeno Toshinori
 *                      Tokyo Institute of Technology
 *
 * Using gcc-2.4.1 (-O2), this program ends in 12 seconds on SS-10/30. 
 *
 * in original algorithm - sub-area for cache tiling
 * #define      L       20
 * #define      L2      20
 * three 20x20 matrices reside in cache; two may be enough
=========================================================================== [THEN]

DFVARIABLE t0
DFVARIABLE t1
DFVARIABLE t2
DFVARIABLE t3
DFVARIABLE t4
DFVARIABLE t5
DFVARIABLE t6
DFVARIABLE t7

kForth ForthSystem = [IF]
VARIABLE @K
VARIABLE it
VARIABLE kt
VARIABLE i2
VARIABLE kk
VARIABLE lparm
DFVARIABLE temp

: MAENO() ( nb -- )
	0 0 0 0 0  @K ! it ! kt ! i2 ! kk ! lparm !         \ LOCALS| @K it kt i2 kk lparm |
	SHHT? 0= IF  CR N 3 .R 'x' EMIT N .  ENDIF
	N lparm @ MOD  N 4 MOD OR IF SHHT? 0= IF ."  mm - Maeno's algorithm, the matrix size " N DEC. ." must be divisible both by the block size " lparm DEC. ." and 4." ENDIF EXIT ENDIF
	lparm @ 4 MOD IF  SHHT? 0= IF ."  mm - block size for Maeno's method must be evenly divisible by 4" ENDIF EXIT  ENDIF
	SHHT? 0= IF  ."  mm - T. Maeno's algorithm, subarray " lparm @ .
	'x' EMIT lparm @ . SPACE  54 HTAB  ENDIF
	INIT-RESULT
	N 0 ?DO N 0 ?DO  0e c{{ J I }} DF!  LOOP LOOP
	    N 0 ?DO I i2 !  N 0 ?DO  I kk !
			i2 @ lparm @ + it !  
			kk @ lparm @ + kt !
			N 0 ?DO  I @K !
			  it @ i2 @ ?DO  
			    0e t0 DF!  0e t1 DF!  0e t2 DF!  0e t3 DF!
			    0e t4 DF!  0e t5 DF!  0e t6 DF!  0e t7 DF!
			    kt @  kk @ ?DO	a{{ J    I }} DF@ temp DF!
						b{{ I @K @ }} DUP DF@+ temp DF@ F* t0 DF+!
						 		  DF@+ temp DF@ F* t1 DF+!
						 		  DF@+ temp DF@ F* t2 DF+!
								  DF@  temp DF@ F* t3 DF+!
						a{{ J 1+ I }} DF@ temp DF!
						 		  DF@+ temp DF@ F* t4 DF+! 
						 		  DF@+ temp DF@ F* t5 DF+!
						 		  DF@+ temp DF@ F* t6 DF+!
								  DF@  temp DF@ F* t7 DF+!
					LOOP
					t0 DF@ c{{ I    J }}  DF+!+
					t1 DF@ ROT 	      DF+!+
					t2 DF@ ROT	      DF+!+
					t3 DF@ ROT	      DF+!
					t4 DF@ c{{ I 1+ J }}  DF+!+
					t5 DF@ ROT            DF+!+
					t6 DF@ ROT            DF+!+
					t7 DF@ ROT            DF+!
				     2 +LOOP
				   4 +LOOP
	    		 lparm @ +LOOP 
	lparm @ +LOOP
	.RESULT ;
[ELSE]
: MAENO() ( nb -- )
	0 0 0 0 0 LOCALS| @K it kt i2 kk lparm |
	SHHT? 0= IF  CR N 0 .R 'x' EMIT N 0 .R  ENDIF
	N lparm MOD  N 4 MOD OR IF SHHT? 0= IF ."  mm - Maeno's algorithm, the matrix size " N DEC. ." must be divisible both by the block size " lparm DEC. ." and 4." ENDIF EXIT ENDIF
	lparm 4 MOD IF  SHHT? 0= IF ."  mm - block size for Maeno's method must be evenly divisible by 4" ENDIF EXIT  ENDIF
	SHHT? 0= IF  ."  mm - T. Maeno's algorithm, subarray " lparm 0 .R 'x' EMIT lparm 0 .R SPACE  54 HTAB  ENDIF
	INIT-RESULT
	N 0 ?DO N 0 ?DO  0e c{{ J I }} DF!  LOOP LOOP
	    N 0 ?DO I TO i2  N 0 ?DO  I TO kk
				      i2 lparm + TO it  
				      kk lparm + TO kt
				      N 0 ?DO  	I TO @K
				      		it i2 ?DO  
							  0e t0 DF!  0e t1 DF!  0e t2 DF!  0e t3 DF!
							  0e t4 DF!  0e t5 DF!  0e t6 DF!  0e t7 DF!
							  kt  kk ?DO	a{{ J    I }} DF@ 
									FDUP b{{ I @K }} DUP DF@+ F* t0 DF+!
									FDUP 		     DF@+ F* t1 DF+!
									FDUP 		     DF@+ F* t2 DF+!
									     		     DF@  F* t3 DF+!
									a{{ J 1+ I }} DF@
									FDUP 		     DF@+ F* t4 DF+! 
									FDUP 		     DF@+ F* t5 DF+!
									FDUP 		     DF@+ F* t6 DF+!
									     		     DF@  F* t7 DF+!
							  	LOOP
							  t0 DF@ c{{ I    J }}  DF+!+
							  t1 DF@  	        DF+!+
							  t2 DF@ 		DF+!+
							  t3 DF@		DF+!
							  t4 DF@ c{{ I 1+ J }}  DF+!+
							  t5 DF@	        DF+!+
							  t6 DF@		DF+!+
							  t7 DF@		DF+!
				      		 2 +LOOP
				      4 +LOOP
	    		 lparm +LOOP 
	lparm +LOOP
	.RESULT ;
[THEN]

0 VALUE ur
: MM ( char n -- )
	DEPTH 0= ABORT" no algorithm chosen" 
	DEPTH 2 < IF 0 ENDIF TO ur                 \ LOCALS| ur |
	&  a{{ N N }}malloc malloc-fail? 
	&  b{{ N N }}malloc malloc-fail? OR
	& bt{{ N N }}malloc malloc-fail? OR
	&  c{{ N N }}malloc malloc-fail? OR
	&  d{{ N N }}malloc malloc-fail? OR ABORT" MM :: out of core"
	SET-COEFFICIENTS
	FLUSH-CACHE
	CASE 
	 'n' OF NORMAL()    ENDOF
	 't' OF TRANSPOSE() ENDOF
	 'b' OF ur TILING() ENDOF
	 'r' OF ROBERT()    ENDOF
	 'm' OF ur MAENO()  ENDOF
	 'w' OF ur WARNER() ENDOF
	 'g' OF GENERIC()   ENDOF
	        CR ." `" DUP EMIT ." ' is an invalid algorithm" 
	ENDCASE
	CHECK-RESULT
	&  d{{ }}free
	&  c{{ }}free
	& bt{{ }}free
	&  b{{ }}free
	&  a{{ }}free ;

: (HEADER) ( -- ) CR ." CLK " CALIBRATE PROCESSOR-CLOCK DEC. ." MHz" ;

: (ALL-TESTS) ( -- )
	'n'    mm  'b' 20 mm  't'    mm		
	'r'    mm  'm' 20 mm  'w' 20 mm  
	specifics  if   'g'    mm  then ;

: ALL-TESTS ( -- ) (HEADER) (ALL-TESTS) ;

: ALL-N-TESTS ( -- )
	(HEADER)
	 60 TO N  (ALL-TESTS) CR
	120 TO N  (ALL-TESTS) CR
	500 TO N  (ALL-TESTS) ;

: NEXT-N ( -- )
	N 1200 1000 */ TO N 
	 17 1 DO  N  I 2^x DUP  9 10 */ SWAP  11 10 */ 
		  WITHIN IF  I 2^x TO N LEAVE  ENDIF  
	    LOOP ;

kForth ForthSystem = [IF]
VARIABLE old-N
VARIABLE silence?
VARIABLE flp
VARIABLE ix
VARIABLE ur
VARIABLE algo
: MEGAFLOPS ( sel -- )
	DEPTH 0= ABORT" no algorithm chosen" 
	DEPTH 2 < IF 0 ENDIF
	0 0 SHHT? N   old-N ! silence? ! flp ! ix ! ur ! algo ! 
	TRUE TO SHHT?  
	CR ." Algorithm = '" algo @ EMIT [CHAR] ' EMIT  ur @ IF ." , parameter is " ur . ENDIF
	." , clock = " CALIBRATE PROCESSOR-CLOCK DEC. ." MHz"
	32 TO N  
	 17 0 DO CR ." testing data size " N 3 .R  ."  x " N 3 .R ':' EMIT
		 algo @ ur @ mm  
		 FLOPS flp @ > IF  FLOPS flp !  N ix !  ENDIF 
		 FLOPS .FLOPS
		 NEXT-N  0 TO FLOPS
	    LOOP 
	ix @ IF  CR CR ." Maximum: " flp @ .FLOPS ."  at N = " ix @ DEC.  ENDIF
	silence? @ TO SHHT?  old-N @ TO N ;
[ELSE]	
: MEGAFLOPS ( sel -- )
	DEPTH 0= ABORT" no algorithm chosen" 
	DEPTH 2 < IF 0 ENDIF
	0 0 SHHT? N LOCALS| old-N silence? flp ix ur algo |
	TRUE TO SHHT?  
	CR ." Algorithm = '" algo EMIT [CHAR] ' EMIT  ur IF ." , parameter is " ur 0 .R ENDIF
	." , clock = " CALIBRATE PROCESSOR-CLOCK DEC. ." MHz"
	32 TO N  
	 17 0 DO CR ." testing data size " N 3 .R  ."  x " N 3 .R ':' EMIT
		 algo ur mm  
		 FLOPS flp > IF  FLOPS TO flp  N TO ix  ENDIF 
		 FLOPS .FLOPS
		 NEXT-N  0 TO FLOPS
	    LOOP 
	ix IF  CR CR ." Maximum: " flp .FLOPS ."  at N = " ix DEC.  ENDIF
	silence? TO SHHT?  old-N TO N ;
[THEN]

: .ABOUT
	CR ." -------------------------- Double-precision benchmark --------------------------"	
	CR ." Try: 'n'    mm  -- normal"
	CR ."      'b'  n mm  -- using blocking by n, 4 < n < " N DEC. 
	CR ."      't'    mm  -- with transposed b matrix"
	CR ."      'r'    mm  -- using Robert's algorithm" 
	CR ."      'm'  n mm  -- using Maeno's algorithm with blocking factor n" 
	CR ."      'w'  n mm  -- using Warner's algorithm with blocking factor n" 
	CR ."      'g'    mm  -- optional superfast vendor-supplied routine"
	CR
	CR ." ALL-TESTS       -- test all algorithms" 
	CR ." ALL-N-TESTS     -- ALL-TESTS for N=60, 120 and 500" 
	CR ." ( x ) MEGAFLOPS -- find optimum size for this machine, algorithm 'x'" ;

                .ABOUT 

( base -- ) BASE !

                              ( * End of Source * )

