\ fcalls-x86_64.4th
\
\ Copyright (c) 2020 Krishna Myneni
\ 2020-01-03
\
\ Requires
\   ans-words
\   modules.fs
\   syscalls
\   mc
\   strings.4th (strings64.4th -- subset of strings.4th)
\   utils.4th
\
\ #     GNU assembly code        Gas output           asm-x86_64 assembly    
\ # ------------------------------------------------------------------------
\	movq (%rbx), %rax   #  48 8b 03             |   0 [rbx] rax  mov,  |
\	addq $8, %rbx       #  48 83 c3 08          |       8 # rbx  add,  |
\	movq (%rbx), %rcx   #  48 8b 0b             |   0 [rbx] rcx  mov,  |
\	addq $8, %rbx       #  48 83 c3 08          |       8 # rbx  add,  |
\	pushq %rbx          #  53                   |           rbx  push, |
\	movq %rcx, %rdx     #  48 89 ca             |       rcx rdx  mov,  |
\ l1:   pushq (%rbx)        #  ff 33                |  DO,  0 [rbx]  push, |
\	addq $8, %rbx       #  48 83 c3 08          |       8 # rbx  add,  |
\	loop l1             #  e2 f8                |                LOOP, |
\	subq $65536, %rsp   #  48 81 ec 00 00 01 00 |   65536 # rsp  sub,  |
\	pushq %rdx          #  52                   |           rdx  push, |
\	addq $65544, %rsp   #  48 81 c4 08 00 01 00 |   65544 # rsp  add,  |
\	call *%rax          #  ff d0                |           rax  call, |
\	subq $65544, %rsp   #  48 81 ec 08 00 01 00 |   65544 # rsp  sub,  |
\	popq %rcx           #  59                   |           rcx  pop,  |
\	addq $65536, %rsp   #  48 81 c4 00 00 01 00 |   65536 # rsp  add,  |
\	movq %rcx, %rdx     #  48 89 ca             |       rcx rdx  mov,  |
\	shl $3, %rcx        #  48 c1 e1 03          |       3 # rcx  shl,  |
\	addq %rcx, %rsp     #  48 01 cc             |       rcx rsp  add,  |
\	popq %rbx           #  5b                   |           rbx  pop,  |
\	movq %rdx, %rcx     #  48 89 d1             |       rdx rcx  mov,  |
\	decq %rcx           #  48 ff c9             |           rcx  dec,  |
\	shl $3, %rcx        #  48 c1 e1 03          |       3 # rcx  shl,  |
\	addq %rcx, %rbx     #  48 01 cb             |       rcx rbx  add,  |
\	movq %rax, (%rbx)   #  48 89 03             |   rax 0 [rbx]  mov,  |
\	movq $0, %rax       #  48 c7 c0 00 00 00 00 |       0 # rax  mov,  |
\ # ------------------------------------------------------------------------

HEX
  48 8b 03                     \  0 [rbx] rax  mov,
  48 83 c3 08                  \      8 # rbx  add,
  48 8b 0b                     \  0 [rbx] rcx  mov,
  48 83 c3 08                  \      8 # rbx  add,
  53                           \          rbx  push,
  48 89 ca                     \      rcx rdx  mov,
  ff 33                        \ DO,  0 [rbx]  push,
  48 83 c3 08                  \      8 # rbx  add,
  e2 f8                        \               LOOP,
  48 81 ec 00 00 01 00         \  65536 # rsp  sub,
  52                           \          rdx  push,
  48 81 c4 08 00 01 00         \  65544 # rsp  add,
  ff d0                        \          rax  call,
  48 81 ec 08 00 01 00         \  65544 # rsp  sub,
  59                           \          rcx  pop,
  48 81 c4 00 00 01 00         \  65536 # rsp  add,
  48 89 ca                     \      rcx rdx  mov,
  48 c1 e1 03                  \      3 # rcx  shl,
  48 01 cc                     \      rcx rsp  add,
  5b                           \          rbx  pop,
  48 89 d1                     \      rdx rcx  mov,
  48 ff c9                     \          rcx  dec,
  48 c1 e1 03                  \      3 # rcx  shl,
  48 01 cb                     \      rcx rbx  add,
  48 89 03                     \  rax 0 [rbx]  mov,
  48 c7 c0 00 00 00 00         \      0 # rax  mov,
5c ctable fcall-code


: fcall ( ... ncells addr -- val )
    fcall-code call ;

\ call a function with no arguments but with one return value
\ fcall0-code ( addr -- xret ) 
  48 8b 03    \  0 [rbx] rax  mov,
  53          \  rbx         push,
  ff d0       \  rax         call,
  5b          \  rbx          pop,
  48 89 03    \  rax 0 [rbx]  mov,
  48 31 c0    \  rax    rax   xor,
  c3          \               ret,
0e ctable fcall0-code

: fcall0       ( addr - x )  fcall0-code call ; 
: fcall0-noret ( addr --  ) fcall0 drop ;


\ Call a function with one argument and one return value.
\ fcall1-code ( x addr -- xret )
  48 8b 03       \ 0 [rbx] rax  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx         push,
  ff d0          \ rax          call,
  5b             \ rbx          pop,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  c3             \              ret,
15 ctable fcall1-code

: fcall1 ( n1 addr -- n2 ) fcall1-code call drop ;

\ Call a function with two arguments and one return value.
\ fcall2-code ( x1 x2 addr -- xret )
  55             \ rbp         push,
  48 89 e5       \ rsp rbp      mov,
  57             \ rdi         push,
  56             \ rsi         push,
  48 8b 03       \ 0 [rbx] rax  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 33       \ 0 [rbx] rsi  mov,
  48 83 c3 08    \ 8 # rbx      add,
  48 8b 3b       \ 0 [rbx] rdi  mov,
  53             \ rbx         push,
  ff d0          \ rax          call,
  5b             \ rbx          pop,
  48 89 03       \ rax 0 [rbx]  mov,
  48 31 c0       \ rax rax      xor,
  5e             \ rsi          pop,
  5f             \ rdi          pop,
  48 89 ec       \ rbp rsp      mov,
  5d             \ rbp          pop,
  c3             \              ret,
28 ctable fcall2-code

: fcall2 ( x1 x2 addr -- x3 ) fcall2-code call drop ;

