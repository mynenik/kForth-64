\ Test signal handling on SIGFPE

1 cells 4 = constant 32bit?

include ans-words
include modules
include syscalls
include mc
include signal

32bit? [IF]
include asm-x86

\ Generate a SIGFPE signal
CODE test
   1 # eax   mov,
   ecx ecx   xor,
       ecx   div,
             ret,
END-CODE

[ELSE]

\ 64-bit machine code to generate SIGFPE
BASE @
HEX
  48 c7 c0 01 00 00 00   \ 1 # rax  mov,
  48 31 c9               \ rcx rcx  xor,
  48 f7 f1               \     rcx  div,
  c3                     \          ret,
E
dup MC-Table test-code
MC-Put
BASE !

: test ( -- ) test-code call ;

[THEN]

\ Install QUIT signal handler for SIGFPE

' quit SIGFPE forth-signal drop


cr .( Type 'test' to generate SIGFPE ) cr


