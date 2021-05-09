\ factorial           compute the factorial of a positive integer

\ Forth Scientific Library Algorithm #14

\ Note: this word takes a single precision integer and returns a
\       double precision integer
\
\ This is an ANS Forth program requiring:
\      1. The word 'SD*' is needed for single precision by double precision
\         integer multiply (double precision result).
\         : SD*   ( multiplicand  multiplier_double  -- product_double  )
\                 2 PICK * >R   UM*   R> +
\         ;
\
\      2. The words 'DOUBLE' and 'ARRAY' to create a
\         1-dimensional double precision integer array, for the test code.

\ Note because the factorial function grows rapidly, this function has
\ a range of validity that is dependent upon the number of bits used to
\ represent numbers.  For a 32 bit system, input parameters in the range
\ 0..20 are valid.  The small range of validity makes this function
\ practical to implement in tabular form for some applications.

\     (c) Copyright 1994  Everett F. Carter.     Permission is granted
\     by the author to use this software for any application provided
\     this copyright notice is preserved.

\ Revisions:
\    2005-01-23  cgm;  changed ?TEST-CODE to TEST-CODE?
\    2007-11-29  km;   added automated tests and base handling

CR .( FACTORIAL         V1.1           18 October 1994   EFC )
BASE @ DECIMAL

: factorial ( n -- d! )
        1 S>D ROT           \ put a double 1 on stack under parameter

        ?DUP IF
                1 SWAP DO I ROT ROT SD* -1 +LOOP
             THEN
;

BASE !

TEST-CODE? [IF]     \ test code =============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
BASE @ DECIMAL

CR
TESTING FACTORIAL
t{  0 factorial  ->         1  s>d  }t 
t{  1 factorial  ->         1  s>d  }t
t{  2 factorial  ->         2  s>d  }t
t{  3 factorial  ->         6  s>d  }t
t{  4 factorial  ->        24  s>d  }t
t{  5 factorial  ->       120  s>d  }t
t{  6 factorial  ->       720  s>d  }t
t{  7 factorial  ->      5040  s>d  }t
t{  8 factorial  ->     40320e f>d  }t
t{  9 factorial  ->    362880e f>d  }t
t{ 10 factorial  ->   3628800e f>d  }t
t{ 11 factorial  ->  39916800e f>d  }t
t{ 12 factorial  -> 479001600e f>d  }t

BASE !
[THEN]
