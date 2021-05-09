(
LANGUAGE    : ANS Forth 
PROJECT     : Forth Environments
DESCRIPTION : Neural net with backpropagation, main module.
CATEGORY    : Example
AUTHOR      : Marcel Hendrix, November 26 1989
LAST CHANGE : April 3rd, 1993, Marcel Hendrix, removed CURON / CUROFF
LAST CHANGE : March 2nd, 1992, Marcel Hendrix, dynamic array mods 
LAST CHANGE : October 13, 1991, Marcel Hendrix 
ADAPTED     : for kForth, September 18, 2003, Krishna Myneni
	      changed NO-CONNECTIONS to NO-ASSOCIATIONS and
	      ADD-PAIR to ASSOCIATE
)

\ The following files are required under kForth in order
\   to load backprop.4th. It is assumed that these files
\   will be INCLUDEd by the main program (e.g. ocr.4th).
\
\	strings.4th
\	ans-words.4th
\	utils.4th
\	ansi.4th
\


\ ************************************************** 
\							
\		    N E U R A L - N E T			
\							
\		    BACK-PROPAGATION CODE			
\							
\  FC:	Dave Parker, DDJ October '89		
\  LC:      Marcel Hendrix, November 18 1989		
\  LC:      November 22nd, fixed scaling bug		
\  LC:    November 25th, IT WORKS! Removed SFP	
\  LC:      June 20th, 1991 for tForth, MHX		
\							
\ ************************************************** 


\ -- Expects constants: Sensors, HiddenUnits and OutputUnits 


CR .( Backpropagation     Version 2.15-2 ) 

