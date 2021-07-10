\ qm8.4th
\
\ Copyright (c) 2003--2006 Krishna Myneni
\
\ Solve the optical Bloch equations for a two-level system
\ interacting with a near-resonant field. Allow for
\ arbitray time-dependent field and detuning profiles.
\ Physical examples which are described by the Bloch equations
\ include:
\
\   1) nuclear spin (1/2) in an external magnetic field,
\      interacting with a near-resonant radio-frequency (RF) wave.
\
\   2) An idealized two-level atom interacting with a laser
\      tuned near its resonance frequency.
\
\ The first example is the basis for magnetic resonance imaging (MRI).
\
\ The optical Bloch equations, which may be derived from the
\ time-dependent Schroedinger wave equation, are [1]:
\
\	du/dt = -Delta(t)*v
\
\	dv/dt = Delta(t)*u + Omega(t)*w   (1)
\    
\	dw/dt = -Omega(t)*v
\
\ where the three components u(t), v(t), and w(t) form a vector
\ called the Bloch vector (rho) and have the following physical
\ significance:
\
\  i) For the case of a spin in an external magnetic field, the
\     Bloch vector is the "polarization" vector, the expectation
\     values of the x,y,z components of the spin. However, because
\     the Bloch equations are expressed in a frame of reference which
\     rotates about the direction of the constant external field, a
\     transformation is required from u,v,w to the x,y,z frame. Our
\     interest here is the expectation value of the z-spin component,
\     proportional to w, which is the same in both frames. The quantity
\     w(t), is called the inversion, and represents the probability of
\     finding the spin-1/2 system with positive z component (recall from
\     qm6.4th that for a spin-1/2 particle, the spin measured along an
\     axis can only assume one of two values, positive or negative).
\
\ ii) For the case of a two-level atom, the u and v components 
\     of the Bloch vector define a complex "polarization" of the atom,
\     which is proportional to its expected electric-dipole moment:
\
\         P(t) = u(t) + i*v(t)            (2)
\
\     and w(t), the inversion, is the probability of finding
\     the atom in its upper level.

\ The inversion, w(t), is scaled such that when the spin/atom is in
\ its lower level with probability of one, w = -1, and in its upper
\ level with a for a probability of one, w = +1. Hence,
\
\      p = (w + 1)/2                      (3)
\
\ where p is the probability of finding the spin/atom in the upper level.
\ For values of w other than +/-1, the spin/atom is in a  superposition 
\ of the upper and lower states. The parameters Delta(t) and Omega(t)
\ represent the RF/optical field driving the system. Delta(t) is the
\ time-dependent detuning from resonance, and Omega(t) is the
\ time-dependent Rabi rate:
\
\      Delta(t) = 2*pi*(nu(t) - nu0)      (4)
\
\      Omega(t) = mu*|B(t)|/hbar          (5a)
\      Omega(t) = mu*|E(t)|/hbar          (5b)
\
\ where nu(t) is the RF/optical frequency of the applied field,
\ nu0 is the resonant frequency, mu is the magnitude of the
\ magnetic/electric dipole moment (in the case of the two-level
\ atom, mu is the magnitude of the electric dipole moment matrix
\ element connecting the two levels). The magnitude of the
\ time-varying fields are |B(t)| or |E(t)|, respectively for the
\ two cases. Both the applied field magnitude and frequency may be
\ varied with time in the simulation, by defining Delta(t) and
\ Omega(t).
\
\ ----------------------------------------------------------------
\
\ Usage:
\
\  Once the time-dependent functions for Delta(t) and Omega(t)
\  have been specified (three examples are provided), simply
\  type,
\
\     bloch
\
\  to solve the equations and print the output. The initial state
\  of the system is set to u(0) = 0, v(0) = 0, w(0) = -1, which
\  represents the spin/atom in its lower level. The output consists
\  of six columns:
\
\     t, Delta(t), Omega(t), u(t), v(t), w(t)
\
\  The output may be plotted using a program such as XYPLOT.
\
\ ---------------------------------------------------------------
\
\ Notes:
\
\  1. Three examples of a driving field are provided:
\     a) resonant step, b) resonant pulse, c) Gaussian
\     pulse with linear frequency sweep. These examples 
\     demonstrate Rabi cycling, pi-pulse inversion,
\     and adiabatic inversion of a two-level system. 
\     Inversion of the system means:
\     
\          w(t = 0)    = -1 
\
\          w(t > tmax) = +1
\
\     The probability of finding the system in the upper
\     level is one, at time t > tmax. Inversion can be
\     accomplished by different methods, as illustrated in
\     the last two examples.
\
\  2. Decay from the upper level is ignored for this idealized
\     simulation.
\
\  3. Uses adaptive step size RK4 integrator.
\
\ References:
\
\  [1] L. Allen and J.H. Eberly, Optical Resonance and Two-Level Atoms,
\      Dover, 1987.
\
\
\ Revisions:
\
\   2006-09-09  cleaned up comments and variable names.  km
\   2006-09-10  vector the words Delta(t) and Omega(t).  km
\   2006-09-11  cleaned up derivs(), added pi-pulse example,
\                 fixed Gaussian width in example, changed
\                 initial conditions slightly.           km
\   2006-09-18  added Rabi-cycling example and revised comments km
\   2006-09-22  added further explanatory material       km
\   2018-10-13  updated include file paths  km
include ans-words
include fsl/fsl-util
include fsl/dynmem
include fsl/runge4

