\ lf v0.0.12f  06 August 2002 + 
\ Leo Wong
\ hello@albany.net
\ http://www.albany.net/~hello/

\ I thank Wil Baden, Anton Ertl, Marcel Hendrix,
\ Benjamin Hoyt, Chris Jakeman, Bruce R. McFarling,
\ Barrie Stott, and Jonah Thomas for their help.

\ I am grateful to Chris Jakeman for pointing out
\ and correcting several mistakes.
                                  
\ LF is an NPBP (not pretty but portable) ANS Forth
\ word processor.

\ Portable means:  designed to work in any ANS Forth
\ ("Standard") system that implements, can define, or can
\ provide the functionality of the ANS Forth words that LF
\ uses (see below for a list of these words).  LF has a few
\ environmental dependencies that could be gotten rid of.

\ See also below the CONSTANTs that may need to be changed
\ for LF to work optimally on your system.

\ I have tested the NP part of LF.  LF could easily become
\ quite comely though still austere.  I await word on the BP
\ part.  Please tell me if LF works or doesn't work on your
\ ANS Forth system.

\ I would also appreciate being notified of any bugs you find.


\ To start LF, load a Standard System, then enter:
\
\ INCLUDE LF.4TH    ( S" LF.F" INCLUDED)
\
\ Enter a filename.  You are now in text-entry mode.  Enter
\ some text or press:
\
\ ``
\
\ that is, two single opening quotations marks, or glottal
\ stops, or left hands clapping to enter Command Mode.  In
\ Command Mode, press:
\
\ q
\
\ to query the help screen.
\
\ The Enter, Backspace, and Tab keys work in both text-entry
\ and command modes.

\ I have not provided a printing function, not knowing how to
\ do so portably.  I've provided some words to try if you can
\ teach your ANS Forth to print.


