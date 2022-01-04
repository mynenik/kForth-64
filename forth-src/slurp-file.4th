\ slurp-file.4th
\
\ Read the contents of a file into a memory buffer.
\ similar to Gforth's SLURP-FILE
\
\    SLURP-FILE  ( c-addr1 u1 -- c-addr2 u2 )
\
\ c-addr1 u1 is the filename string and c-addr2 u2 is the 
\ buffer address and size upon success. Errors in SLURP-FILE
\ are thrown for external handling using CATCH. The following 
\ throw codes may occur:
\
\     -73  -70  -69  -66  -62  -59  1  2
\
\ Program-defined error codes are 1 and 2, file too large,
\ and slurp size does not match requested read size. The
\ value MAX_SLURP may be adjusted below for use with your
\ system.
\
\ In addition to CATCHing thrown errors, it is up to the
\ user to free the allocated buffer into which the file
\ contents are written, when the buffer is no longer needed.
\
\
\ Example:
\
\ s" m41_inverted_2.png" slurp-file
\  ok
\ .s
\
\		1610282
\	addr	140100436811792
\  ok
\ over 16 dump  ( reformatted output below )
\
\ 7F6BACC4E010  :  89  50  4E  47  0D  0A  1A  0A
\                  00  00  00  0D  49  48  44  52  
\                  .PNG........IHDR ok
\
\ swap free 2drop
\  ok
\
\
\ Required:
\   ans-words.4th
\   strings.4th
\   files.4th
\
\ Optional:
\   dump.4th

1024 1024 * 64 * value MAX_SLURP   \ 64 MB limit

0 ptr slurp_buf
variable slurp_fid
variable slurp_size

: slurp-file ( c-addr1 u1 -- c-addr2 u2)
    0 slurp_size !
    R/O BIN open-file 
    if -69 throw 
    then dup slurp_fid !
    file-size  
    if -66 throw 
    then
    0<> over MAX_SLURP > or 
    if 1 throw      \ File too large
    then dup slurp_size ! allocate
    if -59 throw
    then to slurp_buf
    0 s>d slurp_fid @ reposition-file
    if -73 throw
    then  slurp_buf slurp_size @ slurp_fid @ read-file
    if -70 throw 
    then  slurp_size @ over <>
    if  2 throw    \  Slurp size and read size do not match
    then slurp_buf swap
    slurp_fid @ close-file
    if  -62 throw
    then ;