fvariable Delta0	\ initial detuning
fvariable Omega_c	\ Rabi rate for constant field
fvariable t_end         \ end time for calculation

defer Delta(t)
defer Omega(t)

: derivs() ( ft 'u 'dudt -- )
    >r >r fdup Omega(t) fswap Delta(t) fdup
    r@ 1 } f@ f* fnegate    \ du/dt 
    2r@ drop 0 } f!
    r@ 0 } f@ f* fover
    r@ 2 } f@ f* f+         \ dv/dt
    2r@ drop 1 } f!
    r@ 1 } f@ f* fnegate    \ dw/dt
    2r> drop 2 } f! ;	


3 float array rho{	\ the Bloch vector

true value verbose
    
: bloch ( -- )
     0.01e rho{ 0 } F!   0.01e rho{ 1 } F!   -1e rho{ 2 } F!	\ initial conditions

     1e-2	\ max step size 
     1e-6 	\ eps (max fractional error)
     use( derivs() 3 rho{ )rk4qc_init

     1e-2  0e       ( maxstep tstart )          

    BEGIN
	verbose IF
	    FDUP f.
	    2 spaces FDUP Delta(t) f.
	    2 spaces FDUP Omega(t) f.
	    2 spaces 3 rho{ }fprint CR
	THEN
	rk4qc_step 0= >R
 	FDUP t_end f@ F> R> OR
     UNTIL

     FDROP FDROP

     rk4qc_done  ;

true [IF]
\ EXAMPLE 1: Resonant Step  ---------------------------------
\
\   Simulates the application of a resonant beam. The driving
\   Rabi rate and duration are chosen to demonstrate the periodic
\   cycling of the system between its upper and lower levels.
\   This cycling is known as Rabi-cycling or Rabi oscillations.
0e     Delta0 f!
4.e    Omega_c f!
8e     t_end f!

fvariable t_on  \ time at which resonant beam is switched on
2e t_on f!


: D(t) ( t -- Delta | detuning at time t)
    fdrop 0e  \ always on resonace
;
    
: O(t) ( t -- Omega | Rabi rate at time t)
    t_on f@ f>= IF Omega_c f@ ELSE 0e THEN ;

' D(t) is Delta(t)
' O(t) is Omega(t)
CR .( Using Resonant Step. )
\ -----------------------------------------------------------     
[THEN]

false [IF]
\ EXAMPLE 2: Pi Pulse ----------------------------------------
\
\   The pulse height and width are chosen to invert the system.
\   This type of a pulse is known as a "pi pulse".    
    
0e     Delta0 f!
0.785e Omega_c f!
8e     t_end f!

fvariable t_start  \ start time of pulse
2e t_start f!
    
fvariable t_pulse  \ pulse width
4e t_pulse f!


: D(t) ( t -- Delta | detuning at time t)
    fdrop 0e  \ always on resonace
;
    
: O(t) ( t -- Omega | Rabi rate at time t)
    fdup t_start f@ f>= >r t_start f@ t_pulse f@ f+ f< r> and
    IF Omega_c f@ ELSE 0e THEN ;

' D(t) is Delta(t)
' O(t) is Omega(t)
CR .( Using Resonant Square Pulse. )
\ -----------------------------------------------------------
[THEN]


false [IF]
\ EXAMPLE 3: Gaussian Pulse with Linear Frequency Sweep -------
\
\  The following field is applied to
\  the two-level system:
\
\       Delta(t) = Delta0 + s*t
\
\       Omega(t) = Omega_c +
\                    Omega_peak*exp{-0.5*(t-t_mu)^2/t_sigma^2}
\
\     where s is the angular frequency sweep rate. The set of pulse
\     parameters {Delta0, s, Omega_c, Omega_peak, t_mu, t_sigma}
\     were chosen to illustrate adiabatic inversion[1]: w(0) = -1,
\     initially, and, after the pulse, w(t) = +1.
\ 
-2e Delta0 f!       \ initial detuning from resonance
 0e Omega_c f!      \ no constant field
 4e t_end f!
 
\ Gaussian pulse parameters and sweep rate
fvariable Omega_peak
2.1e Omega_peak f!

fvariable t_sigma
.632e t_sigma f!

fvariable t_mu
2e t_mu f!

fvariable s
1e s f!

: D(t) ( t -- Delta | detuning at time t)
    s f@ f* Delta0 f@ f+ ;

: O(t) ( t -- Omega | Rabi rate at time t)
    t_mu f@ f- fdup f* 
    t_sigma f@ fdup f* 2e f*
    f/ fnegate fexp
    Omega_peak f@ f*  Omega_c f@ f+ ;

' D(t) is Delta(t)
' O(t) is Omega(t)
CR .( Using Gaussian pulse with linear frequency sweep. )
\ -----------------------------------------------------------

[THEN]
    

CR .( Type 'bloch' to compute the dynamics of the atomic state. )
