\ -----file big.4th begins------

\ Arithmetic on big signed-magnitude numbers.

\ Forth Scientific Library Algorithm #47

\ Copyright 1996 by Leonard Francis Zettel, Jr.
\ Released to the Forth Scientific Library.
\ This file may be compiled, copied, modified, or sold provided:
\ 1) Full liability for any consequences of doing so is taken.
\ 2) The nature of any modifications is clearly indicated.

\ This is an ANS Forth program requiring:
\ 0<> <> FALSE NIP TRUE \ From the Core Extension word set
\ 2CONSTANT D< M+ From the Double-Number word set
\ ?   From the Programming-Tools word set
\ [IF] [ELSE] [THEN] from the Programming-Tools Extension word set
\ (conditional compilation used only for setting biggest)  

\ This is a Forth implementation of the "classical algorithms".
\ See Knuth, Donald The Art of Computer Programming Vol 2 p 250.

\ The internal representation of the big numbers is "little-endian
\ signed magnitude".  The cell at the address addr contains n, the
\ size of the number in digits.  n is positive for positive numbers,
\ negative for negative.  Each succeeding cell contains a digit of
\ the number in base 2**(cell size-1), least significant digit first.
\
 
\ This version of big.4th is the kForth version. It provides a
\ separate data space for transient storage of big numbers.
\ The following internal words are kForth-specific:
\
\  BIG-ALLOT   ( n -- )
\  BIG,        ( n -- )
\
\ Glossary (General):
\
\  DIGIT       ( c n1 -- n2 true|false )
\  CARRY       ( digit -- carry digit)    
\  D>CARRY     ( low high -- carry digit)
\  OVERFLOW?   ( borrow uj -- uj new_borrow) 
\  BIG_DIGIT_POINTER ( --) ( n -- address) 
\  TO_POINTER  ( <name> -- addr1)
\  CLIP        ( addr --)  
\  BIG_DIGIT   ( addr n1 -- n2)
\  BIG>HERE    ( addr1 -- )
\  REPOSITION  ( addr1 addr2 -- )
\  ADJUST_SIGN ( addr1 addr2 addr3 -- addr3)
\  |BIG|=      ( addr1 addr2 -- flag)
\  |BIG|<      ( addr1 addr2 -- flag)
\  >BIG_NUMBER ( addr1 caddr2 u2 -- addr1 caddr3 u3) 
\  BIGSTRING   ( addr1 sign --  ) 
\  SUM         ( addr1 addr2 - addr3) 
\  DIFFERENCE  ( addr1 addr2 -- addr3)
\  BIG_PRODUCT ( addr1 addr2 -- addr3) 
\  DIVISOR(N)  ( -- n)   
\  DIVISOR(N-1)  ( -- n) 
\  NORMALIZE   ( -- )  
\  BIG.DIGITS  ( addr --)
\  TRIAL       ( n1 -- n2) 
\  DIV_SUBTRACT  ( quotient j -- quotient flag)
\  ADDBACK     ( j --) 
\  |DIVIDE|    ( addr1 addr2 -- addr3) 
\  DIVIDE      ( addr1 addr2 -- addr3) 
\
\  User level words
\
\  MAKE_BIG_NUMBER ( caddr1 u1 -- addr2)  Convert string to big number
\  <BIG#     ( --)      Begin big number pictured output
\  BIGHOLD   ( c -- )   Append char c to beginning of big pictured output
\  BIG#      ( addr -- addr)  Generate next character from big number at addr
\  BIG#S     ( addr -- addr)  Convert all digits of big number at addr
\  BIGSIGN   ( n --)          Put minus sign in big pictured output if n < 0 
\  #BIG>     ( addr1 -- caddr2 u2)  End big number pictured output  
\  BIG       ( <cccc> -- addr)      Parse, convert, return big number
\  BIG.      ( addr --)       Print a big number
\  BIGNEGATE ( addr --)       Negate big number at addr 
\  BIGABS    ( addr --)       Apply absolute value to big number at addr
\  BIG0=     ( addr -- flag)  Test big number is zero.
\  BIG0<>    ( addr -- flag)  Test big number is not zero.
\  BIG0<     ( addr -- flag)  Test big number is negative.
\  BIG=      ( addr1 addr2 -- flag) Test equality for two big numbers
\  BIG<      ( addr1 addr2 -- flag) Test less than for two big numbers
\  BIG+S     ( addr n --)      Add single to big number at addr 
\  BIG*S     ( addr n -- )     Multiply single to big number at addr
\  BIG/MODS  ( addr n1 -- n2)  Divide big number by n1, n2 is remainder
\  BIG+      ( addr1 addr2 -- addr3)  Add two big numbers, return sum
\  BIG-      ( addr1 addr2 - addr3)   Subtract big numbers, return diff
\  BIG*      ( addr1 addr2 -- addr3)  Multiply big numbers, return prod
\  BIG/      ( addr1 addr2 -- addr3)  Divide big numbers, return quotient
\  BIGMOD    ( addr1 addr2 -- addr3)  Divide big numbers, return remainder
\  BIG/MOD   ( addr1 addr2 -- addr3 addr4) Divide, return remainder and quotient 

