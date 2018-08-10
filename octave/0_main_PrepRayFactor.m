%This is a sample script showing how to load data from a LIGGGHTS dump file
clc
clear
close all
more off

%%%%%%%%%%%%%%%%%%%%%%%% USER INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_particles = 0;
i=1;

#This is the standart domain size from dump input
domain_x = [0,8];
domain_y = [0,8];
domain_z = [0,12];

scale_x = 1.0;  %Should be equal to easily calc volume fraction
scale_y = 1.0;
scale_z = 1.0;

calc_particle_fraction = true; # only works if origin is in (0 0 0), should be true if writing xml
ordering_needed = true;	       # Should be ordered to any specific x/y/z - TODO: implement
write_wall = false;             # enables to exclute the wall, than only particle-particle view factors will be evaluated
partile_of_interest = 3;       # enables to select a particle of interest which will be analysed, if wall is written, automatically set to false 
write_xml = true;
write_pos_file = true;
globalRayDensity = 1e6


%%%%%%%%%%%%%%%%%%%%%%%% USER INPUT END %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%% CHOOSE FILE AND ALLOCATE POSITIONS %%%%%%%%%%%%%%%%
addpath('.'); %source the directory where the function file readdump_all.m resides!!

%...now load with the function
data.raw = readdump_all('dump.liggghts_init');

%% Allocate imported array to column variable names
x_pos = data.raw.atom_data(:,3);
y_pos = data.raw.atom_data(:,4);
z_pos = data.raw.atom_data(:,5);
x_bound = data.raw.x_bound
y_bound = data.raw.y_bound
z_bound = data.raw.z_bound

%%%%%%%%%%%%%%%%%%%%% PARTICLE SELECTOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
while(i<=size(x_pos,1))
   if(x_pos(i)>=(domain_x(1)))
       if(x_pos(i)<=domain_x(2))
        if(y_pos(i)>=domain_y(1))
            if(y_pos(i)<=domain_y(2))
                if(z_pos(i)>=domain_z(1))
                  if(z_pos(i)<=domain_z(2))  
                        n_particles = n_particles+1;
                        particles.x(n_particles) = x_pos(i);
                        particles.y(n_particles) = y_pos(i);
                        particles.z(n_particles) = z_pos(i);                       
                  end      
                end
            end
        end
       end
   end
   i=i+1;
end

array_pos = [particles.x' particles.y' particles.z'];

%%%%%%%%%%%%%%%% ORDERING PARTICLES %%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(ordering_needed)

	number_particle = size(array_pos,1)
	while(n_particles <= number_particle)
		distance_matix_reorder(n_particles)  = array_pos(n_particles,3)-z_bound(1);
		n_particles = n_particles+1;
	end

	 [tmp,ind]=sort(distance_matix_reorder, 'ascend');
	 origins_sort_x = array_pos(:,1);
	 origins_sort_y = array_pos(:,2);
	 origins_sort_z = array_pos(:,3);
	 
	 origins_sort_x=origins_sort_x(ind);
	 origins_sort_y=origins_sort_y(ind);
	 origins_sort_z=origins_sort_z(ind);
	 
	n_particles = 1;
	while(n_particles <= number_particle)
		array_pos(n_particles,1) = origins_sort_x(n_particles);
		array_pos(n_particles,2) = origins_sort_y(n_particles);
		array_pos(n_particles,3) = origins_sort_z(n_particles);
		n_particles = n_particles+1;
	end
end

if(calc_particle_fraction)
    volume_box = (x_bound(2)*y_bound(2)*z_bound(2));    
    volume_particle = (n_particles)*(1/6)*scale_x*scale_y*scale_z*pi   
    volume_fraction = volume_particle/volume_box
end

%%%%%%%%%%%%%%%% CREATE XML INPUT %%%%%%%%%%%%%%%%%%%%%%%%%

if(write_xml)
    i=1;
    
    file_name = sprintf('input_phi%g.xml',volume_fraction);
    fid=fopen(file_name,'w');  
    %% Write File Structure %%

    string = sprintf('<?xml version="1.0" ?> \n <project>  \n <settings> \n <globalRayDensity value="%d" /> \n <description> \n ... \n </description> \n </settings> \n <geometry> \n',globalRayDensity);
    fprintf(fid,[string]);
    
    if(write_wall)
     
      %% Write Plane of interest %%
      string = sprintf('<bv> type="rectangle"> \n  <scale x="%d" y="%d" z="%d" />\n  <children> \n  <primitive type="rectangle" > \n ',x_bound(2),y_bound(2),z_bound(2));
      fprintf(fid,[string]);
      string = sprintf('<scale x="1.0" y="1.0" z="1.0" /> \n </primitive> \n  </children> \n </bv> \n');
      fprintf(fid,[string]); 
      %% Write Spehres %%
      while(i<=size(array_pos,1))      
          x= array_pos(i,1);
          y= array_pos(i,2);
          z= array_pos(i,3);     
          
          %if(i=partile_of_interest)
          %  printf(fid,['<primitive type="sphere" > \n']);
          %else
          %  printf(fid,['<primitive type="sphere" analyse="false" > \n']);
          %end
          string = sprintf('<primitive type="sphere" analyse="false"> \n');
          fprintf(fid,[string]); 
          string = sprintf('<scale x="%d" y="%d" z="%d" /> \n <translation x="%d" y="%d" z="%d" /> \n </primitive>\n',scale_x,scale_y,scale_z,x,y,z);               
          fprintf(fid,[string]); 
          
          i=i+1;
      end
    else
      while(i<=size(array_pos,1))      
          x= array_pos(i,1);
          y= array_pos(i,2);
          z= array_pos(i,3);     
          
          if(i==partile_of_interest)
            string = sprintf('<primitive type="sphere"> \n');
            fprintf(fid,[string]); 
            string = sprintf('<scale x="%d" y="%d" z="%d" /> \n <translation x="%d" y="%d" z="%d" /> \n </primitive>\n',scale_x,scale_y,scale_z,x,y,z);               
            fprintf(fid,[string]); 
            i=i+1;
          else
            string = sprintf('<primitive type="sphere" analyse="false"> \n');
            fprintf(fid,[string]); 
            string = sprintf('<scale x="%d" y="%d" z="%d" /> \n <translation x="%d" y="%d" z="%d" /> \n </primitive>\n',scale_x,scale_y,scale_z,x,y,z);               
            fprintf(fid,[string]); 
            i=i+1;
          end

          string = sprintf('<primitive type="sphere" analyse="false"> \n');
          fprintf(fid,[string]); 
          string = sprintf('<scale x="%d" y="%d" z="%d" /> \n <translation x="%d" y="%d" z="%d" /> \n </primitive>\n',scale_x,scale_y,scale_z,x,y,z);               
          fprintf(fid,[string]); 
      end  
    end
    string = sprintf('</geometry> \n </project>\n');
    fprintf(fid,[string]); 
    fclose(fid);
end

%%%%%%%%%%%%%%%% CREATE Position File %%%%%%%%%%%%%%%%%%%%%%%%%

if(write_pos_file)
    
    i=1;
    file_name = sprintf('ordered_position.dat');
    fid=fopen(file_name,'w')  ;    
    while(i<=size(array_pos,1))
                string = sprintf('%d %d %d\n',array_pos(i,1),array_pos(i,2),array_pos(i,3));   
                fprintf(fid,[string]);     
                i = i+1;
    end
    fclose(fid);
    
    
end

