\ animal2.4th

\ animal2  based on silly animal guessing game by Ed Beroset
\ in which the computer "learns" new animals as it goes.
\ 
\ Original written on 25 December 2001 by Edward J. Beroset
\ and released to the public domain by the author.
\
\ This version stores the binary tree directly as words 
\ in a wordlist, with the nodes (animal names and questions)
\ corresponding to word names. Each node is executable,
\ simplifying traversal of the binary tree.
\
\ Krishna Myneni, 2019-10-03

\ : A@ ( a -- a2 ) @ ;
\ : ?ALLOT ( u -- a ) HERE SWAP ALLOT ;  

include ans-words
include strings

: $.l ( caddr u ufield -- )  over - 1 max >r type r> spaces ;

: y/n? ( -- ynflag )
    bl emit ." (y/n) " key
    dup emit
    dup [char] Y = swap [char] y = or ;

[undefined] CREATED [IF]
\ Create word from name in string
: created ( c-addr u -- )
    s" create " 2swap strcat evaluate ;
[THEN]

: name>body ( nt -- a ) name>interpret >body ;

: @branch ( a ynflag -- nt )  0= if cell+ then a@ ;
: !branch ( nt a ynflag -- )  0= if cell+ then ! ;

\ left and right branch operations
: get-left  ( nt -- nt2 ) name>body a@ ;
: get-right ( nt -- nt2 ) name>body cell+ a@ ;
: set-left  ( ntleft nt -- )  name>body ! ;
: set-right ( ntright nt -- ) name>body cell+ ! ;

\ Is the node a leaf node?
: leaf? ( nt -- flag ) dup get-left swap get-right d0= ;

variable root
variable last-node
variable last-branch

\ Execute the node of a binary tree. Execution of a tree node 
\ returns the next node and the branch-flag indicating left or
\ right branch.
: execute-node ( nt -- nt-next bflag )
    name>interpret execute ;

\ Traverse a binary tree starting from a node, typically the
\ root node. Return the leaf node and branch flag.
: traverse-btree ( nt -- nt-leaf bflag )
    BEGIN
      dup execute-node  \ -- nt-current nt-next bflag
      over
    WHILE
      last-branch ! swap last-node !
    REPEAT      
    nip
;

\ Defining word for an animal node (leaf node)
\ c-addr u is the node name (animal name)
: animal ( c-addr u -- )
    CREATED my-name 3 cells ?allot
      2 cells + !  \ store nt
    DOES>              ( a -- nt-next ynflag )
      cr ." Is it a "
      dup 2 cells + a@ name>string type
      [char] ? emit 
      y/n? dup >r @branch r> ;

\ Defining word for question node (non-leaf node)
\ c-addr1,u1 is the question string and c-addr2,u2 is the node name
: question ( c-addr1 u1 c-addr2 u2 -- )
    s" ?" 2swap strcat CREATED
    strpck
    2 cells 256 + ?allot
    2 cells + strcpy
    DOES>              ( a -- nt-next ynflag )
      dup 2 cells + count cr type
      y/n? dup >r @branch r> ;

wordlist constant animal-tree
get-order animal-tree swap 1+ set-order

animal-tree set-current
s" cow" animal
my-name 
forth-wordlist set-current
root !

variable new-animal

: learn ( nt-current -- )
    >r
    cr ." What is the animal you were thinking of? "
    pad 31 accept pad swap animal          \ create new leaf node
    my-name new-animal !

    cr ." What is a yes/no question that differentiates a "
    new-animal a@ name>string   2dup type ."  from a "
    r@            name>string   2dup type [char] ? emit cr
    s" /" strcat 2swap strcat

    pad 128 accept pad swap 2swap question  \ create new node

    new-animal a@ r>
    cr ." And what is the answer in the case of "
    over name>string type [char] ? emit y/n?
    0= IF swap THEN
    my-name set-right
    my-name set-left

    last-node a@ ?dup IF
      my-name swap
      last-branch @ IF set-left ELSE set-right THEN
    ELSE
      my-name root !
    THEN 
;

 
: play ( -- )
    animal-tree set-current
    BEGIN
      root a@ traverse-btree
      IF
        drop cr ." I guessed it!"
      ELSE
        cr ." You stumped me!" cr
        learn
      THEN
      cr cr ." Play again? " y/n? 0=
    UNTIL
    forth-wordlist set-current
;

\ Utilities to display information about the tree

: show-node ( nt -- )
     ?dup IF name>string 20 $.l ELSE [char] X emit 19 spaces THEN ;

\ Display information about one node in the binary tree
: display-node ( nt -- )
    ?dup 0= IF EXIT THEN
    dup           show-node 
    dup get-left  show-node 
    dup get-right show-node 
    drop ;

\ Display the subtree starting with the given node
: display-subtree ( nt -- )  
    dup display-node cr
    dup get-left  ?dup IF recurse THEN 
    dup get-right ?dup IF recurse THEN 
    drop
;

\ Display the entire tree
: display-tree ( -- )
    cr ." Node                Left                Right" cr
    root a@ display-subtree ;

: .animal ( nt -- true )
    dup leaf? IF name>string cr type ELSE drop THEN true ;

: inventory ( -- )
    ['] .animal animal-tree traverse-wordlist cr ; 

CR CR 
.( PLAY          -- starts/continues the game ) CR
.( INVENTORY     -- list the known animals    ) CR
.( DISPLAY-TREE  -- display binary tree nodes ) CR
CR


