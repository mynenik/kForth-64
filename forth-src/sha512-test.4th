\ Test file hashes for the Forth SHA512 implementation.
\

include ans-words
include modules
include syscalls
include mc        \ Comment this line to benchmark pure Forth code.
include strings
include files
include utils
include dump
include slurp-file
[DEFINED] MC-Table [IF]
include sha512-x86_64.4th
[ELSE]
include sha512.4th
[THEN]

also sha512

variable rfileid
create buf[] SHA512_BLOCK_LENGTH ALLOT

\ Read n bytes from input file, store at addr array
: bytes@  ( adr u -- )  rfileid @  READ-FILE  2DROP ;
: block@  buf[]  SHA512_BLOCK_LENGTH  bytes@ ;

: File_SHA512 ( caddr u -- )
    R/O BIN OPEN-FILE  SWAP  rfileid !
    ABORT" Invalid input file."
    SHA512_Init                           \ Valid file, init transform
    rfileid @  FILE-SIZE  DROP  ( ud )    \ Get bytesize of input file
    CR ." Bytesize: " 2DUP  UD.             
    SHA512_BLOCK_LENGTH UM/MOD  ( rembytes nblocks )      \ Compute nblocks & rembytes
    0 ?DO
      block@
      buf[] SHA512_BLOCK_LENGTH SHA512_Update  
    LOOP      \ Do n full blocks
    buf[] swap  2dup bytes@
    SHA512_Update
    SHA512_End
    CR TYPE CR  \ Show SHA512 hash for file
    rfileid @  CLOSE-FILE  DROP 
;

