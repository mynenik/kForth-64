\ parse-h2lines.4th
\
\ Read and parse the file h2lines.dat to test string
\ parsing words. 
\
\ K. Myneni, 2022-03-20
\
\ The file h2lines.dat is created by the program
\ h2spec.f, included in the H2SPEC repository at
\ https://github.com/mynenik/H2SPEC
\
include ans-words
include struct-200x
include strings
include files

BEGIN-STRUCTURE EnergyLevel%
  cfield: eState
   field: vQN
   field: JQN
  cfield: Parity
END-STRUCTURE
    
BEGIN-STRUCTURE SpectralLine%
   field: LineIndex
  ffield: Wavelength  \ Angstroms
  ffield: Wavenumber  \ frequency in cm^-1
  ffield: Aul         \ line transition rate in s^-1
  EnergyLevel% +field LowerLevel
  EnergyLevel% +field UpperLevel
END-STRUCTURE

4096 constant MAX_LINES
12 constant N_COLS

Create LineList SpectralLine% MAX_LINES * allot

: &SpectralLine ( uidx -- addr )  SpectralLine% * LineList + ;

\ Fields conversion
: >uint ( caddr u -- u ) 0 s>d 2swap >number 2drop drop ;
: >char ( caddr u -- c ) bl skip drop c@ ;
\ >float is a standard word

\ String Parsing and Processing

: parse-string ( xt-nexttoken xt-processtoken caddr u -- ntokens )
    0 >r
    BEGIN
      2over drop execute
    WHILE
      r@ 5 pick execute
      1 rp@ +!
    REPEAT
    2drop 2drop 2drop
    r> ;

variable lineCount

[UNDEFINED] next-bs-token [IF]
\ Parse next blank(s)-separated token from a string
: next-bs-token ( caddr u -- arem urem atok utok )
    bl skip 2dup bl scan 2>r r@ - 2r> 2swap ;
[THEN]

: next-line-field ( caddr1 u1 -- caddr2 u2 caddr3 u3 flag )
    next-bs-token dup 0= invert ;
 
\ Field processors

\ Create a table of n single cell numbers/addresses
: table ( v1 v2 ... vn n <name> -- )
    create dup cells allot? 
    over 1- cells + swap
    0 ?DO dup >r ! r> 1 cells - LOOP 
    drop ;

: CurrentLine ( -- addr ) lineCount @ &SpectralLine ;
:NONAME >uint       CurrentLine LineIndex ! ;
:NONAME >float drop CurrentLine Wavelength f! ;
:NONAME >float drop CurrentLine Wavenumber f! ;
:NONAME >float drop CurrentLine Aul f! ;
:NONAME >char  CurrentLine LowerLevel eState c! ;
:NONAME >uint  CurrentLine LowerLevel vQN ! ;
:NONAME >uint  CurrentLine LowerLevel JQN ! ;
:NONAME >char  CurrentLine LowerLevel Parity c! ;
:NONAME >char  CurrentLine UpperLevel eState c! ;
:NONAME >uint  CurrentLine UpperLevel vQN ! ;
:NONAME >uint  CurrentLine UpperLevel JQN ! ;
:NONAME >char  CurrentLine UpperLevel Parity c! ;
12 Table FieldProcessors

: process-line-field ( caddr u ufield -- )
    CELLS FieldProcessors + a@ execute ;

\ Read, parse, and process h2lines.dat

64 constant MAX_LINE_LENGTH
create inpLine MAX_LINE_LENGTH allot
0 value inFid

: read-parse ( -- )
    0 lineCount !
    s" h2lines.dat"
    R/O open-file abort" Error opening input file!"
    to inFid
    BEGIN
      inpLine MAX_LINE_LENGTH inFid read-line
      IF inFid close-file 1 throw THEN
      IF
        inpLine swap 
        ['] next-line-field ['] process-line-field 
        2swap parse-string
        N_COLS = IF  1 lineCount +!  THEN
      ELSE
        \ reached eof
        drop inFid close-file drop EXIT
      THEN
    AGAIN
;

cr
ms@ read-parse ms@ swap -
.( Elapsed time = ) . space .( ms) cr
.( Number of lines = ) lineCount ? cr

\ *** Optional: Display selected spectral line ***

[UNDEFINED] F.RD [IF]
\ Convert r to a formatted fixed point string with
\ n decimal places, 0 <= n <= 17.
\ WARNING: Requesting a number fixed point decimal places which
\   results in total number of digits > 17 will give
\   incorrect results, e.g. "65536.9921875e 15 f>fpstr type"
\   will output garbage (20 digits are being requested).
: f>fpstr ( n -- a u ) ( F: r -- ) \ ( r n -- a u )
    0 max 17 min >r 10e r@ s>f f**
    f* fround f>d dup -rot dabs
    <# r> 0 ?DO # LOOP [char] . hold #s rot sign #> ;

\ Print an fp number as a fixed point string with
\ n decimal places, right-justified in a field of width, w
: f.rd ( w n -- ) ( F: r -- ) \ ( r w n -- )
    swap >r f>fpstr dup 20 > IF
      \ Too many digits requested in fixed point output
      2drop r> 0 ?DO [char] * emit LOOP
    ELSE
      r> over -
      dup 0> IF spaces ELSE drop THEN type
    THEN ;
[THEN]

: .Level ( addr -- )
    dup eState c@ emit space
    dup vQN     @ 2 .R space
    dup JQN     @ 2 .R space
        Parity c@ emit ;

: .SpectralLine ( ulineidx -- )
    precision >r
    4 set-precision
    1- 0 max
    &SpectralLine
    dup LineIndex   @    4 .r   2 spaces
    dup Wavelength f@  8 3 f.rd 2 spaces
    dup Wavenumber f@ 10 3 f.rd 2 spaces
    dup Aul        f@      fs.  space
    dup LowerLevel .Level 2 spaces 
        UpperLevel .Level 
    r> set-precision ;


cr
.( Selected Lines ) cr
  1 .SpectralLine cr
 10 .SpectralLine cr
140 .SpectralLine cr
lineCount @ .SpectralLine cr


