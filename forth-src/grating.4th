\ grating.4th
\
\   Compute the diffraction properties of a diffraction grating, 
\   given the input beam specs. This program is useful in the
\   design of a grating spectrometer, or in determining the properties
\   of a grating with unknown groove spacing. For example, one may 
\   illuminate the grating with a collimated beam from a Helium-Neon 
\   laser. Using the known incidence angle and measured beam angles 
\   for the different diffraction orders, the groove spacing of the 
\   unknown grating may be determined with the output of this program.
\
\   Copyright (c) 2004--2018 Krishna Myneni
\   Provided under the GNU General Public License
\
\ Revisions:
\   2004-11-04  created  km
\   2004-11-05  added formatted output and dispersion and resolution calcs  km
\   2018-10-22  use fp number formatting word F.RD from strings.4th  km
\
\ Notes:
\
\ 1) Usage Example:
\
\      800 633 calc
\
\    For an 800 groove/mm grating and a wavelength of 633 nm,
\    print a table of diffraction angles, dispersion, and
\    resolution for various incidence angles.
\
\    Labels shown on the table are:
\      
\    Theta_i  incidence angle of beam on grating, measured
\             from grating normal (in degrees).
\
\    m        diffraction order; only allowed orders are shown.
\
\    Theta_d  diffraction angle, w.r.t. grating normal, for the
\             corresponding order (in degrees).
\
\    Dispersion  angular deflection per wavelength interval,
\                d(Theta_d)/d lambda (in milliradians of
\                deflection per nanometer wavelength change)
\
\    Resolution  wavelength resolution for a specified beam 
\                size which is assumed to be smaller than the
\                width of the grating. Since the beam is incident
\                on only a finite number of grooves, the resolving
\                power of the grating will be determined by
\                both the diffraction angle and the beam width. 
\                The beam width is set to 5 mm by default, but can
\                be changed in the variable "fwhm". Resolution is 
\                shown in nm.

include strings

\ grating properties

fvariable  a            \ groove spacing in mm

\ beam properties

fvariable  lambda	\ wavelength in nm
fvariable  fwhm   	\ beam full width at half max along
                  	\ diffraction plane in mm

5e fwhm f!  \ default beam diameter

\ Compute diffraction angle for specified incident angle
\ and diffraction order. Angles are in rad, order is integer.      
: diff_angle ( ftheta_i  order -- ftheta_d  flag )
    s>f lambda f@ 1e-9 f* f*   \   m*lambda in meters
    a f@ 1e-3 f*               \   groove spacing in meters
    f/                         \   m*lambda/a
    fswap fsin f-              \   m*lambda/a - sin(theta_i)
    fdup 1e f> 
    IF  false ELSE fasin true THEN ;

: dispersion ( ftheta_d  order -- fdispersion | dispersion in mrad/nm )
      s>f fswap fcos a f@ 1e6 f* f* f/ 1000e f* ;

: resolution ( ftheta_i  ftheta_d  -- fdlambda | wavelength resolution in nm)
      fsin fabs fswap fsin f+ fwhm f@ 1e-3 f* f*
      lambda f@ 1e-9 f* fdup f* fswap f/ 1e-9 f/ ;

: .table-header ( -- | print table header )
    cr ." Theta_i  m    Theta_d  Dispersion    Res(" 
       fwhm f@ f>d d. ." mm)"   
    cr ."  (deg)         (deg)    (mrad/nm)       (nm)"
    cr ." ----------------------------------------------"
;

\ Inputs for the calculation are the grating groove density in
\ grooves/mm, and the wavelength of light in nanometers.
\ Both arguments are integers.
  
: calc ( gr/mm  nm -- )
    s>f lambda f!
    s>f 1e fswap f/ a f!
    .table-header
    90 0 DO		    \ loop over theta_i from 0 to 90 deg
      cr I 4 .r 4 spaces
      10 1 DO
	    J s>f deg>rad I diff_angle
	    IF   I 2 .r fdup fdup
	      rad>deg        2 spaces  8  2 f.rd      \ print theta_d
	      I dispersion   2 spaces  8  2 f.rd      \ print dispersion
	      J s>f deg>rad fswap 
	      resolution     6 spaces  8  3 f.rd      \ print resolution
	      cr 8 spaces 
	    ELSE fdrop leave  ( no valid solution for this order ) 
	    THEN
      LOOP
    10 +LOOP ;

