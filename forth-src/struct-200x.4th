\ struct-200x.4th
\
\ Forth 200x standardized Data Structures.
\
\ Adapted from the reference implementation for Forth 200x
\ structures given in the Structures RfD at the link below:
\
\    http://www.forth200x.org/structures.html
\
\ This RfD was accepted by the Forth-200x standards committee 
\ in 2007. 

\ Begin definition of a new structure. Use in the form
\ BEGIN-STRUCTURE <name>. At run time <name> returns the
\ size of the structure.
: begin-structure       \ -- addr 0 ; -- size
  create
    \ here 0  0 ,
    1 cells allot? 0 2dup swap !        \ mark stack, lay dummy
  does> @  ;                            \ -- rec-len

\ Terminate definition of a structure.
: end-structure         \ addr n --
  swap !  ;                             \ set len

\ Create a new field within a structure definition of size n bytes.
: +FIELD       \ addr size n <"name"> -- ; Exec: addr -- 'addr
  create
    over 1 cells allot? ! +
  does>
    @ +
;

\ Create a new field within a structure definition of size 1 CHARS.
: cfield:       \ n1 <"name"> -- n2 ; Exec: addr -- 'addr
  1 chars +FIELD
;

\ Create a new field within a structure definition of size 1 CELLS.
\ The field is ALIGNED.
: field:        \ n1 <"name"> -- n2 ; Exec: addr -- 'addr
  aligned  1 cells +FIELD
;

\ Create a new field within a structure definition of size 1 FLOATS.
\ The field is FALIGNED.
: ffield:       \ n1 <"name"> -- n2 ; Exec: addr -- 'addr
  faligned  1 floats +FIELD
;

\ Create a new field within a structure definition of size 1 SFLOATS.
\ The field is SFALIGNED.
: sffield:      \ n1 <"name"> -- n2 ; Exec: addr -- 'addr
  sfaligned  1 sfloats +FIELD
;

\ Create a new field within a structure definition of size 1 DFLOATS.
\ The field is DFALIGNED.
: dffield:      \ n1 <"name"> -- n2 ; Exec: addr -- 'addr
  dfaligned  1 dfloats +FIELD
;

