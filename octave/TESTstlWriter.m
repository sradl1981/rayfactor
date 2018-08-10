clc
clear
more off

fileName.STLout='myNew.stl';
stl{1}.origin = [0 0 0];
stl{1}.span = [1.1 2.2 0];

stl{2}.origin = [0 0 3];
stl{2}.span = [3.1 0 3.2];

% END USER INPUT
stlWriter(fileName.STLout, stl);
