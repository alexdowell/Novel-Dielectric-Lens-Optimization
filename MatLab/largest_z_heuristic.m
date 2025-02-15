function selected_surface = largest_z_heuristic(i, open_surfaces, random_interval_left, selected_surface)
    % Check if the loop index i is a multiple of random_interval
    if mod(i, random_interval_left) == 0
        % Initialize variables to store the highest z value and its index
        highest_z_value = -Inf;
        highest_z_index = 0;
       
        % Iterate through each open surface to find the one with highest z value
        for j = 1:size(open_surfaces, 1)
            current_surface = open_surfaces{j}; % Get the current surface
            z_value = current_surface{1}(1); % Extract the z value of the current surface

            % Check if the current z value is greater than the highest found so far
            if z_value > highest_z_value
                highest_z_value = z_value;
                highest_z_index = j;
            end
        end

        % If a surface with highest z value is found, select it
        if highest_z_index > 0
            selected_surface = {open_surfaces{highest_z_index}}; 
        end
    end  