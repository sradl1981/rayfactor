Copyright of This File and modifications starting from Aug 8 2018
==================
Stefan Radl, TU Graz, 2018

Random Number Generator
==================
The dSFMT algorithm has been implemented in rayFactor (see Chapter 4.3) to generate random numbers.

Primitives (that define the "scene", i.e., the geometry)
===========
see Chapter 2.4 of the thesis

In general, all primitives have a RADIUS (or LENGTH) of 1. For example, the rectangle has a unit width of 2 (i.e., it has an area of 2x2 length units).
All primitives are assumed to be centered (or based) on the xy-plane and the ORIGIN (i.e., [0 0 0]).

Primitives include 
- rectangle
- disc
- annulus
- sphere
- cylinder and
- frustum ("TaperedCylinder")

Possibly, also triangle (and 'fasttriangle') are supported (not explored/used in an example, and hence not benchmarked).

Build
==============
Simply run the compile.sh script. The executable will be placed in the directory 'build'. You might want to create a symbolic link to this executable in a folder that is in your PATH.

Usage
===============
basic usage is with (we assume that you created a symbolic link with the name 'rayfactor')

rayfactor

Using multiple threads is done simply by (here we use 4 threads)

rayfactor 4

Using different input file than the default (=input.xml) is done via

rayfactor 4 -f yourInputFile.xml

Functionality of the Algorithm
=================
The code performs ray tracing by considering all possible combinations of defined primitives. See the function 'tracefactors' of each primitive in the source code.

The user can de-activate certain combinations by using the 'analyse="false"' switch in the primitive definition (of course, the primitive is still considered part of the system!). This de-activation will greatly improve the speed in case only view factors from a single object are of interest.