\ Revisions:
\ 2024-07-26 km, ported to kForth module, added Glossary, 
\   revised comments, added test code, revised defn of BIG 
\ 2024-08-12 km, increased size of buffer BIG_STRING from 256 chars
\   to the constant BIG_STRING_MAX_CHARS which currently has the value
\   16384. Revised <BIG# and #BIG> to use BIG_STRING_MAX_CHARS constant.

CR .( BIG               V1.2           12 August    2026  LFZ, KM)
BEGIN-MODULE
BASE @  DECIMAL             \ Housekeeping

Public:

-1 1 LSHIFT 1 RSHIFT  CONSTANT biggest        \ Largest representable signed number

biggest 1+ CONSTANT bigbase       \ big number base as an unsigned number
biggest S>D 1 M+ 2CONSTANT bigbd  \ big number base as a double number

: cell- ( addr1 -- addr2) \ addr2 is the cell address below addr1
  1 CELLS - ;

\ This code guided by the description of DIGIT in C. H. Ting, F-PC
\ Technical Reference Manual, 2nd ed. Offete Enterprises 1989 p. 82.

\ DIGIT is intended for the character range specified by the standard (0..Z)
\ Lower-case digit conversion will require system-specific code modification.

      : DIGIT ( c n1 -- n2 true | false) \ attempt to convert c to its
        \ numerical value in base n1.  Return the value and TRUE if
        \ successful, FALSE otherwise.
        OVER [CHAR] 0 <
        IF   2DROP FALSE   \ characters below the zero character
                           \ can't be digits
        ELSE OVER [CHAR] : <
             IF   DROP [CHAR] 0 - TRUE
             ELSE OVER [CHAR] A <
                  IF   2DROP FALSE
                  ELSE SWAP [CHAR] 7 -        \ convert to numeric value
                       DUP ROT <
                       IF   TRUE              \ valid digit
                       ELSE DROP FALSE
                       THEN
                  THEN
             THEN
        THEN ;

\ Words to handle spillover between cells during calculations

\ check for a carry, remove it, leave it under the result.
: carry ( digit -- carry digit)    
  biggest OVER U<
  IF   bigbase -     \ Remove the carry
       1             \ Show we had a carry
  ELSE 0             \ show we had no carry
  THEN SWAP ;

\ convert a double number to a low-order digit and a carry.
: D>carry ( low high -- carry digit)  bigbase UM/MOD SWAP ;

\ If uj is negative (indicating a result out of range on the 
\ previous subtraction), bring it in range and increment the 
\ borrow that will be necessary on the next digit.
: overflow? ( borrow uj -- uj new_borrow) 
  DUP 0< IF  bigbase +  1  ELSE 0  THEN
  ROT + ;

\ Words to point to parts of big numbers

\ create a word <name>.
\ when <name> is executed return the address of the nth cell after
\ the address in <name>'s data field.
: big_digit_pointer ( --) ( n -- address) 
  CREATE 1 CELLS ALLOT           \ create the word & allot the data space
  DOES> a@                       \ put the address in <name>'s data field
                                 \ on the stack
        SWAP CELLS + ;           \ Increment the address by index cells


\ compiling: addr1 is <name>'s data field.
  ( addr2 --) \ execution: addr2 is placed in <name>'s data field.

: to_pointer ( <name> -- addr1)
  ' >BODY POSTPONE LITERAL  POSTPONE ! ; IMMEDIATE


\ Miscellaneous operations on big numbers

big_digit_pointer clippee

: clip ( addr --)      \ remove leading zeroes from the number at addr
  to_pointer clippee
  0                    \ default - no non-zero digits
  1  0 clippee @ ABS   \ loop from present number of digits to one.
  DO       I clippee @               \ next big digit
           0<> IF DROP I LEAVE THEN  \ index of first non-zero digit
                                     \ on stack
  -1 +LOOP
  ?DUP IF   0 clippee @              \ original sign & size
            0< IF NEGATE THEN        \ minus sign on new size
       ELSE 1                        \ number is exactly zero, keep one
                                     \ of the zeros, show plus number
       THEN
  0 clippee ! ;                 \ store new size

\ Return digit n1 of the big number at addr.
\ If n1 is greater than the number of digits, return a leading zero.
: big_digit ( addr n1 -- n2)
  OVER @ ABS         \ number of digits
  OVER <
  IF   2DROP 0       \ Return leading zero
  ELSE CELLS + @     \ Return digit
  THEN ;

