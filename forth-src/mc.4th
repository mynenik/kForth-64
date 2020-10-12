\ mc.4th
\
\ Machine code buffer allocation and set up for execution.
\
\ Copyright (c) 2020 Krishna Myneni
\ 
\ Provided under the GNU Affero General Public License
\ (AGPL) v3.0 or later.
\
\ Requires: ans-words.4th modules.fs syscalls.4th
\

Also syscalls
BASE @
HEX

: align16 ( u1|a1 -- u2|a2 ) 10 /mod swap IF 1+ THEN 4 LSHIFT ;

\ Page utilities
1000 constant PAGESIZE  \ this should be obtained from the OS config.
PAGESIZE 1- invert constant PAGEMASK

\ Return true if address range a--a+u crosses a page boundary
: ?PageCross ( a u -- flag )
    over + 1- >r PAGEMASK and r> PAGEMASK and <> ;

\ Return the start of the next page after a1 
: NextPage ( a1 -- a2 )  PAGEMASK and PAGESIZE + ;

\ Machine code buffer will be a multiple of PAGESIZE bytes
20 constant MC_NPAGES
PAGESIZE MC_NPAGES * constant MC_BUFSIZE
0 ptr MC-Here0

\ Allocate buffer 
[DEFINED] _WIN32_ [IF]  \ Win32
0 MC_BUFSIZE MEM_RESERVE MEM_COMMIT or PAGE_READWRITE valloc
[ELSE]  \ Linux 
0 MC_BUFSIZE PROT_READ PROT_WRITE or MAP_ANONYMOUS MAP_PRIVATE or
-1 0 mmap 
[THEN]
to MC-Here0

MC-Here0 -1 = [IF]
  cr .( Failed to allocate machine code buffer! ) cr
  ABORT
[THEN]

MC-Here0 ptr MC-Here

\ Use of MC-Allot? must be paired with CREATE
: MC-Allot? ( u -- addr )
    MC-Here over ?PageCross IF MC-Here NextPage to MC-Here THEN
    MC-Here dup 1 cells allot? !
    tuck + to MC-Here ;

\ flag_rw = TRUE,  the page is allowed read-executable
\ flag_rw = FALSE, the page is read-writable
\ return true if successful
[DEFINED] _WIN32_ [IF]  \ Win32
variable OldProt
: MC-Executable ( a_mc flag_rw -- flag )
    >r PAGEMASK and PAGESIZE
    r> IF  PAGE_EXECUTE_READ  ELSE  PAGE_READWRITE  THEN
    OldProt vprotect 0= ;
[ELSE]  \ Linux
: MC-Executable ( a_mc flag_rw -- flag )
    >r PAGEMASK and PAGESIZE 
    r> IF  PROT_EXEC  ELSE  PROT_READ PROT_WRITE or  THEN
    mprotect 0= ;
[THEN]

\ Create a named machine code table, returning the address of
\ the starting address of the machine code buffer. The
\ requested number of bytes, ur, will be adjusted to a multiple
\ of 16 when the buffer is allocated. Executing the table name
\ will return the start address of the machine code buffer.
\ Upon creation, the buffer will be in a read-writable state.

: MC-Table ( ur "name" -- a_mc )
    create align16 MC-Allot?           
    does>  ( a -- a_mc ) a@ ;

: MC-Put ( b1 b2 ... b_u u a_mc -- )
    dup false MC-Executable 0=
    Abort" Cannot make buffer R/W!"
    dup >r
    2dup + 1- nip
    swap 0 ?DO 2dup c! 1- nip LOOP drop
    r> true MC-Executable 0=
    Abort" Cannot make buffer R/X!" ;

\ Return the executable code address
: >MC-Code ( xt -- a ) >body a@ ;

BASE !
Previous

