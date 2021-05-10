\ array-utils0.4th
\
\ Level 0 utilities for working with FSL arrays and matrices
\
\ Copyright (c) 2010 Krishna Myneni, Creative Consulting
\ for Research and Education.
\
\ This code may be re-distributed and used for any 
\ purpose as long as the copyright notice above is 
\ preserved.
\
\  Provides:
\
\   Output:
\
\   d?           Fetch and output a signed double number
\   f?           Fetch and output a float number 
\   print-width  Variable containing the number of elements per 
\                line for printing arrays
\   }iprint      Print integer array
\   }dprint      Print double  array
\   }fprint      Print float   array
\   }}iprint     Print integer matrix
\   }}dprint     Print double  matrix
\   }}fprint     Print float   matrix
\
\   Array Conversions:
\
\   }i>d    Copy integer array to double  array, with conversion
\   }i>f    Copy integer array to float   array, with conversion
\   }d>i    Copy double  array to integer array, with conversion
\   }d>f    Copy double  array to float   array, with conversion
\   }f>d    Copy float   array to double  array, with conversion
\   }f>z    Copy float   array to complex array, with conversion
\
\   Array manipulation:
\
\   }iget    Get integer array elements onto stack
\   }iput    Put integers from stack into integer array
\   }ifill   Fill integer array with integer value
\   }izero   Zero the elements of an integer array
\   }icopy   Copy elements from integer array A to integer array B
\
\   and similarly for corresponding words operating on
\   double and float arrays:  }dx  }fx 
\
\   Matrix manipulation:
\
\   }}irow-get   Get integer matrix row elements onto stack
\   }}icol-get   Get integer matrix column elements onto stack
\   }}iget       Get integer matrix elements onto stack
\   }}irow-put   Put integers from stack into row of integer matrix
\   }}icol-put   Put integers from stack into column of integer matrix
\   }}iput       Put integers from stack into integer matrix
\   }}irow-fill  Fill row of an integer matrix with an integer value
\   }}icol-fill  Fill column of an integer matrix with an integer value
\   }}ifill      Fill integer matrix with an integer value
\   }}izero      Zero the elements of an integer matrix
\   }}irow-copy  Copy row from integer matrix A to row of integer matrix B
\   }}icol-copy  Copy col from integer matrix A to col of integer matrix B
\   }}icopy      Copy elements from integer matrix A to integer matrix B
\
\  and similarly for corresponding words operating on double 
\  and float matrices:  }}dx  }}fx

\   
\   Stack Effects:

\   d?              ( a -- )
\   f?              ( a -- )
\   print-width     ( -- a )
\   }iprint         ( u 'A  -- )
\   }dprint         ( u 'A  -- )
\   }fprint         ( u 'A -- )
\   }}iprint        ( n m 'A -- )
\   }}dprint        ( n m 'A -- )
\   }}fprint        ( n m 'A -- )
\   }i>d            ( 'A 'B u  -- )
\   }i>f            ( 'A 'B u  -- )
\   }d>i            ( 'A 'B u  -- )
\   }d>f            ( 'A 'B u  -- )
\   }f>d            ( 'A 'B u  -- )
\   }f>z            ( 'A 'B u  -- )
\   }iget           ( u 'A  -- n1 n2 ... nu u )
\   }iput           ( n1 n2 ... nu u 'A -- )
\   }ifill          ( n u 'A  -- )
\   }izero          ( u 'A  -- )
\   }icopy          ( 'A 'B u -- )
\   }dget           ( u 'A  -- d1 d2 ... du u )
\   }dput           ( d1 d2 ... du u 'A -- )
\   }dfill          ( d u 'A -- )
\   }dzero          ( u 'A -- )
\   }dcopy          ( 'A 'B u -- )

\   }fget           ( u 'A -- u )  ( F: -- r1 r2 ... ru ) |
\                   ( u 'A -- r1 r2 ... ru u )

\   }fput           ( u 'A -- ) ( F: r1 r2 ... ru -- )  | 
\                   ( r1 r2 ... ru u 'A -- )

\   }ffill          ( u 'A -- )    ( F: r -- )        |
\                   ( r u 'A -- ) 

\   }fzero          ( u 'A -- )
\   }fcopy          ( 'A 'B u -- )
\   }}irow-get      ( u row 'A -- i1 i2 ... iu u )
\   }}icol-get      ( u col 'A -- i1 i2 ... iu u )
\   }}iget          ( n m 'A -- i11 i12 ... inm n m )
\   }}irow-put      ( i1 i2 ... iu u row 'A -- )
\   }}icol-put      ( i1 i2 ... iu u col 'A -- )
\   }}iput          ( i11 i12 ... inm n m 'A -- )
\   }}irow-fill     ( i u row 'A -- )
\   }}icol-fill     ( i u col 'A -- )
\   }}ifill         ( i n m 'A -- )
\   }}izero         ( n m 'A -- )
\   }}irow-copy     ( 'A n1 'B n2 u -- )
\   }}icol-copy     ( 'A m1 'B m2 u -- )
\   }}icopy         ( 'A 'B n m -- )
\   }}drow-get      ( u row 'A -- d1 d2 ... du u )
\   }}dcol-get      ( u col 'A -- d1 d2 ... du u )
\   }}dget          ( n m 'A -- d11 d12 ... dnm n m )
\   }}drow-put      ( d1 d2 ... du u row 'A -- )
\   }}dcol-put      ( d1 d2 ... du u col 'A -- )
\   }}dput          ( d11 d12 ... dnm n m 'A -- )
\   }}drow-fill     ( d u row 'A -- )
\   }}dcol-fill     ( d u col 'A -- )
\   }}dfill         ( d n m 'A -- )
\   }}dzero         ( n m 'A -- )
\   }}drow-copy     ( 'A n1 'B n2 u -- )
\   }}dcol-copy     ( 'A m1 'B m2 u -- )
\   }}dcopy         ( 'A 'B n m -- )

