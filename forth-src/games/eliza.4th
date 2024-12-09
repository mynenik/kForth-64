( *
 * LANGUAGE    : ANS Forth 
 * PROJECT     : Forth Environments
 * DESCRIPTION : Eliza is a psychiatrist of the Carl Roger school.
 * CATEGORY    : AI Game, text based, by Joseph Weizenbaum.
 * AUTHOR      : Marcel Hendrix, November 11, 1986
 * LAST CHANGE : July 24, 1993, Marcel Hendrix, case problem my$ My$
 * LAST CHANGE : March 20, 1992, Marcel Hendrix, new TO strings
 * LAST CHANGE : March 15, 1992, Marcel Hendrix 
 * REVISION    : March 23, 2002, Krishna Myneni, major revision for 
 *                 use with other ANS Forths: tested on kForth, PFE, Gforth
 * REVISION    : March 9, 2003, Krishna Myneni, SEARCH and COMPARE
                   are now part of kForth so equiv. defs removed 
 * REVISION    : March 15, 2003, Krishna Myneni, removed strings
	           code for ANS Forths, since strings.4th is now
		   available for other Forths. 
* )
\ ==== Definitions needed for ANS Forths====

( \ start of comment

 synonym a@ @ 			\ ANS Forth 
 : ?allot  HERE SWAP ALLOT ;	\ ANS Forth 
 : not invert ;  		\ Gforth 
 : 2+ 2 + ;      		\ Gforth 
 : 2- 2 - ;      		\ Gforth 

 ) \ end of comment

\ =====End of defs for ANS Forth============

include ans-words
include strings    
include ansi
include utils

DECIMAL

\ ============== Some prerequisites ==========================
	
: >upper ( a u -- a u )
	2DUP 0 ?DO DUP C@ DUP is_lc_alpha IF 95 AND THEN OVER C! 1+ LOOP DROP ;

: c@+  ( a -- a+1 u )  DUP 1+ SWAP C@ ;

: $in ( a u -- | input a counted string at buffer a with max size u)
	1- OVER 1+ SWAP ACCEPT SWAP C! ;

: $=  ( a1 u1 a2 u2 -- flag | true if strings are equal ) 
        COMPARE 0= ;

: substitute ( a1 u1 a2 u2 a3 u3 -- | substitute string a2 u2 for a1 u1
	in string a3 u3 )
	2ROT SEARCH IF DROP SWAP CMOVE ELSE 2DROP 2DROP THEN ;

