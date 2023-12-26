\ lib-interface.4th
\
\ High-Level Interface to functions in an external shared object 
\ library.
\
\ Copyright (c) 2009 Krishna Myneni, Creative Consulting for
\ Research & Education, http://ccreweb.org
\
\ This software is provided under the GNU Lesser General Public
\ License (LGPL).
\
\ Provides:
\
\   open-lib         open a shared object library
\   lib-sym          lookup and return a pointer to a function in a library
\   lib-error        return an error string 
\   close-lib        close a shared object library
\   check-lib-error  see if an error occured with open-lib or lib-sym and, 
\                      if so, abort.
\   C-word           Create a Forth word and associate it with a C function
\                      from the most recently opened library
\   F-word           Create a Forth word and associate it with a Fortran
\                      subroutine from the last opened library
\
\
\ Requires kForth (ver >= 1.5.x)
\
\ Also requires:
\   ans-words
\   strings
\   asm
\   fcalls
\
\
\ Revisions:
\   2009-10-07  km  created
\   2009-10-10  km  add $>zstr and zstr>$ ; modify lsym to take
\                   a s" ..." string as argument
\   2009-10-12  km  added F-word, changed check-dlerror to check-lib-error.
\   2009-10-14  km  revised open-lib, lib-sym, and lsym to pass
\                   null-terminated strings to dlopen/dlsym, per latest
\                   kForth 1.5.x revision.
\   2009-10-20  km  modified C-word to handle no returns case
\   2009-11-10  km  modified C-word to handle no args case
\   2009-11-18  km  modified F-word to handle integer and floating point return 
\                     cases, providing partial support for calling FORTRAN functions
\   2009-11-19  km  factor common code between C-word and F-word
1 CELLS 8 = constant 64-bit?
[undefined] fcall0 [IF]
   s" fcalls.4th" included
[THEN]

base @
decimal

1 constant RTLD_LAZY

\ Make a null-terminated string.
\ This particular implementation is kForth-specific; all strings 
\ are null-terminated in kForth
: z" ( "string" -- a )
    postpone s" 
    postpone drop ;  immediate   

\ Forth string to null-terminated string
: $>zstr ( c-addr u -- azstr )
    strpck 1+ ;      \ revise this -- current implementation limited to 255 chars

\ null-terminated string to Forth string
: zstr>$ ( azstr -- c-addr u )
   dup strlen ;


\ The following library interface words are modeled from those
\ provided by Gforth:
\
\  open-lib
\  lib-sym
\  lib-error

0 value hndLib

\ Open a shared object library
\ returns a nonzero handle to the opened libary, if successful
: open-lib ( c-addr1 u1 -- u2 )
    $>zstr RTLD_LAZY dlopen dup to hndLib
;

\ Load symbol from library
\ u2 is the library handle
: lib-sym ( c-addr1 u1 u2 -- addr )
    -rot $>zstr dlsym ;

: lib-error ( -- c-addr u ) dlerror ;

\ Look up symbol in the most recently opened library
: lsym ( c-addr u -- addr )
    $>zstr hndLib swap dlsym ;

: close-lib ( u -- error )  dlclose ;

: check-lib-error ( -- ) 
    dlerror dup IF  zstr>$ cr type cr ABORT THEN drop ;


\ High-level interface to C functions and Fortran subroutines and functions
\
\ Arguments:
\    addr  -- function address
\    aargs -- address of counted string describing the arguments
\    u     -- length of aargs string
\    nargs -- number of arguments, for verification of parsing aargs
\
\ Example:
\
\    s" cos"  C-word  cos ( r -- r )
\
\ The string describing the arguments to the C function is a series
\ of symbols separated by one or more spaces, which indicates the Forth
\ data type being passed to or returned from the C function. The symbols 
\ are chosen according to the following conventions:
\
\     a   an address:               void*, char*, int*, double*, char**, etc.
\     n   a single cell value:      int, unsigned, etc.
\     u   a single cell value:      unsigned, etc.
\     d   a double cell integer:    long long
\     s   a single precision float: float
\     r   a double precision float: double
\    --   separator between arguments and return values
\
\ Note that "s" and "r" return types are both returned as a double precision 
\  fp on top of the kForth data stack.