\ This program uses BACKPROPAGATION.
\
\ Parker's BackPropagationDemo is lucid, but it is obscure _how many_ hidden 
\ units are needed. I _assume_ one only links inputs to hidden units, then
\ hidden units to outputs. The EXOR-example illustrates this (numbers in
\ square boxes denote thresholds) :
\
\	Xor (M,W)			 Xor (M,W)
\	+--------+			 +--------+
\  +--->+   0.5	 +<----|	   +---->+  0.5	  +<----|
\  |	+--------+     |	   |	 +--------+	|
\  |	   /|\	       |	   |	    /|\		|
\  |1	    |-2	     1 |	   |1	     |-2      1 |
\  |	And |(M,W)     |	   |	 And |(M,W)	|
\  |	+---+----+     |	 +-+---+ +---+----+  +--+--+
\  |+-->+   1.5	 |<---+|	 | 0.5 | |  1.5	  |  | 0.5 |
\  ||	+--------+    ||	 +-+---+ +-+-----++  +--+--+
\  ||1		     1||	  1|-------|1	1|------|1
\ +-----+	   +---+--+	 +-+--+		     +--+--+
\ |     |	   |	  |	 |    |		     |	   |
\ +-----+	   +------+	 +----+		     +-----+
\ Monday	   Wednesday	 Monday		    Wednesday
\
\
\ The solution to the left needs links directly from input to output. The
\ left implementation does not (at the cost of lower performance?).
\
\ I tend to regard this as two networks switched in series, each network
\ needing LOCAL feedback when learning (output->hidden, hidden->input).
\
\ NOTE: We ALWAYS need a dummy '1' input. Without it, we can not build negated
\ outputs (NAND NOR NEXOR NOT etcetera.) Some researchers think this is obvious 
\ and neglect to mention it. It proved possible to build LRRH and ExorGate 
\ without inverters, but NandGate etcetera can not leave them out.
\
\
\   Structure of a Neural Net with only two layers: Hiddenlayer Outputlayer
\   -----------------------------------------------------------------------
\
\ The logical structure of a two-layer neural net can be described as follows:
\
\ - InputValues, the row vector of inputs (length n), serves as an input to the
\   neurons in the hidden layer.
\   A "complication" is that one element of InputValues, say InputValues[0],
\   MUST be '1' at all times, to enable inverted outputs.
\
\ Forward pass
\ ------------
\
\ - An hidden neuron k has n weights, one for every component of InputValues, 
\   and an 'error' field. When its time has come, the hidden neuron multiplies
\   InputValues with its WeightVector (by taking the dot product) and
\   applies this number to the activation function SIGMOID.  The result is
\   left on the stack to be stored into the kth field of HiddenOutputs.  (It is 
\   useful to save the result in an output field as we will need it to compute 
\   SIGMOID' on the backward pass).  The neuron also clears its error field.
\ 
\ - If the HiddenOutputs vector (length k) is complete, it can be used as input
\   to the output layer.
\
\ - An output neuron p has k weights, one for every component of HiddenOutputs,
\   and an 'error' field.  When its time has come,  an output neuron multiplies
\   HiddenOutputs with its WeightVector (dot product, remember) and applies
\   this number to the activation function SIGMOID.  The result is stored into
\   the pth field of OutputValues, and the Error Field is cleared.  Again we 
\   save the result for use on the backward pass.  Except for different numbers
\   and naming of indices,  this is exactly the same procedure as for the 
\   Hiddenlayer.
\
\ Teacher comes along
\ -------------------
\
\ The difference between the wanted output and the output from the net after
\ the forward pass is taken and stored in the error fields of the outputlayer.
\
\ Backward pass
\ -------------
\
\ - Outputlayer:
\    1] Every neuron multiplies its Error with SIGMOID'.  Each neuron in the
\       hidden layer that is connected to the output layer neuron in question
\       via weight Wab, has its ErrorField incremented by error*SIGMOID'*Wab. 
\       This is the actual back propagation of error.
\
\    2] For all x: The weight 'x' of the output layer neuron p is incremented 
\       by Error(p)*SIGMOID'(p)*LearningRate*HiddenOutputs[x]
\
\ - Hiddenlayer:
\    ( Step 1] above is useless here )
\    2] For all y: The weight 'y' of the hidden layer neuron h is incremented 
\       by Error(h)*SIGMOID'(h)*LearningRate*InputValues[y]
\
\ We now repeat the forward and backward pass for all input vectors that
\ have to be learned, until the error of the output layer is insignificant.
\ LearningRate can be increased to make the learning faster, but this may 
\ cause oscillation.
\
\ NOTE: You may very well wonder about SIGMOID': shouldn't that be 
\ inverse(SIGMOID) instead of the derivative?  In fact, using SIGMOID' and
\ prescribing an 'S'-like function for SIGMOID is the only way of getting some
\ kind of permanent memory into the system. You could liken it to a form of
\ hysteresis; once the output saturates, SIGMOID' approaches zero and VERY large
\ errors are needed to back-change the weights corresponding to this output. The 
\ general effect is that once outputs stabilize to 'ON' or 'OFF', their weights 
\ more ore less lock into position, and the less certain outputs get a chance 
\ to optimize their firing.
\
\				Graphical
\				---------
\
\ InputValues	HiddenLayer	    HiddenOutputs    Outputlayer   OutputValues
\ -----------	-----------	    -------------    -----------   ------------
\
\	Weights	                             
\       +--------\                     Bj              
\  Ai   |  +------\-- Sum -> SIGMOID -----+ 
\ ------*  |  +---/   	          	  |  Weights    
\ ---*--|--*  |                           +---------\
\ ---|--|--|--+                                      \--- Sum -> SIGMOID -->
\    |  |  |                                         /
\ (n)|  |  |                              +---------/
\    |  |  +------\                       |  (h)                        (p)
\    |  +---------/-- Sum -> SIGMOID -----+  
\    +-----------/			     
\	 h * n				      p * h
\

\ The above neural net shows 3 inputs, 2 hidden neurons, and 1 output.

