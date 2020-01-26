\ textbox.4th
\
\ Copyright (c) 2003 Krishna Myneni, Creative Consulting for
\   Research and Education
\
\ Provided under the GNU General Public License
\
\ Requires:
\
\	strings.4th
\	ans-words.4th
\	ansi.4th
\	mini-oof.4th
\

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

: noname ( o -- )  dup tb-bkg @ background tb-fg @ foreground ;
' noname textbox defines tb-setcolors

: noname ( n o -- col row )  >r r@ tb-row @ + r> tb-col @ swap ; 
' noname textbox defines tb-linexy

: noname ( o -- ) 
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

' noname textbox defines tb-draw

: noname ( col row width height fg bkg border o -- )
	 >r 
	 r@ tb-border !
	 r@ tb-bkg !
	 r@ tb-fg !
	 r@ tb-height !
	 r@ tb-width !
	 r@ tb-row !
	 r> tb-col ! ;

' noname textbox defines tb-init

\ Demonstration of text boxes:

(
textbox new tb1 drop
2 1 8 6 RED WHITE BLUE  tb1 tb-init
textbox new tb2 drop
12 4 20 5 YELLOW RED CYAN tb2 tb-init
textbox new tb3 drop
16 12 10 10 BLACK GREEN GREEN tb3 tb-init

page
tb1 tb-draw
tb2 tb-draw
tb3 tb-draw
text_normal
)



	 
         
