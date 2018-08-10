clc
clear
more off

fileName.STLout='myNew.stl';
stl{1}.span = [1.1 2.2 0];
stl{1}.origin = -stl{1}.span/2; %Center at origin

stl{2}.span = [3.1 0 3.2];
stl{2}.origin = -stl{2}.span/2; %Center at origin

% END USER INPUT
stlWriter(fileName.STLout, stl);
