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

