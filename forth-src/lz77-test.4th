\ lz77-test.4th
\
\ Test LZ77 words ENCODE and DECODE
\
include ans-words.4th
include strings.4th
include files.4th
include lz77.4th

\ Execute a shell command in kForth
: shell  ( c-addr u -- n ) strpck system ;

\ Write a line to the output file
: w ( caddr u -- ) out-file @ write-line drop ;

\ Delete file with check to see if it exists.
: del-file ( caddr u -- )
    2dup strpck file-exists 
    if delete-file drop else 2drop then ;

\ Show a binary file, replacing unprintable characters with '|'.
: show-bin-file ( caddr u -- )
    R/O open-file checked in-file !
    BEGIN
      pad 64 in-file @ read-file drop  \ -- u
      ?dup 0= IF cr in-file @ closed EXIT THEN
      cr
      0 ?do 
        pad i + c@ dup 
        32 123 within 0= if drop 124 then emit
      loop
    AGAIN ;

\ Show a text file on the console.
: show-txt-file ( caddr u -- )
    R/O open-file checked in-file !
    BEGIN
      pad 128 in-file @ read-line drop
      if  cr pad swap type false
      else drop true
      then
    UNTIL
    cr in-file @ closed ;


cr .( 0. Creating text file 'green-eggs.txt' if it does not exist.) cr
   s" green-eggs.txt" strpck file-exists 0= [IF]
     s" green-eggs.txt" W/O create-file checked out-file !
     s"     That Sam-I-am!"  2dup w w
     s"     I do not like that Sam-I-am!"  w
     s" "  w
     s"     Do you like green eggs and ham?"  w
     s" "  w
     s"     I do not like them, Sam-I-am."  w
     s"     I do not like green eggs and ham."  w
     s" "  w
     out-file @ closed
     .(    File created.)
  [ELSE]
     .(    File exists.)
  [THEN]
  cr
  
cr .( 1. Deleting files, {'green-eggs.lz','green-eggs2.txt'}, if they exist.) cr
   s" green-eggs.lz"   del-file 
   s" green-eggs2.txt" del-file

cr .( 2. Encoding 'green-eggs.txt' to 'green-eggs.lz'.) cr
   s" green-eggs.txt" R/O  open-file    checked  in-file   !
   s" green-eggs.lz"  W/O  create-file  checked  out-file  !
   ENCODE
   in-file @ closed    out-file @ closed

cr .( 3. Contents of 'green-eggs.lz':) cr
   s" green-eggs.lz" show-bin-file

cr .( 4. Decoding 'green-eggs.lz' to 'green-eggs2.txt'.) cr
   s" green-eggs.lz"   R/O  open-file    checked  in-file   !
   s" green-eggs2.txt" W/O  create-file  checked  out-file  !
   DECODE
   in-file @ closed    out-file @ closed

cr .( 5. Contents of 'green-eggs2.txt':) cr
   s" green-eggs2.txt" show-txt-file

cr .( 6. Comparing decoded file to the original: )
   s" diff green-eggs.txt green-eggs2.txt" shell
[IF]
  .( FAILED!) cr
  .(    Files are not the same.)
[ELSE]
  .( SUCCESS.)
[THEN]
cr

