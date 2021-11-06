% This script uses the transformation data to warp the ROI file,
% registering ROI points to the atlas in the same manner as the image
function Warp_ROI(image_folder)

%get locations of relevant files
processed_folder = fullfile(image_folder,'processed');
transformed_folder = fullfile(processed_folder, 'transformations');
processed_ROI_file_names = dir([processed_folder filesep '*.csv']);
processed_ROI_file_names = natsortfiles({processed_ROI_file_names.name});
transformed_data_file_names = dir([transformed_folder filesep '*.mat']);
transformed_data_file_names = natsortfiles({transformed_data_file_names.name});
image_file_names = dir([image_folder filesep '*.tif']);
image_file_names = natsortfiles({image_file_names.name});
save_name = 'transformed_ROI_';

ud.file_num = 1;
ud.num_files = length(processed_ROI_file_names);
ud.processed_folder = processed_folder;
ud.transformed_folder = transformed_folder;

folder_csvs = fullfile(image_folder,'processed','ROIs');
if ~exist(folder_csvs)
    mkdir(folder_csvs);
end

while(ud.file_num <= ud.num_files)
    load(fullfile(ud.transformed_folder,transformed_data_file_names{ud.file_num}));
    processed_ROI_location = fullfile(ud.processed_folder,processed_ROI_file_names{ud.file_num});
    ROI = readmatrix(processed_ROI_location);
    sz = size(ROI);
    % get locations of ROI points
    [y,x] = find(ROI);
    xy = [x,y];
    geometric_transform = save_transform.transform;
    % perform transform on x,y locations of ROI points
    [tY,tX] = transformPointsForward(geometric_transform,xy(:,1),xy(:,2));
    R = imref2d(sz);
    [tiX,tiY] = worldToIntrinsic(R,tX,tY);
    tiX = round(tiX);
    tiY = round(tiY);
    transformed_ROI = zeros(sz);
    % rebuild ROI matrix with transformed locations of ROI points, ensuring
    % that two or more do not overlap
    for i = 1:length(tiY)
            if transformed_ROI(tiX(i),tiY(i)) == 0
                transformed_ROI(tiX(i),tiY(i)) = 1;
            else
                if transformed_ROI(tiX(i)+1,tiY(i)) == 0
                transformed_ROI(tiX(i)+1,tiY(i)) = 1;
                else
                    transformed_ROI(tiX(i)-1,tiY(i)) = 1;
                end
            end
    end
    save_name_image = [save_name image_file_names{ud.file_num}];
    [pathstr, filename, ext] = fileparts(save_name_image);
    csv_file_name = [filename, '.csv'];
    final_name_csv = fullfile(folder_csvs,csv_file_name);
    writematrix(transformed_ROI,final_name_csv);
    ud.file_num = ud.file_num + 1;
end
