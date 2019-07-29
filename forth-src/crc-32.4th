\ crc-32.4th
\
\  CRC-32 International Standard 32-Bit CRC
\
\  by  Wil Baden - a long time ago
\
\  Modifications for use with kForth (also works without mods in PFE); 
\    also added the words .CRC, CRC32S, and TEST-CRC (after an example 
\    by Petrus Prawirodidjojo)  -- Krishna Myneni, 2001-10-19
\
\        CRC-32 International Standard 32-Bit CRC
\
\ The subject of this article is calculation of the International
\ Standard 32-bit CRC, cyclical redundancy check.  It uses nonce-words,
\ or throw-away definitions, to build a table to speed it up.
\
\ `Update-CRC-by-a-Byte` and `CRC` are equivalent.  However `CRC` will be
\ 5 to 8 times faster.  Since you want to do it to every byte you read
\ or write the speed is important.
\
\ `CRC-Table` and `CRC` are the only two permanent definitions.  The other
\ words given here are compiled, executed, and forgotten.
\
\ To use `CRC-32`, set the check-sum to `TRUE` (all bits on) and for every
\ byte written or read, use `CRC` to update the check-sum. Be sure that 
\ you have set the file-access mode to binary on MSDOS type systems.
\
\ When you've finished writing, write out the check-sum, low-byte to
\ high-byte.
\
\ When reading, include the last four bytes you read in the check-sum
\ you have been accumulating.  If everything has gone right, the
\ check-sum will be 0.
\
\ `NOT` can be defined whichever way you want.  It isn't used where it 
\ would make a difference.
\
\ ----------------------------------------------------------------- 
\
\  The International Standard 32-bit CRC.

CREATE CRC-Table   256 CELLS ALLOT

\  Define CRC-POLYNOMIAL from its coefficient terms.


    : RUN   ( -- poly)  
        32 26 23 22 16 12 11 10 8 7 5 4 2 1 0   ( ...)
          0 BEGIN                               ( ... poly)
                SWAP                            ( ... poly bit)
                DUP 32 = NOT
          WHILE
                31 SWAP -  1 SWAP LSHIFT  OR    ( ... poly)
          REPEAT                                ( ... poly bit)
          DROP                                  ( poly)
    ; 

RUN CONSTANT CRC-POLYNOMIAL         ( )
.( \ CRC-POLYNOMIAL is ) CRC-POLYNOMIAL  HEX U. DECIMAL  CR

\ =================================================================
\
\ `CRC-POLYNOMIAL` represents a polynomial with binary coefficients,
\ 0 or 1, of the 32nd degree, and in the literature is usually
\ written as a sum of powers of _x_ in algebraic notation.  But the
\ coefficient of the highest exponent is always 1, not 0 -- otherwise
\ it wouldn't be of the 32nd degree.  So it can be represented by 32
\ bits.  A file to be checked is treated like a polynomial of degree
\ 8 times the number of bytes.  That is, a 100,000 byte file is a
\ 800,000 degree polynomial.
\
\ If you examine the code for `update-crc-by-a-bit` you can see that
\ it's doing long division the way you learned in third or fourth
\ grade but with binary polynomials as dividend and divisor. `XOR` is
\ subtraction -- and addition.  `CRC-POLYNOMIAL` is the divisor.
\ When you're through with the file the final remainder is the
\ check-sum.
\
\ The coefficients are in reverse order from the arithmetic value.
\ That's the order in which they occur when the file is transmitted.
\ In the polynomial the sign bit represents `1` and `1 AND` represents
\ _x_^31.  `1 RSHIFT` would shift the dividend to the _left_ if you
\ were doing it by hand.
\
\ ----------------------------------------------------------------- 

: Update-CRC-by-a-Bit         ( crc byte -- crc byte )
    >R                            ( crc)( R: byte)
        DUP  1 AND  IF
              1 RSHIFT  CRC-POLYNOMIAL XOR
        ELSE
              1 RSHIFT
        THEN
        R@  1 AND  IF
              CRC-POLYNOMIAL XOR
        THEN
    R>                            ( crc byte)( R: )
    ;

: Update-CRC-by-a-Byte        ( oldcrc byte -- newcrc )
    8 0 DO
        Update-CRC-by-a-Bit
        1 RSHIFT
    LOOP  DROP                    ( newcrc)
    ;

\  Build Crc-Table for every possible byte.

: BUILD-CRC-TABLE             ( -- )
    256 0 DO
        0 I Update-CRC-by-a-Byte  I CELLS CRC-Table +  !
    LOOP
    ;

BUILD-CRC-TABLE

\  Display CRC-Table to see whether it looks OK.

    : PRINT-CRC-TABLE
       CR ." CRC Table:" CR ( ." CREATE CRC-Table "   CR ." HEX ")
       256 CELLS 0 DO    I 5 CELLS MOD 0= IF CR THEN
           I CRC-Table + @ 0
               HEX <# # # # # # # # # #> TYPE 
	       BL EMIT ( ."  , ") DECIMAL
       1 CELLS +LOOP
       CR ( ." DECIMAL ")
    ; 

PRINT-CRC-TABLE  ( uncomment if you want to print the table on include)
FORGET RUN	\ Discard code no longer needed ( everything past CRC-Table)

\  Update CRC by a byte.

: CRC                   ( oldcrc byte -- newcrc )
    OVER XOR  255 AND  CELLS CRC-Table +  @  SWAP  8 RSHIFT  XOR
    ;

\ =================================================================


: .CRC ( crc -- | print the crc value in hex)
	BASE @ >R HEX 0 <# # # # # # # # # #> TYPE R> BASE ! ;

\ Examples:

: CRC32S ( a u -- crc | compute checksum of u bytes at a)
	-1 SWAP 0 ?DO  OVER C@ CRC >R 1+ R>  LOOP INVERT NIP ;

: TEST-CRC
	CR CR
	s" An Arbitrary String" 2DUP TYPE CR
	." crc-32: " CRC32S .CRC ."  should be 6FBEAAE7" CR ;

TEST-CRC

\  End of crc-32.4th


