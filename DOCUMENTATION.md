Copyright of This File and modifications starting from Aug 8 2018
==================
Stefan Radl, TU Graz, 2018

Random Number Generator
==================
the dSFMT algorithm has been implemented (see Chapter 4.3).

Primitives (that define the "scene", i.e., the geometry)
===========
see Chapter 2.4 of the thesis

In general, all primitives have a RADIUS of 1. The rectangle has a unit width of 2 (i.e., 2x1)

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


