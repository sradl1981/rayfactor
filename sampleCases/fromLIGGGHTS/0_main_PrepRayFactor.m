%This is a sample script showing how to load data from a LIGGGHTS dump file
%and feed this into RayFactor software
clc
clear
close all
more off
SRC_PATH='../../octave';
addpath(SRC_PATH); %Source octave magic

%%%%%%%%%%%%%%%%%%%%%%%% USER INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Layout of input, and STL file name
%data.fileIn = 'dump.liggghts';
data.fileIn = 'phi_0.40_Re1_real15_pConfig2000000.liggghts';
data.ColumID  = 1; %Column with Global ID
data.ColumPos = 5; %Column with x position
data.ColumRad = 3; %Column with radius
data.radiusAdjustFactor = 0.5; %factor to adjust data to get radius. e.g., use 0.5 if data is diameter
data.STLprefix='STL';

%bounding box for including particles in analysis
domain.boundActive.x=[6 7];
domain.boundActive.y=[6 7];
domain.boundActive.z=[4 9];
%domain.boundActive.x=[-99 99];
%domain.boundActive.y=[-99 99];
%domain.boundActive.z=[-99 99];

%the wall(s). You can specify multiple walls - all of them will be analyzed 
%domain.walls{1}.span = [10  ...
%                          10  ...
%                        0]; %this is an xy plane with a certain length, so no need to rotate for rayfactor
%domain.walls{1}.normalDir = 1; %in positive direction (here: z): important since rays are shoot from this direction only!;
%domain.walls{1}.origin = [0 0 0]; %Origin at zero : this is NOT STANDARD for rayfactor, so need to translate

%domain.walls{2}.span = domain.walls{1}.span ;
%domain.walls{2}.normalDir = 1; %same as before - just to check random number generator
%domain.walls{2}.origin = [0 0 0]; %Origin at zero : this is NOT STANDARD for rayfactor, so need to translate

%domain.walls{3}.span = domain.walls{1}.span ;
%domain.walls{3}.normalDir = -1; %in NEGATIVE direction (here: minus z);
%domain.walls{3}.origin = [0 0 1.12]; %Origin at zero : this is NOT STANDARD for rayfactor, so need to translate


querry.order                = false;	   # Should be ordered to any specific x/y/z - TODO: implement
%querry.particleOfInterest   = 3;       # TODO: implement. enables to select a particle of interest which will be analysed, if wall is written, automatically set to false 
querry.writeFiles             = true; %Main swith for writing files
globalRayDensity            = 1e6; %ray density per unit area

%%%%%%%%%%%%%%%%%%%%%%%% USER INPUT END %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%% CHOOSE FILE AND ALLOCATE POSITIONS %%%%%%%%%%%%%%%%
addpath('.'); %source the directory where the function file readdump_all.m resides!!

%...now load with the function
data.raw = readdump_all(data.fileIn);

%% Allocate imported array to column variable names
data.id = data.raw.atom_data(:,data.ColumID); %Column with Id
data.pos.x = data.raw.atom_data(:,data.ColumPos);
data.pos.y = data.raw.atom_data(:,data.ColumPos+1);
data.pos.z = data.raw.atom_data(:,data.ColumPos+2);
data.radius = data.raw.atom_data(:,data.ColumRad)*data.radiusAdjustFactor;%Column with radius

%%%%%%%%%%%%%%%%%%%%% PARTICLE SELECTOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
particles.x=zeros( data.raw.Natoms,1);particles.y=particles.x;
particles.z=particles.x; particles.radius=particles.x; 
particles.id=particles.x; 
particles.active=particles.x*0+false; %Pre-allocate for speed
if(isfield(domain,'bound'))
n_particles = 0; i =1;   
while(i<=size(data.pos.x,1))
   if(data.pos.x(i)>=(domain.bound.x(1)))
       if(data.pos.x(i)<=domain.bound.x(2))
        if(data.pos.y(i)>=domain.bound.y(1))
            if(data.pos.y(i)<=domain.bound.y(2))
                if(data.pos.z(i)>=domain.bound.z(1))
                  if(data.pos.z(i)<=domain.bound.z(2))  
                        n_particles = n_particles+1;
                        particles.x(n_particles) = data.pos.x(i);
                        particles.y(n_particles) = data.pos.y(i);
                        particles.z(n_particles) = data.pos.z(i);                       
                        particles.id(n_particles) = data.id(i);
                        particles.radius(n_particles) = data.radius(i);
                  end      
                end
            end
        end
       end
   end
   i=i+1;
end
particles.x(n_particles+1:end)='';particles.y(n_particles+1:end)='';
particles.z(n_particles+1:end)='';particles.id(n_particles+1:end)='';
particles.radius(n_particles+1:end)='';
domain.nPart = n_particles;
else
particles.x = data.pos.x;particles.y = data.pos.y;particles.z = data.pos.z;
particles.id=data.id;particles.radius=data.radius;
domain.bound.x = data.raw.x_bound;
domain.bound.y = data.raw.y_bound;
domain.bound.z = data.raw.z_bound;
domain.nPart = data.raw.Natoms;
endif

