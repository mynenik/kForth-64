\ rational.4th
\
\ Brute force search, optimized to search only within integer bounds
\ surrounding target.
\
\ Requires:
\   ans-words.4th ( for kForth )
\
\ From Rosetta code:
\ https://rosettacode.org/wiki/Convert_decimal_number_to_rational#Forth
\
\ Examples:
\
\  1.618033988e 100 RealToRational  swap . . 144 89 
\  3.14159e 1000 RealToRational     swap . . 355 113
\  2.71828e 1000 RealToRational     swap . . 1264 465
\  0.9054054e 100 RealToRational    swap . . 67  74

fvariable besterror
0 value numtor
0 value denom
0 value realscale
false value neg?

[undefined] ftrunc>s [IF]
: ftrunc>s ( r -- s ) ftrunc f>d d>s ; 
[THEN]

: RationalError ( |r| num den -- rerror ) >r s>f r> s>f f/ f- fabs ;

: RealToRational  ( r den_limit -- numerator denominator )
    0 to numtor  1 to denom
    9999999e besterror f!        \ very large error that will surely
				 \ be improved upon

    >r                           \ r -- 
    fdup f0< to neg?             \ save sign for later
    fabs              
 
\ realscale helps set integer bounds around target 
    fdup ftrunc>s 1+ to realscale 

\ search through possible denominators ( 1 to denlimit) 
    r> 1+ 1 ?DO
      \ |r| -- 
      \ search through numerator within integer limits bounding
      \ the real, e.g. for 3.1419e search only between 3 and 4     
      I realscale *  I realscale 1- *  ?DO     
            fdup I J RationalError
            fdup besterror f@ f< IF
                besterror f! 
                I to numtor J to denom
	    ELSE fdrop  
            THEN
        LOOP
    LOOP  
    fdrop

    numtor neg? IF negate THEN denom
;

