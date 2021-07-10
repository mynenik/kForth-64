\ fsl-tester.4th
\
\  Test revised versions of the FSL routines under kForth,
\  using the ttester.4th test harness.
\
\  K. Myneni, 2007-09-19
\
\  Revisions:
\
\    2007-09-22  km; added gauleg module
\    2007-10-10  km; added regfalsi
\    2007-10-12  km; added expint, horner
\    2007-10-13  km; added polys
\    2007-10-14  km; added runge4
\    2007-10-18  km; added gamma
\    2007-10-22  km; added logistic
\    2007-10-25  km; added adaptint, elip
\    2007-11-11  km; added permcombs, gauss
\    2007-11-25  km; added sph_bes, cubic, crc
\    2007-11-28  km; added isaac, prng
\    2007-11-29  km; added factorl, shanks
\    2007-11-30  km; added pcylfun
\    2007-12-02  km; added gaussj
\    2009-06-04  km; added r250
\    2010-10-21  km; added polrat
\    2010-12-25  km; added aitken
\    2010-12-29  km; added lagroots
\    2011-01-13  km; added erf
\    2011-01-16  km; added hermite
\    2011-01-20  km; added dfourier
\    2011-01-25  km; added elip12
\    2011-01-29  km; added quadratic

include ans-words
include fsl-util
include dynmem
include strings
include struct
include complex
include fsl-test-utils
include ttester
DECIMAL
	
true to TEST-CODE?
true verbose !


CR CR
\ include isaac

CR CR
include prng

CR CR
include sph_bes

CR CR
include logistic

CR CR
include polrat

CR CR
include expint

CR CR
include horner

CR CR
include aitken

CR CR
include hermite

CR CR
include elip

CR CR
include elip12

CR CR
include polys

CR CR
include factorl

CR CR
include gamma

CR CR
include erf

CR CR
include pcylfun

CR CR
include shanks

CR CR
include hilbert

CR CR
include lufact

CR CR
include dets

CR CR
include backsub

CR CR
include invm

CR CR
include gaussj

CR CR
include dfourier

CR CR
include adaptint

CR CR
include gauleg

CR CR
include quadratic

CR CR
include cubic

CR CR
include lagroots

CR CR
include regfalsi

CR CR
include runge4

CR CR
include crc

CR CR
include permcomb

CR CR
include gauss

CR CR
include r250

bye
