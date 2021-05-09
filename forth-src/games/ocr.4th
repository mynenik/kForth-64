( *
 * LANGUAGE    : ANS Forth 
 * PROJECT     : Forth Environments
 * DESCRIPTION : neural net with backpropagation
 * CATEGORY    : Example
 * AUTHOR      : Marcel Hendrix, November 26 1989
 * LAST CHANGE : October 13, 1991, Marcel Hendrix 
 * ADAPTED     : for kForth, Sep 18, 2003, Krishna Myneni
 * )

\ kForth requires the following files and definitions:

include strings
include ans-words
include utils
include ansi

variable start-time

: TIMER-RESET ( -- ) MS@ start-time ! ;
: .ELAPSED ( -- )
	   MS@ start-time @ - 100 / S>D 
	   <# # [CHAR] . HOLD # #S #> TYPE 
	   ."  seconds elapsed." ;

\ end of kForth requirements

\ ****	Define the layers. ******************************************


 140 constant Sensors	  \ Dyadic functions, note extra elements for dummies.
  10 constant HiddenUnits  \ set up 1-dimensional I/Hidden/O vectors
   5 constant OutputUnits  \ 5 outputs: bits 0..4

PAGE

INCLUDE backprop.4th

CR .( Neural App: OCR     Version 1.10-2 )



\ ****	End of layer defs. ******************************************

			( * Application Level * )

 14  constant SensorRows
 10  constant HSensors

: .ABOUT
CR
CR ."     **   OCR in Multi-layered  Neural-Net using back-propagation   **"
CR ."              This net classifies bitmaps to ASCII characters" 
CR
CR ." <l> <s> ASSOCIATE         -- The input pattern <l> is associated to output <s>."
CR ."                              <l> (= {bm:A .. bm:Z}  <s> (= {ac:A .. ac:Z}"
CR ." DRILL                     -- Learns all associated pairs."
CR ." NO-ASSOCIATIONS           -- Forget all associations."
CR ." <l> REACT                 -- Input <l> to the network and show output."
CR ." .STATUS                   -- Prints inputs | outputs | targets."
CR ." .WEIGHTS                  -- Prints all weights."
CR ." <z> TO LearningRate       -- LearningRate, oscillates if too large (>1000)."
CR ." <w> TO Retries            -- Max number of retries (normally 3000)."
CR ." Noisy | Clean             -- Select if input is noisy or not."
CR ." <y> TO Noise              -- 1 out of <y> pixels in <l> is corrupted, if Noisy."
CR ." FALSE | TRUE TO ?display  -- See matrices during learning or not."
CR ." DO-IT!                    -- Sets up defaults and learns the patterns."
CR ." .ABOUT                    -- Print this info." CR
CR ." Note: When running,       '+'  and  '-' influence LearningRate,"
CR ."                           '/'  switches between .STATUS and .WEIGHTS,"
CR ."                           'D'  turns display on and off,"
CR ."                           'ESC' breaks."
CR 
CR ." (Suggested: DO-IT!  bm:A REACT  Noisy bm:A REACT)" ;

