\ zmatrix.4th
\
\ Complex matrix words for FSL style complex matrices
\
\ Copyright (c) 2002--2019 Krishna Myneni
\ Provided under the GNU General Public License
\
\ Glossary:
\ 
\   ZMATRIX    ( nrows ncols "name" -- )  create complex matrix
\   }}ZPUT     ( z_1 ... z_nm n m a -- )  initialize matrix
\   }}ZPRINT   ( nrows a -- )             print matrix
\   }}ZZERO    ( nrows a -- )             zero all elements of matrix
\   }}ZCOPY    ( nrows a1 a2 -- ) copy all elements of matrix: a1->a2
\   }}ZROW@    ( i a -- zrc )        fetch row i of matrix onto stack
\   }}ZCOL@    ( nrows i a -- zrc )  fetch column i of matrix onto stack
\   }}ZROW!    ( zrc i a -- )        store zrc to row i of matrix 
\   }}ZCOL!    ( zrc nrows i a -- )  store zrc to column i of matrix
\   }}ZNEGATE  ( nrows a -- )        negate all elements of matrix
\   }}ZCONJG   ( nrows a -- )        conjugate all elements of matrix 
\   }}ZTRANSPOSE ( nrows a1 a2 -- )  a2 is transpose of matrix a1  
\   }}ZSWAP-ROWS  
\   }}ZSWAP-COLS
\   }}F*Z  ( r nrows a -- )      multiply zmatrix by real scalar, r
\   }}Z*Z  ( z nrows a -- )      multiply zmatrix by complex scalar, z
\   }}Z+   ( nrows a1 a2 a3 -- ) element by element addition of matrices
\   }}ZDOT-PRODUCT ( i a1 j a2 -- z ) dot product of row i of a1 with
\                                     col j of a2
\   }}ZMUL  ( nrows1 a1 nrows2 a2 a3 -- ) a3 is matrix mult of a1, a2
\   }}ZKRON ( nrows1 a1 nrows2 a2 a3 -- ) Kronecker outer product
\ To implement:
\
\   }}ZCOPY-ROW ( i a1 j a2 -- )  copy row i of matrix a1 to row j of a2
\   }}ZCOPY-COL ( nrows i a1 j a2 -- ) copy col i of a1 to col j of a2
\   }}Z^T  ( nrows a -- )         in-place transpose of matrix
\   }}Z-   ( nrows a1 a2 a3 -- )  element by element subtraction
\   }}Z*   ( nrows a1 a2 a3 -- )  element by element multiplication
\ 
\ Requires:
\   fsl-util.4th
\   complex.4th
\
\ Revisions:
\   2002-04-05  created  km
\   2003-02-18  added matrix arithmetic  km
\   2011-04-25  define constants Z=0, Z=1, Z=I, which must have
\               been removed from complex.4th
\   2019-10-31  revised for consistency with FSL matrices  km
\   2019-11-05  added Kronecker outer product, }}ZKRON   km
\   2019-11-06  fixed }}ZTRANSPOSE  km

[UNDEFINED] zfloats [IF]
: zfloats ( u -- ubytes ) 2* dfloats ;
[THEN]
[UNDEFINED] zfloat+ [IF]
: zfloat+ ( a1 -- a2 ) [ 1 zfloats ] literal + ;
[THEN]
[UNDEFINED] zfloat- [IF]
: zfloat- ( a1 -- a2 ) [ 1 zfloats ] literal - ;
[THEN]
[UNDEFINED] }}ncols [IF]
: }}ncols ( a -- ncols ) 2 cells - @ ;
[THEN]
[UNDEFINED] }}ncols= [IF]
: }}ncols= ( a1 a2 -- flag ) }}ncols swap }}ncols = ;
[THEN]  

BEGIN-MODULE
BASE @
DECIMAL

Private:
variable zm_offset
: set-offset ( a -- ) }}ncols zfloats zm_offset ! ;
: offset+ ( a1 -- a2 ) zm_offset @ + ;
: offset- ( a1 -- a2 ) zm_offset @ - ;

Public:

0e 0e zconstant z=0
1e 0e zconstant z=1
0e 1e zconstant z=i

: zmatrix ( nrows ncols "name" -- )
	complex matrix ;

: }}zput ( z_1 ... z_nm n m a -- | initialize a zmatrix from stack)
	dup >r }}ncols over <> ABORT" Matrix size error!"
	* r> 
	over 1- zfloats + \ -- z1 ... zmn nelem a2
	swap 0 ?DO  dup >r z! r> zfloat-  LOOP drop ;

: }}zprint ( nrows a -- | print zmatrix )
	tuck }}ncols swap  \ -- a ncols nrows
	0 ?DO  dup 
	  0 ?DO
	    over J I }} z@ z. 9 emit 
	  LOOP  cr
	LOOP  2drop ;

: }}zzero ( nrows a -- | zero all entries in zmatrix )
	tuck }}ncols * zfloats erase ;

: }}zcopy ( nrows a1 a2 -- | copy zmatrix a1 to a2)
	2dup }}ncols= invert ABORT" Matrix size error!"
	>r dup >r }}ncols * zfloats  
	r> r> rot move ;

: }}z= ( nrows a1 a2 -- flag | check equality of two zmatrices )
	2dup }}ncols= invert IF 2drop drop false EXIT THEN
	2dup 2>r drop }}ncols *
	true swap 2r>
	rot 0 DO  
	  2dup 2>r >r z@ r> z@ z= and
	  2r> zfloat+ swap zfloat+ swap
	LOOP  2drop ; 

: }}zrow@ ( i a -- zrc | fetch row i of zmatrix a )
	tuck }}ncols >r 0 }}   \ -- a
	r@ 0 ?DO  dup >r z@ r> zfloat+  LOOP 
	drop r> ;

: }}zcol@ ( nrows i a -- zrc | fetch column i of zmatrix a )
	tuck set-offset      \ -- nrows a i
	0 swap }} swap dup >r 
	0 ?DO  dup >r z@ r> offset+  LOOP
	drop r> ;

: }}zrow! ( zrc i a -- | store zrc as row i of zmatrix a )
	tuck }}ncols >r r@ 1- }} 
	over r> <> ABORT" Matrix size error!"
	swap 0 ?DO  dup >r z! r> zfloat-  LOOP
	drop ; 

: }}zcol! ( zrc nrows i a -- | store zrc as column i of zmatrix a)
	tuck set-offset 
	2 pick 1- swap }} >r    \ -- zrc nrows  
	over <> ABORT" Matrix size error!"  \ -- zrc
	r> swap 0 ?DO  dup >r z! r> offset-  LOOP
	drop ;

: }}znegate ( nrows a -- | a_ij = -a_ij )
	tuck }}ncols *
	0 ?DO  dup >r z@ znegate r@ z! r> zfloat+  LOOP
	drop ;


: }}zconjg ( nrows a -- | conjugate the zmatrix)
	tuck }}ncols *
	0 ?DO  dup >r z@ conjg r@ z! r> zfloat+  LOOP
	drop ;

Private:
variable zm_1
variable zm_2
variable zm_3
variable zm_ncols
variable zm_nrows

Public:
: }}ztranspose ( nrows a1 a2 -- | a2 will be the transpose of a1)
	2 pick over }}ncols = invert Abort" Matrix size error!"
	zm_2 ! dup zm_1 ! }}ncols zm_ncols !
	0 ?DO 
	  I zm_1 a@ }}zrow@  
	  zm_ncols @ I zm_2 a@ }}zcol!
	LOOP ;

: }}zswap-rows ( i j a -- | interchange rows i and j for zmatrix a )
	tuck 2dup 2>r  \ -- i a j a 
	2over 2>r      \ -- i a j a
	2>r }}zrow@ 2r> }}zrow@
	2r> }}zrow! 2r> }}zrow! ;

: }}zswap-cols ( nrows i j a -- | interchange columns i and j for a )
	3 pick zm_nrows !
	tuck 2dup 2>r
	2over 2>r  2>r }}zcol@ zm_nrows @ 2r> }}zcol@
	zm_nrows @ 2r> }}zcol! zm_nrows @ 2r> }}zcol! ;