\ Change the sign of the big number at addr
: bignegate ( addr --)  
  DUP @ DUP                          \ Number of digits
  1 = IF   OVER CELL+ @              \ Check for zero
           IF   NEGATE SWAP !        \ Non-zero, negate
           ELSE 2DROP                \ Zero, do nothing
           THEN
      ELSE NEGATE SWAP !
      THEN ;

\ Give the big number at addr its absolute value.
: bigabs ( addr --) 
    DUP @ ABS SWAP ! ;

\ Data space for big numbers
create big_data_space 65536 allot
big_data_space ptr big-here

\ Allot big number data space of n bytes 
: big-allot ( n -- )
    big-here + TO big-here ;

\ Append a cell to a big number (digit or header info)
: big, ( u -- ) big-here TUCK ! CELL+ TO big-here ;


\ "big to here" 
\ Append the big number at addr to the end of data space.
: big>here ( addr --)   
  big-here               \ address to move to
  OVER @ ABS 1+ CELLS    \ Number of address units in the number
  DUP big-allot          \ allot space for the number
  MOVE ;

\ Move the number at addr1 to addr2 and free any data space beyond it.
: reposition ( addr1 addr2 -- )
  SWAP 2DUP @                    \ (addr2 addr1 addr2 size)
  ABS 1+ CELLS                   \ (addr2 addr1 addr2 bytes)
  DUP >R  MOVE                   \ (addr2) (bytes)
  R> + big-here - big-allot ;


\ Adjust the sign of the big number at addr3 according 
\ to the rules for forming the algebraic product from the 
\ operands at addr1 and addr2
: adjust_sign ( addr1 addr2 addr3 -- addr3)
    ROT @  ROT @  XOR 0< IF DUP bignegate THEN ;

\ Comparison operators

big_digit_pointer |big|1  big_digit_pointer |big|2

\ Return TRUE if the big number at addr1 has the same absolute 
\ value as the big number at addr2.  FALSE otherwise
: |big|= ( addr1 addr2 -- flag)
  OVER @ ABS OVER @ ABS =     \  are the numbers the same size?
  IF   to_pointer |big|1
       to_pointer |big|2
       TRUE                   \ default initial flag.
       1  0 |big|1 @  ABS
       DO I |big|1 @
          I |big|2 @  <>
          IF DROP FALSE LEAVE THEN
          -1
       +LOOP
  ELSE 2DROP FALSE
  THEN ;

\ Return TRUE if the absolute value of the big number at addr1 is 
\ less than the absolute value of the big number at addr2;
\ FALSE otherwise.
: |big|< ( addr1 addr2 -- flag)
  to_pointer |big|2
  to_pointer |big|1
  0 |big|1 @ ABS
  0 |big|2 @ ABS
  2DUP <
  IF   2DROP TRUE
  ELSE = FALSE                   \ default flag if equal, result if <>.
       SWAP
       IF   1 0 |big|1 @ ABS     \ From the high order digit to the first
            DO                   \ digit
               I |big|1 @
               I |big|2 @
               2DUP
               <> IF < NIP LEAVE THEN
               2DROP
            -1 +LOOP
       THEN
  THEN ;

\ Return TRUE if the big number at addr is zero.
: big0= ( addr -- flag)
  DUP @ 1 = IF CELL+ @ 0= ELSE DROP FALSE THEN ;

\ Return TRUE if the big number at addr is not zero.
: big0<> ( addr -- flag) 
  big0= 0= ;

: big0< ( addr -- flag) @ 0< ;

\ Return TRUE if the operand at addr1 is less than 
\ the operand at addr2, FALSE otherwise.
: big< ( addr1 addr2 -- flag)
  OVER @ OVER @ <           \ Look at operand sign & number of digits
  IF   2DROP TRUE
  ELSE                      \ ( addr1 addr2)
       OVER @ OVER @ >
       IF   2DROP FALSE
       ELSE                 \ To get here the operands must be the
                            \ same sign & be of equal length
            DUP @ 0<
            IF SWAP THEN    \ If the numbers are negative, the one with
                            \ the larger absolute value is the lesser.
            DUP @ ABS >R    \ Park number of digits
            R@ CELLS
            DUP ROT +       \ High order cell of operand 2.
            ROT ROT +       \ High order cell of operand 1.
            SWAP
            FALSE           \ dummy initial flag
            R> 0
            DO                      \ ( addr1 addr2 flag)
               DROP                 \ flag from previous cycle
               OVER @ OVER @        \ ( addr1 addr2 digit1 digit2)
               < DUP IF LEAVE THEN
               ROT cell- ROT cell-
               ROT
            LOOP
            NIP NIP
       THEN
 THEN
 ;