CREATE bm:A	0 0 0 0 0 0 0 0 0 0 
		0 0 1 1 1 1 0 0 0 0 
		0 1 1 0 0 1 1 0 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 1 1 1 1 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:B     0 0 0 0 0 0 0 0 0 0 
		1 1 1 1 1 1 0 0 0 0 
		1 1 0 0 0 1 1 0 0 0 
		1 1 0 0 0 1 1 0 0 0 
		1 1 0 0 0 1 1 0 0 0 
		1 1 1 1 1 1 1 0 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 1 1 1 1 1 0 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:C	0 0 0 0 0 0 0 0 0 0 
		0 0 1 1 1 1 1 0 0 0 
		0 1 1 0 0 0 1 1 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		0 1 1 0 0 0 1 1 0 0 
		0 0 1 1 1 1 1 0 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:D	0 0 0 0 0 0 0 0 0 0 
		1 1 1 1 1 1 1 0 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 1 1 1 1 1 0 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:E     0 0 0 0 0 0 0 0 0 0 
		1 1 1 1 1 1 1 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 1 1 1 1 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 1 1 1 1 1 0 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:F     0 0 0 0 0 0 0 0 0 0 
		1 1 1 1 1 1 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 1 1 1 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:G	0 0 0 0 0 0 0 0 0 0 
		0 0 1 1 1 1 1 0 0 0 
		0 1 1 0 0 0 1 1 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 1 1 1 1 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		0 1 1 0 0 0 1 1 0 0 
		0 0 1 1 1 1 1 1 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:M	0 0 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		1 1 1 0 0 0 1 1 1 0 
		1 1 1 1 0 1 1 1 1 0 
		1 1 0 1 1 1 0 1 1 0 
		1 1 0 0 1 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:S	0 0 0 0 0 0 0 0 0 0 
		0 1 1 1 1 1 1 0 0 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		0 1 1 1 1 1 1 0 0 0 
		0 0 0 0 0 0 1 1 0 0 
		0 0 0 0 0 0 1 1 0 0 
		0 0 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		0 1 1 1 1 1 1 0 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

	\ Hors concours: displaced patterns, to test performance ****
	\ Backpropagation does NOT handle this as well as a BAM!

CREATE bm:M'	0 0 0 0 0 0 0 0 0 0 
		0 1 1 0 0 0 0 0 1 1  \ Translated Right.
		0 1 1 0 0 0 0 0 1 1  \ Will the network map this on M?
		0 1 1 1 0 0 0 1 1 1  \ YES!
		0 1 1 1 1 0 1 1 1 1 
		0 1 1 0 1 1 1 0 1 1 
		0 1 1 0 0 1 0 0 1 1 
		0 1 1 0 0 0 0 0 1 1 
		0 1 1 0 0 0 0 0 1 1 
		0 1 1 0 0 0 0 0 1 1 
		0 1 1 0 0 0 0 0 1 1 
		0 1 1 0 0 0 0 0 1 1 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:M_	1 1 0 0 0 0 0 1 1 0 	\ shifted up 1 row
		1 1 0 0 0 0 0 1 1 0 
		1 1 1 0 0 0 1 1 1 0 
		1 1 1 1 0 1 1 1 1 0 
		1 1 0 1 1 1 0 1 1 0 
		1 1 0 0 1 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		1 1 0 0 0 0 0 1 1 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:S'	0 0 0 0 0 0 0 0 0 0 	\ translated right
		0 0 1 1 1 1 1 1 0 0 
		0 1 1 0 0 0 0 1 1 0 
		0 1 1 0 0 0 0 0 0 0 
		0 1 1 0 0 0 0 0 0 0 
		0 1 1 0 0 0 0 0 0 0 
		0 0 1 1 1 1 1 1 0 0 
		0 0 0 0 0 0 0 1 1 0 
		0 0 0 0 0 0 0 1 1 0 
		0 0 0 0 0 0 0 1 1 0 
		0 1 1 0 0 0 0 1 1 0 
		0 0 1 1 1 1 1 1 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:S_	0 1 1 1 1 1 1 0 0 0 	\ shifted up 1 row
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		0 1 1 1 1 1 1 0 0 0 
		0 0 0 0 0 0 1 1 0 0 
		0 0 0 0 0 0 1 1 0 0 
		0 0 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		0 1 1 1 1 1 1 0 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:G'	0 0 0 0 0 0 0 0 0 0 	\ Horizontally displaced. Okay.
		0 0 0 1 1 1 1 1 0 0 
		0 0 1 1 0 0 0 1 1 0 
		0 1 1 0 0 0 0 0 0 0 
		0 1 1 0 0 0 0 0 0 0 
		0 1 1 0 0 0 0 0 0 0 
		0 1 1 0 0 0 0 0 0 0 
		0 1 1 0 0 0 1 1 1 1 
		0 1 1 0 0 0 0 1 1 0 
		0 1 1 0 0 0 0 1 1 0 
		0 0 1 1 0 0 0 1 1 0 
		0 0 0 1 1 1 1 1 1 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

