\ dltest64.4th
\
\ Test use of the experimental dynamic link library 
\ interface in kForth-64 for x86_64-linux, v 0.1.4 and greater.
\
\ K. Myneni, krishna.myneni@ccreweb.org
\
\ Notes:
\

include ans-words
include modules
include syscalls
include mc
include strings
include dump
include fcalls-x86_64

1 constant RTLD_LAZY

: check-dlerror ( -- ) 
    dlerror dup IF  dup strlen cr type cr ABORT THEN drop ;

0 value hndLib
0 value llabs 
    
: dltest ( -- )
    c" libc-2.30.so" 1+ RTLD_LAZY dlopen to hndLib
    hndLib 0= IF check-dlerror THEN
    cr ." Opened the C library."

    hndLib c" llabs" 1+ dlsym to llabs
    check-dlerror
    cr ." Loaded library function 'llabs' at address " 
    llabs hex u. decimal

    -3 llabs fcall1        \ call the library function

    cr ." -3 llabs returns " dup . 
    ."  which is "
    -3 abs = IF ." correct." ELSE ." INCORRECT!" THEN 
    hndLib dlclose
    cr ." dlclose returned " .
;

dltest