\ Return TRUE if the big number at addr1 has the same value as 
\ the big number at addr2, FALSE otherwise
: big= ( addr1 addr2 -- flag) 
  OVER @  OVER @  =     \  are big numbers the same size and sign?
  IF   to_pointer |big|1
       to_pointer |big|2
       TRUE                   \ default initial flag.
       1  0 |big|1 @  ABS
       DO I |big|1 @
          I |big|2 @  <>
          IF DROP FALSE LEAVE THEN
          -1
       +LOOP
  ELSE 2DROP FALSE
  THEN ;


\ Words doing mixed single-precision and big number arithmetic

big_digit_pointer big_addend

\ Add n to the number at addr.  n must be non-negative and
\ the number at addr must be non-negative and end at BIG-HERE.
: big+s ( addr n --) 
  SWAP to_pointer big_addend  \ ( n)
  0 big_addend @  ABS 1+      \ loop limit
  1                           \ loop start
  DO                          \ ( n)
       I big_addend @  +      \ ( ui+n)
       carry
       I big_addend !         \ store new ui
       DUP 0= IF LEAVE THEN   \ no carry, we are done
  LOOP
                              \ carry in high-order digit?
  IF
      1 BIG,                  \ append carry to the number
      1  0 big_addend +!      \ Increment number size
  THEN ;


\ Multiply the number at addr by n.
\   n must be positive
\   the number at addr must end at "here"
big_digit_pointer big_multiplicand

: big*s ( addr n -- )        
  SWAP
  to_pointer big_multiplicand
  0                           \ ( n carry)
  0 big_multiplicand @ ABS 1+
  1
  DO                          \ ( n carry)
       OVER
       I big_multiplicand @
       M*                     \ ( carry n low[ui*n] high[ui*n])
       ROT  M+                \ ( n low[ui*n+carry] high[ui*n+carry])
       D>carry                \ ( n carry ui*n)
       I big_multiplicand !   \ store digit i back in u ( n carry)
  LOOP
  NIP
  ?DUP IF  0 big_multiplicand  @  \ ( carry n)
            DUP 0< IF   1-
                   ELSE 1+
                   THEN           \ ( carry n)
            0 big_multiplicand  ! BIG,
       THEN ;


big_digit_pointer big_dividend
\ "big slash-mod s"
\  Divide the big number at addr by n1, leaving the quotient 
\  at addr. n2 is the remainder.
: big/mods ( addr n1 -- n2)
  SWAP
  to_pointer big_dividend
  0                         \ ( divisor remainder)
  1  0 big_dividend @ ABS
  DO                        \ ( divisor remainder)
      bigbase UM*           \ ( divisor lowr highr)
      I big_dividend @      \ ( divisor divisor lowr highr uj)
      M+
      2 PICK
      UM/MOD                \ ( divisor r wj )
      I big_dividend !
      -1
  +LOOP
  NIP  0 big_dividend clip ;


\ Words for going from characters to big numbers

\ "to big number"
\ Extend the big number at addr1 by the number represented 
\ by the string at caddr2 u2.  caddr3 u3 is the remaining string
\ of unconverted characters
: >big_number ( addr1 caddr2 u1 -- addr1 caddr3 u3) 
  2DUP + >R                    \ address just beyond end of string on
                               \ return stack
  0 DO                         \ ( addr1 addr2)
        2DUP C@                \ ( addr1 addr2 addr1 char)
        BASE @ DIGIT           \ ( addr1 addr2 addr1 n flag)
        IF   OVER BASE @ big*s \ ( addr1 addr2 addr1 n)
             big+s             \ ( addr1 addr2)
        ELSE                   \ ( addr1 addr2 addr1 char)
             DROP LEAVE        \ ( addr1 addr2)
        THEN
        CHAR+
    LOOP
    R> OVER - ;


\ Convert the string at caddr1 u1 to a big number at addr2
: make_big_number ( caddr1 u1 -- addr2)  
  \ If the first character is "-" (ASCII 45) the result will be negative.
  \ embedded commas are ignored 
  \ (USA representation convention for large numbers)
  \ Conversion stops at the first non-convertible character.
             
  OVER C@                          \ Get the first character
  [CHAR] - =                       \ Is it a minus sign?
  DUP >R
  IF   SWAP CHAR+ SWAP 1- THEN     \ Adjust to next character
                                   \ ( addr1 u)
  big-here 1 big, 0 big,           \ create big number = 0
                                   \ ( addr1 u addr2)
  ROT ROT
  BEGIN                            \ ( addr2 addr1 u)
        >big_number                \ ( addr2 addr1 u)
        OVER C@ [CHAR] , =         \ ( addr2 addr1 u flag)
        OVER AND
  WHILE
        SWAP CHAR+ SWAP 1-
  REPEAT
  2DROP
  R> IF DUP bignegate THEN ;