CREATE bm:G_	0 0 1 1 1 1 1 0 0 0 	\ shifted up 1 row
		0 1 1 0 0 0 1 1 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 0 0 0 0 0 
		1 1 0 0 0 1 1 1 1 0 
		1 1 0 0 0 0 1 1 0 0 
		1 1 0 0 0 0 1 1 0 0 
		0 1 1 0 0 0 1 1 0 0 
		0 0 1 1 1 1 1 1 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 
		0 0 0 0 0 0 0 0 0 0 sensor,

	\ End test patterns *****************************************

CREATE ac:A	0 0 0 0 1 output,	\  1  
CREATE ac:B	0 0 0 1 0 output,	\  2  
CREATE ac:C	0 0 0 1 1 output,	\  3  
CREATE ac:D	0 0 1 0 0 output,	\  4  
CREATE ac:E	0 0 1 0 1 output,	\  5  
CREATE ac:F	0 0 1 1 0 output,	\  6  
CREATE ac:G	0 0 1 1 1 output,	\  7  
CREATE ac:M	0 1 1 0 1 output,	\ 13
CREATE ac:S	1 0 0 1 1 output,	\ 19

/inputs VALUE   #Temp
/inputs ARRAY	Temp	
'OF Temp =: 'Temp
One 0 'Temp []CELL !

: bm:SHIFT	'Temp CELL+ 			\ <'input> <+pixels> --- <'ip>
		Sensors CELLS ERASE
		CELLS >R  @+ 1- CELLS R> MIN >R CELL+
		'Temp CELL+ R@ + 
		Sensors CELLS R> - CMOVE 
		'OF #Temp ;

: .INPUTBIT					\ <n> --- <>
		"0.5" > IF [CHAR] *
		      ELSE ( [CHAR] ú) bl
		     THEN EMIT ;

	\ An output is considered 'on'  when it is >= One
	\ 			  'off' when it is <= Zero
	\ Whenever an output is > "0.5", but below One,
	\ or < "0.5" but greater than Zero, there is doubt:

	\ 0..........Zero.........0.5........One..........1
	\ <-- 'Off' --><-- ?Off --> <-- ?On --><-- 'On' -->


: doOCRShow	CR ." The net observes the following input bit pattern: " CR 
		SensorRows
		 0 DO CR
			HSensors 0 DO J HSensors * I + 1+ InputValues .INPUTBIT
			   	 LOOP
		 LOOP
		CR ." That is why it outputs the binary string: %"
		0 ( %error )
		/outputs 
		 0 DO I ActualOutputs .OUTPUTBIT +
		 LOOP
		0 /outputs
		 0 DO 1 LSHIFT  I ActualOutputs "0.5" > IF 1 OR THEN 
		 LOOP
		." , meaning: '" [CHAR] @ + EMIT ." ', with " 
		/outputs / 1 .R ." % error." CR ;

: OCRShow	['] doOCRShow  IS SHOW-NET ;


: doMultiOCR	 TIMER-RESET
		 NO-ASSOCIATIONS
		 bm:A  ac:A  ASSOCIATE
		 bm:B  ac:B  ASSOCIATE
		 bm:C  ac:C  ASSOCIATE
		 bm:D  ac:D  ASSOCIATE
		 bm:E  ac:E  ASSOCIATE
		 bm:F  ac:F  ASSOCIATE
		 bm:G  ac:G  ASSOCIATE
		 bm:M  ac:M  ASSOCIATE		\ Define OCR functions
		 bm:S  ac:S  ASSOCIATE
		 CR CR
		 ." Learning to recognize the following 14x10 pixel characters:"
		 CR CR 9 EMIT
		 ." A  B  C  D  E  F  G  M  S" CR CR
		 DRILL
		 .ELAPSED ;


: MultiOCR 	['] doMultiOCR IS DO-IT! ;

		OCRShow MultiOCR
		200 TO LearningRate
		false TO ?display
		.ABOUT

		( * End of Application * )
