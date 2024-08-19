\ mlp-telugu.4th
\
\ తెలుగులో ప్రోగ్రామింగ్ చెయ్యి 
\ 
\ మైనేని కృష్ణ
\
\  మార్పులు :
\  13 మే  2017  -- తయారు చేసిన
\  30 నవంబరు 2019

synonym వెంటనే    immediate
synonym తరువాత  postpone 

synonym ఉంటే    if 
synonym కాదంటే  else
synonym అప్పుడు  then
synonym మొదలు  begin
synonym అయితే  while 
synonym ఇంకొసారి  repeat
synonym మళ్ళీ  again
synonym వరకు  until
synonym చెయ్యి  do
synonym చెయ్యనా  ?do
synonym తిరుగు  loop
: ఐ  తరువాత  I ; వెంటనే 
: ఙే  తరువాత  J ; వెంటనే 
synonym వదులు  leave
synonym [అక్షర] [char]
: చేస్తుంది 	తరువాత does>  ; వెంటనే 
synonym ఆపు" abort"
synonym సృజించు  create
synonym ఉంచు   allot
synonym పదము  word
synonym పదాలు  words
synonym కనిపెట్టు  find
synonym పారేయి   drop
synonym 2పారేయి  2drop
synonym డూప్   dup
synonym 2డూప్  2dup
synonym మార్చు   swap
synonym మీద   over
synonym రోట్  rot
synonym రోల్  roll
synonym గిల్లు   nip
synonym లెక్క  count
synonym తుడువు  erase
synonym ఖాళీ  blank
synonym వెతుకు  search
synonym చేరింది  included
synonym చేర్చు  include
synonym తీసుకొ  accept
synonym చూపించు  type 
synonym మరియు  and
synonym కాని  or
synonym కాదు  invert
synonym ఎక్కువ   >
synonym తక్కువ   <
synonym సమానం  =
synonym పెద్ద  max
synonym చిన్న  min
synonym మిగత  mod
synonym /మిగత /mod
synonym సంఖ్యము  >number
synonym అక్షర  char
synonym కీ  key
synonym కీ? key?
synonym ఎమిట్  emit
synonym మారదు  constant
synonym మారేది  variable
synonym వెళ్ళు  exit
synonym మానేయి  quit
synonym ఆపు  abort
synonym బై   bye

\ TRUE and FALSE constants
synonym నిజము  TRUE
synonym తప్పుడు FALSE

\ CONSTANTs "sunna" and "padi"
 0 మారదు సున్న
10 మారదు పది

\ Examples:
\
\ VARIABLE "vI"
\ మారేది  వి
\ 16 వి !
\
\ to-ten ( BEGIN ... UNTIL )
\ : పది-వరకు ( -- ) సున్న మొదలు 1+ డూప్ . డూప్ పది సమానం వరకు పారేయి ;
\
\ ten-times ( DO ... LOOP )
\ : పది-సారిలు  ( -- ) 10 0 చెయ్యి ఐ . తిరుగు ;

