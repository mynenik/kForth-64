\ wl-tools.4th
\
\ Glossary:
\
\   WL-INFO      ( wid -- ) Display information about words in wordlist.
\   WL-IMMEDIATE ( wid -- ) Display IMMEDIATE words in a wordlist.
\   WL-CREATED   ( wid -- ) Display CREATEd words in a wordlist.
\   SO-CREATED   ( -- )     Display all CREATEd words in search order.
\   WL-COLLISIONS ( wid1 wid2 -- ) Display name collisions between two wlists.
\   WL-OCCURRENCES ( caddr u wid -- utimes ) Return number of occurrences.
\   SO-OCCURRENCES ( caddr u -- utimes ) Return number of occurrences of a word.
\   SHOW-CORE    ( -- ) Display all Core words in Forth 2012.
\   CORE-MISSING ( -- u )  Return number of Core words missing in search order.
\   CORE-REDEFINED ( -- u ) Return number of Core words redefined.
\
\ Requires: ans-words.4th
\
\ Example of Use:
\
\   hex forth-wordlist wl-info
\   hex forth-wordlist wl-created
\

: $@ ( a -- caddr u ) dup @ >r cell+ a@ r> ;

[UNDEFINED] $UCASE [IF]
\ $ucase is not a standard word; it is provided here as a helper.
: $ucase ( a u -- a u )  \ transform string to upper case
     2DUP  0 ?DO
       DUP C@
       DUP [CHAR] a [ CHAR z 1+ ] LITERAL WITHIN
       IF 95 AND THEN OVER C! 1+
     LOOP  DROP ;
[THEN]

variable pNames
variable pStrings
variable nNames
: PARSE-NAMES ( anamebuf astrbuf -- n )
    pStrings ! pNames ! 0 nNames !
    BEGIN
      bl word count $ucase
      2dup s" END-PARSE" compare
    WHILE
      ?dup IF
        2dup pNames a@ swap move nip
        dup  pNames a@ swap pStrings a@ 2!
        pNames +!
        2 cells pStrings +!
        1 nNames +!
      ELSE 
        drop
        refill 0= IF nNames @ EXIT THEN
      THEN
    REPEAT
    2drop nNames @
;


\ right justified output of a string in a field
: $.R ( caddr1 u1 nfield -- | assume nfield > u1)
   over - spaces type ;

