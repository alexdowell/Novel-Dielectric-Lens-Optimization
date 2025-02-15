function selected_surface = largest_y_heuristic(i, open_surfaces, random_interval_up, selected_surface)
    % Check if the loop index i is a multiple of random_interval
    if mod(i, random_interval_up) == 0
        % Initialize variables to store the highest y value and its index
        highest_y_value = -Inf;
        highest_y_index = 0;
       
        % Iterate through each open surface to find the one with highest y value
        for j = 1:size(open_surfaces, 1)
            current_surface = open_surfaces{j}; % Get the current surface
            y_value = current_surface{1}(2); % Extract the y value of the current surface

            % Check if the current y value is greater than the highest found so far
            if y_value > highest_y_value
                highest_y_value = y_value;
                highest_y_index = j;
            end
        end

        % If a surface with highest y value is found, select it
        if highest_y_index > 0
            selected_surface = {open_surfaces{highest_y_index}}; 
        end
    end  