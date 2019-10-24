\ catch-throw-ex.4th
\
\ Example of exception handling in Forth using
\   THROW and CATCH. See DPANS94, sec. A.9.6.1.2275
\

include ans-words

: could-fail ( -- char )
    KEY DUP [CHAR] Q =
    IF 1 THROW THEN
;

: do-it ( a b -- c) 2DROP could-fail ;

: try-it ( -- )
    1 2 ['] do-it CATCH IF
       2DROP ." There was an exception" CR
    ELSE
      ." The character was " EMIT CR
    THEN
;

: retry-it ( -- )
    BEGIN
      1 2 ['] do-it CATCH
    WHILE
      2DROP ." Exception, keep trying" CR
    REPEAT
    ." The character was " EMIT CR
;
