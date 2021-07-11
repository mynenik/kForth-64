\ four1-test.4th
\
\ Test Forth version of Numerical Recipes routine four1
\
include ans-words
include fsl/fsl-util
include fsl/complex
include fsl/extras/four1

2048 FLOAT array a{ 
2048 FLOAT array b{
fvariable pulse_height
variable pulse_width
variable start_pulse
variable stop_pulse

variable ntrials
1000 ntrials !

1024 constant IMAX

: setup-pulse ( -- )

    100 pulse_width !
    1e pulse_height f!
    
    IMAX pulse_width @ - 1- start_pulse !
    IMAX pulse_width @ + 1- stop_pulse !
    
    \ Fill array with rectangular pulse data

    IMAX 2* 0 DO
	I start_pulse @ > IF
	    I stop_pulse @ < IF  pulse_height f@ ELSE 0e THEN 
	ELSE 0e THEN
	0e zdup a{ I } z!  b{ I } z!
    2 +LOOP
;

: print-array ( 'a -- )
    IMAX 2* 0 DO
	dup I } F@ F. 2 spaces dup I 1+ } F@ F. cr
    2 +LOOP
    drop ;

: power-spectrum ( 'a -- | print out the power spectrum for given array )
    IMAX 2* 0 DO  dup I } z@ |z|^2 F. CR  2 +LOOP
    drop ;


: verify-four1 ( -- | compute the FFT of the pulse and print its power spectrum )
    setup-pulse
    IMAX 1 a{ }four1
    \ a{ print-array
    a{ power-spectrum
;


: test ( -- | Test the speed of }four1 )
    setup-pulse
    ms@
    ntrials @ 0 DO  IMAX 1 b{ }four1  LOOP
    ms@ swap - .
;

