%This is a sample script showing how to load data from a LIGGGHTS dump file
%and feed this into RayFactor software
clc
clear
close all
more off
SRC_PATH='../../octave';
addpath(SRC_PATH); %Source octave magic

data.fileIn = 'rayFactor.liggghts';
myFontSize = 20;
thresholdVF         = 5e-6;
data.IDGlobalID     = 1;
data.IDx            = 3;
data.IDradius        = 6;
data.IDIsActive = 7;
data.IDDelta    = 1; %1...if no inverse VF, 2 ... if there are inverse VF

data.raw = readdump_all(data.fileIn);

%Determine the list of positions of active particles
globalIt=0;
for i=1:data.raw.Natoms
    if(data.raw.atom_data(i,data.IDIsActive)==1)
        globalIt=globalIt+1;
        data.raw.atom_data(i,:)
        data.activeGlobalID(globalIt)=data.raw.atom_data(i,data.IDGlobalID);
        data.active.x(globalIt)=data.raw.atom_data(i,data.IDx);
        data.active.y(globalIt)=data.raw.atom_data(i,data.IDx+1);
        data.active.z(globalIt)=data.raw.atom_data(i,data.IDx+2);
        data.active.radius(globalIt)=data.raw.atom_data(i,data.IDradius);
    endif
endfor
%data.activeGlobalID
%data.active.x
%data.active.y
%data.active.z

%extract useful samples
data.Nsample=0;
for i=1:data.raw.Natoms
    for j=1:size(data.activeGlobalID,2)
        if(data.raw.atom_data(i,data.IDIsActive+j*data.IDDelta)>thresholdVF)
            data.Nsample=data.Nsample+1;
            deltaSij(1)=data.raw.atom_data(i,data.IDx)  -data.active.x(j);
            deltaSij(2)=data.raw.atom_data(i,data.IDx+1)-data.active.y(j);
            deltaSij(3)=data.raw.atom_data(i,data.IDx+2)-data.active.z(j);
            data.sample.Sij(data.Nsample)=norm(deltaSij) ...
                                         -data.raw.atom_data(i,data.IDradius) ...
                                         -data.active.radius(j);
            data.sample.VF(data.Nsample)=data.raw.atom_data(i,data.IDIsActive+j*data.IDDelta);
        endif
    endfor
endfor
semilogy(data.sample.Sij,data.sample.VF,'ro');
hx=xlabel('S_{i-j}');
set (hx, "fontsize", myFontSize);
hy=ylabel('\epsilon_{i-j}');
set (hy, "fontsize", myFontSize);
set(gca, "linewidth", 4, "fontsize", myFontSize)

%perform fit
data.sample.logVF=log(data.sample.VF);
%[resultF.P,resultF.S]= polyfit(data.sample.Sij,data.sample.logVF,1);
resultF.x=linspace(0,max(data.sample.Sij),100);
resultF.a=max(data.sample.VF);
resultF.b=mean(-(data.sample.logVF-log(resultF.a))./data.sample.Sij);
resultF.y=resultF.a*exp(-resultF.b*resultF.x)
hold on
semilogy(resultF.x,resultF.y,'k--','linewidth',3);
ylim([thresholdVF .1])