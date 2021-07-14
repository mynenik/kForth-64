\ struct.4th
\
\ data structures (like C structs)  by Anton Ertl, circa 1989,
\   adapted for kForth by K. Myneni, 2003-2-16
\
\ This file is in the public domain. NO WARRANTY.
\
\ Usage:
\
\ Example of defining a structure:
\
\	struct
\	  cell% field x
\	  cell% field y
\	end-struct point%
\
\ Creating an instance of, and initializing the above structure:
\
\	create p1 point% %allot drop
\	 3 p1 x !
\	12 p1 y !
\
\ Accessing the members of the structure:
\
\	p1 x	returns the address of member x of p1
\
\ Determining the size of the structure:
\
\	point% %size .
\
\ Determining the alignment of the structure:
\
\	point% %alignment .
\
\ For more information regarding this structures package, see
\
\	http://mips.complang.tuwien.ac.at/forth/objects/structs.html
\
\
\ =======  kForth requires =======================
\ include ans-words  ( commented out here, but include in main program file)
\ ================================================

: naligned ( addr1 n -- addr2 )
    \ addr2 is the aligned version of addr1 wrt the alignment size n
    1- tuck +  swap invert and ;

: nalign naligned ; \ old name, obsolete

: dofield ( -- )
     does> ( name execution: addr1 -- addr2 )
     @ + ;

: dozerofield ( -- )
    immediate
    does> ( name execution: -- )
      drop ;

: create-field ( align1 offset1 align size "name" --  align2 offset2 )
    create swap rot over nalign dup 1 cells allot? ! ( ,) ( align1 size align offset )
    rot + >r nalign r> ;

: field ( align1 offset1 align size "name" --  align2 offset2 )
    \ name execution: addr1 -- addr2
    2 pick >r \ this uglyness is just for optimizing with dozerofield
    create-field
    r> if \ offset<>0
	dofield
    else
	dozerofield
    then ;

: end-struct ( align size "name" -- )
    over nalign \ pad size to full alignment
    2constant ;

\ an empty struct
1 chars 0 end-struct struct

\ type descriptors, all ( -- align size )
1 aligned   1 cells   2constant cell%
1 chars     1 chars   2constant char%
1 faligned  1 floats  2constant float%
1 dfaligned 1 dfloats 2constant dfloat%
1 sfaligned 1 sfloats 2constant sfloat%
cell% 2*              2constant double%

\ memory allocation words
: %alignment ( align size -- align )
    drop ;

: %size ( align size -- size )
    nip ;

: %align ( align size -- )
    ( drop here swap nalign here - allot) 2drop ;

: %allot ( align size -- addr )
    tuck %align ( here swap) allot? ;

: %allocate ( align size -- addr ior )
    nip allocate ;

: %alloc ( size align -- addr )
    %allocate throw ;

