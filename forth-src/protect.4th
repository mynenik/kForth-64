\ protect.4th
\
\ Memory protection of data buffers and executable byte code for 
\ colon definitions.
\
\ Copyright (c) 2022 Krishna Myneni
\ 
\ Provided under the GNU Affero General Public License
\ (AGPL) v3.0 or later.
\
\ Requires: ans-words.4th modules.4th syscalls.4th
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

\ Protected read-only memory buffer will be a multiple of PAGESIZE bytes
60 constant RO_NPAGES
PAGESIZE RO_NPAGES * constant RO_BUFSIZE
0 ptr RO-Here0

\ Allocate buffer 
[DEFINED] _WIN32_ [IF]  \ Win32
0 RO_BUFSIZE MEM_RESERVE MEM_COMMIT or PAGE_READWRITE valloc
[ELSE]  \ Linux 
0 RO_BUFSIZE PROT_READ PROT_WRITE or MAP_ANONYMOUS MAP_PRIVATE or
-1 0 mmap 
[THEN]
to RO-Here0

RO-Here0 -1 = [IF]
  cr .( Failed to allocate protected byte code buffer! ) cr
  ABORT
[THEN]

RO-Here0 ptr RO-Here

\ Allocate space in read only buffer
: RO-Allocate ( u -- addr )
    RO-Here over ?PageCross IF RO-Here NextPage to RO-Here THEN
    RO-Here tuck + to RO-Here ;

\ flag_p = TRUE,  the page is allowed read only
\ flag_p = FALSE, the page is read-writable
\ return true if successful
[DEFINED] _WIN32_ [IF]  \ Win32
variable OldProt
: RO-Protect ( a_bc flag_p -- flag )
    >r PAGEMASK and PAGESIZE
    r> IF  PAGE_READONLY  ELSE  PAGE_READWRITE  THEN
    OldProt vprotect 0= ;
[ELSE]  \ Linux
: RO-Protect ( a_bc flag_p -- flag )
    >r PAGEMASK and PAGESIZE 
    r> IF  PROT_READ  ELSE  PROT_READ PROT_WRITE or  THEN
    mprotect 0= ;
[THEN]

: RO-Relocate ( asrc adest u -- )
    over false RO-Protect 
    0= Abort" Unable to obtain write access to destination!"
    move ;

\ Copy contents of an read-writable memory region to
\ a buffer which will be protected against over-writing.
\ Return the new write-protected buffer.
: Protect-Data ( asrc u -- adest u )
    dup RO-Allocate swap     \ -- asrc adest u
    2dup 2>r RO-Relocate     \ --     R: -- adest u
    2r@ drop true RO-Protect \ --     R: -- adest u
    0= Abort" Unable to write protect new buffer!"
    2r> ;
 
: Protect-Def ( xt u -- )
    dup RO-Allocate swap >r   \ -- xt adest  R: -- u
    over a@ swap 2dup r>      \ -- xt asrc adest asrc adest u
    RO-Relocate               \ -- xt asrc adest
    dup true RO-Protect
    0= Abort" Unable to make destination read-only!"
    swap free Abort" Unable to free original byte code!"
    swap ! ;

: Unprotect-Def ( xt -- )
    a@ false RO-Protect 
    0= Abort" Unable to change protection!" ;

BASE !
Previous