\ ************************************************** 
\							
\		    N E U R A L - N E T			
\							
\		    BACK-PROPAGATION DATASTRUCTS
\
\  FC:	Dave Parker, DDJ October '89		
\  LC:      Marcel Hendrix, November 18 1989		
\  LC:      November 22nd, fixed scaling bug		
\  LC:    November 25th, IT WORKS! Removed SFP	
\  LC:      June 20th, 1991 for tForth, MHX		
\							
\ ************************************************** 

\ -- General Utility *******************************************

\	It was VERY DIFFICULT to find the right combination of the
\	scale factor "1" and the proper way to round-off results. If 
\	this is done incorrectly, the network will not converge, but 
\	perform limit-cycling, especially when weights and/or inputs 
\	are low.


\ ================== kForth requires ========================

27 CONSTANT ESC
25 CONSTANT L/SCR

: @+ ( a -- a' u ) DUP CELL+ SWAP @ ;
: CELL- ( a -- a2 ) 1 CELLS - ; 
: []CELL ( u a -- a2 ) SWAP CELLS + ;
: ARRAY ( u -- ) CREATE CELLS ALLOT 
	DOES>  ( index -- value )  []CELL @ ;
: 'OF ( -- a ) ' >BODY STATE @ IF POSTPONE LITERAL THEN ; IMMEDIATE
: =: CREATE 1 CELLS ?ALLOT ! DOES> a@ ;

\ Pseudo-random number generation
variable last-rn
time&date 2drop 2drop drop last-rn !  \ seed the rng

: lcrng ( -- n ) last-rn @ 31415928 * 2171828 + 31415927 mod dup last-rn ! ;

: next_ran ( -- n | random number from 0 to 255 )
	0 8 0 do 1 lshift lcrng 1 and or loop ;

: choose ( n -- n' | arbitrarily choose a number between 0 and n-1)
 	dup next_ran * 255 / swap 1- min ;

: >INVERSE< ;
\ ================== end of kForth requires =================



( ****	Change "1" for different input range ********************** )

2048 constant "1"

( ****	End input range specification ***************************** )


\
\	An output is considered:
\
\		 'on'  when it is >= One
\	 	 'off' when it is <= Zero
\
\	Whenever an output is > "0.5", but below One,
\	or < "0.5" but greater than Zero, there is doubt:
\
\	0..........Zero.........0.5........One..........1
\	<-- 'Off' --><-- ?Off --> <-- ?On --><-- 'On' -->
\


"1" 2/		constant "0.5"		\ -- switch-over point
"1" 10 /	constant Zero		\ -- Minimum ..
"1" 9 10 */	constant One		\ -- .. maximum neuron output
8 		constant MaxExp		\ -- Range: 1/(1+exp(8)) to 1/(1+exp(-8))
10 		constant Zoom		\ -- integer divisions between -8, 8

MaxExp Zoom * 	constant +maxix		\ -- ABS(maximum index)
+maxix NEGATE 	constant -maxix

\ CREATE sigval
	DECIMAL	  ( NOTE: maxix 2* 1+ values ! )
             1       1       1       1       1       1       1  
             1       2       2       2       2       2       3  
             3       3       3       4       4       5       5  
             6       6       7       8       9       9      10  
            11      13      14      15      17      19      21  
            23      25      28      31      34      37      41  
            45      50      55      61      67      74      81  
            89      98     108     119     130     143     157  
           172     188     206     225     246     268     292  
           318     346     375     407     440     476     513  
           552     593     636     681     727     774     823  
           872     922     973    1024    1075    1126    1176  
          1225    1274    1321    1367    1412    1455    1496  
          1535    1572    1608    1641    1673    1702    1730  
          1756    1780    1802    1823    1842    1860    1876  
          1891    1905    1918    1929    1940    1950    1959  
          1967    1974    1981    1987    1993    1998    2003  
          2007    2011    2014    2017    2020    2023    2025  
          2027    2029    2031    2033    2034    2035    2037  
          2038    2039    2039    2040    2041    2042    2042  
          2043    2043    2044    2044    2045    2045    2045  
          2045    2046    2046    2046    2046    2046    2047  
          2047    2047    2047    2047    2047    2047  
	  2047 	   ( <= catches index = maxix )

+maxix 2* 1+ table sigval
	
\ "1" #2048 <> [IF] CR .( SIGMOID invalid!) QUIT
\ [THEN]

: SIGMOID  \ <x*"1"> -- <1/(1+exp(-x))>
	"1" Zoom / 
	/
	-maxix MAX  +maxix MIN
	+maxix + CELLS sigval + @ ;


\ SIGMOID
\
\ If you have floating point, you can use it to build the sigmoid function


"1" S>F FCONSTANT "fone"	

: FSIGMOID      "fone"			\ <dx*"1"> --- <1/(1+exp(-x))>
		2SWAP
		DNEGATE D>F 
		"fone" F/ FEXP 1e F+ ( F1+) F/
		FROUND>S ; 		\ 0.."1"

: !table
   +maxix -maxix DO 
     I "1" Zoom /  M* FSIGMOID
     I -maxix MAX  +maxix MIN
     +maxix + CELLS sigval + !
   LOOP ; 

\ !table  ( no need to rebuild the table using FSIGMOID )

\ -- Scaled division, using round-off (can't do without!)

: DSCALE	( d -- d/"1")
	DUP >R DABS 		
	"1" UM/MOD
	SWAP "0.5" >= IF 1+ THEN
	R> 0< IF NEGATE THEN ;

: *SCALE	( n1 n --- n1*n/"1")
	M* DSCALE ;	


\ SIGMOID' is the derivative of the Weber-Fechner activation function
\ SIGMOID, or Opj, where Opj = 1 / ( 1 + exp(-Ei) ); 
\
\	 Ei = Sum{ Wji Opi+j }, => Opj'= Opj (1-Opj). 
\
\ So if we know SIGMOID, we do NOT need SIGMOID'. 


\ -- Data: <error> <output> <#weights> <w11> <w12>....<wij>

: SIGMOID'	( addr --- out*[1-out]*err)
	2@ SWAP			
	"1" OVER - *SCALE 
	*SCALE ;


\ F-4TH compatibility
\
\ Note1: The number of neurons is ONLY limited by available RAM.
\ Note2: /inputs and /hidden are both one higher than requested; this accounts 
\	for the dummy "one" in these layers.


Sensors     1+ VALUE /inputs	\ -- #input  values
HiddenUnits 1+ VALUE /hidden	\ -- #hidden values
OutputUnits    VALUE /outputs	\ -- #output values


/inputs  ARRAY InputValues	\ -- The arrays hold input (excitation),
/hidden  ARRAY HiddenOutputs	\ -- hidden neuron output,
/outputs ARRAY DesiredOutputs	\ -- desired output,
/outputs ARRAY ActualOutputs	\ -- Temporary output (For .OUTPUT)

'OF InputValues    =: 'InputValues
'OF HiddenOutputs  =: 'HiddenOutputs
'OF DesiredOutputs =: 'DesiredOutputs
'OF ActualOutputs  =: 'ActualOutputs


One 0 'HiddenOutputs []CELL !	\ -- Initialize dummy

    0 VALUE |error| 		\ -- Measure how close we are to our goal.
   40 VALUE LearningRate	\ -- Adjusts how fast the net learns.
 3000 VALUE Retries		\ -- Retry if learning fails to converge.

: >BIT ( input -- bit ) 
   0> IF One ELSE Zero THEN ;

\ -- In case you forgot: 0 ROLL does nothing, 1 ROLL is SWAP, 
\      2 ROLL is ROT etc.

: sensor,	( ni .. n -- )
	Sensors 2+ CELLS ?ALLOT
	/inputs OVER ! CELL+	\ Note: danger if stack overflows!
	One OVER !		\ dummy, enables inverted outputs.
	1  Sensors ?DO  CELL+ I ROLL >BIT OVER ! -1 +LOOP DROP ;

: output,
	/outputs 1+ CELLS ?ALLOT	
	/outputs OVER !     	
	1  /outputs DO  CELL+ I ROLL >BIT OVER ! -1 +LOOP DROP ;


DEFER DO-IT!		\ -- This word will start the application
DEFER SHOW-NET		\ -- Display I/O patterns in text format.


\ -- Noise Module **********************************************

DEFER POLLUTE		\ -- Selectively pollute input vectors.

19 VALUE Noise
 0 VALUE ?noise

: doNoisy	
	Noise CHOOSE		\ <0|1> --- <probably the same>
	0= IF "1" 1-  XOR	\ once in a Noise times
	THEN ;		  	\ INCORRECT if "1" <> power-of-2
		
: Noisy	['] doNoisy IS POLLUTE 
	TRUE  TO ?noise ; 

: NOOP ;

: Clean	
	['] NOOP IS POLLUTE 
	FALSE TO ?noise ;

Clean

\ -- End Noise Module ******************************************


: FILL-inputs  	( 'inputpattern -- )
	CELL+ 			
	/inputs 0 ?DO  @+ POLLUTE I 'InputValues []CELL ! LOOP DROP ;


: FILL-outputs	( 'outputpattern -- )
	CELL+ 			
	'DesiredOutputs /outputs CELLS MOVE ;


\ Neuron and Layer Defining Words
\
\
\	-- A neuron should have error/output/weightcount fields and a 
\	-- WeightsArea. Sort of like an OOP:
\	-- Data: <error> <output> <#weights> <w11> <w12>....<wij>
\

0 VALUE %action			\ -- Dispatches messages

: EXCITE      0 TO %action ;	\ -- Neuron fires
: TRIMWEIGHTS 1 TO %action ;	\ -- Neuron adjusts its weights
: ZEROWEIGHTS 2 TO %action ;	\ -- Neuron randomly fills its weights
: DELTA	     3 TO %action ;	\ -- Neuron computes Wab*Opj'*error
: NEWERROR    4 TO %action ;	\ -- Set a Neuron's error field
: 'WEIGHTS    5 TO %action ;	\ -- Address of a Neuron's WeightArea
: CELL	     6 TO %action ;	\ -- Neuron's pfa
 
2VARIABLE excitement
VARIABLE S
VARIABLE T

: (XTC)		0 S>D excitement 2! 	\ <'input> <addr> --- <n>
		0 OVER !  		\ clear error field
		2 CELLS + @+ SWAP S !	\ 'weights and #weights
					\ == Update(Backward) ==
		0 ?DO @+		\ Get input value
		      I S a@ []CELL @	\ Get weight
		      M* excitement 2@
		      D+ excitement 2!
		LOOP DROP		\ remove 'input
		excitement 2@ DSCALE 	\ result is factor "1" too high
		SIGMOID 		\ square-off sum
		DUP S a@ 2 CELLS - ! ; 	\ update output field and leave result.


: (ADJ)		DUP 3 CELLS + T !	\ <'input> <size> <addr> --- <>
		SIGMOID'		\ output*(1-output)*error..
		LearningRate 100 */ S !	\ ..times learning rate
		T a@ CELL- @		\ #weights
		0 ?DO @+ S @ *SCALE	\ times input value
		      I T a@ []CELL +!	\ increment weight
		 LOOP 
		DROP ;


: (CLEAR)	2 CELLS + @+  		\ <addr> --- <>
		0 ?DO [ "0.5" 4 / 1+ ] LITERAL CHOOSE 
		      [ "0.5" 8 /    ] LITERAL - 
		      OVER I CELLS + ! 
		 LOOP DROP ;


: (DELTA)	SWAP 3 +		\ <ix> <addr> --- <double_delta>
		 OVER []CELL @		\ get weight ("1"^2  too high)
		SWAP SIGMOID' M* ;	\ (output)(1-output)*error*weight



\ -- Data: <error> <output> <#weights> <w11> <w12>....<wij>

: LAYER	CREATE	
(
	    2DUP 		  	\ <#neurons> <inputwidth> --- <>
	    3 + CELLS DUP ,		\ size of neuron structure in bytes
	    * ALLOCATE ?ALLOCATE DUP , 	\ #neurons, inputwidth, address
)
	    2DUP 3 + CELLS DUP >R	\ n w n w3cells 
	    * 2 CELLS + ?ALLOT		\ n w a
	    R> OVER !			\ n w a
	    CELL+ DUP CELL+ OVER !	   
	    CELL+			\ #neurons, inputwidth, address
	    -ROT S ! 			\ init length fields
	    0 ?DO  S @ 3 + CELLS  I *  
		   2 CELLS + OVER + 
		   S @ SWAP !
	     LOOP
	    One SWAP CELL+ !		\ Set output of (possibly dummy) to "1"
	DOES>	
	    DUP @ 			\ <ix> <'{size,addr}> --- <?>
	    SWAP CELL+ a@ SWAP		
	    ROT * +  			\ <ix> <addr> <size> --- <addr>
	    %action 0 TO %action
	    CASE
		 0  OF  (XTC)     ENDOF	  ( excite )
		 1  OF  (ADJ)     ENDOF	  ( trimweights )
		 2  OF  (CLEAR)   ENDOF   ( zeroweights )
		 3  OF  (DELTA)   ENDOF   ( delta )
		 4  OF  !         ENDOF   ( newerror )
		 5  OF  3 CELLS + ENDOF   ( 'weights )
		 6  OF 		  ENDOF   ( cell )
		 DUP ABORT" Invalid Layer Command"
	    ENDCASE ;




\ Examples:
( *
  'InputValues EXCITE  5  Hiddenlayer
  'HiddenOutputs TRIMWEIGHTS 2 Outputlayer
  ZEROWEIGHTS 5 Outputlayer
  9 DELTA 3 Hiddenlayer
* )



\  ****	Define the layers. ******************************************

	/hidden  ( #neurons ) /inputs ( inputs ) LAYER Hiddenlayer
	/outputs ( #neurons ) /hidden ( inputs ) LAYER Outputlayer

			 ( * End of Structures * ) 		



: Update(Forward)			\ <'inputvector> --- <>
	FILL-inputs

	/hidden 
	1 ?DO
	    'InputValues EXCITE I Hiddenlayer  
	    I 'HiddenOutputs []CELL !
	 LOOP
 
	One 0 'HiddenOutputs []CELL !
	/outputs 
	0 ?DO
 	    'HiddenOutputs EXCITE I Outputlayer  
	    I 'ActualOutputs []CELL !
	 LOOP ;

: Update(Backward)			\ <'outputvector> --- <>
	FILL-outputs
	/outputs
	0 ?DO
	      I DesiredOutputs I ActualOutputs -  
	      NEWERROR I Outputlayer
	 LOOP
	/hidden
	1 ?DO 0 S>D
	      /outputs 
	      0 ?DO
		   J DELTA I Outputlayer  D+
	       LOOP
	      DSCALE NEWERROR I Hiddenlayer
	 LOOP 
	/outputs
	0 ?DO
		'HiddenOutputs TRIMWEIGHTS I Outputlayer
	 LOOP
	/hidden 
	1 ?DO
		'InputValues TRIMWEIGHTS I Hiddenlayer
	 LOOP ;

( *
  An output is considered 'on'  when it is >= One-Criteria
  		          'off' when it is <= Zero+Criteria
  Whenever an output is > "0.5", but below One-Criteria,
  or < "0.5" but greater than Zero+Criteria, there is doubt:

  0........Zero+C.........0.5.......One-C.........1
  <-- 'Off' --><-- ?Off --> <-- ?On --><-- 'On' -->
* )


\ ?DEF HighlyAccurate [IF] "1" #30 /		( not encouraged )
\		    [ELSE] "1" #20 /		( works best )
\		    [THEN] =: Criteria

20 VALUE Criteria

: DIFFERENCES				\  <> --- <#errors>
		0 /outputs
		0 ?DO	I DesiredOutputs  I ActualOutputs 
			OVER One = IF        - Criteria >
			 	   ELSE SWAP - Criteria >
				   THEN
			1 AND +
		 LOOP ;
 
0 VALUE #Items

CREATE	Items	256  2 CELLS  *  ALLOT

: ClearLayers ( -- )
    /outputs 0 ?DO  
      ZEROWEIGHTS  I  Outputlayer  
    LOOP
    /hidden  1 ?DO
      ZEROWEIGHTS  I  Hiddenlayer 
    LOOP ;

: NO-ASSOCIATIONS ( -- )
   0 TO #Items
   ClearLayers ;

: Associate ( 'inputs 'outputs -- )
    #Items 1+ 			\  <'inputs> <'outputs> --- <>
    DUP 256 >= ABORT" Layer overflow"
    TO #Items   			\ Increment #Items..
    Items #Items 1- 2 CELLS * +  
    2! ;				\ ..add pair to list

: Remember?  ( -- b )
    0 TO |error|
    #Items 0 ?DO 
      Items I 2 CELLS * + 
      DUP CELL+ a@ SWAP a@ SWAP
      Update(Forward)	
      Update(Backward)
      |error| DIFFERENCES + TO |error|
    LOOP
    |error| 0= ;


		 ( * Formatting and Querying * ) 


: .BIT					    	\ <n> --- <>		
    "0.5" >= 1 AND [CHAR] 0 + EMIT ;

: .OUTPUTBIT	DUP				\ <n> --- <%error>
		Zero Criteria + 
		One  Criteria -
		WITHIN DUP >R
		IF >INVERSE< THEN		\ INVERSE if NOT sure about it.
		DUP "0.5" >= IF    One - ABS  100  One */ SWAP [CHAR] 1
		             ELSE Zero - ABS  100 Zero */ SWAP [CHAR] 0 
		             THEN EMIT
		R> IF >INVERSE< THEN ;


: PRINT		1000 "1" */ 			\ <n> --- <>
		S>D  DUP >R DABS
		<#  # # # [CHAR] . HOLD # 
		R> 0< IF  [CHAR] - ELSE BL  THEN HOLD
		#>  TYPE SPACE ;


22 VALUE itMAX		
 0 VALUE itMIN
10 VALUE ipMAX
 1 VALUE ipMIN
10 VALUE opMAX
 0 VALUE opMIN
10 VALUE hiMAX
 1 VALUE hiMIN

: ItemRANGE 	#Items   itMAX MIN  itMIN ;
: InputRANGE	/inputs  ipMAX MIN  ipMIN ;
: OutputRANGE	/outputs opMAX MIN  opMIN ;
: HiddenRANGE	/hidden  hiMAX MIN  hiMIN ;


: .STATUS	CR
		ItemRANGE
		  ?DO   Items I 2 CELLS * + 
		        DUP CELL+ a@ SWAP a@ 
			FILL-outputs Update(Forward)
			InputRANGE  DO  I InputValues .BIT
	 			  LOOP  SPACE [CHAR] | EMIT SPACE
			OutputRANGE DO  I ActualOutputs PRINT
			 	  LOOP  [CHAR] | EMIT SPACE
			OutputRANGE DO  I DesiredOutputs .BIT
				  LOOP  CR
		 LOOP ; 


TRUE  VALUE ?display
FALSE VALUE ?status
0     VALUE ?dot
3     VALUE RefreshRate


: .STATUS?	?dot RefreshRate MOD 0=
		?dot 1+ TO ?dot 
		?status AND ?display AND
		IF .STATUS THEN ;

: CONTAINS				\ 3 -rd CELL of Hiddenlayer CONTAINS
					\ <addr> --- <>  Diagnostic tool
		CR ." error | output | #weights | Weights " CR
		@+      5 .R 3 SPACES
		@+      6 .R 3 SPACES
		@+ DUP >R 6 .R 5 SPACES
		R> 0 ?DO  @+ 6 .R SPACE  LOOP DROP ; 


: DEC. ( n -- ) . ;

: .PARAMETERS				\ <n> --- <n+1>
		?noise IF 
		  >INVERSE<
		  ." Corruptions : 1 in " Noise DEC. 5 SPACES
		  >INVERSE<
		THEN ;

: WHATIF?				\ <'inputvector> --- <>
		Update(Forward)		\ assume InputValues set.
		SHOW-NET .PARAMETERS ;

: REACT WHATIF? ;		\ <'inputvector> --- <>

: .HEADER	?display 0= IF EXIT THEN
		PAGE ( HOME) 
		?status  0= IF CR EXIT THEN
		>INVERSE<
		  ." Input | Output | Target  (LearningRate = " 
		  LearningRate 4 .R [CHAR] ) EMIT  
		>INVERSE< CR CR ;

: .WEIGHTS ( -- )	
    cr ." --- Hidden Layer Weights ---" cr 
    HiddenRANGE DO
      cr I 'WEIGHTS Hiddenlayer  
      InputRANGE DO  @+ PRINT  LOOP drop
      /inputs ipMAX > IF ."  ..." THEN
    LOOP		 
    cr
	/hidden hiMAX > IF ."  :      :      :" THEN
    cr ." --- Output Layer Weights ---" cr
    OutputRANGE DO
      cr I 'WEIGHTS Outputlayer  
      HiddenRANGE DO  @+ PRINT  LOOP drop
      /hidden hiMAX > IF ."  ..." THEN
    LOOP 
    /outputs opMAX > IF ."  :      :      :" THEN ;


: .WEIGHTS?  ( -- )
    ?display ?status 0= AND 
    ?dot RefreshRate MOD 0= AND
    ?dot 1+ TO ?dot 
    IF  .WEIGHTS  THEN ;

: STOP-NET  ( -- )	
    ?display IF 0 20 AT-XY THEN 
    TRUE ABORT" user interrupt" ;

: test-user ( -- )
    BEGIN 
      KEY?
    WHILE
      KEY
      CASE 
        ESC       OF STOP-NET			      ENDOF
        [CHAR] +  OF LearningRate 2+ TO LearningRate      ENDOF
        [CHAR] -  OF LearningRate 2- 0 MAX TO LearningRate  ENDOF
        [CHAR] /  OF ?status  0= TO ?status PAGE CR       ENDOF
        [CHAR] D  OF ?display 0= TO ?display  PAGE        ENDOF
      ENDCASE
    REPEAT ;

: display  ( -- )
    TEST-USER	
    .HEADER 
    .STATUS? .WEIGHTS? ;


		 ( * Words to BUILD the net * )


variable attempts

: learned-all?  ( -- b )  \ TRUE if successful
    0 attempts !		
    Retries 0 DO  
      display	\ Rehearse old pairs
      remember? IF LEAVE THEN
      1 attempts +!
      12 cur_left attempts @ DEC. ." pass.." 
    LOOP
    ?display IF  0 L/SCR 5 - AT-XY  ELSE  CR  THEN
    attempts @ Retries = IF
	  ." Problems..." CR FALSE
	ELSE TRUE THEN ;



0 VALUE ?converged

: exam-ok?  ( -- b )	
   0 TO ?converged
   4 0 DO 
     learned-all? IF
       ?converged 1+ TO ?converged
     ELSE   
	    0 TO ?converged LEAVE
     THEN
   LOOP 
   ?converged 4 = ;


: drill  ( -- )		
   ?display IF  PAGE  
   ELSE ." .. working .. " CR
   THEN  
   BEGIN
     exam-ok? 0=
	WHILE	ClearLayers
	REPEAT	;

	
( * End of Source * ) 