0 value lword_ncells      \ physical number of stack cells to supply arguments
0 value lword_nargs       \ logical number of arguments to library function
0 value lword_nret        \ logical number of values returned from library function

\ Return types:
\
\   0 = signed int OR unsigned int OR address (1 cells)
\   1 = double integer (2 cells)
\   2 = single or double precision real (2 cells)
\
0 value lword_ret_type    

: inc-ncells ( -- ) lword_ncells 1+ to lword_ncells ;
: inc-nargs  ( -- ) lword_nargs  1+ to lword_nargs ;
: inc-nret   ( -- ) lword_nret   1+ to lword_nret ;

: lword-parse-ret ( "ret" -- )
     0 to lword_nret
     BEGIN
       bl word count
     WHILE
       c@ CASE
         [char] ) OF EXIT ENDOF
         [char] \ OF refill 0= ABORT" Unfinished return list!" ENDOF
         [char] n OF inc-nret 0 to lword_ret_type ENDOF
         [char] a OF inc-nret 0 to lword_ret_type ENDOF
         [char] u OF inc-nret 0 to lword_ret_type ENDOF
         [char] d OF inc-nret 1 to lword_ret_type ENDOF
         [char] s OF inc-nret 2 to lword_ret_type ENDOF
         [char] r OF inc-nret 2 to lword_ret_type ENDOF
         true ABORT" Unsupported return type!"
       ENDCASE
     REPEAT
;

: lword-parse-args ( "args_ret" -- )
     0 to lword_nargs
     0 to lword_ncells
     bl word count 0= swap c@ [char] ( <> or 
     ABORT" Start of argument list not found!"
     BEGIN
       bl word count
     WHILE
       c@ 
       CASE
         [char] a OF ( ... ) inc-ncells inc-nargs ENDOF
         [char] n OF ( ... ) inc-ncells inc-nargs ENDOF
         [char] u OF ( ... ) inc-ncells inc-nargs ENDOF
         [char] d OF ( ... ) inc-ncells inc-ncells inc-nargs ENDOF
         [char] s OF ( ... ) inc-ncells inc-nargs ENDOF
         [char] r OF ( ... ) inc-ncells inc-ncells inc-nargs ENDOF
         [char] - OF lword-parse-ret EXIT ENDOF
         [char] \ OF refill 0= ABORT" Unfinished argument list!" ENDOF
         [char] ) OF true ABORT" Need to specify return value!" ENDOF
         true ABORT" Unrecognized argument type!"
       ENDCASE
     REPEAT
;

64-bit? 0= [IF]
: lword-does> ( -- )
      lword_nargs 0= IF
        lword_nret 0= IF  
	  does> @ fcall0-noret  
         ELSE 
	  does> @ fcall0  
         THEN
      ELSE
        lword_nret 0= IF  
	  does> 2@ fcall-noret  
        ELSE 
          lword_ret_type CASE
	    0 OF  does> 2@ fcall     ENDOF
            2 OF  lword_nret CASE
                   1 OF  does> 2@ fcall-1r  ENDOF
                   2 OF  does> 2@ fcall-2r  ENDOF
                   true ABORT" Unsupported number of returns"
                  ENDCASE
                ENDOF
            true ABORT" Unsupported return type!"
          ENDCASE
	THEN
      THEN
;


0 ptr lword_pfa


: C-word ( c-addr u "name" "args_ret" -- )
     lsym check-lib-error
     create 2 cells allot? to lword_pfa
     lword_pfa !
     lword-parse-args 
     lword_ncells lword_pfa cell+ !
     lword-does>
;

\ High-level interface to Fortran SUBROUTINEs
\
\ Can only deal with Fortran integer and real FUNCTIONs at present!


: F-word ( c-addr u "name" "args_ret" -- )
     s" _" strcat lsym check-lib-error
     create 2 cells allot? to lword_pfa
     lword_pfa !
     lword-parse-args
     \ lword_nargs and lword_ncells MUST be same for F-word 
     lword_nargs lword_ncells <> ABORT" Incorrect type in F-word arg list!"
     lword_nargs lword_pfa cell+ !      
     lword-does>
;
[THEN]

base !

