\ fcalls-x86_64.4th
\
\ Copyright (c) 2023--2024 Krishna Myneni
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
 
\ Call a function with no arguments and with one 64-bit
\ return value.
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

\ Call a function with no arguments. Convert 32-bit 
\ return to sign-extended 64-bit return.
\ fcall0-dq-code ( addr -- xret ) 
  48 83 c3 08    \ 8 #     rbx  add,
  48 8b 03       \ 0 [rbx] rax  mov,
  53             \         rbx  push,
  ff d0          \         rax  call,
  5b             \         rbx  pop,
  48 98          \              cdqe,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax     rax  xor,
  c3             \              ret,
14
dup MC-Table fcall0-dq-code
MC-Put

\ Call a function with one argument and one 64-bit return value.
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

\ Call a function with one argument and one return value.
\ Convert 32-bit return to sign-extended 64-bit value.
\ fcall1-dq-code ( x addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx         push,
  ff d0          \ rax          call,
  5b             \ rbx          pop,
  48 98          \              cdqe,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
1b
dup MC-Table fcall1-dq-code
MC-Put

\ Call a function with one cell arg, and one
\ fp arg. One return value on data stack, and one
\ return value on the fp stack.
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


\ Call a function with two arguments and one 64-bit return value.
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

\ Call a function with two arguments and one return value.
\ Convert 32-bit return to 64-bit sign-extended return.
\ fcall2-dq-code ( x1 x2 addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,   ( rax = addr )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 33       \ 0 [rbx] rsi  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx         push,
  ff d0          \ rax          call,
  5b             \ rbx          pop,
  48 98          \              cdqe,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
22
dup MC-Table fcall2-dq-code
MC-Put

\ Call a function with two cell args, and one
\ fp arg. One return value on data stack, and one
\ return value on the fp stack.
\ fcall(2,1;1,1)-code ( x1 x2 addr -- xret ) ( F: r1 -- r2 )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 33       \ 0 [rbx] rsi  mov,
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
2a
dup MC-Table fcall(2,1;1,1)-code
MC-Put

\ Call a function with three args and one 64-bit return value.
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

\ Call a function with three args and one return value.
\ Convert 32-bit return to sign-extended 64-bit return.
\ fcall3-dq-code ( x1 x2 x3 addr -- xret )
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
  48 98          \              cdqe,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
29
dup MC-Table fcall3-dq-code
MC-Put

\ Call a function with four args and one 64-bit return value.
\ fcall4-code ( x1 x2 x3 x4 addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,   ( rax = addr )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 0b       \ 0 [rbx] rcx  mov,
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
2E
dup MC-Table fcall4-code
MC-Put

\ Call a function with four args and one return value.
\ Convert 32-bit return to sign-extended 64-bit return.
\ fcall4-dq-code ( x1 x2 x3 x4 addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,   ( rax = addr )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 0b       \ 0 [rbx] rcx  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 13       \ 0 [rbx] rdx  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 33       \ 0 [rbx] rsi  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx         push,
  ff d0          \ rax          call,
  5b             \ rbx          pop,
  48 98          \              cdqe,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
30
dup MC-Table fcall4-dq-code
MC-Put

\ Call a function with five args and one 64-bit return value.
\ fcall5-code ( x1 x2 x3 x4 x5 addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,   ( rax = addr )
  48 83 c3 08    \ 8 # rbx      add,
  4c 8b 03       \ 0 [rbx] r8   mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 0b       \ 0 [rbx] rcx  mov,
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
35
dup MC-Table fcall5-code
MC-Put

\ Call a function with five args and one return value.
\ Convert 32-bit return to sign-extended 64-bit return.
\ fcall5-dq-code ( x1 x2 x3 x4 x5 addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,   ( rax = addr )
  48 83 c3 08    \ 8 # rbx      add,
  4c 8b 03       \ 0 [rbx] r8   mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 0b       \ 0 [rbx] rcx  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 13       \ 0 [rbx] rdx  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 33       \ 0 [rbx] rsi  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx         push,
  ff d0          \ rax          call,
  5b             \ rbx          pop,
  48 98          \              cdqe,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
37
dup MC-Table fcall5-dq-code
MC-Put

\ Call a function with six args and one 64-bit return value.
\ fcall6-code ( x1 x2 x3 x4 x5 x6 addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,   ( rax = addr )
  48 83 c3 08    \ 8 # rbx      add,
  4c 8b 0b       \ 0 [rbx] r9   mov,
  48 83 c3 08    \ 8 # rbx      add,
  4c 8b 03       \ 0 [rbx] r8   mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 0b       \ 0 [rbx] rcx  mov,
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
3c
dup MC-Table fcall6-code
MC-Put

\ Call a function with six args and one return value.
\ Convert 32-bit return to sign-extended 64-bit return.
\ fcall6-dq-code ( x1 x2 x3 x4 x5 x6 addr -- xret )
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 03       \ 0 [rbx] rax  mov,   ( rax = addr )
  48 83 c3 08    \ 8 # rbx      add,
  4c 8b 0b       \ 0 [rbx] r9   mov,
  48 83 c3 08    \ 8 # rbx      add,
  4c 8b 03       \ 0 [rbx] r8   mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 0b       \ 0 [rbx] rcx  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 13       \ 0 [rbx] rdx  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 33       \ 0 [rbx] rsi  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx         push,
  ff d0          \ rax          call,
  5b             \ rbx          pop,
  48 98          \              cdqe,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
3e
dup MC-Table fcall6-dq-code
MC-Put

\ Basic calls with no floating-point number args/returns.
: fcall0    ( addr - xret )          fcall0-code call ;
: fcall0-dq ( addr -- xret32 )       fcall0-dq-code call ; 
: fcall1    ( x addr -- xret )       fcall1-code call drop ;
: fcall1-dq ( x addr -- xret32 )     fcall1-dq-code call drop ;
: fcall2    ( x1 x2 a -- xret )      fcall2-code call 2drop ;
: fcall2-dq ( x1 x2 a -- xret32 )    fcall2-dq-code call 2drop ;
: fcall3    ( x1 x2 x3 a -- xret )   fcall3-code call 2drop drop ;
: fcall3-dq ( x1 x2 x3 a -- xret32)  fcall3-dq-code call 2drop drop ;
: fcall4    ( x1 x2 x3 x4 a -- xret) fcall4-code call 2drop 2drop ;
: fcall4-dq ( x1 x2 x3 x4 a -- xret32)  fcall4-dq-code call 2drop 2drop ;
: fcall5    ( x1 x2 x3 x4 x5 a -xret)   
    fcall5-code call 2drop 2drop drop ;
: fcall5-dq ( x1 x2 x3 x4 x5 a -xret32) 
    fcall5-dq-code call 2drop 2drop drop ;
: fcall6    ( x1 x2 x3 x4 x5 x6 a -- xret)   
    fcall6-code call 2drop 2drop 2drop ;
: fcall6-dq ( x1 x2 x3 x4 x5 x6 a -- xret32) 
    fcall6-dq-code call 2drop 2drop 2drop ;

\ Calls with one data stack arg, and zero/one double-precision
\ floating-point number args and zero/one fp return.

: fcall(1,0;1,1) ( x addr -- xret ) ( F: -- r )
    0.0e0 fcall(1,0;1,1)-code call drop ;

: fcall(1,1;1,1) ( x addr -- xret) ( F: r1 -- r2 )
    fcall(1,1;1,1)-code call drop ;

: fcall(1,1;1,0) ( x addr -- xret) ( F: r1 -- )
    fcall(1,1;1,1)-code call drop fdrop ;

: fcall(1,1;0,0) ( x addr -- ) ( F: r -- )
    fcall(1,1;1,1)-code call 2drop fdrop ;

\ Calls with two data stack args, and zero/one double-precision
\ floating-point number args and zero/on fp return.

: fcall(2,1;1,1) ( x1 x2 addr -- xret ) ( F: r1 -- r2 )
    fcall(2,1;1,1)-code call 2drop ;

: fcall(2,0;0,1) ( x1 x2 addr -- ) ( F: -- r )
    0.0e0 fcall(2,1;1,1)-code call 2drop drop ;

: fcall(2,1;0,0) ( x1 x2 addr -- ) ( F: r -- )
    fcall(2,1;1,1)-code call 2drop drop fdrop ;

: fcall(2,1;1,0) ( x1 x2 addr -- xret ) ( F: r -- )
    fcall(2,1;1,1)-code call 2drop fdrop ;

BASE !

