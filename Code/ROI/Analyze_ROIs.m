% ------------------------------------------------------------------------
%        Get ROI reference-space locations and region annotations
% ------------------------------------------------------------------------

function [fig, roi_location, roi_annotation] = Analyze_ROIs(image_folder, file_name, annotation_volume_location, structure_tree_location, plane, allen_atlas, chon_image_folder,CCF_to_FP_location)
%% SET FILE LOCATIONS OF TRANSFORM AND ROIS
% load ROI (image / array of the same size as the reference ie 800 x 1140)
roi_file = fullfile(image_folder,'processed','ROIs',append('transformed_ROI_',file_name,'.csv'));

%file_name = extractBefore(file_name, "_");

% file location of transform and transformed image
transform_location = fullfile(image_folder,'processed\','transformations\',append(file_name,'_processed_transform_data.mat'));
transformed_slice_location = fullfile(image_folder,'processed\','transformations\',append(file_name,'_processed_transformed.tif'));
atlas_overlay_location = fullfile(image_folder,'processed\','transformations\',append(file_name,'_processed_atlas.tif'));

transformed_slice_image = imread(transformed_slice_location);
atlas_overlay_image = imread(atlas_overlay_location);


%% LOAD THE DATA

% load the transformed slice image
transformed_slice_image = imread(transformed_slice_location);

% load the transform from the transform file
transform_data = load(transform_location);
transform_data = transform_data.save_transform;

% get the actual transformation from slice to atlas
slice_to_atlas_transform = transform_data.transform;

% get the position within the atlas data of the transformed slice
slice_num = transform_data.allen_location{1};
slice_angle = transform_data.allen_location{2};

% load the rois
rois = readmatrix(roi_file);

% if the rois come from a transformed roi image of non-contiguous roi
% pixels (e.g. an ROI pixel for each neuron), then run these lines to ensure
% a one-to-one mapping between ROIs in the original and transformed images:
rois = uint8(imregionalmax(rois));

% load the reference brain annotations
if ~exist('av','var') || ~exist('st','var')
    if allen_atlas
        disp('loading reference atlas...');
    end
    av = readNPY(annotation_volume_location);
    st = loadStructureTree(structure_tree_location);
end
if ~exist('CCFtoFPtable','var')
    % disp('loading CCF-FP lookup tables...')
    CCFtoFPtable = loadCCFtoFP(CCF_to_FP_location);
end
% select the plane for the viewer
if strcmp(plane,'coronal')
    av_plot = av;
elseif strcmp(plane,'sagittal')
    av_plot = permute(av,[3 2 1]);
elseif strcmp(plane,'transverse')
    av_plot = permute(av,[2 3 1]);
end

av_size = size(av_plot);

%% GET REFERENCE-SPACE LOCATIONS AND REGION ANNOTATIONS FOR EACH ROI

% I will do this for every *pixel* in the roi image with nonzero value, 
% but this code can be modified, e.g. to do it by clusters of pixels

[row, col] = size(rois);
if row > av_size(1,2)
    rois(end,:) = [];
    [row, col] = size(rois);
end
if col > av_size(1,3)
    rois(:,end) = [];
    [row, col] = size(rois);
end
if row < av_size(1,2) || col < av_size(1,2)
    rois = zeros(size(transformed_slice_image(:,:,1)), 'like', rois);
end


% make sure the rois are in a properly size image
assert(size(rois,1)==av_size(1,2)&size(rois,2)==av_size(1,3)&size(rois,3)==1,'roi image is not the right size');


% If the user is analyzing the section with the Allen CCF data
if allen_atlas
    ROI_figure = figure(); imshow(atlas_overlay_image);
    title('Allen Atlas borders overlayed on registered image, fused with ROI points');
end

% The user is analyzing section with Chon et al. (2020) data for updated
% allen CCF brain regions
if ~allen_atlas
    apBrainPoint = slice_num;
    % argmin to get nearest slice
    [m, idx] = min(abs(apBrainPoint - CCFtoFPtable.slice_num));
    % get the label image name
    curr_label_file = char(CCFtoFPtable.label_file(idx));
    if strcmp(plane,'coronal')
    % display fused section image with chon regions
        chon_image_file_names = dir([chon_image_folder filesep '*.tif']);
        chon_image_file_names = natsortfiles({chon_image_file_names.name});
        numFiles = length(chon_image_file_names);
        for(i=1:numFiles)
            if contains(chon_image_file_names(i),curr_label_file)
                chon_section = chon_image_file_names(i);
            end
        end
        chon_path = string(fullfile(chon_image_folder,chon_section));
        chon_border_image = imread(chon_path);
        chon_border_image = chon_border_image(:,:,1:3);
        original_image_size = size(chon_border_image);
        ud.chon_border_image = imresize(chon_border_image, [round(original_image_size(1)/4.167)  NaN]);
        ROI_figure = figure(); imshow(ud.chon_border_image); hold on;
        title('Chon et al updated borders, fused with ROI points');
    else
        fprintf('Overlay image with Chon atlas only available for coronal sections');
    end
end 

ud.totalROIs = nnz(rois);
ud.ROIstruct = struct();
[rows,cols] = find(rois);
X = cols;
Y = rows;

for numROI = 1:ud.totalROIs
    ROIpoint = drawpoint('Position',[X(numROI),Y(numROI)],'MarkerSize',3,'Color',[0,1,0]);
    ud.ROIstruct(numROI).roi = ROIpoint;
end
    
fprintf('\nDrag ROI points to move cells to new region(s) if necessary for registration \n');
fprintf('Press "a" with figure active to add new ROIs with mouse point and click \n');
fprintf('Press "m" to draw polygon around ROI points to move them as a group \n');
fprintf('Press "b" to show overlay of borders over ROI points for better clarity \n');
fprintf('Right click to delete points or polygons \n');
fprintf('Press "enter" key in command window when complete \n');

set(ROI_figure, 'UserData', ud);

set(ROI_figure, 'KeyPressFcn', @(ROI_figure,keydata)ROIHotKeyFcn(ROI_figure,keydata));

function ROIHotKeyFcn(ROI_figure,keydata)
    ud = get(ROI_figure, 'UserData');
    if strcmp(lower(keydata.Key),'a') %turn on ability to add new ROI points with mouse click
        addROIpoint = drawpoint('MarkerSize',3,'Color',[0,1,0]);
        ud.totalROIs = ud.totalROIs + 1;
        ud.ROIstruct(ud.totalROIs).roi = addROIpoint;
    elseif strcmp(lower(keydata.Key),'m') %create ROI polygon which can move groups of ROI points
        ROIpoly = drawpolygon;
        addlistener(ROIpoly,'MovingROI',@allevents);
    elseif strcmp(lower(keydata.Key),'b') %visualize boundaries over rois
        xROI = [];
        yROI = [];
        for ROInum = 1:ud.totalROIs
            ud.ROIstruct(ROInum).roi.Visible = 'off';
            xROI(ROInum) = ud.ROIstruct(ROInum).roi.Position(1,1);
            yROI(ROInum) = ud.ROIstruct(ROInum).roi.Position(1,2);
        end
        I = rgb2gray(ud.chon_border_image);
        BW = edge(I);
        B = bwboundaries(BW,4);
        plot(xROI,yROI,'g*','MarkerSize',3);
        for k=1:length(B)
            boundary = B{k};
            plot(boundary(:,2),boundary(:,1),'k','LineWidth',0.3);
        end
    elseif strcmp(lower(keydata.Key),'r') %return to modify rois
        h = findobj('Color','g');
        delete(h);
        k = findobj('Color','k');
        delete(k);
        for ROInum = 1:ud.totalROIs
            ud.ROIstruct(ROInum).roi.Visible = 'on';
        end
    end
    set(ROI_figure,'UserData',ud);
end

function allevents(src,evt)
    changeX = evt.CurrentPosition(1,1) - evt.PreviousPosition(1,1);
    changeY = evt.CurrentPosition(1,2) - evt.PreviousPosition(1,2);
    for numROI = 1:ud.totalROIs
        try
            position = round(ud.ROIstruct(numROI).roi.Position);
            if inROI(src,position(1,1),position(1,2))
                ud.ROIstruct(numROI).roi.Position(1,1) = ud.ROIstruct(numROI).roi.Position(1,1) + changeX;
                ud.ROIstruct(numROI).roi.Position(1,2) = ud.ROIstruct(numROI).roi.Position(1,2) + changeY;
            end
        end
    end
end

input('');

rois(:,:) = 0;
for numROI = 1:ud.totalROIs
  try 
    position = round(ud.ROIstruct(numROI).roi.Position);
    if rois(position(1,2),position(1,1)) == 0
        rois(position(1,2),position(1,1)) = 1;
    elseif rois(position(1,2)+1,position(1,1)) == 0
        rois(position(1,2)+1,position(1,1)) = 1;
    elseif rois(position(1,2)-1,position(1,1)) == 0
        rois(position(1,2)-1,position(1,1)) = 1;
    end
  end
end

% h = findobj('Color','g');
% delete(h);
% k = findobj('Color','k');
% delete(k);
% xROI = [];
% yROI = [];
% for ROInum = 1:ud.totalROIs
%     ud.ROIstruct(ROInum).roi.Visible = 'off';
%     xROI(ROInum) = ud.ROIstruct(ROInum).roi.Position(1,1);
%     yROI(ROInum) = ud.ROIstruct(ROInum).roi.Position(1,2);
% end
% image = ud.chon_border_image;
% imshow(image);
% I = im2bw(image);
% imshow(I);
% visboundaries(I);
% BW = edge(I);
% imshow(BW);
% B = bwboundaries(BW,4);
% plot(xROI,yROI,'g*','MarkerSize',3);
% for k=1:length(B)
%     boundary = B{k};
%     plot(boundary(:,2),boundary(:,1),'k','LineWidth',0.3);
% end
% k = findobj('Color','k');
% xB = get(k,'XData');
% for j=1:length(xB)
%     xB{j} = rot90(xB{j});
% end
% xboundary = vertcat(xB{:});
% yB = get(k,'YData');
% for j=1:length(xB)
%     yB{j} = rot90(yB{j});
% end
% yboundary = vertcat(yB{:});

% initialize array of locations (AP, DV, ML relative to bregma) in reference space
% and the correponding region annotations
roi_location = zeros(sum(rois(:)>0),3);
roi_annotation = cell(sum(rois(:)>0),3);

% get location and annotation for every roi pixel
[pixels_row, pixels_column] = find(rois>0);

% generate other necessary values
bregma = allenCCFbregma(); % bregma position in reference data space

atlas_resolution = 0.010; % mm
ref_size = size(squeeze(av_plot(1,:,:)));
offset_map = get_offset_map(slice_angle, ref_size);

% prevName = "";

% loop through every pixel to get ROI locations and region annotations
for pixel = 1:length(pixels_row)
    
    % get the offset from the AP value at the centre of the slice, due to
    % off-from-coronal angling
    offset = offset_map(pixels_row(pixel),pixels_column(pixel));
    
    % use this and the slice number to get the AP, DV, and ML coordinates
    if strcmp(plane,'coronal')
        ap = -(slice_num-bregma(1)+offset)*atlas_resolution;
        dv = (pixels_row(pixel)-bregma(2))*atlas_resolution;
        ml = (pixels_column(pixel)-bregma(3))*atlas_resolution;
    elseif strcmp(plane,'sagittal')
        ml = -(slice_num-bregma(3)+offset)*atlas_resolution;
        dv = (pixels_row(pixel)-bregma(2))*atlas_resolution;
        ap = -(pixels_column(pixel)-bregma(1))*atlas_resolution;
    elseif strcmp(plane,'transverse')
        dv = (slice_num-bregma(2)+offset)*atlas_resolution;
        ml = (pixels_row(pixel)-bregma(3))*atlas_resolution;
        ap = -(pixels_column(pixel)-bregma(1))*atlas_resolution;
    end
    


    roi_location(pixel,:) = [ap dv ml];
    
    % finally, find the annotation, name, and acronym of the current ROI pixel
    ann = av_plot(slice_num+offset,pixels_row(pixel),pixels_column(pixel));
    name = st.safe_name{ann};
    acr = st.acronym{ann};
    
    roi_annotation{pixel,1} = ann;
    roi_annotation{pixel,2} = name;
    roi_annotation{pixel,3} = acr;
    
%     if name ~= prevName
%         in_region_location = [pixels_row(pixel), pixels_column(pixel)];
%         %index = dsearchn([yboundary,xboundary],in_region_location);
%         region_boundary = bwtraceboundary(BW,in_region_location,'W');
%     end
%     hold on
%     plot(region_boundary(:,2),region_boundary(:,1),'b','LineWidth',2);
end

% allen region name
%roi_location(:,4) = roi_annotation(:,2);

 roi_table = table(roi_annotation(:,2),roi_annotation(:,3), ...
                    roi_location(:,1),roi_location(:,2),roi_location(:,3), roi_annotation(:,1), ...
     'VariableNames', {'name', 'acronym', 'AP_location', 'DV_location', 'ML_location', 'avIndex'});
 
 fig = [];
 % If the user is analyzing the section with the Allen CCF data
 if allen_atlas
    try
        disp(roi_table(1:10,1:3))
    catch
        disp(roi_table(1,1:3))
    end
 end
 fig = gcf;
 
folder_brain_points = fullfile(image_folder,'processed','ROIs','Brain_Points');
if ~exist(folder_brain_points)
    mkdir(folder_brain_points)
end
 writematrix(roi_location,fullfile(folder_brain_points,append('brain_points_',file_name,'.csv')));
 
% now, use roi_locations and roi_annotations for your further analyses
end




