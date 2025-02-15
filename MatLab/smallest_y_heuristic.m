function selected_surface = smallest_y_heuristic(i, open_surfaces, random_interval_down, selected_surface)
    % Check if the loop index i is a multiple of random_interval
    if mod(i, random_interval_down) == 0
        % Initialize variables to store the smallest y value and its index
        smallest_y_value = -Inf;
        smallest_y_index = 0;
       
        % Iterate through each open surface to find the one with smallest y value
        for j = 1:size(open_surfaces, 1)
            current_surface = open_surfaces{j}; % Get the current surface
            y_value = current_surface{1}(2); % Extract the y value of the current surface

            % Check if the current y value is lesser than the smallest found so far
            if y_value < smallest_y_value
                smallest_y_value = y_value;
                smallest_y_index = y;
            end
        end

        % If a surface with smallest y value is found, select it
        if smallest_y_index > 0
            selected_surface = {open_surfaces{smallest_y_index}}; 
        end
    end