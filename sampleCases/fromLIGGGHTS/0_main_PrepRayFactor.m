%This is a sample script showing how to load data from a LIGGGHTS dump file
%and feed this into RayFactor software
clc
clear
close all
more off
SRC_PATH='../../octave';
addpath(SRC_PATH); %Source octave magic

%%%%%%%%%%%%%%%%%%%%%%%% USER INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data.fileIn = 'dump.liggghts';
data.STLprefix='STL';
data.ColumID  = 1; %Column with radius
data.ColumPos = 3; %Column with x position
data.ColumRad =15; %Column with radius


#This is used to select particles. Keept empty to take all particles in dump
# file
domain.bound.x = [0,5];
domain.bound.y = [0,5];
domain.bound.z = [0,12];

%the wall(s) 
domain.walls{1}.span = [10  ...
                        10  ...
                        0]; %this is an xy plane with a certain length, so no need to rotate for rayfactor
domain.walls{1}.normalDir = 1; %in positive direction (here: z);
domain.walls{1}.origin = [0 0 0]; %Origin at zero : this is NOT STANDARD for rayfactor, so need to translate

%the wall(s) 
domain.walls{2}.span = domain.walls{1}.span ;
domain.walls{2}.normalDir = -1; %in NEGATIVE direction (here: minus z);
domain.walls{2}.origin = [0 0 1.12]; %Origin at zero : this is NOT STANDARD for rayfactor, so need to translate


domain.scale.x = 1.0;  %Should be equal to 1 to easily calc volume fraction
domain.scale.y = 1.0;
domain.scale.z = 1.0;

querry.order                = false;	   # Should be ordered to any specific x/y/z - TODO: implement
querry.particleOfInterest   = 3;       # enables to select a particle of interest which will be analysed, if wall is written, automatically set to false 
querry.writeFiles             = true;
globalRayDensity            = 2e5; %ray density per unit area

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
data.radius = data.raw.atom_data(:,data.ColumRad);%Column with radius

%%%%%%%%%%%%%%%%%%%%% PARTICLE SELECTOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
particles.x=zeros( data.raw.Natoms,1);particles.y=particles.x;
particles.z=particles.x; particles.radius=particles.x; 
particles.id=particles.x; %Pre-allocate for speed
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
        string = sprintf('  </primitive>\n');
        fprintf(fid,[string]); 
    endfor
    
    %...also dump to STL
    stlWriter(file_nameStl, domain.walls);

    %PARTICLES
    i=1;
    while(i<=size(particles.radius,1))      
         %TODO: implement particle of interes
                string = sprintf('  <primitive type="sphere" analyse="false"> \n');
                fprintf(fid,[string]); 
                string = sprintf('    <scale x="%d" y="%d" z="%d"/> \n ', ...
                                    particles.radius(i),particles.radius(i),particles.radius(i));
                fprintf(fid,[string]); 
                string = sprintf('    <translation x="%d" y="%d" z="%d" /> \n', ...
                                  particles.x(i),particles.y(i),particles.z(i));              
                fprintf(fid,[string]); 
                string = sprintf('  </primitive>\n');
                fprintf(fid,[string]); 
                i=i+1;
    end  
    string = sprintf('</geometry> \n</project>\n');
    fprintf(fid,[string]); 
    fclose(fid);
end
