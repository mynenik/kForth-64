\ jd.4th
\
\ Julian Day and Calendar calculator by Wil Baden

\ The following definitions are needed for kForth -- K. Myneni, 9-13-2001
\ -----------------------------------------
: third 2 pick ;
: space 1 spaces ;
: 3drop 2drop drop ;
\ -----------------------------------------

( 
In gathering old stuff, I came across the following, written long ago,
which I thought would be of interest.

The Julian Day is the number of days since 1 January 4713 BC.
)

\  Julian Day

: JD                ( dd mm yyyy -- julian-day )
    >R                            ( dd mm)( R: yyyy)
        3 -  DUP 0< IF  12 +  R> 1- >R  THEN
        306 *  5 +  10 /  +       ( day)
        R@  1461 4 */  +  1721116 +
           DUP 2299169 > IF
               3 +  R@ 100 / -  R@ 400 / +
           THEN
    R> DROP                               ( R: )
;

: BC 1- NEGATE ;

( 
With this you can print a calendar, good for any month except
October 1582.
) 


: CAL  ( dd mm yyyy -- )
    1 third 1+ third JD >R      ( R: 1/mm+1/yyyy)
    1 third third JD >R         ( R: 1/mm+1/yyyy 1/mm/yyyy)
    JD R@ 1-                ( dd/mm/yyyy 0/mm/yyyy)
    CR  R@ 1+ 7 MOD  4 *  SPACES
    2R> DO
        I over -  3 .R
        over I = IF ." *" ELSE SPACE THEN
        I 2 +  7 MOD 0= IF  CR  THEN
    LOOP 2DROP ;

: TODAY   ( -- )
    TIME&DATE CAL  3DROP ;


\ Here are some test values.

\ 1  1 4713 BC JD . ( 0 )
\ 31 12 1 BC JD . ( 1721422 )
\ 1  1    1 JD . ( 1721423 )
\ 5 10 1582 JD . ( 2299160 )
\ 15 10 1582 JD . ( 2299161 )
\ 1  1 1933 JD . ( 2427074 Merriam-Webster dictionary )
\ 1  1 1965 JD . ( 2438762 Random House dictionary )
\ 23  5 1968 JD . ( 2440000 Winning Ways )



(
--  
Wil Baden    Costa Mesa, California   Per neilbawd@earthlink.net
)


