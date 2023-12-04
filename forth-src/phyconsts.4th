\ phyconsts.4th
\
\ Handy definitions for my Forth desktop environment
\

-1e facos fconstant  pi
pi 2e f*  fconstant  2pi

     299792458e  fconstant  c	  \ speed of light in m/s
8.854187817e-12  fconstant  eps0  \ electric constant in F/m
 6.62606876e-34  fconstant  h     \ Planck's constant in J*s
h 2pi f/         fconstant  hbar  \ 
1.602176462e-19  fconstant  e     \ elementary charge in C
1.3806503e-23    fconstant  kB    \ Boltzmann's constant in J/K
9.10938188e-31   fconstant  m_e   \ electron mass in kg
1.67262158e-27   fconstant  m_p   \ proton mass in kg

\ Derived Constants
137.035999139e   fconstant  alpha^-1  \ inverse fine structure constant

\ Unit Conversions
e                fconstant  J/eV     \ electron volts -> Joules
1.66053873e-27   fconstant  kg/amu   \ atomic mass unit -> kilograms
219474.6314e     fconstant  cm^-1/Eh \ Hartree to wavenumber conversion
0.5291772083e    fconstant  A/a0     \ Bohr radii to Angstroms conversion

.( Defined FCONSTANTs [physical constants in MKS units]: ) CR CR
.(        pi ) CR
.(       2pi ) CR
.(         c     speed of light ) CR
.(      eps0     permitivitty of free space ) CR
.(         h     Planck's constant ) CR
.(      hbar ) CR
.(         e     elementary charge ) CR
.(        kB     Boltzmann's constant ) CR
.(       m_e     electron mass ) CR
.(       m_p     proton mass ) CR
.(  alpha^-1     inverse fine structure constant ) CR
CR
.( Conversions between units: ) CR CR
.(      J/eV     eV -> J ) CR
.(    kg/amu     amu -> kg ) CR
.(  cm^-1/Eh     Hartree -> wavenumber ) CR
.(      A/a0     Bohr radius -> Angstroms ) CR
CR CR

