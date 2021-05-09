\ dynmem.4th                Dynamic Memory Allocation package
\                      this code is an adaptation of the routines by
\         Dreas Nielson, 1990; Dynamic Memory Allocation;
\         Forth Dimensions, V. XII, No. 3, pp. 17-27
\
\ Revisions:
\   2003-03-18  km;  Adapted for kForth 
\   2004-07-16  km;  Fixed deallocation of memory in }}free
\   2007-10-27  km;  save base, switch to decimal, and restore base
\   2011-09-16  km;  use Neal Bridges' anonymous module interface
\   2012-02-19  km;  use KM/DNW's modules library

\ This is an ANS Forth program requiring:
\      1. The Memory-Allocation wordset, or the implementations below of
\         ALLOCATE and FREE
\      2. The compilation of the local ALLOCATE and FREE is controlled by
\          the VALUE HAS-MEMORY-WORDS?
\         and the conditional compilation words in the Programming-Tools wordset
\
\ This code is designed to work in conjunction with the FSL implementation
\ of arrays as given in the file, 'fsl-util'.
\
\ The words ALLOCATE and FREE are implementations of the ANS Forth
\ words from the Memory-Allocation wordset.  If your Forth system
\ has the Memory-Allocation wordset the following words can be eliminated from here:
\       freelist
\       Dynamic-Mem
\       ALLOCATE
\       FREE
\
\
\  To use dynamic memory, a dynamic memory pool needs to be created and
\  initialized. The dynamic memory pool needs to be initialized before it is ever
\  used.  IF THIS IS NOT DONE, ALLOCATE will abort with a message
\  complaining about the lack of initialization.  Typically
\  the initialization would look like,
\
\
\	CREATE POOL   #bytes  ALLOT
\	POOL #bytes Dynamic-Mem
\
\	(any other way of allocating space for the pool will also work, one
\	just has to pass the starting address of some contigous memory and the
\	number of bytes to Dynamic-Mem).  If there are alignment requirements
\       for the data space, this should be satisfied BEFORE the address is
\       passed to Dynamic-Mem.
\
\	If your application ends up using more bytes than are in the memory
\	pool ( #bytes ) then the internal pointer will be NULL when }malloc
\	fails.  You can detect this by invoking  malloc-fail?,
\
\		malloc-fail?
\
\	If there is a true on the stack at this point, then the allocation
\	failed. This allows the following usage,
\
\        	malloc-fail? ABORT" ALLOCATE failed "
\
\	The allocation and freeing of dynamic memory can be done in any order.
\	Since this can be done in any order, there is a possiblity that the
\	pool will become fragemented.   It is then possible that a }malloc
\       will fail if the memory pool is very fragmented.
\
\	The current version of the dynamic memory package can have
\	only one memory pool.
\
\	For dynamically allocated arrays, the delcaration looks like,
\
\	element_size DARRAY name{
\
\	where element_size is the number of cells that the data type occupies
\	just as for static arrays.
\
\	To allocate space for a dynamic array (this can be done at runtime),
\
\	& name{ #elements }malloc
\
\	If it succeeds then there will have been contiguous space allocated
\	for the required number of elements.
\
\	To release the space (this can also be done at runtime) use,
\
\	& name{ }free
\
\
\	A dynamic array name can be re-used by calling }free to release
\	the old space and then calling }malloc again to reallocate it.

CR .( DYNMEM            V1.9d          19 February  2012   EFC )
BASE @ DECIMAL

BEGIN-MODULE
Private:

HAS-MEMORY-WORDS? 0= [IF]

1024 1024 * CONSTANT POOLSIZE	\ adjust up or down as needed
CREATE pool POOLSIZE allot


\ pointer to beginning of free space
variable freelist ( 0 ,)


[THEN]

Public:

\ memory allocation status variable, 0 for OK
0 VALUE malloc-fail?

: cell_size ( addr -- n )      >BODY CELL+ @ ;       \ gets array cell size

HAS-MEMORY-WORDS? 0= [IF]

\ initialize memory pool at ALIGNED address 'start_addr'
: Dynamic-Mem ( start_addr length -- )
          OVER DUP freelist !
          0 SWAP !
          SWAP CELL+ !
;

pool POOLSIZE Dynamic-Mem

: ALLOCATE ( u -- addr ior )      \ allocate n bytes, return pointer to block
                                  \ and result flag ( 0 for success )

         \ check to see if pool has been initialized first
         freelist a@ 0= ABORT" ALLOCATE::memory pool not initialized! "

         CELL+ freelist DUP
         BEGIN
           WHILE DUP a@ CELL+ @ 2 PICK U<
                 IF a@ @ DUP   \ get new link
                 ELSE   DUP a@ CELL+ @ 2 PICK - 2 CELLS MAX DUP 2 CELLS =
                        IF DROP DUP a@ DUP @ ROT !
                        ELSE  OVER OVER SWAP a@ CELL+ !   SWAP a@ +
                        THEN
                        OVER OVER ! CELL+ 0       \ store size, bump pointer
                 THEN                             \ and set exit flag
           REPEAT

          SWAP DROP

          DUP 0=
          
;

: FREE ( ptr -- ior )           \ free space at ptr, return status ( 0 for success )
           1 CELLS - DUP @ SWAP OVER OVER CELL+ ! freelist DUP
           BEGIN
             DUP 3 PICK U< AND
           WHILE
             a@ DUP @
           REPEAT

           DUP a@ DUP 3 PICK ! ?DUP
           IF DUP 3 PICK 5 PICK + =
              IF DUP CELL+ @ 4 PICK + 3 PICK CELL+ ! @ 2 PICK !
              ELSE   DROP THEN
           THEN

           DUP CELL+ @ OVER + 2 PICK =
           IF  OVER CELL+ @ OVER CELL+ DUP @ ROT + SWAP ! SWAP @ SWAP !
           ELSE !
           THEN

           DROP
           0           \ this code ALWAYS returns a success flag
;

[THEN]

\ word for allocation of a dynamic 1-D array memory
\ typical usage:  & a{ #elements }malloc
                                      \ ---------------------
: }malloc ( addr n -- )               \ | size | data area
                                      \ ---------------------
          OVER cell_size DUP >R *        \ save extra cell_size on rstack
          \ now add space for the cell_size entry
          CELL+ ALLOCATE
	  TO malloc-fail?
          OVER >BODY !

          \ now store the cell size in the beginning of the block
          >BODY a@ R> SWAP !
;

\ word to release dynamic array memory, typical usage:  & a{ }free

: }free   ( addr -- )
        >BODY DUP
        a@ FREE
        TO malloc-fail?
        0 SWAP !
;

\ word for allocation of a dynamic 2-D array memory
\ typical usage:  & a{{ #rows #cols }}malloc
                                       \  -------------------------
: }}malloc ( addr n m -- )             \  | m | size | data area 
                                       \  -------------------------
          2 PICK cell_size DUP
          >R OVER >R         \ save extra cell_size and m on rstack
          * *                \ calculate the space needed
          \ now add space for the cell_size entry and m
          CELL+ CELL+ ALLOCATE
          TO malloc-fail?

          SWAP OVER CELL+ SWAP >BODY !    \ store pointer to allocated space
                                          \ Note: pointing to size field not m

          \ now store m and cell size in the beginning of the block
          R> OVER !
          R> SWAP CELL+ !

;

: }}free  ( addr -- )  
	>BODY DUP a@ 
	1 CELLS -	\ see note in }}malloc above, ptr points to 
	                \   1 cell past start of region. 
	FREE TO malloc-fail?
	0 SWAP ! ;


END-MODULE
BASE !