\   }}frow-get      ( u row 'A -- u )  ( F: -- r1 r2 ... ru ) |
\                   ( u row 'A -- r1 r2 ... ru u )

\   }}fcol-get      ( u col 'A -- u )  ( F: -- r1 r2 ... ru ) |
\                   ( u col 'A -- r1 r2 ... ru u )

\   }}fget          ( n m 'A -- n m )  ( F: -- r11 r12 ... rnm ) |
\                   ( n m 'A -- r11 r12 ... rnm n m )

\   }}frow-put      ( u row 'A -- )  ( F: r1 r2 ... ru -- )  |
\                   ( r1 r2 ... ru u row 'A -- )

\   }}fcol-put      ( u col 'A -- )  ( F: r1 r2 ... ru -- )  |
\                   ( r1 r2 ... ru u col 'A -- )

\   }}fput          ( n m 'A -- )  ( F: r11 r12 ... rnm )  |
\                   ( r11 r12 ... rnm n m 'A -- ) 

\   }}frow-fill     ( u row 'A -- )  ( F: r -- )  |
\                   ( r u row 'A -- )

\   }}fcol-fill     ( u col 'A -- )  ( F: r -- )  |
\                   ( r u col 'A -- )

\   }}ffill         ( n m 'A -- )  ( F: r -- )  |
\                   ( r n m 'A -- )
 
\   }}fzero         ( n m 'A -- )
\   }}frow-copy     ( 'A n1 'B n2 u -- )
\   }}fcol-copy     ( 'A m1 'B m2 u -- )
\   }}fcopy         ( 'A 'B n m -- )

\
\ Revisions:
\    2011-09-16  km; use Neal Bridges' anonymous modules.
\    2012-02-19  km; use KM/DNW's modules library.
\    2020-02-15  km; set arr_op in private base words.

BEGIN-MODULE

BASE @
DECIMAL

Public:

VARIABLE print-width      6 print-width !
[undefined] D? [IF]  : D?  2@ D.  ;  [THEN]
[undefined] F? [IF]  : F?  F@ F.  ;  [THEN]

Private:

DEFER arr_op
: integers  ( u1 -- u2 ) INTEGER * ;
: doubles   ( u1 -- u2 ) DOUBLE  * ;

\ Print u elements of an array
: }print ( u addr xt -- )
    IS arr_op
    swap 0 ?do 
      I print-width @ MOD 0= I and IF cr THEN
      dup I } arr_op 
    loop drop ;

: }get ( u 'a xt -- x1 ... xu u )
    IS arr_op
    swap dup >r
    0 ?DO  dup I } swap >r arr_op r>  LOOP  drop r> ;
      
\ Store x1 ... xn into array of size n
: }put  ( x1 ... xu u 'a xt --  )
     IS arr_op
     swap dup 0 ?DO  1- 2dup 2>r } arr_op 2r>  LOOP  
     2drop ;

\ Fill the first u elements of an array with x
: }fillx ( x u 'a xt -- x)
    IS arr_op
    swap 0 ?DO  dup I } swap >r arr_op r>  LOOP  drop ;

\ Zero the first u elements of an array
: }zero ( u 'a xt -- )  IS arr_op over arr_op erase drop ;

\ Copy elements from one array into another
: }copy ( 'src 'dest u xt -- ) IS arr_op
     >r 0 } swap 0 } swap r> arr_op move ;

\ Matrix words

: }}row-get  ( u n 'A xt -- x1 ... xu u )
    IS arr_op
    rot >r swap 
    r@ 0 ?do  2dup I }} -rot 2>r arr_op 2r>  loop
    2drop r> ;

: }}col-get  ( u m 'A xt -- x1 ... xu u )
    IS arr_op
    rot >r swap
    r@ 0 ?do  2dup I swap }} -rot 2>r arr_op 2r>  loop
    2drop r> ;

: }}get  ( ) ;