% Set particles active for analysis or not
i =1;   
while(i<=size(particles.x,1))
   if(particles.x(i)>=(domain.boundActive.x(1)))
       if(particles.x(i)<=domain.boundActive.x(2))
        if(particles.y(i)>=domain.boundActive.y(1))
            if(particles.y(i)<=domain.boundActive.y(2))
                if(particles.z(i)>=domain.boundActive.z(1))
                  if(particles.z(i)<=domain.boundActive.z(2))  
                            particles.active(i) = true;
                  end      
                end
            end
        end
       end
   end
   i=i+1;
end
sum( particles.active)
%

%%%%%%%%%%%%%%%% ORDERING PARTICLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%
if(querry.order)
    arradata.pos.y = [particles.x' particles.y' particles.z'];
    orderParticles
end

if(true)
    domain.volume=  (domain.bound.x(2)-domain.bound.x(1)) ...
                   *(domain.bound.y(2)-domain.bound.y(1)) ...
                   *(domain.bound.z(2)-domain.bound.z(1));
       
    domain.volPart = pi*4/3 * sum(particles.radius.^3);
    domain.phiPart = domain.volPart/domain.volume;
end

%%%%%%%%%%%%%%%% CREATE XML INPUT %%%%%%%%%%%%%%%%%%%%%%%%%

if(querry.writeFiles)

    %File names
    endingPos = strfind(data.fileIn,'.liggghts');
    fileRawName = data.fileIn(1:endingPos-1)
    file_name = sprintf('input_%s_%.5f.xml', fileRawName, domain.phiPart);
    file_nameStl = sprintf('%s_%s_%.5f.stl', data.STLprefix, fileRawName, domain.phiPart);
    fid=fopen(file_name,'w');  
    
    %% Write File Structure %%

    string = sprintf('<?xml version="1.0" ?> \n<project>  \n<settings> \n  <globalRayDensity value="%d" /> \n  <description> \n    LIGGGHTS Interface Output \n  </description> \n </settings> \n<geometry> \n',globalRayDensity);
    fprintf(fid,[string]);
    
    %% PLANES %% TODO: Implement rotation
    if(isfield(domain,'walls'))
    for(iSTL=1:size(domain.walls,2))
        %complete STL information   
        domain.walls{iSTL}.center = domain.walls{iSTL}.span./2 + domain.walls{iSTL}.origin;
        string = sprintf('  <primitive type="rectangle"> \n');
        fprintf(fid,[string]);
        spanForXML=ifelse(domain.walls{iSTL}.span==0, ...
                          domain.walls{iSTL}.normalDir, ...
                          domain.walls{iSTL}.span/2); %set span for empty to 1, also divide by 2 since span in XML is HALF width!!
        string = sprintf('    <scale x="%.4g" y="%.4g" z="%.4g" />\n ', ...
                          spanForXML(1), ...
                          spanForXML(2), ...
                          spanForXML(3));
        fprintf(fid,[string]);
        string = sprintf('   <translation x="%.4g" y="%.4g" z="%.4g" />\n', ...
                         domain.walls{iSTL}.center(1), ...
                         domain.walls{iSTL}.center(2), ...
                         domain.walls{iSTL}.center(3));
        fprintf(fid,[string]);
        string = sprintf('    <globalID id="%.0f" />\n',
                         -1*iSTL);
        fprintf(fid,[string]);                  
        string = sprintf('  </primitive>\n');
        fprintf(fid,[string]); 
    endfor
    %...also dump to STL
    stlWriter(file_nameStl, domain.walls);
    endif
    
    %PARTICLES
    i=1;
    while(i<=size(particles.radius,1))      
         %TODO: implement particle of interes
                     if( particles.active(i))
                        string = sprintf('  <primitive type="sphere" analyse="true"> \n');
                     else
                        string = sprintf('  <primitive type="sphere" analyse="false"> \n');
                     endif
                fprintf(fid,[string]); 
                string = sprintf('    <scale x="%d" y="%d" z="%d"/> \n', ...
                                    particles.radius(i),particles.radius(i),particles.radius(i));
                fprintf(fid,[string]); 
                string = sprintf('    <translation x="%d" y="%d" z="%d" /> \n', ...
                                  particles.x(i),particles.y(i),particles.z(i));              
                fprintf(fid,[string]); 
                string = sprintf('    <globalID id="%.0f" />\n',
                                 particles.id(i));
                fprintf(fid,[string]); 
                string = sprintf('  </primitive>\n');
                fprintf(fid,[string]); 
                i=i+1;
    end  

    
   
    string = sprintf('</geometry> \n</project>\n');
    fprintf(fid,[string]); 
    fclose(fid);
end
