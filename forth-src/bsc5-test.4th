\ bsc5-test.4th
\
\ Verify proper reading of the Yale Bright Star Catalog
\ binary file [1].
\
\ K. Myneni, 2014-10-03
\
\ Revised:
\   2026-03-26  km  use Forth 200x structures, 32-bit/64-bit
\
\ References:
\   1. http://tdc-www.harvard.edu/catalogs/bsc5.html


\ The following four are needed by kForth.
include ans-words
include strings
include files
include utils

include struct-200x
include struct-200x-ext
include modules
include bsc5-structs
include bsc5-reader

\ Expose the module interfaces

Also bsc5-structs
Also bsc5-reader

\ catalog handles
0 ptr cat
variable nstars

\ Open the BSC5 catalog
s" BSC5.bin" open-catalog ABORT" Unable to open catalog: BSC5."
to cat
cat get-nstars nstars !
cr nstars ? .( stars in catalog. ) cr

\ Catalog handle to record address.
: >rec ( handle u -- arec ) 1- REC_SIZE * + HDR_SIZE + ;

: print-sf ( F: r -- ) precision >r 6 set-precision fs. r> set-precision ;
: print-df ( F: r -- ) precision >r 8 set-precision fs. r> set-precision ;

\ Display record u of catalog.
: show-record ( handle u -- )
    dup 1 nstars @ 1+ within 0= Abort" Record number out of range!"
    >rec
    dup r_xno sf@ ftrunc>s
        cr ." Catalog number: " 6 .r
    dup r_sra0 df@
        cr ." Right Ascension (rad): " print-df
    dup r_sdec0 df@
        cr ." Declination (rad):     " print-df
    dup r_spec cr ." Spectral Type: " 2 type
    dup r_mag w@ s>f 100e f/
        cr ." Visual Magnitude: " 6 2 f.rd
    dup r_xrpm sf@
        cr ." R.A. Proper Motion (rad/year): " print-sf
        r_xdpm sf@
        cr ." Dec. Proper Motion (rad/year): " print-sf
    cr
;

\ Display the first and last records of the catalog.
cr .( Printing first and last star records in BSC5 ) cr
cat 1 show-record
cr
cat dup get-nstars show-record
cr

cr .( To show record for star n, type 'cat <n> show-record' e.g. ) cr
cr .(   'cat 3652 show-record' ) cr cr

\ Close the catalog (free the memory).
\ cat close-catalog drop
  