: immediate? ( nt -- flag )
    name>compile ['] execute = nip ;

: word-info ( nt -- flag )
   cr
   dup name>string 32 $.R      \ display the word name
   dup immediate? 
   4 spaces
   IF   s" IMM "  \ display precedence IMMEDIATE
   ELSE s"     "
   THEN type
   name>interpret   
   dup >body swap   \ -- pfa xt 
   16 u.r           \ display the xt
   2 spaces
   16 u.r           \ display the pfa
   true ;

\ Display info on each word in the specified wordlist:
\   Name, Precedence, xt, pfa 
: wl-info ( wid -- )
    ['] word-info swap traverse-wordlist ;

\ Display name of IMMEDIATE word
: immediate-word ( nt -- flag )
    dup immediate? IF
      cr name>string 4 spaces type
    ELSE
      drop
    THEN
    true ;

\ Display all IMMEDIATE words in the specified wordlist
: wl-immediate ( wid -- )
   ['] immediate-word swap traverse-wordlist cr ;

\ Display name and body address for a CREATEd word only:
\ i.e. has a non-zero xt and non-zero body address
: created-word ( nt -- flag )
   dup name>interpret 
   ?dup IF
     >body ?dup IF   
       swap name>string cr 32 $.R     \ display the wordname
       4 spaces 16 u.r   \ display the body address
     ELSE drop
     THEN
   ELSE drop
   THEN
   true ;

\ Display the CREATEd words in the specified wordlist
: wl-created ( wid -- )
   ['] created-word swap traverse-wordlist cr ;

\ Display all CREATEd words in the search order
: so-created ( -- )
    get-order 0 do cr wl-created loop ;

\ Count number of occurrences of a word in a wordlist
\   The string argument should have persistence.
variable nOccurrences
: count-occurrences ( caddr u nt -- caddr u flag )
    >r 2dup r> name>string $ucase 
    compare 0= IF 1 nOccurrences +! THEN 
    true ;
 
: wl-occurrences ( caddr u wid -- utimes )
    0 nOccurrences ! >r $ucase r>
    ['] count-occurrences swap traverse-wordlist 2drop 
    nOccurrences @ ;  

\ Count number of occurrences of a word in the search order
variable nTotalOccurrences
: so-occurrences ( caddr u -- utimes )
    2>r  0 nTotalOccurrences !
    get-order 2r> rot 
    0 DO 
      2dup 2>r 
      rot wl-occurrences 
      nTotalOccurrences +!
      2r>
    LOOP
    2drop nTotalOccurrences @   
;

\ Show all name collisions between two wordlists
\
\ Usage:
\  	wid1 wid2 wl-collisions 

variable wid2

: next-name2 ( c-addr u nt -- c-addr u flag )
	name>string
	2over 2over compare 0= IF
	  cr type false
	ELSE
	  2drop true
	THEN ;

: next-name1 ( nt -- c-addr u flag )
	name>string ['] next-name2 wid2 a@ traverse-wordlist 
	2drop true ;

: wl-collisions ( wid1 wid2 -- ) 
	wid2 ! ['] next-name1 swap traverse-wordlist ;

\ Core words

150 constant MAX_CORE_WORDS
create corenames 1024 allot
create corewords MAX_CORE_WORDS cells 2* allot
variable nCoreWords

corenames corewords PARSE-NAMES 
  ! # #> #S ' ( * */ */MOD + +! +LOOP , - . ."
  / /MOD 0< 0= 1+ 1- 2! 2* 2/ 2@ 2DROP 2DUP 2OVER
  2SWAP : ; < <# = > >BODY >IN >NUMBER >R ?DUP @
  ABORT ABORT" ABS ACCEPT ALIGN ALIGNED ALLOT AND
  BASE BEGIN BL C! C, C@ CELL+ CELLS CHAR CHAR+ 
  CHARS CONSTANT COUNT CR CREATE DECIMAL DEPTH DO
  DOES> DROP DUP ELSE EMIT ENVIRONMENT? EVALUATE
  EXECUTE EXIT FILL FIND FM/MOD HERE HOLD I IF
  IMMEDIATE INVERT J KEY LEAVE LITERAL LOOP LSHIFT
  M* MAX MIN MOD MOVE NEGATE OR OVER POSTPONE QUIT
  R> R@ RECURSE REPEAT ROT RSHIFT S" S>D SIGN
  SM/REM SOURCE SPACE SPACES STATE SWAP THEN TYPE 
  U. U< UM* UM/MOD UNLOOP UNTIL VARIABLE WHILE WORD 
  XOR [ ['] [CHAR] ]
END-PARSE
nCoreWords !

\ Display names of all Core words
: show-core ( -- )
    cr nCoreWords @ 0 ?DO
      2 spaces 
      corewords I 2* cells + $@ type
      I 1+ 8 mod 0= IF cr THEN
   LOOP
;

\ Check for missing Core words in the search order
variable nCoreMissing

: core-missing ( -- u )
    0 nCoreMissing !
    nCoreWords @ 0 ?DO
      corewords I 2* cells + $@
      2dup so-occurrences 0= IF
        cr type
        1 nCoreMissing +!
      ELSE 2drop
      THEN
    LOOP
    nCoreMissing @ ;

 
\ Check for redefinitions of standard Core words;
\ Return number of core words which have multiple
\ occurrences in the search order. The Forth
\ wordlist is assumed to be in the search order,
\ but maybe we should explicitly check for that.  
variable nCoreChanged

: core-redefined ( -- u )
    0 nCoreChanged !
    nCoreWords @ 0 ?DO
      corewords I 2* cells + $@
      2dup so-occurrences 1 > IF
        cr type
        1 nCoreChanged +!
      ELSE 2drop
      THEN
    LOOP
    nCoreChanged @
;

