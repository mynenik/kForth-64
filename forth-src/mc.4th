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

\ Page utilities
1000 constant PAGESIZE  \ this should be obtained from the OS config.
PAGESIZE 1- invert constant PAGEMASK

\ Return true if address range a--a+u crosses a page boundary
: ?PageCross ( a u -- flag )
    over + 1- >r PAGEMASK and r> PAGEMASK and <> ;

\ Return the start of the next page after a1 
: NextPage ( a1 -- a2 )  PAGEMASK and PAGESIZE + ;

\ Machine code buffer will be a multiple of PAGESIZE bytes
16    constant MC_NPAGES
PAGESIZE MC_NPAGES * constant MC_BUFSIZE
0 ptr MC-Here0

\ Allocate buffer 
0 MC_BUFSIZE PROT_READ PROT_WRITE or MAP_ANONYMOUS MAP_PRIVATE or
-1 0 mmap to MC-Here0

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
: MC-Executable ( a_mc flag_rw -- flag )
    >r PAGEMASK and PAGESIZE 
    r> IF  PROT_EXEC  ELSE  PROT_READ PROT_WRITE or  THEN
    mprotect 0= ;

BASE !
Previous
 




