\ array-utils1.4th
\
\ Level 1 utilities for working with FSL arrays and matrices
\
\ Copyright (c) 2010 Krishna Myneni
\
\ This code may be re-distributed and used for any 
\ purpose as long as the copyright notice above is 
\ preserved.
\
\  Provides:
\
\  Array arithmetic:
\
\   }imin    Return minimum of elements in signed integer array
\   }imax    Return maximum of elements in signed integer array
\   }iscale  Multiply elements of integer array by integer scale factor
\
\   and similarly for corresponding words operating on
\   double and float arrays:  }dx  }fx 
\
\  Matrix arithmetic:
\
\   }}irow-min   Return minimum value of a row in integer matrix
\   }}icol-min   Return minimum value of a col in integer matrix
\   }}imin       Return minimum value in integer matrix
\   }}irow-max   Return maximum value of a row in integer matrix
\   }}icol-max   Return maximum value of a col in integer matrix
\   }}imax       Return maximum value in integer matrix
\   }}irow-scale Multiply row of integer matrix by integer scale factor
\   }}icol-scale Mulitply col of integer matrix by integer scale factor
\   }}iscale     Multiply elements of integer matrix by integer scale factor
\
\  and similarly for corresponding words operating on double 
\  and float matrices:  }}dx  }}fx
\
\   
\   Stack Diagrams:
\
\   Array arithmetic:
\
\   }imin           ( u 'A -- min )     \ u <= length('A); 'A = name of array

\   }imax           ( u 'A -- max )

\   }iscale         ( nscale u 'A -- )

\   }dmin           ( u 'A  -- dmin )

\   }dmax           ( u 'A  -- dmax )

\   }dscale         ( nscale u 'A -- )  \ nscale is a signed *single length* integer

\   }fmin           ( u 'A -- )    ( F: -- rmin )       |
\                   ( u 'A -- rmin )

\   }fmax           ( u 'A -- )    ( F: -- rmax )       |
\                   ( u 'A -- rmax )

\   }fscale         ( u 'A -- )    ( F: rscale -- )       |  
\                   ( rscale u 'A -- )

\   Matrix arithmetic:

\   }}irow-min      ( u row 'A -- min )

\   }}icol-min      ( u col 'A -- min )

\   }}imin          ( n m 'A -- min )

\   }}irow-max      ( u row 'A -- max )

\   }}icol-max      ( u col 'A -- max )

\   }}imax          ( n m 'A -- max )

\   }}iscale        ( s n m 'A -- )

\   }}drow-min      ( u row 'A -- d )

\   }}dcol-min      ( u col 'A -- d )

\   }}dmin          ( n m 'A -- d )
 
\   }}drow -max     ( u row 'A -- d )

\   }}dcol-max      ( u col 'A -- d )

\   }}dmax          ( n m 'A -- d )

\   }}dscale        ( nscale n m 'A -- )

\   }}frow-min      ( u row 'A -- )  ( F: -- r )  |
\                   ( u row 'A -- r )

\   }}fcol-min      ( u col 'A -- )  ( F: -- r )  |
\                   ( u col 'A -- r )

\   }}fmin          ( n m 'A -- )  ( F: -- r )   |
\                   ( n m 'A -- r )

\   }}frow-max      ( u row 'A -- )  ( F: -- r )  |
\                   ( u row 'A -- r )

\   }}fcol-max      ( u col 'A -- )  ( F: -- r )  |
\                   ( u col 'A -- r )

\   }}fmax          ( n m 'A -- )  ( F: -- r )   |
\                   ( n m 'A -- r )

\   }}fscale        ( n m 'A -- )  ( F: rscale -- )  |
\                   ( rscale n m 'A -- )

\ Revisions:
\    2011-09-16  km; use Neal Bridges' anonymous modules.
\    2012-02-19  km; use KM/DNW's modules library.
\    2017-04-20  km; implemented }IMIN  }IMAX  }ISCALE 
\                    }DMIN  }DMAX  }DSCALE.

BEGIN-MODULE

BASE @
DECIMAL

0 ptr temp{

Public:

: }imin   ( u 'a -- min )
    to temp{ >R temp{ 0 } @ R> 1 ?DO  temp{ I } @  MIN  LOOP ;

: }imax   ( u 'a -- max )
    to temp{ >R temp{ 0 } @ R> 1 ?DO  temp{ I } @  MAX  LOOP ;

: }iscale ( nscale u 'a -- )
    0 } swap 0 ?DO >R dup R@ @ *  r@ !  R> CELL+  LOOP  2drop ;

: }dmin   ( u 'a -- dmin )
    to temp{ >R temp{ 0 } 2@ R> 1 ?DO  temp{ I } 2@  DMIN  LOOP ;

: }dmax   ( u 'a -- dmax )
    to temp{ >R temp{ 0 } 2@ R> 1 ?DO  temp{ I } 2@  DMAX  LOOP ;

: }dscale ( dscale u 'a -- )
    0 } swap 0 ?DO >R dup R@ 2@ rot ds* drop R@ 2!  R> 2 CELLS +  LOOP drop 2drop ;

: }fmin ( n 'a -- rmin | return minimum of elements in array of size n )
     to temp{ >R temp{ 0 } F@ R> 1 ?DO  temp{ I } F@  FMIN  LOOP ;

: }fmax ( n 'a -- rmax | return maximum of elements in array of size n )
     to temp{ >R temp{ 0 } F@ R> 1 ?DO  temp{ I } F@  FMAX  LOOP ;   

: }fscale ( rscale n 'a -- | Multiply first n elements of an array by real )
     0 } swap 0 ?DO >r fdup r@ F@ F*  r@ F!  r> FLOAT +  LOOP  drop fdrop ;

BASE !
END-MODULE

