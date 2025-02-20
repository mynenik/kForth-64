\ gpib-test.4th
\
\ Test kForth interface to the linux-gpib driver using the HP multimeter
\
\ Revisions:
\   2011-09-14  km  updated to include modules.4th
\   2011-11-03  km  revised to use modular version of hp34401.4th
\   2021-05-06  km  uses gpib64.4th until integrated with gpib.4th
\   2021-07-15  km  updated to use Forth 200x standard data structures
\   2024-02-26  km  use loader, gpib.4th

include ans-words
include modules
include strings
include files
include struct-200x
include struct-200x-ext
include ioctl

include daq/gpib/gpib.4th
include daq/hp/hp34401.4th

: meter1 hp34401 ;

Also gpib

cr 
.( Opening GPIB driver ... )
∋ gpib open dup [IF] .( Error ) . [ELSE] drop .( ok ) [THEN] cr

.( Getting Board Info ... ) cr
∋ gpib ibboard_info
0= [IF]
  .( Board Primary Address:   ) gpinfo ul@ u. cr
  .( Board Secondary Address: ) gpinfo ( cell+) 4 + ul@ u. cr
[ELSE]
  .( ibboard Failed. ) cr
[THEN]
cr
.( Initializing GPIB interface ... )

∋ gpib init dup [IF] .( Error ) . [ELSE] drop .( ok ) [THEN] cr

.( Setting timeout ... )
  10000000 ∋ gpib ibtmo dup [IF] .( Error )  . [ELSE] drop .( ok ) [THEN] cr
   
.( Talking to meter at ADRESS ) ∋ meter1 get-pad . cr
.( Sending CLEAR DEVICE ) ∋ meter1 clear .( ... returns ) . cr
.( Reading meter: result = ) ∋ meter1 read f. cr
.( Closing GPIB ) ∋ gpib close .( ... returns ) . cr


