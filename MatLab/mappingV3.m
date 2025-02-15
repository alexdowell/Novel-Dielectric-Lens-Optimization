function node_list = mappingV3(all_surfaces, epsilon_value, inside_height_boundary, lens_base_inside_boundary, cone_angle, outside_boundary)

% Step 1: Remove all vertical surfaces
all_surfaces = all_surfaces(~cellfun(@(s) s{1}(1) == s{2}(1), all_surfaces));

% Step 2: Group and order z1 surfaces
z1_values = cellfun(@(s) s{1}(1), all_surfaces);
[unique_z1, ~, z1_group_indices] = unique(z1_values);
grouped_surfaces = cell(length(unique_z1), 1);
for i = 1:length(unique_z1)
    z1 = unique_z1(i);
    group = all_surfaces(z1_group_indices == i);
    grouped_surfaces{i} = group;
end

% Now sort each group based on y1 values
for i = 1:length(grouped_surfaces)
    group = grouped_surfaces{i};
    y1_values = cellfun(@(s) s{1}(2), group);
    [~, sorted_indices] = sort(y1_values);
    grouped_surfaces{i} = group(sorted_indices);
end

% Step 3: Initialize node_list and process surfaces
node_list = [];

% First add empty space to unoccupied node columns close to the switch
% Find the first z1 value from the first group
first_z1 = unique_z1(1);

if (first_z1 - 1) > lens_base_inside_boundary
    % Loop from last_z1  to outside_boundary - 1
    for i = (lens_base_inside_boundary ):(first_z1-2)
        % Calculate boundary_height for the current i value
        boundary_height = floor((i - lens_base_inside_boundary) * tan(deg2rad(cone_angle))) + inside_height_boundary + 1;

        % The height to be appended to node_list
        h = boundary_height;

        % Append zeros to the node_list for the calculated height
        node_list = [node_list, repmat(0, 1, h)];
    end
end


for i = 1:length(grouped_surfaces)
    boundary_height = floor((grouped_surfaces{i}{1}{2}(1) - lens_base_inside_boundary) * tan(deg2rad(cone_angle))) + inside_height_boundary + 1;
    for j = 1:length(grouped_surfaces{i})
        surface = grouped_surfaces{i}{j};
        z1 = surface{1}(1);
        y1_j = surface{1}(2);
        if i ~= length(grouped_surfaces)            
            next_surface = grouped_surfaces{i+1}{1};
            next_z1 = next_surface{1}(1);
        else
            next_surface = z1 + 1;
        end
        
        if length(grouped_surfaces{i}) > 1 
            if mod(j, 2) == 1  % Odd indexed surface
                y1_next = grouped_surfaces{i}{j + 1}{1}(2);
                if (y1_j ~= 0) && (j == 1) 
                    h = y1_j;
                    node_list = [node_list, repmat(0, 1, h)];
                    h2 = y1_next - y1_j;
                    node_list = [node_list, repmat(epsilon_value, 1, h2)];

                elseif (y1_j == 0) && (i == 1)
                    h = y1_next;
                    node_list = [node_list, repmat(epsilon_value, 1, h)];
                else
                    h = y1_next - y1_j;
                    node_list = [node_list, repmat(epsilon_value, 1, h)];
                end

            else % Even indexed surface
                if j < length(grouped_surfaces{i})  % Not at the end of the list
                    y1_next = grouped_surfaces{i}{j + 1}{1}(2);
                    h = y1_next - y1_j;
                    node_list = [node_list, repmat(0, 1, h)];
                else  % At the end of the list
                    h = boundary_height - y1_j;
                    node_list = [node_list, repmat(0, 1, h)];
                end
            end
        end
    end
    if i == 1
        blank_column_count = 1;
    else
        blank_column_count = next_z1 - z1;
    end
    
    % Add 0's for blank columns
    if blank_column_count ~= 1
        blank_column_index = z1 + 1;
        for z = 1:(blank_column_count - 1)
            
            boundary_height = floor((blank_column_index - lens_base_inside_boundary) * tan(deg2rad(cone_angle))) + inside_height_boundary + 1;

            % The height to be appended to node_list
            h = boundary_height;

            % Append zeros to the node_list for the calculated height
            node_list = [node_list, repmat(0, 1, h)];
            
            % Next column
            blank_column_index = blank_column_index + 1;
        end
    end
end

% add remaining free space to unoccupied node columns
% Find the last z1 value from the last group
last_z1 = unique_z1(end);

% Loop from last_z1  to outside_boundary - 1
for i = (last_z1 ):(outside_boundary-1)
    % Calculate boundary_height for the current i value
    boundary_height = floor((i - lens_base_inside_boundary) * tan(deg2rad(cone_angle))) + inside_height_boundary + 1;

    % The height to be appended to node_list
    h = boundary_height;

    % Append ones to the node_list for the calculated height
    node_list = [node_list, repmat(0, 1, h)];
end