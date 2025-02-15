function selected_surface = smallest_z_heuristic(i, open_surfaces, random_interval_right, selected_surface)
    % Check if the loop index i is a multiple of random_interval
    if mod(i, random_interval_right) == 0
        % Initialize variables to store the smallest z value and its index
        smallest_z_value = -Inf;
        smallest_z_index = 0;
       
        % Iterate through each open surface to find the one with smallest z value
        for j = 1:size(open_surfaces, 1)
            current_surface = open_surfaces{j}; % Get the current surface
            z_value = current_surface{1}(1); % Extract the z value of the current surface

            % Check if the current z value is lesser than the smallest found so far
            if z_value < smallest_z_value
                smallest_z_value = z_value;
                smallest_z_index = j;
            end
        end

        % If a surface with smallest z value is found, select it
        if smallest_z_index > 0
            selected_surface = {open_surfaces{smallest_z_index}}; 
        end
    end  