\ ANS Forth Documentation
\
\ LF uses ANS Forth words from the Core word set.
\
\ LF also uses words from other word sets.  Though "required"
\ by LF, many of these words don't need to be in your Forth
\ system:  they can be easily defined or their functionality
\ can be provided by other words.  I believe that the only
\ real requirements are the Core word set and the abilities to
\ position the cursor and to read and write to mass storage.
\
\ Having said this, I say that:
\
\ LF is an ANS Forth Program
\
\ With environmental dependencies:
\   will respond to control characters 8, 9, and 13 though
\   the ability to receive control characters is not required
\   may be configured to send control character 7.
\   uses flags as arithmetic operands  (I think it does)
\   uses two's complement arithmetic  (maybe - I hope not)
\
\ Requiring from the Core Extensions word set:
\   2>R 2R> <> ?DO CASE ENDCASE ENDOF ERASE FALSE MARKER
\   NIP OF PAD TO TRUE TUCK U.R UNUSED VALUE WITHIN \
\
\ Requiring from the Facility word set:
\   AT-XY PAGE
\
\ Requiring from the File-Access word set:
\   ( BIN CREATE-FILE FILE-SIZE INCLUDED OPEN-FILE
\   R/O READ-FILE S" W/O WRITE-FILE
\
\ Requiring from the String word set:
\   -TRAILING BLANK CMOVE CMOVE> SEARCH
\
\ Requiring the Memory-Allocation word set (if ALLOCATEing):
\  ALLOCATE FREE
\
\
\ LF requires keyboard input, the ability to position
\ the cursor, and access to mass storage in the form of
\ files.
\
\
\ A Standard System exists after LF is loaded.

\ ===================================================
\ Notes (by Krishna Myneni, 2002-09-06):
\
\ -- Line numbering may be turned off/on by setting the
\    constant LINE#-SPACE. Here, line numbers are turned off
\    by default.
\
\ -- The page length may be changed by setting the constant
\    MAX-Y. Here it is set to the original default of 23,
\    but I prefer to use a full page length (54 for MAX-Y).
\    Longer page lengths may be used in ANSI consoles with
\    a sufficient number of rows, for example a BASH shell
\    under X-Windows that has been resized to accomodate
\    the full text display. The cursor position will be
\    incorrect if the console does not support enough output
\    lines. MAX-Y of 23 should work on any console.
\
\ -- The constant 'CR has been changed from decimal 13 to 10,
\    since the LF character represents an end of line under
\    UNIX systems.
\
\ -- The constant EDIT-BUF-SIZE is 1 MB, suitable for most
\    day to day usage. Increase/decrease as desired.
\
\ ===================================================
\ Code modifications for the kForth version (KM  2002-08-13):
\
\ 1. Changed >FILE to BUF>FILE and FILE> to FILE>BUF.
\ 2. Modified BUF>FILE test for WRITE-FILE result.
\ 3. Recoded -TRAILING<> to remove WHILE ... THEN structure.
\ 4. Changed READ to READ-DOC and ?READ to ?READ-DOC.
\ 5. Changed CALL to CALL-WAY.
\ 6. VALUEs which are addresses have been changed to "ptr"s
\ 7. Remove use of HERE and "," and replace with equivalent code.
\ 8. Replaced ?DE-ALLOCATE and DO-ALLOCATE with dummy definitions.
\ 9. TEXT buffer is CREATEd and ALLOTed initially.
\ 
\ =============== kForth requires ===================
include ans-words
include strings
include ansi
include files	\ include filesw under Windows

: ptr   CREATE 1 CELLS ?ALLOT ! DOES> a@ ;
: BIN ;
\ ANS compliant defn of >NUMBER is now part of ans-words.4th (km 2003-3-9)

\ ============== end of kForth requires ============


\ Here begins the source code for LF:

1024 1024 * CONSTANT EDIT-BUF-SIZE
CREATE EDIT-BUF EDIT-BUF-SIZE ALLOT

( MARKER TASK )


: K*  ( n1 -- n2 )  1024 * ;


\ adjust constants as needed

\ filename delimiters
CHAR / CONSTANT PATH-DELIMITER 
CHAR : CONSTANT DRIVE-DELIMITER 

\ using ALLOCATE ?
FALSE CONSTANT ALLOCATING
128 CONSTANT DEFAULT-ALLOCATE  \ in K

\ beeps?
TRUE CONSTANT BEEPS

\ tab, linewidth
 5 CONSTANT TABWIDTH
12 CONSTANT TABS/LINE
TABWIDTH TABS/LINE * CONSTANT LINEWIDTH  \ multiple makes easy
 2 CONSTANT LEDGE           \ room for spaces beyond linewidth
LINEWIDTH LEDGE + CONSTANT PLANK

\ a cut or copy goes to memory if it fits,
\ otherwise to a file
2 K* CONSTANT POCKET-SIZE

\ left margin holds line number
\ the start of a page is shown to the right of the line
( 6) 0 CONSTANT LINE#-SPACE  \ 0 if not displaying
5 CONSTANT PAGE#-SPACE  \ 0 if not displaying

\ screen display
LINEWIDTH
   LINE#-SPACE +
   PAGE#-SPACE LEDGE MAX +
   CONSTANT MAX-X  \ # of columns
( 23)  ( 54) 40  CONSTANT MAX-Y                 \ # of rows
MAX-X 16 - CONSTANT MAX-INPUT     \ reserves space for a prompt

\ screen/page
0 CONSTANT BANNER-LINE
2 CONSTANT TOP                             \ line 1 has a ruler
MAX-Y 1- CONSTANT STATUS-LINE       \ display status below text
STATUS-LINE TOP - 1- CONSTANT LMAX/SCREEN  \ text lines to show
TOP LMAX/SCREEN + 1- CONSTANT BOTTOM  \  last line to show text

\ displayable characters are implementation defined
126 CONSTANT LAST-DISPLAYABLE
\ this from Marcel Hendrix
\ TRUE PAD !  PAD C@  CONSTANT LAST-DISPLAYABLE

\ characters for displaying "invisibles"
CHAR _ CONSTANT .BL     \ BL
CHAR | CONSTANT .CR     \ CR
CHAR ^ CONSTANT .OTHER  \ e.g. LF !

\ keyboard entry

\ ASCII characters used in command mode
\ command mode provides all the functions
\ that LF implements

\ two of these start, one ends command mode
\ consider using ESCape once if it's available
\ Bruce R. McFarling recommends having a character for
\ starting and a different character for ending command mode
CHAR ` CONSTANT ^COMMAND

\ command keys
CHAR F CONSTANT ^Find-string
CHAR G CONSTANT ^find-aGain
CHAR R CONSTANT ^Replace
CHAR T CONSTANT ^replace-Too

CHAR " CONSTANT ^(un)mark(1)
CHAR ' CONSTANT ^(un)mark(2)

CHAR C CONSTANT ^Copy
CHAR D CONSTANT ^Delete
CHAR E CONSTANT ^Embed
CHAR W CONSTANT ^Wedge

CHAR V CONSTANT ^inVest

CHAR Q CONSTANT ^Query
CHAR A CONSTANT ^Alter-input
CHAR Z CONSTANT ^Show

CHAR X CONSTANT ^change-name

CHAR S CONSTANT ^Save

CHAR B CONSTANT ^good-Bye

\ next 6 aren't shown in the help screen
\ I don't expect them to be used but they would
\ eliminate the environmental dependency on the use of
\ control codes (if you silence BEEP) 
CHAR | CONSTANT -Enter-key(1)
CHAR \ CONSTANT -Enter-key(2)
CHAR _ CONSTANT -Backspace-key(1)
CHAR - CONSTANT -Backspace-key(2)
CHAR @ CONSTANT -Tab-key(1)
CHAR 2 CONSTANT -Tab-key(2)

\ cursor keys
CHAR L CONSTANT ^right
CHAR J CONSTANT ^left
CHAR I CONSTANT ^up
CHAR K CONSTANT ^down(1)
CHAR < CONSTANT ^down(2)
CHAR , CONSTANT ^down(3)
CHAR H CONSTANT ^1st-col
CHAR : CONSTANT ^last-col(1)
CHAR ; CONSTANT ^last-col(2)
CHAR O CONSTANT ^page-up
CHAR > CONSTANT ^page-down(1)
CHAR . CONSTANT ^page-down(2)
CHAR U CONSTANT ^BOF
CHAR M CONSTANT ^EOF
CHAR P CONSTANT ^TOP
CHAR ? CONSTANT ^BOP(1)
CHAR / CONSTANT ^BOP(2)

\ ASCII control characters
\ use of control characters is an environmental dependency
 7 CONSTANT BEL    \ bell
\ 8 CONSTANT BS     \ backspace
127 CONSTANT BS    \ backspace on Linux/KDE system
 9 CONSTANT HT     \ horizontal tab
\ 10 CONSTANT LF   \ LF doesn't know LF
\ 12 CONSTANT FF   \ formfeed for printing
\ 13 CONSTANT 'CR    \ Enter (also marks end of a paragraph)
10 CONSTANT 'CR    \ use LF for EOL on Unix systems

\ in-key 
\ would be nice to have DEFER and IS
0 ptr (IN-KEY)  \ changed from VALUE to ptr -- km 8-11-02
: IN-KEY  ( -- u flag )  (IN-KEY) EXECUTE ;

\ Jonah Thomas:
\ Here is something that should work on standard systems:
\
\ : NO-GOOD ." bad DEFERed word" ABORT ;
\ : DEFER
\    CREATE ['] NO-GOOD ,
\    DOES> @ EXECUTE ;
\
\ : (IS)  ( xt -- )
\    ' >BODY ! ;
\ : [IS]  ( -- )
\    ' >BODY POSTPONE LITERAL POSTPONE ! ; IMMEDIATE
\ : IS  ( S: xt -- ) ( C: -- )
\    STATE @ IF POSTPONE [IS] ELSE (IS) THEN ; IMMEDIATE

\ KEY is a Core word
: KEY-CHAR  ( -- char true)  KEY TRUE ;

' KEY-CHAR TO (IN-KEY)

\ if your system supports it, and you want to, add
\ more keys (such as actual cursor keys) and use
\ EKEY instead of KEY :
\ : EVENT  ( -- u flag )  EKEY EKEY>CHAR ;
\
\ ' EVENT TO (IN-KEY)


\ PAD space
84 CONSTANT PAD-SPACE     \ region guaranteed by PAD

\ search pad
\ LF uses PAD
PAD-SPACE CONSTANT GULP   \ #characters in search space
: SEARCH-PAD  ( -- )  PAD ;

\ constants for printing +

50 CONSTANT LINES/PAGE  \ printed page
\ 11 CONSTANT PMARGIN   \ left margin for printing


\ tools
\ some of these may already exist in your ANS Forth

\ do nothing
: NOP ;

\ number of cells/characters in n1 address units
1 CELLS CONSTANT /CELL
1 CHARS CONSTANT /CHAR

\ stack manipulation
\ : -ROT  ( x1 x2 x3 -- x3 x1 x2 )  ROT ROT ;

\ unsigned max and min
: UMAX  ( u1 u2 -- u1|u2 )  2DUP U< IF  NIP  ELSE  DROP  THEN ;
: UMIN  ( u1 u2 -- u1|u2 )  2DUP U< IF  DROP  ELSE  NIP  THEN ;

\ increment/decrement variable
: INCR  ( a -- )  1 SWAP +! ;
: DECR  ( a -- )  -1 SWAP +! ;

\ add stack items
: UNDER+  ( n1 n2 n3 -- n1+n3 n2 )  ROT + SWAP ;

\ unsigned division
: U/MOD  ( u1 u2 -- r q)  >R  1 UM*  R> UM/MOD ;
: U/  ( u1 u2 -- q )  U/MOD  NIP ;

\ fences
: BETWEEN  ( n1 n2 n3 -- f)  1+ WITHIN ;
: CLAMP  ( n1 lo hi - n2)  ROT MIN MAX ;

\ warnings
' NOP ptr (BEEP)
: ?BEEP  ( -- )  (BEEP) EXECUTE ;
: BEEP  ( -- )  BEL EMIT ;
: DEEP  ( n)  DROP ?BEEP ;
: ?BEEPS  ( -- )
   BEEPS
   IF    ['] BEEP
   ELSE  ['] NOP
   THEN  TO (BEEP) ;
: WAIT  ( -- )  ." Press a key to continue."  IN-KEY 2DROP ;

\ string words

\ Is character between A and Z?
: UPPER?  ( c -- ? ) [CHAR] A - 26 U< ;

\ Is character between a and z?
: lower?  ( c -- ? ) [CHAR] a - 26 U< ;

\ make a character lower/upper case
: >lower  ( C -- c)  DUP UPPER? BL AND XOR ;
: >UPPER  ( c -- C)  DUP lower? BL AND XOR ;

\ make a string lower case
: lcase  ( a u -- )
   0 ?DO  DUP C@ >lower  OVER  C! CHAR+  LOOP  DROP ;

\ string less the number of trailing characters <> c

: -TRAILING<>  \ a u1 c -- a u2 
   >R
   BEGIN  DUP
     IF  1-  2DUP CHARS +  C@ R@ = ELSE 1- TRUE THEN
   UNTIL  1+
   R> DROP ;


\ string after last character = c
: TRAILING<>  ( a1 u1 c -- a2 u2 )
   OVER >R  -TRAILING<>
   R> SWAP  /STRING ;

\ leading characters = c
: LEADING=  ( a u1 c -- a u2 )
   >R  2DUP
       BEGIN  OVER  C@ R@ =  OVER AND
       WHILE  1 /STRING
       REPEAT
   R> DROP 
   NIP - ;

\ string less leading characters <> c
: -LEADING<>  ( a1 u1 c -- a2 u2 )
   >R  BEGIN  OVER  C@ R@ <>  OVER AND
       WHILE  1 /STRING
       REPEAT
   R> DROP ;

\ string arithmetic
: C+!  ( n a -- )  DUP C@ UNDER+ C! ;
: S+!  ( a u s -- )
   2DUP 2>R
   COUNT CHARS +  SWAP CMOVE
   2R> C+! ;

\ move a counted string
: SMOVE  ( s1 s2 -- )  OVER C@ 1+ CMOVE ;

\ vectored execution +
VARIABLE way#
: CALL-WAY  ( a n -- ? )  CELLS + a@ EXECUTE ;
: WAYS
   CREATE  ( n -- )  DUP CELLS ?allot SWAP 
   0 DO  DUP ' SWAP !  /CELL + LOOP DROP
   DOES>  way# @  CALL-WAY ;

\ at most one file is open at a time
\ some error recovery could be introduced here
0 VALUE FILE-ID

\ create a file for writing
: CREATE-WRITE  ( a u -- )
   W/O BIN CREATE-FILE
   ABORT" CREATE-FILE problem" TO FILE-ID ;

\ open a file for reading only
: OPEN-READ  ( a u - fileid flag )
   R/O BIN OPEN-FILE ;

\ close an opened file
: FCLOSE  ( -- )
   FILE-ID CLOSE-FILE
   ABORT" CLOSE-FILE problem" ;

\ write u characters starting at a , then close the file
: BUF>FILE  ( a u -- )
   FILE-ID WRITE-FILE
   0< ABORT" WRITE-FILE problem"
   FCLOSE ;

\ read u chars to a , then close the file
: FILE>BUF  ( a u -- )  FILE-ID  READ-FILE
   ABORT" READ-FILE problem"  DROP
   FCLOSE ;


\ data structures +
\ chars and lines
\ actual values determined later
0 ptr TEXT     \ start of text area
0 VALUE CMAX   \ max # of characters
0 ptr LINES    \ start of lines data
0 VALUE LMAX   \ max # of lines

CREATE POCKET  POCKET-SIZE CHARS ALLOT       \ cut/copy buffer
CREATE FILENAME$  MAX-INPUT 6 + CHARS ALLOT  \ filename string

CREATE CURSOR>  2 CELLS ?ALLOT 0 0 ROT 2! ( 0 , 0 ,)  \ cursor position


\ document
VARIABLE doc-size   \ size of document
VARIABLE last-line  \ last line of document
VARIABLE last-old   \ previous last line
VARIABLE char-now   \ current character #
VARIABLE topline    \ current top screen line
VARIABLE top-old    \ previous top screen line
VARIABLE line-now   \ current line
VARIABLE line-old   \ previous current line
VARIABLE col#       \ current column

\ before the last character?
: -DOC-END  ( -- f)  char-now @ doc-size @ U< ;

\ room to add u characters?
: ROOM?  ( u -- f)  doc-size @ + CMAX 1+ U< ;


\ lines

\ address of nth element of line array
: LINE  ( l# - a)  CELLS LINES + ;

\ starting character # and length of a line
: LINESPEC  ( l# - c# u)  LINE 2@ TUCK - ;

\ number of characters in a line
: LINELENGTH  ( l# - u)  LINESPEC NIP ;

\ zero line data between line#1 and line#2
: 0LINES  ( l#1 l#2)
   OVER - 1+ 0 MAX  >R  LINE  R>  CELLS ERASE ;

\ zero all line information
: 0>LMAX  ( -- )   0 LMAX  0LINES ;

\ add u to lines between current line and last line
: LINES+!  ( u -- )
   line-now @ 1+ DUP  LINE SWAP
   last-line @  SWAP -  1+  0 MAX
   0 ?DO  2DUP +!  CELL+ LOOP  2DROP ;

\ move lines data starting with l# forward one cell
: LINES>  ( l# -- )
   DUP LINE  DUP CELL+
   ROT last-line @ 1+  DUP last-line !
   SWAP - CELLS 0 MAX MOVE ;

\ move lines data starting with l#+1 back one cell
: <LINES  ( l# -- )
   1+ DUP LINE  DUP CELL+  SWAP
   ROT last-line @ SWAP - CELLS 0 MAX MOVE
   last-line DECR ;

\ starting from a line, find the line a character is in
: C>L  ( c# l#1 -- l#2 )
   OVER doc-size @ U< 0=
   IF  2DROP last-line @
   ELSE  OVER
      IF  1- LINE
          BEGIN  CELL+ 2DUP @  U< UNTIL
          NIP  LINES -  /CELL / 1-
      ELSE  DROP
      THEN
   THEN ;

\ find screen row of line
: >Y  ( l# -- row#)  topline @ - TOP + ;

\ find bottom line of screen
: BOTTOMLINE  ( -- u )  topline @ LMAX/SCREEN + 1- ;


\ allocate / allot memory

\ allocate memory
0 VALUE ALLOCATED

\ GET-NUMBER from Woehr, Forth: the New Model
: GET-NUMBER  ( -- ud f )
   0 0
   PAD 84 BLANK
   PAD 84 ACCEPT
   PAD SWAP -TRAILING
   >NUMBER NIP 0= ;

\ get a number
: GET-INTEGER  ( -- u )
   GET-NUMBER DROP D>S ;

( =============================================================

\ release previously allocated memory
: ?DE-ALLOCATE  \ -- 
  ALLOCATED
   IF  LINES FREE  ABORT" FREE problem"  0 TO ALLOCATED  THEN ;

\ allocate memory from user input

: DO-ALLOCATE  \ -- 
   PAGE  10 10 AT-XY
   ." Reserve space for how many characters [K]:"
   GET-INTEGER
   ?DUP 0= IF  DEFAULT-ALLOCATE  THEN
   K* DUP LINEWIDTH 2/ U/ 1+
      2DUP CELLS  DUP
      ROT CHARS +
      DUP ALLOCATE
      ABORT" ALLOCATE problem.  Not enough memory?"
      DUP TO LINES
      ROT + TO TEXT
      TO ALLOCATED
      1- TO LMAX
      TO CMAX ;

\ allot memory
: DO-ALLOT
   CMAX 0=                            
   IF  UNUSED                          
       4 K* CELLS -         \ breathing room - could be less?
       LINEWIDTH 2/ CHARS  /CELL +  U/
       DUP 1- TO LMAX
       DUP HERE TO LINES  CELLS ALLOT     \ allot cells first
       LINEWIDTH 2/ *
       DUP TO CMAX  HERE TO TEXT  CHARS ALLOT
   THEN ;
=========================================================== )

: ?DE-ALLOCATE ;
: DO-ALLOCATE ;

: DO-ALLOT
   CMAX 0=                            
   IF  EDIT-BUF-SIZE                          
       4 K* CELLS -         \ breathing room - could be less?
       LINEWIDTH 2/ CHARS  /CELL +  U/
       DUP 1- TO LMAX
       EDIT-BUF TO LINES     \ allot cells first
       DUP EDIT-BUF + TO TEXT 
       LINEWIDTH 2/ *
       TO CMAX
   THEN ;

\ character<-->memory
: SPOT  ( -- a )  TEXT  char-now @ CHARS + ;
: T>MEM  ( c# u -- a u )  >R  CHARS TEXT +  R> ;


\ screen display

\ blank a screen line
: RUB  ( row -- )
   0 SWAP
   2DUP AT-XY  MAX-X LEDGE + SPACES  AT-XY ;

\ display a tab section in a ruler line
: .TAB  ( -- )
   TABWIDTH 1- 0 MAX 0 ?DO [CHAR] - EMIT  LOOP
   [CHAR] | EMIT ;

\ display a ruler line
: .RULER ( row -- )
   0 SWAP AT-XY
   LINE#-SPACE IF  ."  Line "  THEN
   [CHAR] | EMIT  LINEWIDTH TABWIDTH / 0 ?DO  .TAB LOOP
   PAGE#-SPACE IF  ." Page"  THEN ;

\ display top and bottom rulers
: .RULERS  ( -- )
   TOP 1-  DUP RUB .RULER
   BOTTOM 1+ DUP RUB .RULER ;

\ display current way of input
: .INSERT  ( -- )     ." INSERT       " ;
: .OVERWRITE  ( -- )  ." OVERWRITE    " ;
: .MARKING  ( -- )    ." MARKING      " ;

' NOP ptr (.WAY)
: .WAY  ( -- )  (.WAY) EXECUTE ;

FALSE VALUE COMMANDING  \ false = text entry mode

\ delete path from filename
: -PATH  ( a1 u1 -- a2 u2 )
   PATH-DELIMITER TRAILING<>  DRIVE-DELIMITER TRAILING<> ;

\ display filename
: .FILENAME  ( -- )
   FILENAME$ COUNT -PATH TYPE  SPACE ;

\ display filename, way, mode
: .HEADLINE  ( a u -- )
   BANNER-LINE RUB
   .FILENAME .WAY  2 SPACES
   TYPE  2 SPACES ;

\ headline when entering text
: .TEXT-ENTRY  ( -- )
   S" TEXT ENTRY" .HEADLINE
   ^COMMAND DUP EMIT EMIT SPACE ^Query EMIT SPACE
   ." for help" ;

\ headline when commanding
: .COMMANDING  ( -- )
   S" COMMANDING" .HEADLINE
   ^Query EMIT SPACE ." to query help" ;

\ display the headline
: BANNER  ( -- )
   COMMANDING
   IF  .COMMANDING  ELSE  .TEXT-ENTRY  THEN ;

\ display screen before displaying the document
: .SCREEN  ( -- )
   PAGE
   BANNER .RULERS  LINE#-SPACE TOP AT-XY ;


\ document display
BL VALUE "bl"     \ to EMIT  BL
BL VALUE "cr"     \ to EMIT 'CR
BL VALUE "other"  \ to EMIT other "invisible" character

\ 32 displays as "bl" , 13 displays as "cr"
: "INVISIBLE"  ( c1 -- c2 )
   CASE
      BL OF "bl"  ENDOF
     'CR OF "cr"  ENDOF
            "other"
      SWAP
   ENDCASE ;
: ?DISPLAY  ( c1 -- c2)
   DUP BL 1+ <
   IF  "INVISIBLE"  THEN ;

\ toggle visible and invisible "bl" AND "cr"
: ~DISPLAY  ( -- )
   "cr" BL <>
   IF     BL TO "bl"   BL TO "cr"      BL TO "other"
   ELSE  .BL TO "bl"  .CR TO "cr"  .OTHER TO "other"
   THEN
   -1 top-old ! ;

\ "highlighting"
' NOP ptr (?MARK)
: ?MARK  ( c1 -- c2 )  (?MARK) EXECUTE ;

\ erasers
\ keep current line in screen within n lines of top
: AIM  ( c# n -- )
   >R  0 C>L  DUP line-now !
   R>  -  0 MAX  topline ! ;

\ erase to end of line
: EraseEOL  ( col -- )
   PLANK SWAP -  SPACES ;

\ erase to end of text area
: EraseEOS  ( -- )
   BOTTOM last-line @ >Y -  0 MAX
   0 ?DO  MAX-X SPACES  CR  LOOP ;

\ display text line
: LTYPE  ( c# u -- )
   TUCK T>MEM
   0 ?DO  COUNT  ?DISPLAY  ?MARK  EMIT  LOOP  DROP
   EraseEOL ;

\ much faster ltype by Marcel Hendrix:
\ LINEWIDTH LEDGE + CONSTANT C/L
\ 0 VALUE cnt
\ CREATE lbuff  128 CHARS ALLOT
\ : LTYPE  ( c# u -- )
\    0 TO cnt
\    TUCK T>MEM
\    0 ?DO
\        COUNT  ?DISPLAY  ?MARK
\        lbuff cnt + C!  1 +TO cnt ( or: cnt 1+ TO cnt )
\    LOOP  DROP ( u)
\    lbuff cnt C/L 1- MIN TYPE
\    ( u) EraseEOL ;

\ line and page numbers
' NOP ptr (.LINE#)
' NOP ptr (.PAGE#)
: ?LINE#  ( -- )  (.LINE#) EXECUTE ;
: ?PAGE#  ( -- )  (.PAGE#) EXECUTE ;

\ display line number
: <.LINE#>  ( l# -- l#)  DUP  1+ 5 U.R SPACE ;

\ calculate page number
: PAGE-LINE  ( l# -- p# n )  LINES/PAGE /MOD  1+ SWAP ;

\ if first line of a page, display the page number
: <.PAGE#>  ( l# -- l# )
   DUP PAGE-LINE
   IF  DROP 3 SPACES  ELSE  3 U.R  THEN ;

\ display line and page numbers?
: ?MARGIN  ( -- )
   LINE#-SPACE IF  ['] <.LINE#> TO (.LINE#)  THEN
   PAGE#-SPACE IF  ['] <.PAGE#> TO (.PAGE#)  THEN ;

\ display line#, line, page#
: .TLINE  ( l# l# -- l# )
   ?LINE#
   LINESPEC LTYPE
   ?PAGE#
   CR ;

\ which lines to display
VARIABLE .start   \ first
VARIABLE .end     \ last
VARIABLE .mend    \ override .end

\ display some lines of text
: .TLINES  ( -- )
   .start @  topline @ MAX  0 OVER >Y AT-XY
   .end @ .mend @ MAX  last-line @ MIN  BOTTOMLINE MIN
   OVER -  1+
   0 ?DO  DUP .TLINE  1+  LOOP  DROP
   top-old @ topline @ U<  last-line @ last-old @ U<  OR 
   last-line @ BOTTOMLINE U<  AND
   IF  0 last-line @ topline @ -  1+ TOP + AT-XY
       EraseEOS
   THEN ;


\ formatting
FALSE VALUE FORMAT-ALL  \ true = format the entire document
FALSE VALUE SAME        \ true if line data hasn't changed
VARIABLE line#          \ line being formatted

\ 'CR a special case
: CReturn  ( a -- )
   line# @ TUCK  1+ LINE @  2DUP <>
   IF  U< IF  LINES>  ELSE  <LINES  THEN  last-line @ .mend !  
   ELSE  2DROP DROP  THEN  ;

\ formatting old ground?
: ?SAME  ( c# 'line -- )
   FORMAT-ALL
   IF  2DROP
   ELSE  @ =
      IF  line# @  line-now @  OVER U<
          OVER LINELENGTH LINEWIDTH U<  AND AND ?DUP
          IF 1- .end !  TRUE TO SAME  THEN 
      THEN
   THEN ;

\ store a character position in the next line
: LINE!  ( c# -- )  line# DUP INCR @ LINE  2DUP ?SAME ! ;

\ word wrap
\ lines are wrapped by priority:
\ 1. first CR up to LINEWIDTH+1
\ 2. last BL up to LINEWIDTH+1, allowing
\    for LEDGE BLs beyond LINEWIDTH
\ 3. at LINEWIDTH
LINEWIDTH 1+ CONSTANT LINEWIDTH+
: WRAP  ( c#1 a u -- c#2 )
   2DUP LINEWIDTH+ MIN                  \ allow 1+ column for CR
   'CR -LEADING<>                       \ look for first CR
   IF  NIP SWAP - 1+ +  
       DUP CReturn  DUP LINE!           \ end of paragraph
   ELSE  DROP DUP LINEWIDTH >           \ else need to wrap?
       IF  OVER LINEWIDTH+              \ allow 1+ column for BL 
           BL -TRAILING<>  ?DUP         \ break on last BL
           IF  DUP LINEWIDTH+ =         \ at extra column?
               IF  2SWAP                \ ( c# a u2 a u1 )
                   LINEWIDTH+ /STRING   \ rest of LEDGE
                   BL LEADING=  NIP +   \ add its leading BLs
               ELSE  2SWAP 2DROP        \ else dump plank
               THEN  NIP                \ ( c# u )
           ELSE  DROP 2DROP  LINEWIDTH  \ no BLs
           THEN  +  DUP LINE!           \ ( c# )
       ELSE  NIP +                      \ no need to wrap
       THEN
   THEN ;

\ clean-up after formatting
: DEJA?  ( -- )
   SAME
   IF  last-line DUP @ line# @ 1- MAX SWAP !
       doc-size @ last-line @ 1+ LINE !
   ELSE  last-line @ 1+ line# @  DUP last-line !  DUP .end !
       1+ doc-size @ OVER LINE !  1+ SWAP 0LINES
   THEN ;

\ the f word
: FORMAT  ( -- )
   FALSE TO SAME  line-now @ 1- 0 MAX  DUP line# !  
   LINE @
   BEGIN  DUP DUP PLANK +  doc-size @ UMIN
      OVER - T>MEM WRAP
      DUP doc-size @ = SAME OR
   UNTIL  DROP  DEJA? ;


\ moving around in the document

\ cursor right
: RIGHT  ( -- )
   -DOC-END
   IF  char-now INCR  ELSE  ?BEEP  THEN ;

\ cursor left
: LEFT  ( -- )
   char-now @
   IF  char-now DECR  ELSE  ?BEEP  THEN ;

\ calculate the column of the current character
: CPLACE  ( -- col# )  char-now @  line-now @ LINE @  - ;

\ calculate where to place the cursor in a line
: >char-now  ( cplace l# -- )
   LINESPEC  ROT 2DUP U<
   IF  DROP  1-  0 MAX  ELSE  NIP  THEN  + char-now ! ;

\ cursor up
: UP  ( -- )
   line-now @
   IF  CPLACE line-now DUP DECR @ >char-now
   ELSE  ?BEEP  THEN ;

\ cursor down
: DOWN  ( -- )
   line-now @ last-line @ U<
   IF  CPLACE line-now DUP INCR @ >char-now
   ELSE  ?BEEP  THEN  ;


\ text pushes and pulls

\ number of characters to the end of the document
: #>END  ( a -- u )  TEXT -  /CHAR U/  doc-size @ SWAP - ;

\ suture text separated by u chars
: JOIN  ( u -- )  CHARS  SPOT  DUP UNDER+  OVER #>END  CMOVE ;

\ prepare to delete u characters
: <#SLIDE  ( u -- )
   doc-size @
   IF  DUP JOIN  NEGATE doc-size +!  ELSE  DEEP  THEN ;

\ prepare to delete character
: <SLIDE  ( -- )  1 <#SLIDE  -1 LINES+!  ;

\ make room for u characters
: SPLIT  ( u -- )  CHARS  SPOT  TUCK +  OVER #>END  CMOVE> ;

\ prepare to insert u characters
: #SLIDE>  ( u -- )
   DUP ROOM?
   IF  DUP SPLIT  doc-size +!  ELSE  DEEP  THEN ;

\ prepare to insert character
: SLIDE>  ( -- )  1 #SLIDE>  1 LINES+! ;


\ text input

0 VALUE PREVIOUS-KEY  \ two keys need to enter command mode
0 VALUE VANQUISHED   \ text character overwritten by ^command character

\ put character into the document
: OVERWRITE  ( c -- )
   char-now @ CMAX U<  line-now @ LMAX U< AND
   IF  
       SPOT C@ -DOC-END AND
       PREVIOUS-KEY ^COMMAND <> AND TO VANQUISHED
       SPOT C! doc-size DUP @ char-now DUP INCR @ UMAX SWAP !
       FORMAT
   ELSE  DEEP  THEN ;

\ insert character into the document
: INSERT  ( c -- )
   1 ROOM?  last-line @ LMAX U< AND
   line-now @ LMAX 1- U< AND
   IF  -DOC-END IF  SLIDE>  THEN  OVERWRITE
   ELSE  DEEP  THEN ;

\ delete character
: DELETE  ( -- )
   -DOC-END
   IF  <SLIDE FORMAT  ELSE  ?BEEP  THEN ;

\ delete the previous character
: <DELETE  ( -- )
   char-now @
   IF  LEFT DELETE  ELSE  ?BEEP  THEN ;


\ Enter key

\ inserting:  put in a paragraph end
: PARAGRAPH  ( -- )
   last-line @ LMAX 1- U<
   IF  'CR INSERT  ELSE  ?BEEP  THEN ;

\ overwriting:  if not at document's end go to the next
\ line, else insert a paragraph end
: RETURN  ( -- )
   -DOC-END
   IF  line-now @ LINE @ char-now !  DOWN
   ELSE  way# @ 2 <> IF  PARAGRAPH  ELSE  ?BEEP  THEN THEN ;


\ Tab
CREATE TAB$  TABWIDTH DUP CHARS ?ALLOT SWAP BLANK

\ #cols to next tab mark
: NEXT-TAB  ( -- n )
   TABWIDTH  col# @ TABWIDTH MOD  - ;

\ tab while inserting
\ will sometimes fall short of the first tab mark but
\ but will go to it with the next tab
: NUDGE  ( -- )
   NEXT-TAB
   DUP ROOM? 
   IF  DUP >R #SLIDE>  TAB$ SPOT R@ CMOVE
       R>  DUP LINES+!  char-now +!  FORMAT
   ELSE  DEEP  THEN ;

\ tab while overwriting
: HOP  ( -- )
   -DOC-END
   IF  NEXT-TAB 
       char-now @ +  
       line-now @ 1+ LINE @ MIN
       doc-size @ 1+ UMIN  char-now !  
   ELSE  NUDGE  THEN ;


\ jumps

\ keep jumped to line within document
: CONFINE  ( l1 -- l2 )  0 last-line @ CLAMP ;

\ jump n lines
: JUMP  ( n -- )
   DUP topline @ + CONFINE topline !
   CPLACE SWAP line-now @ + CONFINE
   DUP line-now ! >char-now ;

\ jump down
: +JUMP  ( u -- )
   line-now @ last-line @ =
   IF  DEEP  ELSE  JUMP  THEN ;

\ jump up
: -JUMP  ( u -- )
   line-now @ 0=
   IF  DEEP  ELSE  NEGATE JUMP  THEN ;

\ jump to the beginning of the line
: <LEFT  ( -- )   line-now @ LINE @ char-now ! ;

\ jump to the end of the line
: RIGHT>  ( -- )
   line-now @
   DUP 1+ LINE @  1-
   SWAP last-line @ = 1 AND  +  char-now ! ;

\ jump up one screen
: PAGE-UP  ( -- )   LMAX/SCREEN -JUMP ;

\ jump down one screen
: PAGE-DOWN  ( -- )  LMAX/SCREEN +JUMP ;

\ jump to the start of the document
: >BOF  ( -- )   0 char-now !  0 line-now !  0 topline ! ;

\ jump to the end of the document
: >EOF  ( -- )
   doc-size @ char-now !
   last-line @ DUP line-now ! DUP .end !
   DUP topline @ LMAX/SCREEN + 1- >
   IF  6 - DUP .start !  topline !
   ELSE  DROP  THEN ;

\ jump to current top screen line
: >TOP  ( -- )
   topline @ line-now @ U<
   IF  CPLACE  topline @  DUP line-now !  >char-now
   ELSE  ?BEEP  THEN ;

\ jump to current bottom screen line
: >BOTTOM  ( -- )
   line-now @ DUP last-line @ U< SWAP BOTTOMLINE U< AND
   IF  CPLACE  last-line @ BOTTOMLINE MIN
       DUP line-now !  >char-now
   ELSE  ?BEEP  THEN ;


\ ~insert
\ toggle insert/overwrite
: ~INSERT  ( -- )  way# DUP @ 1 XOR SWAP !  BANNER ;


\ find/replace
CREATE S$  MAX-INPUT CHARS ALLOT  \ search string
CREATE R$  MAX-INPUT CHARS ALLOT  \ replace string
FALSE VALUE FOUND    \ has search string been found?
VARIABLE found-char  \ where?
VARIABLE slen        \ length of search string
VARIABLE spad>       \ offset in PAD of found string
VARIABLE rlen        \ length of replace string

\ does the string have an uppercase character?
: UC?  ( a u -- f )
   0 ?DO  COUNT UPPER? IF  DROP TRUE  UNLOOP EXIT  THEN
     LOOP DROP  FALSE ;

\ does the string have a lowercase character?
: lc?  ( a u -- f )
   0 ?DO  COUNT lower? IF  DROP TRUE  UNLOOP EXIT  THEN
     LOOP DROP  FALSE ;

\ does the string have both upper- and lower-case characters?
: MIXED?  ( a u -- f )  2DUP UC? >R  lc?  R> AND ;

' 2DROP ptr ?lcase  \ "deferred" ?lcase


\ make string lower case if NOT mixed
: ?MIXED  ( a u -- )
   2DUP MIXED?
   IF  ['] 2DROP  ELSE  ['] lcase  THEN  TO ?lcase 
   ?lcase EXECUTE ;

\ look for searched string in search pad
: LOOKING ( a u -- )
   2DUP ?lcase EXECUTE  S$ slen @ SEARCH
   NIP ?DUP IF  TO FOUND  SEARCH-PAD - spad> !
            ELSE  DROP  THEN ;

\ you can't go home again (i.e. you can go home once)
TRUE VALUE OK-TO-GO-HOME  \ ok to loop back to BOF?
VARIABLE snow             \ char# now at SEARCH-PAD 

\ move some text to the search pad
: T>SPAD  ( a u -- spad u )
   T>MEM  >R
   SEARCH-PAD R@ CMOVE
   SEARCH-PAD  R> ;

\ search text for a string, if it isn't found, 
\ continue to look from the beginning of the document
: SWEEP  ( -- )
   TRUE TO OK-TO-GO-HOME
   doc-size @ >R
   char-now @ 1+ DUP R@ 1+ slen @ - U< AND
   BEGIN  DUP snow !  DUP  DUP GULP +  R@ UMIN  DUP >R
      OVER - T>SPAD LOOKING
      R> R@ = OK-TO-GO-HOME AND
         IF  DROP 0  FALSE TO OK-TO-GO-HOME  
         ELSE  GULP slen @ 1- - +  THEN
      DUP char-now @ 1+ U<  OK-TO-GO-HOME  OR 0=  FOUND OR
   UNTIL R> 2DROP ;

\ if the string found identify the starting character
\ if necessary ensure that it can be displayed
: ?FOUND  ( -- )
   FOUND
   IF  snow @ spad> @ +
       DUP char-now !  DUP found-char !
       6 AIM
   ELSE  ?BEEP  THEN ;

\ the seek word
: SEEK  ( -- )
   FALSE TO FOUND
   slen @ ?DUP
   IF  doc-size @ 1+ U<
       IF  S$ slen @ ?MIXED SWEEP  THEN THEN
   ?FOUND ;

\ seek with prompt
\ empty string seeks the previous string
: SEEK?  ( -- )
   BANNER-LINE RUB  ." Find:"  S$ MAX-INPUT ACCEPT  ?DUP
   IF  slen !  THEN  SEEK  BANNER ;

\ was something found here?
: POINT?  ( -- f )  FOUND  char-now @ found-char @ = AND ;

\ adjust for difference between sought and replace lengths
: SLIDE  ( n -- )
   DUP 0<
   IF  NEGATE <#SLIDE  ELSE  #SLIDE>  THEN ;

\ replace
: PUT  ( -- )
   POINT?
   rlen @ DUP >R AND  R@ slen @ - TUCK  0 MAX ROOM? AND
   IF  ?DUP IF  DUP SLIDE LINES+!  THEN
       R$ SPOT R@ CMOVE  FORMAT
   ELSE  DEEP  THEN
   R> DROP  FALSE TO FOUND ;

\ replace with prompt
\ empty string subsitutes the previous string
: PUT?  ( -- )
   POINT?
   IF  BANNER-LINE RUB  ." Replace with:"  R$ MAX-INPUT ACCEPT
     ?DUP IF  rlen !  THEN  PUT  BANNER
   ELSE  ?BEEP  THEN ;


\ insert text from the command line
: STUFF  ( -- )
   BANNER-LINE RUB ." Wedge in:" PAD MAX-INPUT ACCEPT 
   DUP ?DUP ROOM? AND
   IF  DUP SLIDE  DUP LINES+!
       DUP PAD SPOT ROT CMOVE  FORMAT
       char-now +!  THEN  BANNER ;


\ marking a block
VARIABLE was      \ way# before marking
VARIABLE bstart   \ where marking originated
VARIABLE .bstart  \ beginning of marked text
VARIABLE .bend    \ end of marked text
VARIABLE blength  \ number of characters in the block
VARIABLE btop     \ top block line to display

\ keeping the block within the document, give the block's size
: BLOCK-IN  ( -- n )
   char-now
   DUP @ doc-size @ 1- UMIN TUCK SWAP ! ;

\ if marking, define marked area
: <BLOCK>  ( -- )
   BLOCK-IN bstart @
   2DUP UMIN .bstart !  UMAX .bend !
   line-old @ line-now @  2DUP MIN .start !  MAX .end !  ;

\ starting character and length of the block
: MARKED  ( -- c# u )
   .bstart @  .bend @  OVER -  1+ ;

\ start and end lines of the block
: <LL>  ( -- l1 l2 )  .bstart @ 0 C>L  .bend @ OVER C>L ;

\ would like a Standard way to highlight:  GLOW ?
: MARK ( a c -- a c )
   OVER 1- .bstart @ CHARS  TEXT +  .bend @ CHARS TEXT +  BETWEEN
   IF  >UPPER  THEN ;

' NOP ptr (?BLOCK)
: ?BLOCK  (?BLOCK) EXECUTE ;

\ start marking
: +MARK  ( -- )
   way#  DUP @ was !  2 SWAP !
   ['] MARK TO (?MARK)  ['] <BLOCK> TO (?BLOCK)
   BLOCK-IN  bstart !  topline @ btop !
   -1 top-old !  BANNER ;

\ leave marking
: -MARK  ( -- )
   <LL> .end !  .start !  was @ way# !
   ['] NOP  DUP TO (?MARK)  TO (?BLOCK)  BANNER ;

\ copy, cut, embed

\ fits into allotted space?
: SMALL?  ( u -- flag )  POCKET-SIZE 1+ U< ;

\ write larger block to a temporary file
: >PURSE  ( a u -- )
   S" temp.wnk" CREATE-WRITE BUF>FILE ;

\ copy marked
: APE  ( -- )
   MARKED  DUP blength !  T>MEM
   DUP SMALL?
     IF  POCKET  SWAP CMOVE
     ELSE  >PURSE  THEN
   -MARK ;

\ copy and delete
: CUT  ( -- )
   APE
   .bend @ .bstart @
   DUP 0 C>L  DUP .start !  line-now ! DUP char-now !
   - 1+ DUP <#SLIDE NEGATE LINES+!  FORMAT
   btop @ topline @ U<
   IF  btop @ topline !  THEN  
   last-line @ .end ! ;

\ read large cut block
: PURSE>  ( u -- )
   S" temp.wnk" OPEN-READ
   ABORT" OPEN-FILE problem" TO FILE-ID
   SPOT SWAP FILE>BUF ;

\ paste copied or cut block
: PASTE  ( -- )
   blength @ DUP DUP ROOM? AND
   <LL> SWAP - last-line @ + LMAX U< AND
   IF  DUP >R #SLIDE>
       R@ SMALL?
          IF  POCKET SPOT R@ CMOVE
          ELSE  R@ PURSE> THEN
       R@ LINES+!  FORMAT
       R> char-now +!
       char-now @  LMAX/SCREEN 2/ AIM
   ELSE  DEEP  THEN ;


\ print
\ some code to try if you can invoke printing
\ not tested with LF
\ VARIABLE spacing
\ VARIABLE pline
\ define >PRN and PRN> according to your system
\ : >PRN ... ;  \ enable printing
\ : PRN> ... ;  \ return from printing
\ : SPACED  ( u)  spacing ! ;
\ : CRs  ( n) 0 ?DO CR LOOP ;
\ : FF   12 EMIT ;
\ : .PAGE  ( n -- )  PMARGIN LINEWIDTH + SPACES 1+ . ;
\ : NEWPAGE  ( n -- )  FF  3 CRs  .PAGE  3 CRs ;
\ : ?NEWPAGE  ( -- )
\    pline @ ?DUP
\    IF  LINES/PAGE spacing @ /  /MOD SWAP 0=
\        IF  NEWPAGE  ELSE  DROP  THEN
\    ELSE  6 CRs  THEN ;
\ : TPRINT  ( a u -- )
\    T>MEM
\    0 ?DO  COUNT DUP 'CR > AND EMIT  LOOP
\    DROP ;
\ : <print>  ( start end -- )
\    >PRN
\    0 pline !  OVER - 1+  0
\    ?DO  ?NEWPAGE  PMARGIN SPACES
\          DUP LINESPEC TPRINT spacing @ CRs  pline INCR  1+
\    LOOP  DROP  FF
\    PRN> ;
\ : printing  ( n -- )  0 last-line @ <print> ;
\ : bprinting  ( n -- )  <LL> <print> ;
\ : (PRINT)  ( -- )  1 SPACED printing ;
\ : BPRINT  ( -- )  1 SPACED bprinting ;
\ : (2PRINT)  ( -- )  2 SPACED printing ;
\ : 2BPRINT  ( -- ) 2 SPACED bprinting ;


\ file i/o

\ request filename
\ a u1 is the prompt, u2 is the number of characters entered
: FILENAME  ( a u1  -- u2 )
   BANNER-LINE RUB TYPE
   PAD 1+ MAX-INPUT ACCEPT DUP PAD C! ;

\ number of chars to dot
: >DOT  ( s -- n )  COUNT [CHAR] . -TRAILING<> NIP ;

\ add extension?
: ?+WNK  ( s -- )
   DUP   >DOT 0=
   IF  S" .wnk"  ROT S+!  ELSE  DROP  THEN  ;

\ move name to filename
: PAD$>FILENAME$  ( -- )  PAD FILENAME$ SMOVE ;

\ file?
: GET-FILENAME  ( -- a u)
   S" Filename: "  FILENAME
   IF  PAD$>FILENAME$
   ELSE  ?DE-ALLOCATE  QUIT  THEN
   FILENAME$ ?+WNK  FILENAME$ COUNT  ;

\ save file
: FSAVE  ( s -- )
   COUNT CREATE-WRITE  TEXT doc-size @ BUF>FILE ;

\ save the document
: SAVE-DOC  ( -- )  FILENAME$ FSAVE ;

\ save a marked block
: SAVE-MARKED  ( -- )
   S" Save marked to:" FILENAME
   IF  PAD ?+WNK PAD COUNT CREATE-WRITE
       MARKED T>MEM BUF>FILE  
   THEN  BANNER ;

\ read in the document from a file
: READ-DOC  ( -- )
   FILE-ID
   FILE-SIZE ABORT" FILE-SIZE problem"
   OVER CMAX U< 0= OR
   ABORT" FILE TOO BIG"  doc-size !
   TEXT doc-size @ FILE>BUF ;

\ if there's a file read it, else create a file
: ?READ-DOC  ( a u -- )
   2DUP R/O BIN OPEN-FILE
   IF  DROP  CREATE-WRITE FCLOSE
   ELSE  TO FILE-ID 2DROP READ-DOC THEN ;

\ prompt for a filename, try to read the file
: GET-DOCUMENT  ( -- )  GET-FILENAME  ?READ-DOC ;

\ inVest file
: FROM>  ( -- )
   S" Read from:" FILENAME
   IF PAD ?+WNK PAD COUNT OPEN-READ
      IF  DROP BANNER-LINE RUB
          PAD COUNT TYPE 2 SPACES  ." ?? "  WAIT
      ELSE  TO FILE-ID   BANNER-LINE RUB
         FILE-ID FILE-SIZE ABORT" FILE-SIZE problem"
         OVER ROOM? 0= OR
            IF ." NOT ENOUGH ROOM " DROP WAIT
            ELSE  DUP #SLIDE>  SPOT OVER FILE>BUF
                  TRUE TO FORMAT-ALL  FORMAT  FALSE TO FORMAT-ALL
                  char-now +!
                  char-now @  LMAX/SCREEN 2/ AIM
            THEN
      THEN
   THEN  BANNER ;

\ do a backup
: BACKUP  ( -- )
   PAD PAD-SPACE BLANK
   FILENAME$ PAD SMOVE  PAD >DOT ?DUP
   IF  1- PAD C!  THEN  S" .bak" PAD S+!  PAD FSAVE ;

\ if the file has some data, back it up
: ?BACKUP  ( -- )  doc-size @ IF  BACKUP  THEN ;

\ change filename 
: ~NAME  ( -- )
   S" Change filename to:" FILENAME
   IF  PAD$>FILENAME$  FILENAME$ ?+WNK  FILENAME$ FSAVE  THEN
   BANNER ;


\ scrolling

\ scroll up one line
: SCRUP  ( -- )  topline DUP INCR @ .start !  last-line @ .end ! ;

\ scroll down one line
: SCROWN  ( -- )  topline DUP DECR @ .start !  last-line @ .end ! ;

\ do I need to scroll?
: SCROLL?  ( row#1 -- row#2 )
   DUP BOTTOM > IF  SCRUP DROP BOTTOM topline @ top-old !  ELSE
   DUP   TOP  < IF  SCROWN  1+  topline @ top-old !  THEN THEN ;

\ where to put the cursor
: CURSOR!  ( -- )
   char-now @
   DUP line-now @ 1- 0 MAX C>L  DUP line-now !
   DUP >Y SCROLL?  -ROT LINE @ -  DUP col# !  LINE#-SPACE +
   SWAP CURSOR> 2! ;

\ should I redisplay the entire text area?
: ?FRAME  ( -- )
   topline @ top-old @ <>
   IF  topline @ .start !  last-line @ .end !  THEN ;


\ .status

\ display of and the statistic
: .OF  ( n -- )  [CHAR] / EMIT U. ;

\ display max
: .MAX  ( n -- )
   [CHAR] m EMIT U. SPACE ;

\ display status line
: .STATUS  ( -- )
   STATUS-LINE RUB
   [CHAR] C EMIT SPACE  char-now @ 1+ U.  doc-size @ 1+ .OF  CMAX .MAX
   last-line @ line-now @
   PAGE#-SPACE IF 2DUP THEN
   [CHAR] L EMIT SPACE 1+ U.  1+ .OF  LMAX .MAX
   PAGE#-SPACE
   IF  [CHAR] P EMIT SPACE  PAGE-LINE DROP U.
       PAGE-LINE DROP .OF  THEN
   ." Col "  col# @ 1+ U.
   ;


\ .result 
: .RESULT  ( -- )
   CURSOR!  ?FRAME  .TLINES .STATUS
   CURSOR> 2@  AT-XY ;


\ begin and end

\ virgin mother
\ reserve memory for text and lines data
: MOTHER  ( -- )
   ALLOCATING
   IF  DO-ALLOCATE  ELSE  DO-ALLOT  THEN              
   0>LMAX ;

: VIRGIN  ( -- )
   MOTHER
   0 doc-size !   0 last-line !
   0 char-now !   0 line-now !
   0 topline !    0 way# !
   BL TO "bl"     BL TO "cr"     BL TO "other"
   FALSE TO FOUND
   ['] NOP  DUP TO (?MARK)  TO (?BLOCK) ;

\ yes, I wrote most of this
: (c)  ( -- )
   PAGE 13 12 AT-XY ." LF v1.0  "
   ." Copyright 1997 Leo Wong.  All rights reserved." ;

\ our story begins
: START  ( -- )
   VIRGIN
   ?BEEPS  (c)
   ?MARGIN  GET-DOCUMENT  .SCREEN  FORMAT  .RESULT
   ?BACKUP ;

\ finish
FALSE VALUE DONE  \ true if leaving LF

\ offer to save before leaving
: FINISH  ( -- )
   BANNER-LINE RUB ." Save " .FILENAME ." (Y/n)?"  IN-KEY
   AND BL OR [CHAR] n <> IF  SAVE-DOC  THEN  TRUE TO DONE ;


\ help - designed for 25 lines

\ leave help
: BACK-TO-TEXT  ( -- )
   .SCREEN  topline @ .start !  last-line @ .end !
   .RESULT  BANNER ;

\ show help
: HELP  ( -- )
   PAGE
   4  0 AT-XY  ." when in TEXT ENTRY:"
   0  1 AT-XY  ^COMMAND DUP EMIT EMIT ."  enter COMMANDs"

   4  3 AT-XY  ." when COMMANDing:"
   0  4 AT-XY  ^COMMAND      EMIT  ."  return to TEXT ENTRY"

   0  6 AT-XY  ^Find-string  EMIT  ."  Find"
   0  7 AT-XY  ^find-aGain   EMIT  ."  find aGain"
   0  8 AT-XY  ^Replace      EMIT  ."  Replace"
   0  9 AT-XY  ^replace-Too  EMIT  ."  replace Too"

   0 11 AT-XY  ^(un)mark(1)  EMIT  ."  mark<->unmark"
   0 12 AT-XY  ^Copy         EMIT  ."  Copy marked"
   0 13 AT-XY  ^Delete       EMIT  ."  Delete char / cut marked"
   0 14 AT-XY  ^Embed        EMIT  ."  Embed (paste) copied/cut"

   0 16 AT-XY  ^inVest       EMIT  ."  inVest (insert) a file"
   0 17 AT-XY  ^Wedge        EMIT  ."  Wedge in text"

   0 19 AT-XY  ^Alter-input  EMIT  ."  insert<->overwrite"
   0 20 AT-XY  ^Show         EMIT  ."  show<->hide spaces/CRs"

   0 22 AT-XY  ^change-name  EMIT  ."  change filename"

  38  0 AT-XY  ." when COMMANDing:"

  34  2 AT-XY  ." cursor moves:"

  34  4 AT-XY  ^right        EMIT  ."  right"
  34  5 AT-XY  ^left         EMIT  ."  left"
  34  6 AT-XY  ^up           EMIT  ."  up"
  34  7 AT-XY  ^down(1)      EMIT  ."  or "
               ^down(2)      EMIT  ."  down"

  34  9 AT-XY  ^1st-col      EMIT  ."  first column"
  34 10 AT-XY  ^last-col(1)  EMIT  ."  last column"

  34 12 AT-XY  ^page-up      EMIT  ."  page up"
  34 13 AT-XY  ^page-down(1) EMIT  ."  page down"

  34 15 AT-XY  ^TOP          EMIT  ."  top of page"
  34 16 AT-XY  ^BOP(1)       EMIT  ."  bottom of page"

  34 18 AT-XY  ^BOF          EMIT  ."  beginning of document"
  34 19 AT-XY  ^EOF          EMIT  ."  end of document"

  34 21 AT-XY  ^Save         EMIT  ."  Save document"

  34 22 AT-XY  ^good-Bye     EMIT  ."  Bye to LF"

  14 24 AT-XY  ." Press a key to leave this screen"

  IN-KEY 2DROP  BACK-TO-TEXT ;


\ most commands depend on whether you're inserting,
\ overwriting, or marking text
\                    Insert      Overwrite    Marking
3 WAYS <.WAY>       .INSERT     .OVERWRITE   .MARKING
3 WAYS CHARACTER     INSERT      OVERWRITE    DEEP
3 WAYS ENTER         PARAGRAPH   RETURN       RETURN
3 WAYS BACKSPACE    <DELETE     <DELETE      ?BEEP
3 WAYS TABITHA       NUDGE       HOP         ?BEEP
3 WAYS FIND-1ST      SEEK?       SEEK?       ?BEEP
3 WAYS FIND-AGAIN    SEEK        SEEK        ?BEEP
3 WAYS REPLACE       PUT?        PUT?        ?BEEP
3 WAYS REPLACE-TOO   PUT         PUT         ?BEEP
3 WAYS ~MARK        +MARK       +MARK        -MARK
3 WAYS COPY         ?BEEP       ?BEEP         APE
3 WAYS EMBED         PASTE       PASTE       ?BEEP
3 WAYS DELE          DELETE      DELETE       CUT
3 WAYS WEDGE         STUFF       STUFF       ?BEEP
3 WAYS QUERY-HELP    HELP        HELP         HELP
3 WAYS ~INPUT       ~INSERT     ~INSERT      ?BEEP
3 WAYS ~SHOW        ~DISPLAY    ~DISPLAY     ~DISPLAY
3 WAYS SAVING        SAVE-DOC    SAVE-DOC     SAVE-MARKED
3 WAYS INVEST        FROM>       FROM>       ?BEEP
\ 3 WAYS PRINT       (PRINT)     (PRINT)      BPRINT
\ 3 WAYS 2PRINT      (2PRINT)    (2PRINT)     2BPRINT

\ there had to be a (.WAY)
' <.WAY> TO (.WAY)


\ control keys
\ control-key handler
: CONTROL-KEY?  ( u -- )
   CASE
     'CR  OF  ENTER      ENDOF
      BS  OF  BACKSPACE  ENDOF
      HT  OF  TABITHA    ENDOF
              ?BEEP
   ENDCASE ;


\ command mode

\ toggle text-entry and command modes
: ~COMMANDING  ( -- )
   COMMANDING 0= DUP TO COMMANDING
   IF  BACKSPACE
       way# @ 1 =  VANQUISHED AND  ?DUP IF  INSERT  LEFT  THEN
   ELSE  way# @ 2 = IF  -MARK  THEN THEN  
   BANNER .RESULT ;

\ am I commanding?
: COMMAND-MODE?  ( c -- f )
   ^COMMAND =  ^COMMAND PREVIOUS-KEY = AND COMMANDING OR ;

\ so that the space bar can be used in command mode
: SPACE-BAR  ( -- )  BL CHARACTER ;

\ command-mode key handler
: COMMAND-MODE ( c1 -- c2 )
   >UPPER
   CASE

     \ cursor keys
       ^left              OF  LEFT          ENDOF
       ^right             OF  RIGHT         ENDOF
       ^up                OF  UP            ENDOF
       ^down(1)           OF  DOWN          ENDOF
       ^down(2)           OF  DOWN          ENDOF
       ^down(3)           OF  DOWN          ENDOF
       ^1st-col           OF  <LEFT         ENDOF
       ^last-col(1)       OF  RIGHT>        ENDOF
       ^last-col(2)       OF  RIGHT>        ENDOF
       ^page-up           OF  PAGE-UP       ENDOF
       ^page-down(1)      OF  PAGE-DOWN     ENDOF
       ^page-down(2)      OF  PAGE-DOWN     ENDOF
       ^BOF               OF  >BOF          ENDOF
       ^EOF               OF  >EOF          ENDOF
       ^TOP               OF  >TOP          ENDOF
       ^BOP(1)            OF  >BOTTOM       ENDOF
       ^BOP(2)            OF  >BOTTOM       ENDOF

     \ function keys
       ^Find-string       OF  FIND-1ST      ENDOF
       ^find-aGain        OF  FIND-AGAIN    ENDOF
       ^Replace           OF  REPLACE       ENDOF
       ^replace-Too       OF  REPLACE-TOO   ENDOF

       ^(un)mark(1)       OF  ~MARK         ENDOF
       ^(un)mark(2)       OF  ~MARK         ENDOF

       ^Delete            OF  DELE          ENDOF
       ^Wedge             OF  WEDGE         ENDOF
       ^inVest            OF  INVEST        ENDOF

       ^Copy              OF  COPY          ENDOF
       ^Embed             OF  EMBED         ENDOF
       
       ^COMMAND           OF  ~COMMANDING   ENDOF

       ^Query             OF  QUERY-HELP    ENDOF

       ^Alter-input       OF  ~INPUT        ENDOF
       ^Show              OF  ~SHOW         ENDOF
       ^change-name       OF  ~NAME         ENDOF

       ^Save              OF  SAVING        ENDOF
       ^good-Bye          OF  FINISH        ENDOF

       \ -control-keys

       -Enter-key(1)      OF  ENTER         ENDOF
       -Enter-key(2)      OF  ENTER         ENDOF
       -Backspace-key(1)  OF  BACKSPACE     ENDOF
       -Backspace-key(2)  OF  BACKSPACE     ENDOF
       -Tab-key(1)        OF  TABITHA       ENDOF
       -Tab-key(2)        OF  TABITHA       ENDOF

       \ space in command mode
       BL                 OF  SPACE-BAR    ENDOF

       DUP CONTROL-KEY?

   ENDCASE  0 ;


\ process

\ get ready to process a keyboard event
: PROCESS>  ( -- )
   line-now @  DUP line-old !  1-
   topline @  DUP top-old !
   last-line @  DUP last-old !  CLAMP
   DUP .start !  1-  DUP .end !  .mend ! ;

\ process a character 
: KEYBOARD-CHARACTER  ( c -- )
   DUP                COMMAND-MODE? IF  COMMAND-MODE   ELSE
   DUP  BL LAST-DISPLAYABLE BETWEEN IF  DUP CHARACTER  ELSE
   DUP  CONTROL-KEY?
                                    THEN THEN
   DROP ;

\ process other keyboard event (such as a cursor key)
\ if using ekey
: OTHER-KEYBOARD-EVENT  ( u -- )  DEEP ;

\ handle a keyboard event
: PROCESS-KEY  ( c flag -- )
   PROCESS>
   2DUP  AND COMMANDING OR  >R  \ if commanding, hide key
   IF    KEYBOARD-CHARACTER
   ELSE  OTHER-KEYBOARD-EVENT  THEN
   R> TO PREVIOUS-KEY ;


\ LF, an NPBP ANS Forth word processor
: LF  ( -- )
   FALSE TO COMMANDING  FALSE TO DONE  START
   BEGIN IN-KEY
         PROCESS-KEY ?BLOCK .RESULT
   DONE UNTIL  ?DE-ALLOCATE  PAGE ;


LF  \ start LF