Private:
fvariable fscale

Public:
: }}f*z ( r nrows a -- | multiply zmatrix with real constant r)
	tuck }}ncols * 2>r fscale f!
	2r> 0 ?DO 
	  dup >r z@ 
	  fscale f@ z*f r@ z! 
	  r> zfloat+  
	LOOP  drop ;    

: }}z*z ( z nrows a -- | multiply zmatrix with complex constant z) 
	tuck }}ncols *
	0 ?DO
	  dup >r z@ zover z* r@ z!
	  r> zfloat+
	LOOP  drop zdrop ;  

: }}z+ ( nrows a1 a2 a3 -- | add element by element, result in a3)
	zm_3 ! 
	2dup }}ncols=  over zm_3 a@ }}ncols= and
	invert Abort" Matrices are of unequal size!"
	2dup 2>r drop }}ncols * 2r>
	rot 0 ?DO
	  2dup 2>r 
	  >r z@ r> z@ z+ zm_3 a@ z!
	  2r> zfloat+ swap zfloat+ swap
	  complex zm_3 +!
	LOOP
	2drop ;

Private:
2variable zm_rc

Public:

\ Compute dot product of row i of a1 with column j of a2.
\ Size compatibility is not checked -- this is up to the user.
: }}zdot-product ( i a1 j a2 -- z )
	zm_2 ! swap zm_1 ! zm_rc 2!
	z=0
	zm_1 a@ }}ncols 0 ?DO  \ loop over columns of a1
	  zm_1 a@   zm_rc 2@ drop I }} z@
	  zm_2 a@ I zm_rc 2@ nip    }} z@
	  z* z+
	LOOP ;


Private:
variable zm_1
variable zm_2

Public:
\ Multiply zmatrices a1 and a2 to produce nrows1 x ncols2 zmatrix, a3.
\ The matrix size compatibility check performed is:
\   (ncols1 = nrows2)  AND  (ncols2 = ncols3)

: }}zmul ( nrows1 a1 nrows2 a2 a3 -- | a3 = matrix multiplication of a1 a2)
	2dup }}ncols= >r
	zm_3 ! zm_2 ! 
	over }}ncols over = r> and
	invert Abort" Incompatible sizes for matrices!" 
	\ -- nrows1 a1 nrows2 
	drop zm_1 ! zm_2 a@ }}ncols swap  \ ncols2 nrows1
	0 ?DO
	  dup 0 ?DO
	    J zm_1 a@ I zm_2 a@ }}zdot-product
	    zm_3 a@ J I }} z!
	  LOOP
	LOOP
	drop ;

Private:
variable zm_1
variable zm_2
variable zm_3
variable nrows1
variable ncols1
variable nrows2
variable ncols2
variable nrows3
variable ncols3
variable RowOffset
variable ColOffset

Public:

: }}zkron ( nrows1 a1 nrows2 a2 a3 -- )
    zm_3 ! zm_2 ! >r zm_1 ! r>  \ -- nrows1 nrows2
    2dup nrows2 ! nrows1 ! 
    * nrows3 !
    zm_1 a@ }}ncols dup ncols1 ! 
    zm_2 a@ }}ncols dup ncols2 !
    * dup ncols3 !
    zm_3 a@ }}ncols <> Abort" Matrix size error!"
    nrows1 @ 0 ?DO
      ncols1 @ 0 ?DO
        J nrows2 @ * RowOffset !  
        I ncols2 @ * ColOffset !
        zm_1 a@ J I }} z@
        nrows2 @ 0 ?DO
          ncols2 @ 0 ?DO
            zdup zm_2 a@ J I }} z@ z*
            zm_3 a@  RowOffset @ J +  ColOffset @ I + }} z!
          LOOP
        LOOP
        zdrop
      LOOP
    LOOP ;

BASE !
END-MODULE

TEST-CODE? [IF]     \ test code =============================================
[undefined] T{      [IF]  include ttester.4th  [THEN]
BASE @ DECIMAL

1e-15 rel-near F!
1e-15 abs-near F!
set-near

: z}t rr}t ;
: zz}t rrrr}t ;