\ Words for big number output
\ The words <big# through big#s and big. are adapted from
\ descriptions of their pictured numeric output string counterparts
\ in "All About Forth" 2nd ed by Glen Haydon.  Used with permission.
16384 constant BIG_STRING_MAX_CHARS
CREATE big_string BIG_STRING_MAX_CHARS CHARS ALLOT

VARIABLE bighld

\ "less big number sign"
\ Initialize the big number pictured numeric output area
: <big# ( --) 
  big_string BIG_STRING_MAX_CHARS CHARS + bighld ! ;  \ Haydon p 67

\ Append character c to the beginning of the big pictured 
\ numeric output string
: bighold ( c -- ) 
  -1 CHARS bighld +!  bighld a@ C! ; \ Haydon p 170.

\ "number sign big less"
\ End big number pictured output conversion
: #big> ( addr1 -- addr2 +n) 
  DROP  bighld a@            \ Start of string
  big_string BIG_STRING_MAX_CHARS CHARS +     \ One past end of string
  OVER - 1 CHARS / ;         \ Length of string

\ "big number-sign"
\ Generate the next ASCII character from the big number at addr.
\ Afterward the big number at addr will hold the quotient obtained
\ by dividing its previous value by the value in BASE.
\ This result can then be used for further processing.
\ Haydon p 18
: big# ( addr -- addr)  
  DUP
  BASE @ big/mods       \ Next digit
  9 OVER <              \ Is it bigger than a decimal digit?
  IF 7 + THEN           \ Add seven to its character representation,
                        \ thus skipping the ASCII codes between 9 and A.
  48 +                  \ Convert from number to ASCII character code.
  bighold ;             \ add the character to the front of the output
                        \ string

\ "big number-sign s"
\ Convert all digits of the big number at addr to 
\ big numeric output, leaving zero at addr
: big#s ( addr -- addr) 
  BEGIN big# DUP @ 1 =      \ Down to length 1
        OVER CELL+ @ 0=     \ Remaining cell is zero
        AND
  UNTIL ;               \ Haydon p 21.

\ Put a minus sign in the big pictured numeric character 
\ output string if n is negative
: bigsign ( n --) 
  0< IF 45 bighold THEN ; \ Haydon p 222.

\ Display the big number at addr1 with the sign of the 
\ number in sign.
: bigstring ( addr1 sign --  )
  <big# big#s SWAP bigsign #big> TYPE ;

\ Words doing arithmetic on two big numbers


\ Add the absolute value of the big number at addr1 to the 
\ absolute value of the big number at addr2. Return the sum
\ in the big number at addr3.
big_digit_pointer long_addend  big_digit_pointer short_addend
: sum ( addr1 addr2 - addr3) 
  OVER @ ABS  OVER @ ABS <     \ compare the size of the addends
  IF SWAP THEN
  to_pointer short_addend
  to_pointer long_addend

  big-here                     \ address of result
  0 big,                       \ dummy placeholder for the count of the
                               \ result
  0                            \ initialize carry

  0 short_addend @ ABS 1+      \ for each digit in the short addend
  1                            \ starting at the first
  DO
       I short_addend @  +     \ add digit to carry
       I long_addend  @  +     \ add digit to previous sum
       carry big,              \ new carry, append digit to result
  LOOP

  0 long_addend @ ABS          \ number of digits in long operand
  1+                           \ jog to make DO end on last digit
  0 short_addend @ ABS         \ number of digits in short operand
  1+                           \ jog to start DO on first digit
                               \ not yet used
  ?DO  I long_addend @  +      \ append any remaining digits to the
       carry big,              \ result, rippling the carry as
  LOOP                         \ necessary

  0 long_addend @ ABS          \ result size so far
  SWAP
  IF 1 big, 1+ THEN            \ if final carry, append to result,
                               \ bump size
  OVER ! ;                     \ store result size.

\ addr3 is the address of the difference of the absolute values of
\ the big number at addr1 and the big number at addr2.

big_digit_pointer minuend  big_digit_pointer subtrahend

: difference ( addr1 addr2 -- addr3)

  big-here >R                   \ park address of result
  2DUP |big|=
  IF   2DROP  1 big, 0 big,     \ equal absolute values, result is zero
  ELSE
       2DUP |big|<
       IF SWAP THEN
       to_pointer subtrahend
       to_pointer minuend
       0 minuend @ ABS  big,    \ count of the result
       0                        \ initialize borrow

       0 minuend @ ABS 1+       \ for each minuend digit
       1                        \ starting with the first
       DO                       \ ( borrow)
          0                     \ next borrow
          I minuend @           \ get the ith minuend digit
          ROT -                 \ subtract previous borrow
          overflow?
          SWAP                  \ ( borrow result)
          0 subtrahend
          I big_digit  -        \ subtract the ith subtrahend digit
          overflow?             \ ( result borrow)
          SWAP big,             \ append result
       LOOP

       DROP                 \ Get rid of final borrow (it will be zero)
       R@ clip              \ remove leading zeroes
  THEN
  R> ;                      \ address of result on stack

