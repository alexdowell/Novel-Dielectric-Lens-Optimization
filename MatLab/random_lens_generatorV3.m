% Bicone Cavity boundaries
outside_boundary = 150;% collar radius
lens_base_inside_boundary = 15; % inside boundary
inside_height_boundary = 13; % inside height of the cavity
cone_height_boundary = 15; % outside height of the cavity/2
cone_angle = 0; %  cone angle boundary in degrees
max_loops = floor(1890*.75); % 3/4 of maximum amount of loops that can fit in half of the cavity 
epsilon_min = 1.7; % minimum epsilon value
epsilon_max = 4.3; % maximum epsilon value
current_sample_number = 10145; % current sample and low end range 
sim_data_set_size = 2000; % number of simulations
square_range = 10; % Number of squares to generate
single_dielectric_value = true; % turn on(true) and all samples will have a singular shared dielectric_value
dielectric_constant = 2.2;

% Initialize an array to store time for each simulation
individual_sim_times = zeros(1, sim_data_set_size);

% Start measuring total simulation time
total_time_start = tic;

for sim = current_sample_number:(current_sample_number+sim_data_set_size)

    % Start measuring time for this iteration
    iteration_start = tic;    
    
    % Path to the CST file
    cst_file_path = 'C:\Users\addkbr\Desktop\Bicone_Studies\500Mhz_bicone_no_collar.cst';

    % Check if the file exists
    if ~exist(cst_file_path, 'file')
        error('CST file not found: %s', cst_file_path);
    end

    % Establishing a connection with CST Studio Suite
    cst = actxserver('CSTStudio.Application');

    % Open the existing Microwave Studio (MWS) project
    mws = cst.invoke('OpenFile', cst_file_path);

    % Randomized epsilon value between epsilon_min and epsilon_max or
    % selected dielectric_constant
    if single_dielectric_value == true
        epsilon_value = dielectric_constant;
    else
        epsilon_value = epsilon_min + (epsilon_max - epsilon_min) * rand();
        epsilon = round(epsilon_value, 1);
    end

    % Material Creation
    material = invoke(mws,'material');

    % Resetting the Material settings
    invoke(material, 'Reset');

    % Setting properties for the Material
    invoke(material, 'Name', 'lens_dielectric_matlab');
    invoke(material, 'Epsilon', epsilon_value);

    % Creating the Material
    invoke(material, 'Create');
    
    % Generate a random number between 1 and square_range
    if rand() < 0.5
        squares = 1; % Select 1 with 50% probability
    else
        squares = randi([2, square_range]); % Select any other number in the range with 50% probability
    end
    %squares = randi([1, square_range]); % Randomly select the number of squares from 1 to square_range

    % To keep track of unique (z_dist, y_dist) pairs
    unique_pairs = zeros(squares, 2);
    pair_count = 0;

    while pair_count < squares
            
        z_dist = (lens_base_inside_boundary + 3) + floor((outside_boundary - (lens_base_inside_boundary + 3)) * rand());
        y_max = floor((z_dist - lens_base_inside_boundary) * tan(deg2rad(cone_angle))) + inside_height_boundary - 1;
        y_dist = randi([2, y_max]);

        % Check for uniqueness
        new_pair = [z_dist, y_dist];

        % initializing open surfaces cell array 6 x (number of surfaces) [[z,y], [z,y], [up/down/NA(0/1/2),
        % left/right/NA(0/1/2)]
        if pair_count == 0
            open_surfaces = {...
        {[z_dist, y_dist], [z_dist - 1, y_dist], [0,2]};...
        {[z_dist - 1, y_dist - 1], [z_dist - 1, y_dist], [2,1]};...
        {[z_dist, y_dist - 1], [z_dist - 1, y_dist - 1], [1,2]};...
        {[z_dist, y_dist - 1], [z_dist, y_dist], [2,0]}};
        end    
        if ~ismember(new_pair, unique_pairs, 'rows')
            % Increment the pair_count and add the new unique pair to the tracking matrix
            pair_count = pair_count + 1;
            unique_pairs(pair_count, :) = new_pair;

            % Add the new unique surfaces to open_surfaces
            if pair_count > 1
                origin_surfaces = {...
                    {[z_dist, y_dist], [z_dist - 1, y_dist], [0, 2]};...
                    {[z_dist - 1, y_dist - 1], [z_dist - 1, y_dist], [2, 1]};...
                    {[z_dist, y_dist - 1], [z_dist - 1, y_dist - 1], [1, 2]};...
                    {[z_dist, y_dist - 1], [z_dist, y_dist], [2, 0]}
                };
                open_surfaces = [open_surfaces; origin_surfaces];
                
                % creating a single loop for the lens base
                % Accessing the Rotate object
                rotate2 = invoke(mws, 'Rotate');

                % Resetting the Rotate settings
                invoke(rotate2, 'Reset');

                % Setting properties for the Rotate operation
                invoke(rotate2, 'Name', 'Lens_Base2');
                invoke(rotate2, 'Component', 'component1');
                invoke(rotate2, 'Material', 'lens_dielectric_matlab'); 
                invoke(rotate2, 'Mode', 'Pointlist');
                invoke(rotate2, 'StartAngle', '0.0');
                invoke(rotate2, 'Angle', '360');
                invoke(rotate2, 'Height', '0.0');
                invoke(rotate2, 'RadiusRatio', '1.0');
                invoke(rotate2, 'NSteps', '0');
                invoke(rotate2, 'SplitClosedEdges', 'True');
                invoke(rotate2, 'SegmentedProfile', 'False');
                invoke(rotate2, 'SimplifySolid', 'False');
                invoke(rotate2, 'UseAdvancedSegmentedRotation', 'True');
                invoke(rotate2, 'CutEndOff', 'False');
                invoke(rotate2, 'Origin', '0.0', '0.0', '0.0');
                invoke(rotate2, 'Rvector', '0.0', '0.0', '1.0');
                invoke(rotate2, 'Zvector', '0.0', '1.0', '0.0');
                invoke(rotate2, 'Point', num2str(z_dist), num2str(y_dist));
                invoke(rotate2, 'LineTo', num2str(z_dist - 1), num2str(y_dist));
                invoke(rotate2, 'LineTo', num2str(z_dist - 1), num2str(y_dist - 1));
                invoke(rotate2, 'LineTo', num2str(z_dist), num2str(y_dist - 1));

                % Creating the rotated shape
                invoke(rotate2, 'Create');

                % mirroring a single loop
                brick_mirror1 = invoke(mws, 'Transform');
                invoke(brick_mirror1, 'Reset');
                invoke(brick_mirror1, 'Name', 'component1:Lens_Base2');
                invoke(brick_mirror1, 'Origin', 'Free');
                invoke(brick_mirror1, 'Center', '0', '0', '0'); 

                mirror_height = y_dist;

                invoke(brick_mirror1, 'PlaneNormal', '0', mirror_height, '0');

                invoke(brick_mirror1, 'MultipleObjects', 'True'); 
                invoke(brick_mirror1, 'GroupObjects', 'False');
                invoke(brick_mirror1, 'Repetitions', '1');
                invoke(brick_mirror1, 'MultipleSelection', 'False');
                invoke(brick_mirror1, 'Destination', '');
                invoke(brick_mirror1, 'Material', 'lens_dielectric_matlab');
                invoke(brick_mirror1, 'Transform', 'Shape', 'Mirror');
                % merge both loops to the lens base bottom and top
                solid1 = invoke(mws,'solid');
                invoke(solid1, 'Add', 'component1:Lens_Base1', 'component1:Lens_Base2');
                invoke(solid1, 'Add', 'component1:Lens_Base1_1', 'component1:Lens_Base2_1');
            else 
                % creating a single loop for the lens base
                % Accessing the Rotate object
                rotate1 = invoke(mws, 'Rotate');

                % Resetting the Rotate settings
                invoke(rotate1, 'Reset');

                % Setting properties for the Rotate operation
                invoke(rotate1, 'Name', 'Lens_Base1');
                invoke(rotate1, 'Component', 'component1');
                invoke(rotate1, 'Material', 'lens_dielectric_matlab'); 
                invoke(rotate1, 'Mode', 'Pointlist');
                invoke(rotate1, 'StartAngle', '0.0');
                invoke(rotate1, 'Angle', '360');
                invoke(rotate1, 'Height', '0.0');
                invoke(rotate1, 'RadiusRatio', '1.0');
                invoke(rotate1, 'NSteps', '0');
                invoke(rotate1, 'SplitClosedEdges', 'True');
                invoke(rotate1, 'SegmentedProfile', 'False');
                invoke(rotate1, 'SimplifySolid', 'False');
                invoke(rotate1, 'UseAdvancedSegmentedRotation', 'True');
                invoke(rotate1, 'CutEndOff', 'False');
                invoke(rotate1, 'Origin', '0.0', '0.0', '0.0');
                invoke(rotate1, 'Rvector', '0.0', '0.0', '1.0');
                invoke(rotate1, 'Zvector', '0.0', '1.0', '0.0');
                invoke(rotate1, 'Point', num2str(z_dist), num2str(y_dist));
                invoke(rotate1, 'LineTo', num2str(z_dist - 1), num2str(y_dist));
                invoke(rotate1, 'LineTo', num2str(z_dist - 1), num2str(y_dist - 1));
                invoke(rotate1, 'LineTo', num2str(z_dist), num2str(y_dist - 1));

                % Creating the rotated shape
                invoke(rotate1, 'Create');

                % mirroring a single loop
                brick_mirror = invoke(mws, 'Transform');
                invoke(brick_mirror, 'Reset');
                invoke(brick_mirror, 'Name', 'component1:Lens_Base1');
                invoke(brick_mirror, 'Origin', 'Free');
                invoke(brick_mirror, 'Center', '0', '0', '0'); 

                mirror_height = y_dist;

                invoke(brick_mirror, 'PlaneNormal', '0', mirror_height, '0');

                invoke(brick_mirror, 'MultipleObjects', 'True'); 
                invoke(brick_mirror, 'GroupObjects', 'False');
                invoke(brick_mirror, 'Repetitions', '1');
                invoke(brick_mirror, 'MultipleSelection', 'False');
                invoke(brick_mirror, 'Destination', '');
                invoke(brick_mirror, 'Material', 'lens_dielectric_matlab');
                invoke(brick_mirror, 'Transform', 'Shape', 'Mirror');

            end
        end
    end
    % remove any duplicate surfaces in open_surfaces
    % Initialize a new array to keep track of surfaces to be removed
    to_remove = false(size(open_surfaces, 1), 1);

    % Loop through each surface in the open_surfaces array
    for i = 1:size(open_surfaces, 1)
        for j = i + 1:size(open_surfaces, 1)
            % Retrieve and sort the [z, y] pairs from each surface
            % Make sure to sort each pair internally first
            surface1 = open_surfaces{i}(1:2);
            surface2 = open_surfaces{j}(1:2);

            % Sort the coordinates to ignore direction ([z,y] vs. [y,z])
            sorted_surface1 = sort([surface1{1}(1), surface1{2}(1); surface1{1}(2), surface1{2}(2)], 2);
            sorted_surface2 = sort([surface2{1}(1), surface2{2}(1); surface2{1}(2), surface2{2}(2)], 2);

            % Flatten the arrays for direct comparison
            sorted_surface1 = sorted_surface1(:)';
            sorted_surface2 = sorted_surface2(:)';

            % Compare the sorted and flattened pairs
            if isequal(sorted_surface1, sorted_surface2)
                to_remove([i j]) = true;  % Mark both surfaces for removal
%                 % Optionally display removed surface
%                 disp(['Removed surface: ', mat2str(sorted_surface1)]);
            end
        end
    end

    % Remove the marked surfaces from open_surfaces
    open_surfaces(to_remove) = [];
    
    never_removed_surfaces = open_surfaces; % for debugging

    % initialize removed boundary surfaces so they can be added to the
    % open_surfaces later to have a complete description of the lens geometry
    removed_boundary_surfaces = []; %open_surfaces;

    % randomly selecting lens size within the range of 0 to Max_loops
    lens_size = randi([(squares+1),max_loops]);

    disp('lens size: ')
    disp(lens_size)
    % Initialize a boolean variable to track orientation
    vertical = false;
    horizontal = false;

    % random selection interval between 1 and lens_size
    random_interval_max = randi([1, (lens_size)]);
    random_interval_up = randi([1, (random_interval_max)]);
    random_interval_down = randi([1, (random_interval_max)]);
    random_interval_left = randi([1, (random_interval_max)]);
    random_interval_right = randi([1, (random_interval_max)]);

    % Set the flags for each heuristic function before the loop
    % Each flag has a 50% chance to be true (1) or false (0)
    use_smallest_z_heuristic = rand() > 0.5;
    use_smallest_y_heuristic = 0; %rand() > 0.5; currently off
    use_largest_z_heuristic = rand() > 0.5;
    use_largest_y_heuristic = 0; %rand() > 0.5;  currently off
    
    % create a for loop with range of 0 to lens_size
    for i = 1:(lens_size - squares)
         if size(open_surfaces,1) == 0
            break
         end         
        % randomly select an open surface from the open_surfaces list
        random_index = randi(size(open_surfaces, 1));
        selected_surface = squeeze(open_surfaces(random_index, :, :));
        
        %%%% SELECTION HEURISTICS
        % Apply heuristics based on their respective flags
        if use_smallest_z_heuristic
            selected_surface = smallest_z_heuristic(i, open_surfaces, random_interval_right, selected_surface);
        end
        if use_smallest_y_heuristic
            selected_surface = smallest_y_heuristic(i, open_surfaces, random_interval_down, selected_surface);
        end
        if use_largest_z_heuristic
            selected_surface = largest_z_heuristic(i, open_surfaces, random_interval_left, selected_surface);
        end
        if use_largest_y_heuristic
            selected_surface = largest_y_heuristic(i, open_surfaces, random_interval_up, selected_surface);
        end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Determine if it is a vertical or horizontal surface
        if selected_surface{1}{1}(1) == selected_surface{1}{2}(1)
    %         disp('Vertical Surface:');
    %         disp(selected_surface);
            vertical = true;
            horizontal = false;
        else
    %         disp('Horizontal Surface:');
    %         disp(selected_surface);
            vertical = false;
            horizontal = true;
        end

        % Determine height boundary based on the surface that is selected
        if (horizontal == true) && (selected_surface{1}{3}(1) == 0)
            horizontal_top_boundary_left = floor((selected_surface{1}{1}(1) - lens_base_inside_boundary) * tan(deg2rad(cone_angle))) + inside_height_boundary;
            horizontal_top_boundary_right = floor((selected_surface{1}{2}(1) - lens_base_inside_boundary) * tan(deg2rad(cone_angle))) + inside_height_boundary;
        end
        if (vertical == true) && (selected_surface{1}{3}(2) == 1)
            vertical_top_boundary = floor((selected_surface{1}{1}(1) - 1 - lens_base_inside_boundary) * tan(deg2rad(cone_angle))) + inside_height_boundary;
        end    
        % creating a single loop
        % Accessing the Rotate object
        rotate = invoke(mws, 'Rotate');

        % Resetting the Rotate settings
        invoke(rotate, 'Reset');

        % Setting properties for the Rotate operation
        invoke(rotate, 'Name', 'loop1');
        invoke(rotate, 'Component', 'component1');
        invoke(rotate, 'Material', 'lens_dielectric_matlab'); 
        invoke(rotate, 'Mode', 'Pointlist');
        invoke(rotate, 'StartAngle', '0.0');
        invoke(rotate, 'Angle', '360');
        invoke(rotate, 'Height', '0.0');
        invoke(rotate, 'RadiusRatio', '1.0');
        invoke(rotate, 'NSteps', '0');
        invoke(rotate, 'SplitClosedEdges', 'True');
        invoke(rotate, 'SegmentedProfile', 'False');
        invoke(rotate, 'SimplifySolid', 'False');
        invoke(rotate, 'UseAdvancedSegmentedRotation', 'True');
        invoke(rotate, 'CutEndOff', 'False');
        invoke(rotate, 'Origin', '0.0', '0.0', '0.0');
        invoke(rotate, 'Rvector', '0.0', '0.0', '1.0');
        invoke(rotate, 'Zvector', '0.0', '1.0', '0.0');

        % Adding points for the rotation path
        if horizontal == true
            if selected_surface{1}{3}(1) == 0
                invoke(rotate, 'Point', num2str(selected_surface{1}{1}(1)), num2str(selected_surface{1}{1}(2)));
                invoke(rotate, 'LineTo', num2str(selected_surface{1}{2}(1)), num2str(selected_surface{1}{2}(2)));
                invoke(rotate, 'LineTo', num2str((selected_surface{1}{2}(1))), num2str(selected_surface{1}{2}(2) + 1));
                invoke(rotate, 'LineTo', num2str((selected_surface{1}{1}(1))), num2str(selected_surface{1}{1}(2) + 1));
                if (selected_surface{1}{2}(2) + 1) > horizontal_top_boundary_right
                    if ((selected_surface{1}{1}(2) + 1) > horizontal_top_boundary_left) || (selected_surface{1}{1}(1) == outside_boundary)
                        new_surfaces = {...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [1, 2]}};
                        other_surfaces = {...
                            {[selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) + 1)], [2, 1]}; ...
                            {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) + 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) + 1)],  [0, 2]}; ...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) + 1)],  [2, 0]}};

                        removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];
                    else
                        new_surfaces = {...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [1, 2]}; ...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) + 1)],  [2, 0]}};
                        other_surfaces = {...
                            {[selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) + 1)], [2, 1]}; ...
                            {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) + 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) + 1)],  [0, 2]}}; 

                        removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];
                    end
                elseif selected_surface{1}{1}(1) == outside_boundary
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [1, 2]}; ...
                        {[selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) + 1)], [2, 1]}; ...
                        {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) + 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) + 1)],  [0, 2]}}; 
                    other_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) + 1)],  [2, 0]}};

                    removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];
                elseif selected_surface{1}{2}(1) == lens_base_inside_boundary
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [1, 2]}; ...
                        {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) + 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) + 1)],  [0, 2]}; ...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) + 1)],  [2, 0]}}; 

                    other_surfaces = {...
                        {[selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) + 1)], [2, 1]}};

                    removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];

                else
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [1, 2]}; ...
                        {[selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) + 1)], [2, 1]}; ...
                        {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) + 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) + 1)],  [0, 2]}; ...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) + 1)],  [2, 0]}};

                end
    %         disp('up')
            else
                invoke(rotate, 'Point', num2str(selected_surface{1}{1}(1)), num2str(selected_surface{1}{1}(2)));
                invoke(rotate, 'LineTo', num2str(selected_surface{1}{2}(1)), num2str(selected_surface{1}{2}(2)));
                invoke(rotate, 'LineTo', num2str((selected_surface{1}{2}(1))), num2str(selected_surface{1}{2}(2) - 1));
                invoke(rotate, 'LineTo', num2str((selected_surface{1}{1}(1))), num2str(selected_surface{1}{1}(2) - 1));
                if (selected_surface{1}{2}(2) - 1) == 0 && (selected_surface{1}{1}(2) - 1) == 0
                    if selected_surface{1}{1}(1) == outside_boundary
                        new_surfaces = {...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [0, 2]}; ...
                            {[((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)],  [2, 1]}};
                        other_surfaces = {...
                            {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [1, 2]}; ...
                            {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [2, 0]}};

                        removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];
                    elseif selected_surface{1}{2}(1) == lens_base_inside_boundary
                        new_surfaces = {...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [0, 2]}; ...
                            {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [2, 0]}};
                        other_surfaces = {...
                            {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [1, 2]}; ...
                            {[((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)],  [2, 1]}};  

                        removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];
                        
                    else
                        new_surfaces = {...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [0, 2]}; ...
                            {[((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)],  [2, 1]};  ...
                            {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [2, 0]}};
                        other_surfaces = {...
                            {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [1, 2]}}; 

                        removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];

                    end
                elseif selected_surface{1}{1}(1) == outside_boundary
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [0, 2]}; ...
                        {[((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)],  [2, 1]};  ...
                        {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [1, 2]}};
                    other_surfaces = {...
                        {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [2, 0]}};

                    removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];

                elseif selected_surface{1}{2}(1) == lens_base_inside_boundary
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [0, 2]}; ...
                        {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [1, 2]}; ...
                        {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [2, 0]}};
                    other_surfaces = {...
                        {[((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)],  [2, 1]}}; 

                    removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];

                else    
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [0, 2]}; ...
                        {[((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)],  [2, 1]};  ...
                        {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [((selected_surface{1}{2}(1))), (selected_surface{1}{2}(2) - 1)], [1, 2]}; ...
                        {[((selected_surface{1}{1}(1))), (selected_surface{1}{1}(2) - 1)], [selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [2, 0]}};
                end
    %             disp('down')
            end
        end
        if vertical == true
            if selected_surface{1}{3}(2) == 0
                invoke(rotate, 'Point', num2str(selected_surface{1}{1}(1)), num2str(selected_surface{1}{1}(2)));
                invoke(rotate, 'LineTo', num2str(selected_surface{1}{2}(1)), num2str(selected_surface{1}{2}(2)));
                invoke(rotate, 'LineTo', num2str(selected_surface{1}{2}(1) + 1), num2str((selected_surface{1}{2}(2))));
                invoke(rotate, 'LineTo', num2str(selected_surface{1}{1}(1) + 1), num2str((selected_surface{1}{1}(2))));
                if selected_surface{1}{1}(2) == 0
                    if (selected_surface{1}{1}(1) + 1) == outside_boundary
                        new_surfaces = {...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [2, 1]}; ...
                            {[(selected_surface{1}{2}(1) + 1), ((selected_surface{1}{2}(2)))], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [0, 2]}};
                        other_surfaces = {...
                            {[(selected_surface{1}{1}(1) + 1), ((selected_surface{1}{1}(2)))], [(selected_surface{1}{2}(1) + 1), ((selected_surface{1}{2}(2)))], [2, 0]}; ...
                            {[(selected_surface{1}{1}(1) + 1), ((selected_surface{1}{1}(2)))], [selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [1, 2]}};

                        removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];

                    else
                        new_surfaces = {...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [2, 1]}; ...
                            {[(selected_surface{1}{2}(1) + 1), ((selected_surface{1}{2}(2)))], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [0, 2]}; ...
                            {[(selected_surface{1}{1}(1) + 1), ((selected_surface{1}{1}(2)))], [(selected_surface{1}{2}(1) + 1), ((selected_surface{1}{2}(2)))], [2, 0]}};
                        other_surfaces = {...
                            {[(selected_surface{1}{1}(1) + 1), ((selected_surface{1}{1}(2)))], [selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [1, 2]}};

                        removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];

                    end
                elseif (selected_surface{1}{1}(1) + 1) == outside_boundary
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [2, 1]}; ...
                        {[(selected_surface{1}{2}(1) + 1), ((selected_surface{1}{2}(2)))], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [0, 2]}; ...
                        {[(selected_surface{1}{1}(1) + 1), ((selected_surface{1}{1}(2)))], [selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [1, 2]}};
                    other_surfaces = {...
                        {[(selected_surface{1}{1}(1) + 1), ((selected_surface{1}{1}(2)))], [(selected_surface{1}{2}(1) + 1), ((selected_surface{1}{2}(2)))], [2, 0]}}; 

                    removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];

                else
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [2, 1]}; ...
                        {[(selected_surface{1}{2}(1) + 1), ((selected_surface{1}{2}(2)))], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [0, 2]}; ...
                        {[(selected_surface{1}{1}(1) + 1), ((selected_surface{1}{1}(2)))], [(selected_surface{1}{2}(1) + 1), ((selected_surface{1}{2}(2)))], [2, 0]}; ...
                        {[(selected_surface{1}{1}(1) + 1), ((selected_surface{1}{1}(2)))], [selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [1, 2]}};

                end
    %             disp('left')
            else
                invoke(rotate, 'Point', num2str(selected_surface{1}{1}(1)), num2str(selected_surface{1}{1}(2)));
                invoke(rotate, 'LineTo', num2str(selected_surface{1}{2}(1)), num2str(selected_surface{1}{2}(2)));
                invoke(rotate, 'LineTo', num2str(selected_surface{1}{2}(1) - 1), num2str((selected_surface{1}{2}(2))));
                invoke(rotate, 'LineTo', num2str(selected_surface{1}{1}(1) - 1), num2str((selected_surface{1}{1}(2))));
                if selected_surface{1}{2}(2) > vertical_top_boundary
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [2, 0]}; ...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [(selected_surface{1}{1}(1) - 1), ((selected_surface{1}{1}(2)))], [1, 2]}};            
                    other_surfaces = {...
                        {[selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [(selected_surface{1}{2}(1) - 1), ((selected_surface{1}{2}(2)))], [0, 2]}; ...
                        {[(selected_surface{1}{1}(1) - 1), ((selected_surface{1}{1}(2)))], [(selected_surface{1}{2}(1) - 1), ((selected_surface{1}{2}(2)))], [2, 1]}}; 

                    removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];

                elseif selected_surface{1}{1}(2) == 0
                    if (selected_surface{1}{1}(1) - 1) == lens_base_inside_boundary
                        new_surfaces = {...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [2, 0]}; ...
                            {[selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [(selected_surface{1}{2}(1) - 1), ((selected_surface{1}{2}(2)))], [0, 2]}}; 
                        other_surfaces = {...
                            {[(selected_surface{1}{1}(1) - 1), ((selected_surface{1}{1}(2)))], [(selected_surface{1}{2}(1) - 1), ((selected_surface{1}{2}(2)))], [2, 1]}; ...                         
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [(selected_surface{1}{1}(1) - 1), ((selected_surface{1}{1}(2)))], [1, 2]}};

                        removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];
                        
                    else    
                        new_surfaces = {...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [2, 0]}; ...
                            {[selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [(selected_surface{1}{2}(1) - 1), ((selected_surface{1}{2}(2)))], [0, 2]}; ...
                            {[(selected_surface{1}{1}(1) - 1), ((selected_surface{1}{1}(2)))], [(selected_surface{1}{2}(1) - 1), ((selected_surface{1}{2}(2)))], [2, 1]}}; 
                        other_surfaces = {...
                            {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [(selected_surface{1}{1}(1) - 1), ((selected_surface{1}{1}(2)))], [1, 2]}};

                        removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];
                    end

                elseif (selected_surface{1}{1}(1) - 1) == lens_base_inside_boundary
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [2, 0]}; ...
                        {[selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [(selected_surface{1}{2}(1) - 1), ((selected_surface{1}{2}(2)))], [0, 2]}; ...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [(selected_surface{1}{1}(1) - 1), ((selected_surface{1}{1}(2)))], [1, 2]}};
                    other_surfaces = {...
                        {[(selected_surface{1}{1}(1) - 1), ((selected_surface{1}{1}(2)))], [(selected_surface{1}{2}(1) - 1), ((selected_surface{1}{2}(2)))], [2, 1]}}; 

                    removed_boundary_surfaces = [removed_boundary_surfaces; other_surfaces];

                else
                    new_surfaces = {...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [2, 0]}; ...
                        {[selected_surface{1}{2}(1), selected_surface{1}{2}(2)], [(selected_surface{1}{2}(1) - 1), ((selected_surface{1}{2}(2)))], [0, 2]}; ...
                        {[(selected_surface{1}{1}(1) - 1), ((selected_surface{1}{1}(2)))], [(selected_surface{1}{2}(1) - 1), ((selected_surface{1}{2}(2)))], [2, 1]}; ...
                        {[selected_surface{1}{1}(1), selected_surface{1}{1}(2)], [(selected_surface{1}{1}(1) - 1), ((selected_surface{1}{1}(2)))], [1, 2]}};            
                end
    %             disp('right')

            end
        end

        % Creating the rotated shape
        invoke(rotate, 'Create');

        % mirroring a single loop
        brick_mirror = invoke(mws, 'Transform');
        invoke(brick_mirror, 'Reset');
        invoke(brick_mirror, 'Name', 'component1:loop1');
        invoke(brick_mirror, 'Origin', 'Free');
        invoke(brick_mirror, 'Center', '0', '0', '0'); 

        if selected_surface{1}{2}(2) >= selected_surface{1}{1}(2)
            mirror_height = selected_surface{1}{2}(2);
        end
        if selected_surface{1}{1}(2) > selected_surface{1}{2}(2)
            mirror_height = selected_surface{1}{1}(2);
        end



        invoke(brick_mirror, 'PlaneNormal', '0', mirror_height, '0');

        invoke(brick_mirror, 'MultipleObjects', 'True'); 
        invoke(brick_mirror, 'GroupObjects', 'False');
        invoke(brick_mirror, 'Repetitions', '1');
        invoke(brick_mirror, 'MultipleSelection', 'False');
        invoke(brick_mirror, 'Destination', '');
        invoke(brick_mirror, 'Material', '');
        invoke(brick_mirror, 'Transform', 'Shape', 'Mirror');

        % merge both loops to the lens base bottom and top
        solid1 = invoke(mws,'solid');
        invoke(solid1, 'Add', 'component1:Lens_Base1', 'component1:loop1');
        invoke(solid1, 'Add', 'component1:Lens_Base1_1', 'component1:loop1_1');

        %%%% debug variable for tracking
        break_point = {...
            {[0, 0], [0, 0], [0, 0]}};
        never_removed_surfaces = [never_removed_surfaces; break_point];
        never_removed_surfaces = [never_removed_surfaces; new_surfaces];
        % remove the surfaces that have been used already
        surfaces_removed_new = [];
        surfaces_removed_open = [];  
        for i = 1:size(new_surfaces, 1)
            new_surface = new_surfaces{i, 1}(1:2);
            for j = size(open_surfaces, 1):-1:1
                open_surface = open_surfaces{j, 1}(1:2);
                % Compare the new surface with the open surface
                if isequal(new_surface{1}, open_surface{1})
                    if isequal(new_surface{2}, open_surface{2})
                        % If found, make lists of indexes that need to be removed
                        % from the open and new surfaces
                        surfaces_removed_new = [surfaces_removed_new,i];
                        surfaces_removed_open = [surfaces_removed_open,j];
                    end
                end
            end
        end
        % Remove matched surfaces from new_surfaces and open_surfaces
        pre_new_surfaces = new_surfaces;
        new_surfaces(surfaces_removed_new, :) = [];
        post_new_surfaces = new_surfaces;
        pre_open_surfaces = open_surfaces;

        open_surfaces(surfaces_removed_open, :) = [];

        post_open_surfaces = open_surfaces;
        open_surfaces = [open_surfaces; new_surfaces];
    end
    all_surfaces = [open_surfaces; removed_boundary_surfaces];
    node_list = mappingV3(all_surfaces, epsilon_value, inside_height_boundary, lens_base_inside_boundary, cone_angle, outside_boundary);
    
    disp(['geometric file size: ', num2str(size(node_list, 2))]);
    simStr = num2str(sim); % Convert sim to string

    % Define the base file path with placeholder for sim value
    basePath = 'E:\ML_Lens(Dowell)\500Mhz_bicone_random_lens_sims\'; % local solid state
    basePath = [basePath, 'Model', simStr, '\'];
    
    % Save simulation file .cst
    mws.invoke('saveas', [basePath, 'Model', simStr, '.cst'], 'false');

    % % frequency domain solver
    % FDSolver = invoke(mws,'FDSolver');
    % invoke(FDSolver,'Start');

    % % time domain solver
    Solver = invoke(mws,'Solver');
    invoke(Solver,'Start'); %initializes simulation
    
    % Save simulation file .cst
    mws.invoke('saveas', [basePath, 'Model', simStr, '.cst'], 'false');
    
    % saving the lens geometry in node_list to txt (nueral net input)
    filename = [basePath, 'geometric_input', simStr, '.txt'];  % Name of the file to save the data
    fileID = fopen(filename, 'w');  % Open the file for writing

    % Iterate over each element in node_list and write it to the file
    for i = 1:length(node_list)
        fprintf(fileID, '%.1f\n', node_list(i));  % Adjust the format as needed
    end

    fclose(fileID);  % Close the file
    % Time domain solver
    Solver = invoke(mws,'Solver');
    invoke(Solver,'Start'); % Initializes simulation

    % Saving the simulation E-field vs. Time
    SelectTreeItem = invoke(mws,'SelectTreeItem',['1D Results\Probes\E-Farfield\Probe Signals\E_Field (Farfield) (Cartesian) (1063.5 0 0)(Y) [1]']);
    ASCIIExport = invoke(mws,'ASCIIExport');
    invoke(ASCIIExport,'Reset');
    invoke(ASCIIExport,'SetVersion','2010');
    invoke(ASCIIExport,'FileName', [basePath, 'efield_vs_time', simStr, '.txt']);
    invoke(ASCIIExport,'Execute');

    % Saving the simulation E-field vs. Frequency
    SelectTreeItem = invoke(mws,'SelectTreeItem',['Tables\1D Results\E_Field (Farfield) (Cartesian) (1063.5 0 0)(Y) (1)_FT']);
    ASCIIExport = invoke(mws,'ASCIIExport');
    invoke(ASCIIExport,'Reset');
    invoke(ASCIIExport,'SetVersion','2010');
    invoke(ASCIIExport,'FileName', [basePath, 'efield_vs_freq', simStr, '.txt']);
    invoke(ASCIIExport,'Execute');

    % Saving the simulation Impedance vs. Frequency
    SelectTreeItem = invoke(mws,'SelectTreeItem',['1D Results\Discrete Ports\Impedances\Port 1 [1]']);
    ASCIIExport = invoke(mws,'ASCIIExport');
    invoke(ASCIIExport,'Reset');
    invoke(ASCIIExport,'SetVersion','2010');
    invoke(ASCIIExport,'FileName', [basePath, 'impedance_vs_freq', simStr, '.txt']);
    invoke(ASCIIExport,'Execute');
    
    % Save any final changes and close the current CST project
    invoke(mws, 'Save');
    invoke(mws, 'Quit');

    % Ensure the CST application object is properly released
    release(cst);
    
    % close CST and associated files
    system('taskkill /IM "CST DESIGN ENVIRONMENT_AMD64.exe" /F');
    system('taskkill /IM "schematic_AMD64.exe" /F');
    system('taskkill /IM "modeler_AMD64.exe" /F');
    % Optional pause to make sure CST has fully closed before continuing
    pause(10);
    
    % Define the destination path for the file and its associated model folder
    destinationFilePath = ['M:\PTERA\Technical Sections\HPM Sources\ASR\ML_Lens(Dowell)\500Mhz_bicone_random_lens_sim_data\Model', simStr, '\'];
    destinationFile = [destinationFilePath, 'Model', simStr, '.cst'];
    
    % % Check if the source file exists before trying to move it
    % if exist([basePath, 'Model', simStr, '.cst'], 'file') == 2
    %     % Create the destination directory if it does not exist
    %     if ~exist(destinationFilePath, 'dir')
    %         mkdir(destinationFilePath);
    %     end
    % 
    %     % Move the CST file
    %     movefile([basePath, 'Model', simStr, '.cst'], destinationFile, 'f');
    %     disp(['CST file moved to: ', destinationFile]);
    % 
    %     % Move the entire folder
    %     movefile([basePath, 'Model', simStr], destinationFilePath, 'f');
    %     disp(['Model folder moved to: ', destinationFilePath]);
    % else
    %     disp('Source CST file does not exist.');
    % end

    % Measure and store the time taken for this iteration
    individual_sim_times(sim - current_sample_number + 1) = toc(iteration_start);
end

% Measure total simulation time
total_simulation_time = toc(total_time_start);

% Display individual simulation times
disp('Time for each simulation:');
disp(individual_sim_times);

% Display total simulation time
fprintf('Total time for all simulations: %.2f seconds\n', total_simulation_time);
% %% history log for debuging
% % Iterate over each cell in the never_removed_surfaces array
% for i = 1:length(never_removed_surfaces)
%     % Extract the 1x3 cell array from the current cell
%     currentSurface = never_removed_surfaces{i};
% 
%     % Print the index of the outer cell
%     fprintf('Surface %d: ', i);
% 
%     % Iterate over each element in the 1x3 cell array
%     for j = 1:length(currentSurface)
%         % Print each value in the 1x3 cell array
%         fprintf('%s ', mat2str(currentSurface{j}));
%     end
% 
%     % Print a new line for better readability
%     fprintf('\n');
% end