cr
TESTING ZMATRIX  }}NCOLS  }}ZPUT  }}Z=  }}ZZERO  }}ZCOPY 
t{ 2 2 zmatrix m1{{  ->  }t
t{ m1{{ }}ncols  ->  2 }t

t{ z=1  z=i znegate  z=i  z=1 znegate  2 2 m1{{ }}zput -> }t
t{ m1{{ 0 0 }} z@  ->  z=1  z}t
t{ m1{{ 0 1 }} z@  ->  z=i znegate z}t
t{ m1{{ 1 0 }} z@  ->  z=i  z}t
t{ m1{{ 1 1 }} z@  ->  z=1 znegate z}t

t{ 2 2 zmatrix m2{{  ->  }t
t{ z=1  z=i znegate  z=i  z=1 znegate  2 2 m2{{ }}zput -> }t
t{ 2 m1{{ m2{{ }}z=  ->  true }t
t{ z=0 m2{{ 0 0 }} z!  ->  }t
t{ 2 m1{{ m2{{ }}z=  ->  false }t

t{ 2 m2{{ }}zzero  -> }t
t{ m2{{ 0 0 }} z@  ->  z=0 z}t
t{ m2{{ 0 1 }} z@  ->  z=0 z}t
t{ m2{{ 1 0 }} z@  ->  z=0 z}t
t{ m2{{ 1 1 }} z@  ->  z=0 z}t

t{ 2 m1{{ m2{{ }}zcopy -> }t
t{ 2 m1{{ m2{{ }}z=  ->  true }t

TESTING }}ZROW@ }}ZCOL@ }}ZROW! }}ZCOL!
t{ 0 m1{{ }}zrow@ drop ->  z=1 z=i znegate  zz}t
t{ 2 1 m1{{ }}zcol@ drop ->  z=i znegate z=1 znegate zz}t 

t{ 0 m1{{ }}zrow@  1 m2{{ }}zrow! ->  }t
t{ m2{{ 1 0 }} z@  m1{{ 0 0 }} z@ z=  ->  true }t
t{ m2{{ 1 1 }} z@  m1{{ 0 1 }} z@ z=  ->  true }t

t{ 2 m2{{ }}zzero  ->  }t
t{ 0 m1{{ }}zrow@  2 1 m2{{ }}zcol! -> }t
t{ m2{{ 0 1 }} z@  m1{{ 0 0 }} z@ z=  ->  true }t
t{ m2{{ 1 1 }} z@  m1{{ 0 1 }} z@ z=  ->  true }t

TESTING }}ZTRANSPOSE  }}ZSWAP-ROWS  }}ZSWAP-COLS
t{ 2 m2{{ }}zzero  ->  }t
t{ 2 m1{{ m2{{ }}ztranspose  ->  }t
t{ m2{{ 0 0 }} z@  m1{{ 0 0 }} z@ z=  ->  true }t
t{ m2{{ 1 1 }} z@  m1{{ 1 1 }} z@ z=  ->  true }t
t{ m2{{ 0 1 }} z@  m1{{ 1 0 }} z@ z=  ->  true }t
t{ m2{{ 1 0 }} z@  m1{{ 0 1 }} z@ z=  ->  true }t

t{ 2 m1{{ m2{{ }}zcopy  ->  }t
t{ 0 1 m2{{ }}zswap-rows  ->  }t
t{ m2{{ 0 0 }} z@  m1{{ 1 0 }} z@ z=  ->  true }t
t{ m2{{ 0 1 }} z@  m1{{ 1 1 }} z@ z=  ->  true }t
t{ m2{{ 1 0 }} z@  m1{{ 0 0 }} z@ z=  ->  true }t
t{ m2{{ 1 1 }} z@  m1{{ 0 1 }} z@ z=  ->  true }t  

t{ 2 m1{{ m2{{ }}zcopy  ->  }t
t{ 2 0 1 m2{{ }}zswap-cols  ->  }t
t{ m2{{ 0 0 }} z@  m1{{ 0 1 }} z@ z=  ->  true }t
t{ m2{{ 1 0 }} z@  m1{{ 1 1 }} z@ z=  ->  true }t
t{ m2{{ 0 1 }} z@  m1{{ 0 0 }} z@ z=  ->  true }t
t{ m2{{ 1 1 }} z@  m1{{ 1 0 }} z@ z=  ->  true }t  

TESTING }}ZNEGATE  }}ZCONJ  }}F*Z  }}Z*Z
t{ 2 m1{{ m2{{ }}zcopy  ->  }t
t{ 2 m2{{ }}znegate  ->  }t
t{ m2{{ 0 0 }} z@ m1{{ 0 0 }} z@ znegate z=  ->  true }t
t{ m2{{ 0 1 }} z@ m1{{ 0 1 }} z@ znegate z=  ->  true }t
t{ m2{{ 1 0 }} z@ m1{{ 1 0 }} z@ znegate z=  ->  true }t
t{ m2{{ 1 1 }} z@ m1{{ 1 1 }} z@ znegate z=  ->  true }t

t{ 2 m1{{ m2{{ }}zcopy  ->  }t
t{ 2 m2{{ }}zconjg  ->  }t
t{ m1{{ 0 0 }} z@ m2{{ 0 0 }} z@ conjg z=  ->  true }t
t{ m1{{ 0 1 }} z@ m2{{ 0 1 }} z@ conjg z=  ->  true }t
t{ m1{{ 1 0 }} z@ m2{{ 1 0 }} z@ conjg z=  ->  true }t
t{ m1{{ 1 1 }} z@ m2{{ 1 1 }} z@ conjg z=  ->  true }t

t{ 2 m1{{ m2{{ }}zcopy  ->  }t
t{ -1e0 2 m2{{ }}f*z  ->  }t
t{ m2{{ 0 0 }} z@ m1{{ 0 0 }} z@ znegate z=  ->  true }t
t{ m2{{ 0 1 }} z@ m1{{ 0 1 }} z@ znegate z=  ->  true }t
t{ m2{{ 1 0 }} z@ m1{{ 1 0 }} z@ znegate z=  ->  true }t
t{ m2{{ 1 1 }} z@ m1{{ 1 1 }} z@ znegate z=  ->  true }t

t{ 2 m1{{ m2{{ }}zcopy  ->  }t
t{ z=i 2 m2{{ }}z*z  ->  }t
t{ m2{{ 0 0 }} z@ m1{{ 0 0 }} z@ z=i z* z=  ->  true }t
t{ m2{{ 0 1 }} z@ m1{{ 0 1 }} z@ z=i z* z=  ->  true }t
t{ m2{{ 1 0 }} z@ m1{{ 1 0 }} z@ z=i z* z=  ->  true }t
t{ m2{{ 1 1 }} z@ m1{{ 1 1 }} z@ z=i z* z=  ->  true }t

TESTING }}Z+ }}ZDOT-PRODUCT  }}ZMUL 
t{ 2 2 zmatrix m3{{  ->  }t
t{ z=1 z=0 z=0 z=1 znegate 2 2 m2{{ }}zput  ->  }t
t{ z=0 z=i znegate z=i z=0 2 2 m3{{ }}zput  ->  }t
t{ 2 m2{{ m3{{ m3{{ }}z+  ->  }t
t{ 2 m1{{ m3{{ }}z=  -> true  }t

t{ 0 m1{{ 1 m1{{ }}zdot-product  ->  z=0  z}t
t{ 1 m1{{ 1 m1{{ }}zdot-product  ->  z=1 2e z*f  z}t

t{ 2 m1{{ 2 m1{{ m3{{ }}zmul  ->  }t
t{ m3{{ 0 0 }} z@  ->  2e 0e  z}t
t{ m3{{ 0 1 }} z@  ->  z=0    z}t
t{ m3{{ 1 0 }} z@  ->  z=0    z}t
t{ m3{{ 1 1 }} z@  ->  2e 0e  z}t

BASE !
[THEN]