\ Mulitply the absolute value of the big number at addr1 
\ by the absolute value of the big number at addr2. Return
\ the result in the big number at addr3.

big_digit_pointer multiplicand  big_digit_pointer multiplier
big_digit_pointer product

: big_product ( addr1 addr2 -- addr3) 
  to_pointer multiplier
  to_pointer multiplicand               \ store operand addresses
  big-here DUP to_pointer product       \ address of result
  0 multiplier   @ ABS
  0 multiplicand @ ABS   2DUP
  + big,                                \ store product size

                                        \ allot and clear the first
  DUP 0 DO 0 big, LOOP                  \ n digits of the product
  OVER CELLS big-allot                  \ allot remaining digits of product

  OVER 1+  1                            \ for each multiplier digit,
                                        \ starting with the first
  DO
     0                                  \ initial carry

     OVER 1+  1                         \ for each multiplicand digit,
                                        \ starting with the first
     DO
        I multiplicand @                \ mulitplicand digit times
        J multiplier @                  \ multiplier digit
        M*
        I J 1- + >R                     \ current product digit index
        R@ product @  M+                \ add previous product result
        ROT M+                          \ add carry
        D>carry                         \ split into digit & carry
        R> product !                    \ store product digit
     LOOP

     OVER I + product !                 \ store carry
  LOOP
  2DROP
  DUP clip ;                          \ if there is a high-order zero,
                                      \ remove it


big_digit_pointer dividend  big_digit_pointer divisor
big_digit_pointer quotient  VARIABLE normalizer

: divisor(n) ( -- n) \ n is the high digit of the divisor
  0 divisor @ ABS divisor @ ;

: divisor(n-1) ( -- n) \ n is the next-to-high-order digit of the divisor
  0 divisor @ ABS 1- divisor @ ;

\ Multiply dividend and divisor by a factor that will guarantee 
\ that the leading "digit" of the divisor will be > bigbase/2
: normalize ( -- )
  bigbd                        \ big number base as double number
  divisor(n)                   \ high order digit of divisor
  1+ UM/MOD  normalizer !      \ normalizing factor (base/(vn+1))
  DROP                         \ discard remainder
  big-here                     \ This will be the address of the
                               \ normalized dividend
  0 dividend big>here          \ copy dividend to end of data space
  to_pointer dividend          \ new dividend address
  normalizer @ 1 >
  IF 0 dividend
     normalizer @ big*s        \ normalize the dividend.
  THEN
  0 big,                       \ append high order zero to dividend
  0 dividend DUP @ 0<          \ negative dividend?
  IF -1 ELSE 1 THEN
  SWAP +!                      \ up the dividend digit count
  big-here                     \ address of the normalized divisor
  0 divisor big>here           \ copy divisor to end of data space
  DUP to_pointer divisor
  normalizer @ big*s ;         \ normalize the divisor

\ "big dot"
\ Display the big number at addr
: big. ( addr --)    
  big-here >R R@
  SWAP big>here                        \ Copy for nondestructive write
  DUP @                                \ sign of the number
  SWAP bigstring
  SPACE
  R> big-here - big-allot ;            \ recover space used by big>here

\ "big dot digits"
\ Print the digits of the big number at addr
: big.digits ( addr --) 
  DUP CELL+ SWAP DUP @ ABS CELLS + DO I ? -1 CELLS +LOOP ;

: trial ( n1 -- n2)             \ n2 is trial quotient digit n1
  \ CR ." trial " 
  0 divisor @ ABS + >R
  R@ dividend @ bigbase UM*     \ u(j)*b
  R@ 1- dividend @ M+           \ [u(j)*b+u(j-1)]
  divisor(n)                    \ v(1), high digit of divisor
  R@ dividend @  =              \ equal to uj?
                                \ data stack: low[u(j)*b+u(j-1)]
                                \             high[u(j)*b+u(j-1)]
                                \             flag
  IF   2DROP
       R@ 1- dividend @         
       0 divisor(n) M+          \ rhat = u(j-1) + v(1)
       biggest
       SWAP
       IF R> DROP EXIT THEN     \ We have the right q
  ELSE divisor(n) UM/MOD        \ rhat qhat
  THEN                          \ ( rhat qhat) (j)

  BEGIN                         \ test trial quotient
        2DUP divisor(n-1)  UM*  \ v(n-1)*qhat
        ROT bigbase UM*         \ rhat*b
        R@ 2 - dividend @       \ u(j-2)
        M+
        2SWAP D<
  WHILE                         \ ( rhat qhat) (j)
        1-                      \ decrease trial quotient
        SWAP divisor(n) +       \ adjust remainder
        SWAP
  REPEAT
  R> DROP                       \ clear return stack
  NIP ;                         \ drop trial remainder

