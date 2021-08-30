\ textbox.4th
\
\ Copyright (c) 2003 Krishna Myneni, Creative Consulting for
\   Research and Education
\
\ Provided under the GNU General Public License
\
\ Requires:
\   ans-words.4th
\   mini-oof.4th
\   strings.4th
\   ansi.4th
\
\ Revisions:
\   2020-02-02  km; use :NONAME  
\   2021-08-27  km; update for revised mini-oof library

1 cells constant cell

object class
       cell var tb-col
       cell var tb-row
       cell var tb-width
       cell var tb-height
       cell var tb-bkg		\ background color
       cell var tb-fg		\ foreground color
       cell var tb-border	\ border color
       method	tb-setcolors
       method   tb-linexy	\ return col and row for start of line
       method	tb-draw
       method	tb-init
end-class textbox

:noname ( o -- )  dup tb-bkg @ background tb-fg @ foreground ;
textbox defines tb-setcolors

:noname ( n o -- col row )  >r r@ tb-row @ + r> tb-col @ swap ; 
textbox defines tb-linexy

:noname ( o -- ) 
	 >r
	 r@ tb-setcolors 
	 0 r@ tb-linexy at-xy
	 r@ tb-border @ background r@ tb-width @ spaces r@ tb-bkg @ background
	 r>
	 dup tb-height @ 1- 1 ?do
	   dup i swap tb-linexy at-xy
	   dup tb-border @ background  space  dup tb-bkg @ background
	   dup tb-width @ 2- spaces 
	   dup tb-border @ background  space  dup tb-bkg @ background
	 loop
	 dup dup tb-height @ 1- swap tb-linexy at-xy
	 dup tb-border @ background dup tb-width @ spaces 
	 dup tb-bkg @ background 
	 drop ;

textbox defines tb-draw

:noname ( col row width height fg bkg border o -- )
	 >r 
	 r@ tb-border !
	 r@ tb-bkg !
	 r@ tb-fg !
	 r@ tb-height !
	 r@ tb-width !
	 r@ tb-row !
	 r> tb-col ! ;

textbox defines tb-init

\ Demonstration of text boxes:

1 [IF]
textbox new constant tb1
2 1 8 6 RED WHITE BLUE  tb1 tb-init
textbox new constant tb2
12 4 20 5 YELLOW RED CYAN tb2 tb-init
textbox new constant tb3
16 12 10 10 BLACK GREEN GREEN tb3 tb-init

page
tb1 tb-draw
tb2 tb-draw
tb3 tb-draw
text_normal
[THEN]



	 
         
