\ gpib.4th
\
\ Loader for Forth to Linux GPIB driver interface
\
1 cells 8 = [IF]
cr .( Loading 64-bit GPIB interface. ) cr
include daq/gpib/gpib64
[ELSE]
cr .( Loading 32-bit GPIB interface. ) cr
include daq/gpib/gpib32
[THEN]

