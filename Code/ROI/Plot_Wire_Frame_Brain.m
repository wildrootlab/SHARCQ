function Plot_Wire_Frame_Brain(image_folder)

brain_points_location = fullfile(image_folder,'processed','ROIs','Brain_Points');
files = dir([brain_points_location filesep '*.csv']);
file_names = natsortfiles({files.name});

bregma = allenCCFbregma();
atlas_resolution = 0.010;

% should the brain image be dark or light
black_brain = true;
brain_points_color = [0 1 1];

% plot points on the wire frame brain
fwireframe = plotBrainGrid([], [], [], black_brain); hold on; 
fwireframe.InvertHardcopy = 'off';
figure(fwireframe); hold on

for i=1:length(file_names)
    current_section = fullfile(image_folder,'processed','ROIs','Brain_Points',file_names{i});
    coords = readmatrix(current_section);
    brain_points = [];
    brain_points(:,1) = round(-((coords(:,1)/atlas_resolution)) + bregma(1));
    brain_points(:,2) = round((coords(:,2)/atlas_resolution) + bregma(2));
    brain_points(:,3) = round((coords(:,3)/atlas_resolution) + bregma(3));
    
    plot3(brain_points(:,1), brain_points(:,3), brain_points(:,2), '.','linewidth',2, 'color',brain_points_color,'markers',3);
    hold on;
end

brain_points_location = fullfile(image_folder,'processed','rabies ROIs','Brain_Points');
if exist(brain_points_location, 'dir')
    files = dir([brain_points_location filesep '*.csv']);
    file_names = natsortfiles({files.name});
    
    for i=1:length(file_names)
        current_section = fullfile(image_folder,'processed','rabies ROIs','Brain_Points',file_names{i});
        coords = readmatrix(current_section);
        brain_points = [];
        brain_points(:,1) = round(-((coords(:,1)/atlas_resolution)) + bregma(1));
        brain_points(:,2) = round((coords(:,2)/atlas_resolution) + bregma(2));
        brain_points(:,3) = round((coords(:,3)/atlas_resolution) + bregma(3));
    
        plot3(brain_points(:,1), brain_points(:,3), brain_points(:,2), '.','linewidth',2, 'color',[1,0,0],'markers',3);
        hold on;
    end

end
