clc
clear
close all
more off
SRC_PATH='../../octave';
addpath(SRC_PATH); %Source octave magic

dataFileName = 'dat.mat'

%%% END USER INPUT %%%%%

load(dataFileName)

myData.activeGlobalID    =  data.activeGlobalID;
myData.raw.atom_data  = data.raw.atom_data;

%HERE NOW THE PROJECTION METHOD ANALYSIS