: choose ( n -- n' | arbitrarily choose a number between 0 and n-1)
	1- TIME&DATE 2DROP DROP XOR XOR * 60 / ;

\ ==========================================================
	
 3  CONSTANT  #Resp
18  CONSTANT  #Conjupairs
80  CONSTANT  C/L

VARIABLE  last-c
VARIABLE  char#
VARIABLE  phrase_voc

: Rmargin	C/L 10 - ;	
: CR		CR  0 char# ! ;
: SPACE		char# @ IF  BL EMIT  1 char# +! THEN ;

: emit'		char# @ 1+ Rmargin > OVER BL = AND	\ <char> --- <>
		IF  CR DROP  
		ELSE  DUP last-c !  EMIT  1 char# +! 
		THEN ;

: print-?	last-c @ [CHAR] ? <>  last-c @ [CHAR] ! <>  AND	\ <> --- <>
		IF [CHAR] . emit' THEN ;


variable echo

: `TYPE'  ( a u -- )	
	ABS 255 MIN
	0 ?DO
	  c@+
	  DUP [CHAR] * <> IF EMIT'		\ This is all..
	  ELSE DROP -1 char# +!
	    echo a@ EXECUTE			\ More (forward)
	  THEN
	LOOP DROP ;


\ print a CR or BL, then the string

: .string  ( a u -- )
	DUP char# @ + Rmargin >			
	IF  CR  ELSE  SPACE  THEN `TYPE' ;




S" Please do not repeat yourself."	2constant  Notrepeat$
S" GOODBYE"				2constant  Goodbye$
S" Ok, hope to see you again."	 	2constant  Farewell$
S" Hello..."				2constant  Hello$
S" The doctor is in..please stand by."	2constant  Doctorin$
S" Welcome to my shrinker's office."   	2constant  Session$

S" ARE YOU"				2constant  Areyou$	
S" are_you"				2constant  Are_you$	
S" YOU ARE"				2constant  Youare$  	
S" you_are"				2constant  You_are$
S" AM I"				2constant  AmI$
S" am_I"				2constant  Am_I$
S" I AM"				2constant  Iam$
S" I_am"				2constant  I_am$
S" YOU"					2constant  YOU$
S" MY"					2constant  my$


S" What does that suggest to you?"
S" Please elaborate on that"
S" I'm not sure I understand that fully"
S" Why?"
S" That's very interesting"
S" Well....please continue....."
S" And then?"
S" I see..Please tell me more about that"

8 80 $table random_replies

CREATE ^temp	80 ALLOT
CREATE ^temp2	80 ALLOT
CREATE ^temp3	80 ALLOT
CREATE ^old	80 ALLOT
CREATE ^keep	80 ALLOT
CREATE ^work	80 ALLOT


99  CONSTANT  push!
66  CONSTANT  pick!
33  CONSTANT  empty?
24  CONSTANT  /lines
80  CONSTANT  /chars

VARIABLE $stack
VARIABLE $sp


: stack  ( nlines nchars -- )	
	CREATE	* DUP 1 CELLS + ?allot	\ allot space for sp and data
		0 OVER !		\ initialize sp
		1 CELLS + SWAP ERASE

	DOES>	DUP CELL+ $stack !  $sp !
		CASE 
		  PUSH! OF  $stack a@ $sp a@ @ /chars *  +  ( addr u -- )
			    pack  
			    $sp a@ @ 1+  /lines MOD  $sp a@ !
		     ENDOF
		  PICK! OF  $stack a@ $sp a@ @ choose	(  -- addr u )
			    /chars * +  COUNT
		     ENDOF 
		 EMPTY? OF  $sp a@ @ 1 U<  ENDOF	( -- flag )
		ENDCASE ;

/lines /chars stack cmds

: clear-cmds ( -- | reset the cmds stack )
	['] cmds >BODY 0 SWAP ! ;


: opening-message	 
	PAGE
	20 10 AT-XY Doctorin$	.string
	1000 MS PAGE  
	20 10 AT-XY Session$	.string
	00 13 AT-XY Hello$	.string ;



: input
	BEGIN   
	  CR C/L 2- 0 DO  [CHAR] =  EMIT LOOP
	  CR ." $ "  ( $ID) 
	  ^temp 80  $in  
	  ^temp C@ 0= IF QUIT THEN		\ Empty string
	  ^temp COUNT >upper 
	  ^keep COUNT $=	 		\ the same as before!
	WHILE	
	  CR Notrepeat$ .string
	REPEAT	

	^temp ^keep strcpy
	\ [CHAR] . rtrim  ^temp  [CHAR] ? rtrim ^temp  
	^temp ^old  strcpy
	^temp COUNT Goodbye$ SEARCH >R 2DROP R> IF CR Farewell$ .string
	  CR QUIT
	THEN ;

 
S" ARE"		S" am"
S" AM"		S" are"	
S" YOU"    	S" me"
S" ME"          S" you"
S" MY"    	S" your"
S" YOUR"  	S" my"
S" WAS"    	S" were"
S" MINE"	S" yours"
S" YOU"    	S" I"
S" I"	  	S" you"
S" I'VE"	S" you've"
S" YOU'VE"	S" I've"
S" YOU ARE"	S" I_am"	
S" ARE YOU"	S" Am_I"	
S" I AM"	S" you_are"	
S" AM I"	S" Are_you"	
S" MYSELF" 	S" yourself"
S" YOURSELF" 	S" myself"

#Conjupairs 2* 12 $table conjugations

 
S" Please tell me more about your*"
S" Is there a link here with your*?"
S" Does that have anything to do with your*?"
S" Why don't we go back and discuss your* a little more?"
S" Does any connection between that and your* suggest itself?"
S" Would you prefer to talk about your*"
S" I think perhaps worries about your* are bothering you"

7 80 $table earlier_remarks


: use-early-remarks
	CR empty? cmds IF 8 choose random_replies .string EXIT THEN
	7 choose earlier_remarks 
	0 ?DO  c@+ DUP [CHAR] * 
	  <> IF  emit'  ELSE  DROP pick! cmds .string  THEN
	LOOP DROP ;



\ Take first blank-delimited word of userinput, the rest if no delimiter 
\ found.


: next-word  ( -- a u )	
	^old COUNT parse-token strpck
	-ROT ^old pack COUNT ;

: conjugated					\ <addr><u> -- <adr><u>
	#Conjupairs 2*				
	0 ?DO	
	  2DUP I conjugations  
	  $= IF 2DROP  I 1+ conjugations  LEAVE  THEN
	2 +LOOP ;

: .conjugated					\ <c-addr> <u> --- <>
	conjugated .string ;		


\ alternative trigger: ``MY''

: "MY"-input?	
	^old COUNT my$ SEARCH
	IF  3 - SWAP 3 + SWAP  push! cmds ELSE 2DROP THEN ;

: echo.it	
	Areyou$ Are_you$ ^old COUNT  substitute		\ <> --- <>
	Youare$ You_are$ ^old COUNT  substitute
	AmI$    Am_I$    ^old COUNT  substitute
	Iam$    I_am$    ^old COUNT  substitute
	BEGIN
	  next-word DUP
	WHILE  
	  .conjugated
	REPEAT 	2DROP ;


' echo.it echo !


: lookup ( c-addr u --- a flag )
	( phrase_voc SEARCH-WORDLIST)
	strpck FIND DUP
	IF DROP C" TPHRASE" FIND DROP OVER < THEN  ;


: get$	( n -- a u )
	>R next-word R> 
	0 ?DO  S" _" strcat next-word strcat  LOOP ;


: ?phrase  ( -- flag )
	FALSE
	1 3 DO 
	  ^old ^work strcpy   
	  I get$ lookup
	  IF  #Resp choose SWAP EXECUTE CR .string 0= LEAVE  
	  ELSE  ^work ^old strcpy THEN DROP
	-1 +LOOP ;


: ?word  ( -- flag )
	FALSE >R  ^old ^work strcpy
	BEGIN   
	  next-word DUP  R@ 0=  AND
	WHILE   
	  lookup IF  #Resp choose swap EXECUTE CR .string R> INVERT >R  
	  ELSE  DROP  THEN
	REPEAT 
	2DROP 
	R> DUP FALSE = IF  ^work ^old strcpy THEN ;


S" WHY"
S" WHEN"
S" WHERE"
S" WHO"	   
4 8 $table w's

\  Why do I stink ... ==> (why don't YOU tell me)  why you do stink.

: "W"-input?	
	4 0 DO   
	  ^old COUNT I w's SEARCH
	  IF	
	    next-word ^temp2 pack  
	    ^temp2 COUNT S"  " strcat ^temp2 pack
	    S"  " ^temp3 pack
	    ^temp3 COUNT next-word strcat S"  " strcat
	    next-word strcat ^temp3 pack
	    ^temp2 COUNT ^temp3 COUNT strcat ^temp2 pack
	    ^old COUNT ^temp2 COUNT strcat ^old pack  
	    2DROP LEAVE
	  THEN
	  2DROP
	LOOP ;


\ The main word.

: doctor
	clear-cmds
	opening-message
	BEGIN	
	  input
	  "MY"-input?
	  ?phrase  0= IF "W"-input? 
	    ?word  0= IF use-early-remarks THEN
	  THEN
	  print-?
	AGAIN ;


: about	CR ." ==========================================================="
	CR ." Start with:  Doctor   <cr> "
	CR ." Stop  with:  Goodbye  <cr> (NOT case-sensitive)" 
	CR ." ===========================================================" ;



: tphrase  ( -- | create a string table of responses for the given phrase)
	#Resp 80 $table ;


\ Type randomly one of three possible response strings.
\ Add your own trigger phrases and responses and amaze your friends...


S" Why do you need*" 
S" Would it really be helpful if you got*"
S" Are you sure you need*"			tphrase  I_NEED

S" Do you really think I don't*" 
S" Perhaps I eventually will*"
S" Do you really want me to*"			tphrase WHY_DON'T_YOU

S" Do you think you should be able to*"
S" Why can't you*"
S" Perhaps you didn't try"			tphrase WHY_CAN'T_I

S" Why are you interested whether I am or not*"
S" Would you prefer it if I were not*"
S" Perhaps you sometimes dream I am*"		tphrase ARE_YOU

S" How do you know you can't*"
S" Have you tried?"
S" Perhaps, now, you can*"			tphrase I_CAN'T

S" How do you know I can't*"
S" Don't you think I can*"
S" Why do you think I can't*"
						tphrase CAN'T_YOU

S" Did you come to me because you are*"
S" Do you think it is absolutely normal to be*"
S" How long have you been*"			tphrase I_AM

S" Do you enjoy being*"
S" Why tell me you're*"
S" Why are you*"				tphrase I'M

S" What would it mean to you if you got*" 
S" Why do you want*"
S" What would it add to your life if you got*" 
						tphrase I_WANT

S" Why do you ask?"  
S" How would an answer to that help you?"
S" What do you think?"				tphrase WHAT

S" How would you solve that?"
S" It would be best to answer that for yourself"
S" What is it you're really asking?"		tphrase HOW

S" Do you often think about such questions?"
S" What answer would put your mind at rest?"
S" Who do you think*"				tphrase WHO

S" That's a pretty silly question"
S" Do you really need to know where*"
S" What would it mean to you if I told you where*"
						tphrase WHERE

S" Things have a habit of happening more or less at the right time"
S" The time should not be discussed here"
S" How should I know when*"			tphrase WHEN

S" Please repeat the information needed to tell you why*"
S" Why don't y o u tell me the reason why*"
S" Do you really need to know why*"     	tphrase WHY

S" Is that the real reason?" 
S" What else does that explain?"
S" What other reasons come to mind?"    	tphrase BECAUSE

S" In what other circumstances do you apologize?"
S" There are many times when no apology is needed"
S" What feelings do you have when you apologize?" 
						tphrase SORRY

S" How are you.. I'm looking forward to another chat with you"
S" Hello to you.. I'm glad you could drop by today"
S" Hello.. it's good to see you"		tphrase HELLO

S" Hi there.. I'm glad to see you here today"
S" Hi. I'm glad you've dropped by......we've got lots of time to chat"
S" Hi to you..relax now, and let's talk about your situation"
						tphrase HI

S" You seem a little hesitant" 
S" That's pretty indecisive"
S" In what other situations do you show such a tentative approach?"
						tphrase MAYBE

S" That's pretty forceful. What does it suggest to you?"
S" Are you saying that just to be negative"
S" Why are you being so negative about it?" 	tphrase NO

S" Please give me a specific example"  
S" When?"
S" Isn't `ALWAYS' a little strong?"		tphrase ALWAYS

S" Do you doubt*"  
S" Do you really think so?"
S" But you are not sure*"			tphrase I_THINK

S" Why do you bring up the subject of friends?"
S" Please tell me more about your friendship.."
S" What is your best memory of a friend?"	tphrase FRIEND

S" In what way do your friends' reactions bother you?"
S" What made you start to talk about friends just now?"
S" In what way do your friends impose on you?"	tphrase FRIENDS

S" What feelings do you get, sitting there talking to me like this?"
S" Are you thinking about me in particular"
S" What aspect of computers interests you the most?"
						tphrase COMPUTER

S" Work... I can look at it for ages"
S" I know what it is when your boss hates you"
S" It is a universal problem, but that's no solace"
						tphrase WORK
S" Do you think it is*"	 
S" In what circumstances would it*"
S" It could well be that*"			tphrase IS_IT

S" What degree of certainty would you place on it being*"
S" Are you certain that it's*"
S" What emotions would you feel if I told you that it probably isn't*"
						tphrase IT_IS

S" What makes you think I can't*"  
S" Don't you think that I can*"
S" Perhaps you would like to be able to*"	tphrase CAN_YOU

S" Perhaps you don't want to*"
S" Do you want to be able to*"
S" I doubt it"					tphrase CAN_I

S" Why do you think I am*"
S" Perhaps you would like to be*"
S" Does it please you to believe I am*"		tphrase YOU_ARE

S" Why do you think I am*"
S" Why do you say I'm*"
S" Does it please you to believe I am*"		tphrase YOU'RE

S" Don't you really*"  
S" Why don't you*"
S" Do you want to be able to*"			tphrase I_DON'T

S" Tell me more about such feelings" 
S" Do you often feel*"
S" Do you enjoy feeling*"			tphrase I_FEEL

S" Let's explore that statement a bit"
S" What emotions do such feelings stir up in you?"
S" Do you often feel like that?"		tphrase FEEL

S" Why tell me that you've*"
S" How can I help you with*"
S" It's obvious to me that you have*"		tphrase I_HAVE

S" Could you explain why you would*"
S" How sure are you that you would*"
S" Who else have you told you would*"		tphrase I_WOULD

S" Of course there is*" 
S" It's likely that there is*"
S" Would you like there to be*"			tphrase IS_THERE

S" What does it mean to you, that your*"
S" That's interesting! You really said your*, didn't you?"
S" I see, your*"				tphrase MY

S" This session is to help you...not to discuss me"
S" What prompted you to say that about me?"
S" Remember, I'm taking notes on all this to solve your situation"
						tphrase YOU

S" What does that dream suggest to you?"
S" Do you dream often?"
S" Are you disturbed by your dreams?"
						tphrase DREAM

about CR

			      ( * End of Source * ) 

