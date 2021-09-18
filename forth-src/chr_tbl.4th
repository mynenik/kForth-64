\ Automatic character encoding tables

\ ---------------------------------------------------
\     (c) Copyright 2001  Julian V. Noble.          \
\       Permission is granted by the author to      \
\       use this software for any application pro-  \
\       vided this copyright notice is preserved.   \
\ ---------------------------------------------------

\ This is an ANS Forth program using the CORE wordset

\ Adapted for kForth, 2003-3-10  km
\ Requires ans-words.4th (for defn of CHARS)

: char_table:   ( #chars "table_name" -- )
    CREATE   DUP  CHARS  allot?   SWAP  0 FILL
    DOES>  ( char -- code[c])
           CHARS +   C@  ;

: install      (  adr char.n char.1 -- )   \ fast fill
    SWAP 1+ SWAP   DO  2DUP  I  CHARS +  C!  LOOP  2DROP ;
\ end automatic conversion tables


