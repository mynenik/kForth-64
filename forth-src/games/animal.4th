\ animal.4th

\ animal  01.12.25 18:21 -- EJB

\ silly animal guessing game in which the computer
\ "learns" new animals as it goes.
\ 
\ written on 25 December 2001 by Edward J. Beroset
\ and released to the public domain by the author.
\
\ Revisions:
\   2001-12-29  km  Modified to run under kForth
\   2019-08-04  km  Added utility words to display and reset
\                   the binary tree
\   2019-08-05  km  simplified DISPLAY-SUBTREE.
\
\ To run this code under ANS Forth, uncomment definition of 
\ A@ and comment out the empty definition of ALIGN below:
\ : A@ @ ; 
: ALIGN ;

\ --------------- begin defs for kForth ----------

CREATE ANIMAL-TREE 256 256 * ALLOT	\ allot space for the binary tree
VARIABLE TREE-PTR
ANIMAL-TREE TREE-PTR !

\ insert an integer value into the tree

: TREE, ( n -- )
    TREE-PTR A@ ! TREE-PTR A@ CELL+ TREE-PTR ! ;

\ insert a string into the tree

: TREE-S, ( c-addr u -- )
    DUP TREE, 
    DUP >R
    TREE-PTR A@ SWAP CMOVE 
    TREE-PTR A@ R> + TREE-PTR ! ;

\ ------------ end defs for kForth -------------
	
VARIABLE ROOT
CREATE MYPAD 80 ALLOT


\ adds a new node to the binary tree using
\ the passed string as the data

: NEWNODE ( c-addr u -- c-addr )
    ALIGN
    TREE-PTR A@ >R  \ save original address
    0 TREE,  \ save YES node
    0 TREE,  \ save NO node
    TREE-S,  \ save string
    R> ;     \ return address of this node


\ : NEWNODE ( c-addr u -- c-addr )
\    HERE >R \ save original address
\    0 , \ save YES node
\    0 , \ save NO node
\    DUP , \ save string length
\    HERE OVER ALLOT SWAP MOVE \ save string
\    R> ; \ return address of this node

\ returns the address of the left branch of
\ the passed node
: LEFT ( a-addr -- a-addr )
    A@ ;

\ returns the address of the right branch of
\ the passed node
: RIGHT ( a-addr -- a-addr )
    CELL+ A@ ;

\ given the address of a node, types the
\ text stored at that node.
: GETQ ( a-addr -- )
    CELL+ CELL+ DUP @ SWAP CELL+ SWAP TYPE ;

\ returns TRUE if this is a terminal node.
: TERM? ( a-addr -- t )
    DUP LEFT SWAP RIGHT OR 0= ;

\ prints the question based on the text
\ stored at this node.
: SHOWQ ( a-addr -- )
    DUP TERM? IF \ is it a terminal node?
        ." Is it " GETQ ." ? "
    ELSE
        GETQ 
    THEN ;

\ returns TRUE if the passed char was y or Y
: YES? ( n -- t )
    DUP [CHAR] Y = SWAP
    [CHAR] y = OR ;

\ returns TRUE if the passed char was n or N
: NO? ( n -- t )
    DUP [CHAR] N = SWAP
    [CHAR] n = OR ;

\ returns the letter pressed by the user
\ and TRUE if that was either Y or N
: GETA ( -- n t )
    MYPAD 1 ACCEPT DROP MYPAD C@
    DUP DUP YES? SWAP NO? OR ;

\ asks a question based on the text at the
\ passed node and gets a response.  The
\ letter returned is the users response and
\ the flag returned is TRUE if the user
\ wants to continue
: QUERY ( a-addr -- n t )
    SHOWQ CR ." (Y, N or Q): "
    GETA ;

\ learning consists of asking three questions.  The questions
\ are: what was the animal? what's a question to differentiate?
\ and what is the answer to that question in the case of the new
\ animal?  The first question causes a new terminal node to be
\ created.  The second causes a new non-terminal node to be
\ created, and the last question allows the links to that
\ non-terminal to be set correctly.
: LEARN ( a-addr -- )
    CR ." What is the animal you were thinking of?" CR
    MYPAD DUP 80 ACCEPT NEWNODE  ( -- oldtermaddr newnode )
    CR ." What is a yes/no question that differentiates "
    OVER A@ GETQ ."  from " DUP GETQ ." ?" CR
    MYPAD DUP 80 ACCEPT NEWNODE  ( -- oldtermaddr newnode qnode )
    CR ." And what is the answer in the case of " OVER GETQ 
    ." ?" GETA IF
        YES? IF
            DUP ROT ROT ! ( -- oldtermadd qnode )
            2DUP CELL+ SWAP @ SWAP !
            SWAP !
        ELSE
            DUP ROT ROT CELL+ ! ( -- oldtermadd qnode )
            2DUP SWAP @ SWAP !
            SWAP !
        THEN
    THEN ;

\ starts with the address of a variable which contains the
\ first structure.  We do it this way so that the variable
\ can be modified when we learn a new animal.
: GUESS ( a-addr -- a-addr t )
    DUP A@ QUERY IF \ user wants to continue
        OVER A@ TERM? IF
	    YES? IF  \ answer was Y
                CR ." I guessed it!!  Let's play again!" CR
                DROP 
            ELSE            \ answer was N
                CR ." You stumped me!"
                LEARN CR
            THEN
            ROOT	
        ELSE \ follow the answer to the next question
            YES? IF
                A@ 
            ELSE
                A@ CELL+
            THEN
        THEN
	0   \ indicate that the user wants to continue
    ELSE DROP 1  \ indicate that the user wants to quit
    THEN ;

\ seeds the binary tree with a single terminal node
: SEED ( -- )
    S" a cow" NEWNODE ROOT ! ;

SEED

\ given a node address, this either prints
\ the text if it's a terminal node or replaces
\ the address with the addresses of the left 
\ and right nodes.
: EXPAND ( a-addr -- a-addr a-addr | )
	DUP TERM? IF
		GETQ CR
	ELSE
		DUP LEFT SWAP RIGHT
	THEN ;

\ Utilities to display information about the tree

: show-node-address ( anode -- )
     ?dup IF 8 u.r ELSE [char] X emit 7 spaces THEN ;

\ Display information about one node in the binary tree
: display-node ( anode -- )
    ?dup 0= IF EXIT THEN
    dup       show-node-address 2 spaces
    dup left  show-node-address 2 spaces
    dup right show-node-address 2 spaces
    2 cells + dup @ swap cell+ swap type ;

\ Display the subtree starting with the given node
: display-subtree ( anode -- )  
    dup display-node cr
    dup left  ?dup IF recurse THEN 
    dup right ?dup IF recurse THEN 
    drop
;

\ Display the entire tree
: display-tree ( -- )
    cr ." Node      Left      Right" cr
    base @ hex root a@ display-subtree base ! ;

\ Reset the tree to its startup state.
: reset-tree ( -- )  ANIMAL-TREE TREE-PTR ! SEED ;


\ lists the animals known to the game
: INVENTORY ( -- )
	0 ROOT A@ CR BEGIN EXPAND DUP 0= UNTIL DROP ;

\ plays the animal game
: ANIMAL
    ROOT BEGIN CR CR GUESS UNTIL DROP ;


CR CR 
.( ANIMAL        -- starts/continues the game ) CR
.( INVENTORY     -- list the known animals    ) CR
.( DISPLAY-TREE  -- display binary tree nodes ) CR
.( RESET-TREE    -- reset the tree to startup state ) CR
CR

