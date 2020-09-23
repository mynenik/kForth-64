\ fcalls-x86_64.4th
\
\ Copyright (c) 2020 Krishna Myneni
\
\ Requires
\   ans-words
\   modules.fs
\   syscalls
\   mc
\

BASE @
HEX

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

: fcall0       ( addr - x ) fcall0-code call ; 
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

: fcall1 ( n1 addr -- n2 ) fcall1-code call drop ;

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

: fcall2 ( x1 x2 addr -- x3 ) fcall2-code call 2drop ;

BASE !