\ Subtract (vn..v1)q from (u(j+n)..u(j))
\ flag is TRUE if the result is negative
: div_subtract ( quotient j -- quotient flag)
  0                                \ borrow
  0 divisor @ ABS 1+  1
  DO                               \ ( quotient j borrow)
       >R 2DUP R>
       ROT I divisor @  M*
       D>carry                     \ convert from double number to
                                   \ big digits
                                   \ ( quotient j j borrow carry digit)
       ROT +                       \ add the previous borrow to the digit
       overflow?
       ROT dividend @              \ uj
       ROT -                       \ new uj
       BEGIN 
              overflow? OVER 0< 
       WHILE SWAP REPEAT
       >R                          \ park new borrow
       OVER dividend !             \ store new uj
       1+                          \ bump j
       R>
   LOOP
   OVER dividend @  
   SWAP -         \ subtract the last borrow from the
                                   \ next digit of u
   DUP
   ROT dividend !                  \ put the result in the digit of u
   0<> ;                           \ test for overflow

\ Add (vn..v1) to (u(j+n)..u(j))
: addback ( j --) 
  0                            \ carry
  0 divisor @ ABS 1+ 1
  DO                            \ j carry
        OVER DUP dividend @     \ j carry j u(j)
        I divisor @
        +  ROT +                \ j j (v(i)+u(j)+carry)
        carry
        ROT dividend !
        SWAP 1+ SWAP            \ increment j
   LOOP
   DUP
   IF                           \ Deal with the final carry (I'm not sure
                                \ this is strictly necessary (If you can
                                \ prove it one way or the other, I would be
                                \ interested in seeing it) but it is neater)
        SWAP dividend +!
   ELSE 2DROP
   THEN   ;

\ Divide the absolute value of the big number at addr1 
\ by the absolute value of the big number at addr2. The 
\ numbers must be unequal and the divisor must have at 
\ least two "digits". Return the big number quotient at
\ addr3.
: |divide| ( addr1 addr2 -- addr3) 
       to_pointer divisor               
       to_pointer dividend 
       normalize
       big-here DUP            \ address of quotient
       to_pointer quotient
       1                       \ limit for DO - stop after digit 1
       0 dividend @ ABS        \ number of digits in normalized dividend
       0 divisor  @ ABS        \ number of digits in divisor
       - 1 MAX DUP big,        \ number of digits in quotient
       DUP CELLS big-allot     \ space for quotient
       DO
          I trial              \ trial quotient digit
          I div_subtract
          IF 1- I addback THEN \ ( qi)
          I quotient !         \ store qi
       -1 +LOOP
       DUP clip ;

\ Divide the absolute value of the big number at addr1 by 
\ the absolute value of the big number at addr2. Return the
\ big number quotient at addr3.
: divide ( addr1 addr2 -- addr3) 
  2DUP |big|<                  \ Is the number at addr1 < num at addr2?
  IF   2DROP  big-here  1 big, 0 big,        \ answer is 0
  ELSE 2DUP |big|=                      \ are the numbers equal?
       IF   2DROP  big-here  1 big, 1 big,    \ answer is 1
       ELSE DUP @ ABS 1 =               \ single "digit" divisor?
            IF   CELL+ @                \ divisor on stack
                 big-here ROT big>here  \ dividend to here
                 DUP ROT big/mods
                 DROP               \ drop remainder
                 DUP @ ABS          \ absolute value for sign of quotient
                 OVER !
            ELSE |divide|
            THEN
       THEN
  THEN ;


\ Finally! the words for the user.

\ Parse the space-delimited characters cccc from the 
\ input stream and convert string to a big number
\ and return the address of the big number, addr
: big ( <cccc> -- addr) 
  BL PARSE make_big_number ;                     


\ Add the big number at addr1 to the big number at addr2. 
\ Return the big number sum at addr3.
big_digit_pointer op1 big_digit_pointer op2

: big+ ( addr1 addr2 -- addr3) 
  big-here >R
  2DUP to_pointer op2
  to_pointer op1
  0 op1 @  0 op2 @ XOR
  0< IF   difference           \ operands are of opposite sign
          0 op1  0 op2 |big|<
          IF   0 op2 @         \ result has the sign of operand 2
          ELSE 0 op1  0 op2 |big|=
               IF   1          \ result is zero, plus sign
               ELSE 0 op1 @    \ result has the sign of operand 1
               THEN
          THEN
     ELSE sum                  \ operands have same sign
          0 op1 @
     THEN
     OVER @                    \ size of result
     SWAP 0< IF NEGATE THEN    \ add the sign
     OVER !
  R@ reposition R> ;


\ Subtract the big number at addr2 from the bug number at addr1.
\ Return the difference in the big number at addr3.
: big- ( addr1 addr2 - addr3) 
  big-here >R big>here         \ copy second operand
  R@ bignegate                 \ switch its sign
  R@ big+                      \ add
  R@ reposition R> ;


