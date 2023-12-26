\ fcalls-x86_64.4th
\
\ Copyright (c) 2023 Krishna Myneni
\
\ Requires
\   ans-words
\   modules.fs
\   syscalls
\   mc
\
\ Notes:
\
\  0. On entry to function calling code, the
\     the rbx register points to one cell above
\     the data stack, and the top of the fp stack
\     is in rcx.

BASE @
HEX

0 constant CALL_TYPE_CELL
1 constant CALL_TYPE_2CELL
2 constant CALL_TYPE_SFLOAT
3 constant CALL_TYPE_DFLOAT

create callTypes 16 allot

\ call a function with m arguments and types specified
\ in byte array callTypes
\ fcall-m-code ( ... m -- )
 
\ call a function with no arguments but with one return value
\ fcall0-code ( addr -- xret ) 
  48 83 c3 08    \ 8 #     rbx  add,
  48 8b 03       \ 0 [rbx] rax  mov,
  53             \         rbx  push,
  ff d0          \         rax  call,
  5b             \         rbx  pop,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax     rax  xor,
  c3             \              ret,
12 
dup MC-Table fcall0-code
MC-Put

: fcall0       ( addr - xret ) fcall0-code call ; 
: fcall0-noret ( addr --  ) fcall0 drop ;


\ Call a function with one argument and one return value.
\ fcall1-code ( x addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx         push,
  ff d0          \ rax          call,
  5b             \ rbx          pop,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
19 
dup MC-Table fcall1-code
MC-Put

: fcall1 ( x addr -- xret ) fcall1-code call drop ;

\ Call a function with one cell arg, and one
\ fp arg. One return value on data stack, and zero
\ return values on the fp stack.
\ fcall(1,1;1,1)-code ( x1 addr -- xret ) ( F: r1 -- r2 )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx          push,
  51             \ rcx          push,
  f2 0f 10 01    \ 0 [rcx] xmm0 movsd,  
  ff d0          \ rax          call,
  59             \ rcx          pop,
  5b             \ rbx          pop,
  48 89 03       \ rax 0 [rbx]  mov,
  f2 0f 11 01    \ xmm0 0 [rcx] movsd,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
23
dup MC-Table fcall(1,1;1,1)-code
MC-Put

: fcall(1,1;1,1) ( x addr -- xret) ( F: r1 -- r2 )
    fcall(1,1;1,1)-code call drop ;

: fcall(1,1;1,0) ( x addr -- xret) ( F: r1 -- )
    fcall(1,1;1,1)-code call drop fdrop ;

: fcall(1,1;0,0) ( x addr -- ) ( F: r -- )
    fcall(1,1;1,1)-code call 2drop fdrop ;

\ Call a function with one ds argument, 0 fp arg,
\ and one return ds value and one return fp value.
\ fcall(1,0;1,1)-code ( x addr -- xret ) ( F: -- r )  
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx          push,
  51             \ rcx          push,  
  ff d0          \ rax          call,
  59             \ rcx          pop,
  5b             \ rbx          pop,
  48 89 03       \ rax 0 [rbx]  mov,
  f2 0f 11 01    \ xmm0 0 [rcx] movsd,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
1F
dup MC-Table fcall(1,0;1,1)-code
MC-Put

: fcall(1,0;1,1) ( x addr -- xret ) ( F: -- r )
    0.0e0 fcall(1,0;1,1)-code call drop ;

\ Call a function with two arguments and one return value.
\ fcall2-code ( x1 x2 addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,   ( rax = addr )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 33       \ 0 [rbx] rsi  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx         push,
  ff d0          \ rax          call,
  5b             \ rbx          pop,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
20
dup MC-Table fcall2-code
MC-Put

: fcall2 ( x1 x2 addr -- xret ) fcall2-code call 2drop ;

\ Call a function with three integer/ptr args and
\ one return value.
\ fcall3-code ( x1 x2 x3 addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,   ( rax = addr )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 13       \ 0 [rbx] rdx  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 33       \ 0 [rbx] rsi  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx         push,
  ff d0          \ rax          call,
  5b             \ rbx          pop,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
27
dup MC-Table fcall3-code
MC-Put

: fcall3 ( x1 x2 x3 addr -- xret )  fcall3-code call 2drop drop ;

BASE !

