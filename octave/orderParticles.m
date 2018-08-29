	number_particle = size(arradata.pos.y,1)
	while(n_particles <= number_particle)
		distance_matix_reorder(n_particles)  = arradata.pos.y(n_particles,3)-data.bound.z(1);
		n_particles = n_particles+1;
	end

	 [tmp,ind]=sort(distance_matix_reorder, 'ascend');
	 origins_sort_x = arradata.pos.y(:,1);
	 origins_sort_y = arradata.pos.y(:,2);
	 origins_sort_z = arradata.pos.y(:,3);
	 
	 origins_sort_x=origins_sort_x(ind);
	 origins_sort_y=origins_sort_y(ind);
	 origins_sort_z=origins_sort_z(ind);
	 
	n_particles = 1;
	while(n_particles <= number_particle)
		arradata.pos.y(n_particles,1) = origins_sort_x(n_particles);
		arradata.pos.y(n_particles,2) = origins_sort_y(n_particles);
		arradata.pos.y(n_particles,3) = origins_sort_z(n_particles);
		n_particles = n_particles+1;
	end