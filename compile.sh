#!/bin/sh

g++ -fopenmp -msse -msse2 -msse3 -mssse3 -msse4 -msse4.1 -msse4.2 -O3 -Wall -o build/rayfactor src/*.cpp