\ Multiply the big number at addr1 by the big number at addr2
\ and return the product in the big number at addr3.
: big* ( addr1 addr2 -- addr3)
  2DUP big_product adjust_sign ;

\ Divide the big number at addr1 by the big number at addr2
\ and return the floored quotient in the big number at addr3.
: big/ ( addr1 addr2 -- addr3)
  big-here >R
  2DUP divide
  ( adjust_sign)
  ROT @ ROT @  XOR 0<                \ Do we need an adjustment?
  IF DUP 1 big+s  DUP bignegate THEN
  R@ reposition R> ;

\ big 288,265,561,597,526,014 big 17,593,259,786,239 big/ should leave a 
\ result of 16384.  This tests the rare "trial divisor off by two" division 
\ branch on a 16 bit system.  See Regener for more on this

\ Divide the big number at addr1 by the big number at addr2
\ and return the remainder in the big number at addr3.
: bigmod ( addr1 addr2 -- addr3) 
  big-here >R
  2DUP big/                   \ (addr1 addr2 qoutient-addr)
  big*  big-
  R@ reposition R> ;


\ Divide the big number at addr1 by the big number at addr2.
\ Return the remainder in the big number at addr3, and the
\ quotient in the big number at addr4.
: big/mod ( addr1 addr2 -- addr3 addr4) 
  2DUP big/
  DUP >R
  big* big-
  R> ;

BASE !                        \ End of module; restore BASE
END-MODULE

[DEFINED] TEST-CODE? [IF]
TEST-CODE? [IF]
BASE @ DECIMAL
[UNDEFINED] T{ [IF] include ttester [THEN]
COMMENT Partial testing of the big number words.
COMMENT Tests assume BIG= works.
0 ptr b1
0 ptr b2
0 ptr b3
TESTING MAKE_BIG_NUMBER
t{ biggest s>d <# #s #>  make_big_number to b1 -> }t
t{ b1 @ -> 1 }t
t{ b1 cell+ @ -> biggest }t
t{ 0 1 <# #s #>  make_big_number to b2 -> }t
t{ b2 @ -> 2 }t
t{ b2 cell+ @ 0  bigbase b2 cell+ cell+ @ UM* D+ -> 0 1 }t

TESTING <BIG# BIG#s #BIG>
create sbuf 32 allot
variable slen
t{ -1 0 <# #s #> dup slen ! sbuf swap move -> }t
t{ sbuf slen @ make_big_number to b1 -> }t
t{ b1 <big# big#s #big> sbuf slen @ compare -> 0 }t   

TESTING BIG*S
\ "big factorial"  
: big! ( n -- addr ) 
   big-here 1 big, 1 big,  \ addr of new big 1
   swap abs 1+ 200 min
   1 do dup I BIG*S loop ;

t{ 100 big!
big 93,326,215,443,944,152,681,699,238,856,266,700,490,715,968,264,381,621,468,592,963,895,217,599,993,229,915,608,941,463,976,156,518,286,253,697,920,827,223,758,251,185,210,916,864,000,000,000,000,000,000,000,000
   big= -> true }t

TESTING BIG* BIG/
t{ big 199,928,740,922,274,529,000,090,300,055,888,888 to b1 -> }t
t{ big 20,384,923,712 to b2 -> }t
t{ big 4,075,532,131,536,778,795,187,572,407,750,484,318,228,512,256 to b3 -> }t
t{ b1 b2 big* b3 big= -> true }t
t{ big 9,807,676,680,417,617,105,678,884 to b3 -> }t


t{ b1 b2 big/ b3 big= -> true }t
t{ big 288,265,561,597,526,014 
   big 17,593,259,786,239 
   big/
   big 16384 big= -> true }t

BASE !
[THEN]
[THEN]

\ Bibliography & references:
\ Haydon, Glen B.  All About FORTH, An Annotated Glossary, Second edition
\ 1984  MVP-FORTH Series Volume 1, Mounatin View Prees, Inc., P.O. Box 4656
\ Mountain View CA 94040 USA.  ISBN 0-914699-00-8.

\ Knuth, Donald B.  The Art of Computer Programming, Second Edition Volume 2
\ Seminumerical Algorithms.  Addison-Wesley Publishing Company Reading, 
\ Massachusetts USA 1961. ISBN 0-201-03822-6 (v.2)

\ Regener, Eric "Multiprecision Integer Division Examples Using Arbitrary Radix"
\ ACM Transactions on Mathematical SOftware, Vol 10 No. 3, September 1984 
\ pp 325-28.

\ Ting, C. H.  F-PC 3.5 Technical Reference Manual, Second Edition 1989.
\ Offete Enterprises, Inc. 1306 South B Street San MAteo CA 94402 USA.
\
\ ------end of file------
