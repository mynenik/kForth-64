\ protect.4th
\
\ Memory protection of executable byte code for 
\ colon definitions.
\
\ Copyright (c) 2022 Krishna Myneni
\ 
\ Provided under the GNU Affero General Public License
\ (AGPL) v3.0 or later.
\
\ Requires: ans-words.4th modules.fs syscalls.4th
\

[DEFINED] _WIN32_ [IF]
[UNDEFINED] MEM_RESERVE   [IF] include syscalls.4th [THEN]
[ELSE]
[UNDEFINED] MAP_ANONYMOUS [IF] include syscalls.4th [THEN]
[THEN]

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

\ Virtual code buffer will be a multiple of PAGESIZE bytes
20 constant BC_NPAGES
PAGESIZE BC_NPAGES * constant BC_BUFSIZE
0 ptr BC-Here0

\ Allocate buffer 
[DEFINED] _WIN32_ [IF]  \ Win32
0 BC_BUFSIZE MEM_RESERVE MEM_COMMIT or PAGE_READWRITE valloc
[ELSE]  \ Linux 
0 BC_BUFSIZE PROT_READ PROT_WRITE or MAP_ANONYMOUS MAP_PRIVATE or
-1 0 mmap 
[THEN]
to BC-Here0

BC-Here0 -1 = [IF]
  cr .( Failed to allocate protected byte code buffer! ) cr
  ABORT
[THEN]

BC-Here0 ptr BC-Here

\ Allocate space for relocating byte code to protected memory
: BC-Allocate ( u -- addr )
    BC-Here over ?PageCross IF BC-Here NextPage to BC-Here THEN
    BC-Here tuck + to BC-Here ;

\ flag_p = TRUE,  the page is allowed read only
\ flag_p = FALSE, the page is read-writable
\ return true if successful
[DEFINED] _WIN32_ [IF]  \ Win32
variable OldProt
: BC-Protect ( a_bc flag_p -- flag )
    >r PAGEMASK and PAGESIZE
    r> IF  PAGE_READONLY  ELSE  PAGE_READWRITE  THEN
    OldProt vprotect 0= ;
[ELSE]  \ Linux
: BC-Protect ( a_bc flag_p -- flag )
    >r PAGEMASK and PAGESIZE 
    r> IF  PROT_READ  ELSE  PROT_READ PROT_WRITE or  THEN
    mprotect 0= ;
[THEN]

: BC-Relocate ( asrc adest u -- )
    over false BC-Protect 
    0= Abort" Unable to obtain write access to destination!"
    cmove ;

: Protect-Def ( xt u -- )
    dup BC-Allocate swap >r   \ -- xt adest  R: -- u
    over a@ swap 2dup r>      \ -- xt asrc adest asrc adest u
    BC-Relocate               \ -- xt asrc adest
    dup true BC-Protect
    0= Abort" Unable to make destination read-only!"
    swap free Abort" Unable to free original byte code!"
    swap ! ;

: Unprotect-Def ( xt -- )
    a@ false BC-Protect 
    0= Abort" Unable to change protection!" ;

BASE !
Previous