: }}row-put  ( x1 ... xu u n 'A xt -- )
    IS arr_op
    swap rot 0 ?do  2dup I }} -rot 2>r arr_op 2r>  loop 2drop ;
    
: }}col-put  ( x1 ... xu u m 'A xt -- )
    IS arr_op
    swap rot 0 ?do  2dup I swap }} -rot 2>r arr_op 2r>  loop 
    2drop ;

: }}row-copy ( 'src n1 'dest n2 u xt -- )
     IS arr_op  1 arr_op 
;
 
\ Print n x m elements of a 2-D array (matrix)
: }}print ( n m addr xt -- )
    IS arr_op       
    ROT ROT SWAP 
    0 DO
      DUP 0 DO  OVER J I  }} arr_op  LOOP CR
    LOOP 2DROP ;


Public:

\ Array conversion

: }i>d  ( 'a 'b u -- ) 
    0 ?do  over I } over I } >r @ s>d r> 2!  loop 2drop ;
: }i>f  ( 'a 'b u -- )  
    0 ?do  over I } over I } >r @ s>f r> f!  loop 2drop ;
: }d>i  ( 'a 'b u -- )
    0 ?do  over I } 2@ d>s over I } !  loop 2drop ;
: }d>f  ( 'a 'b u -- )
    0 ?do  over I } over I } >r 2@ d>f r> f!  loop 2drop ;
: }f>d  ( 'a 'b u -- )
    0 ?do  over I } over I } >r f@ f>d r> 2!  loop 2drop ;

 
  
\ INTEGER arrays and matrices

: }iprint  ( u 'a  -- )             ['] ?  }print ;
: }iget    ( u 'a  -- )             ['] @  }get ;
: }iput  ( i1 ... iu u 'a -- )      ['] !  }put ;
: }ifill   ( n u 'a -- )            ['] !  }fillx drop ;
: }izero  ( u 'a -- )               ['] integers }zero ;
: }icopy ( 'src 'dest u -- )        ['] integers }copy ;
: }}irow-get ( u n 'a -- i1...iu u) ['] @  }}row-get ;
: }}icol-get ( u m 'a -- i1...iu u) ['] @  }}col-get ;   
: }}irow-copy ( 'src n1 'dest n2 u -- ) ;
: }}iprint  ( n m 'a -- )           ['] ?  }}print ;
: }}icopy ( 'src 'dest n m -- ) ;


\ Double arrays and matrices

: }dprint  ( u 'a -- )              ['] d?  }print ;
: }dget  ( u 'a -- d1 ... du u )    ['] 2@  }get ;
: }dput  ( d1 ... du u 'a -- )      ['] 2!  }put ;
: }dfill ( d u 'a -- )              ['] 2!  }fillx 2drop ;
: }dzero ( u 'a -- )                ['] doubles }zero ;
: }dcopy ( 'A 'B u -- )             ['] doubles }copy ;
: }}drow-get ( u n 'a -- d1...du u) ['] 2@  }}row-get ;
: }}dcol-get ( u m 'a -- d1...du u) ['] 2@  }}col-get ;
: }}drow-copy ( 'a n1 'b n2 u -- ) ;
: }}dprint ( n m 'A -- )            ['] d?  }}print ;
: }}dcopy ( 'src 'dest n m -- ) ;

\ FLOAT arrays and matrices

: }fprint ( n addr -- )             ['] F?  }print ;
: }fget  ( u 'a -- r1 ... ru u )    ['] F@  }get ;
: }fput  ( r1 ... r_n n 'a -- )     ['] F!  }put ;
: }ffill  ( r u 'a -- )             ['] F!  }fillx fdrop ;
: }fzero ( n 'a -- )                ['] floats  }zero ;
: }fcopy ( 'src 'dest n -- )        ['] floats  }copy ;
: }}frow-get ( u n 'a -- r1...ru u) ['] F@  }}row-get ;
: }}fcol-get ( u m 'a -- r1...ru u) ['] F@  }}col-get ;
: }}frow-copy ( 'a n1 'b n2 u -- ) ;
: }}fprint ( n m 'a -- )            ['] F?  }}print ;

\ Copy n×m elements of 2-D array src to dest
: }}fcopy ( 'src 'dest n m  -- ) 
     SWAP 0 DO
       DUP 0 DO
         2 PICK J I  }} F@
         3 PICK J I  }} F!
       LOOP
     LOOP
     DROP 2DROP ;

: }}frow-put  ( r1 ... ru  u n 'A -- )
   swap 0 }} over 1- FLOATS + swap 
   0 DO dup >r F! r> [ 1 FLOATS ] literal - LOOP drop ;

\ Store elements r11 ... r_nm from stack into nxm matrix A 
: }}fput ( r11 r12 ... r_nm  n m 'A -- | )
      -ROT 2DUP * >R 1- SWAP 1- SWAP }} R> 
      0 ?DO  DUP >R F! R> float -  LOOP  drop ;

BASE !
END-MODULE

