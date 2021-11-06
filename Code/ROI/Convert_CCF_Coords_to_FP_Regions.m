% ----------------------------------------------------------------------------
%
%         Convert Allen CCF indices to Franklin-Paxinos labels
%
%   Based on data from Chon et al. Enhanced and unified anatomical labeling 
%   for a common mouse brain atlas (2020).
%
% ----------------------------------------------------------------------------

function [data_table] = convert_CCF_Coords_to_FP_Regions(image_folder,roi_location,annotation_volume_location,structure_tree_location,CCF_to_FP_location,FP_table_location,chon_image_folder,suppl_File1_labels,plane)
%% Start with coordinates within the Allen CCF mouse brain atlas
% in the form [AP1, DV1, ML1
%              AP2, DV2, ML2] 

% This example is of points along a neuropixels probe track through cortex, SC, PAG

% generate values for pixel-to-coordinate transformation
bregma = allenCCFbregma(); % estimated bregma position in reference data space
atlas_resolution = 0.010; % pixels to mm

Coords = roi_location;
brain_points = [];
brain_points(:,1) = round(-((Coords(:,1)/atlas_resolution)) + bregma(1));
brain_points(:,2) = round((Coords(:,2)/atlas_resolution) + bregma(2));
brain_points(:,3) = round((Coords(:,3)/atlas_resolution) + bregma(3));
               
% directory of reference files
 % from the allen inst (see readme)
 % located in github repo
 % located in github repo
 % located in github repo
 % from chon et al (supplementary data 4, https://www.nature.com/articles/s41467-019-13057-w)


%% load the reference brain annotations
if ~exist('av','var') || ~exist('st','var')
    disp('loading reference atlas...')
    av = readNPY(annotation_volume_location);
    st = loadStructureTree(structure_tree_location);
end
if ~exist('CCFtoFPtable','var') || ~exist('FPtable','var')
    disp('loading CCF-FP lookup tables...')
    CCFtoFPtable = loadCCFtoFP(CCF_to_FP_location);
    FPtable = loadFPtable(FP_table_location);
end

% initialize array of region annotations
annotation_CCF = cell(size(brain_points,1),3);    
annotation_FP = cell(size(brain_points,1),3);  

%% process data

% loop through every point to get ROI locations and region annotations
for point = 1:size(brain_points,1)

    % find the annotation, name, and acronym of the current point from
    % Allen CCF data
    ann = av(brain_points(point,1),brain_points(point,2),brain_points(point,3));
    name = st.safe_name{ann};
    acr = st.acronym{ann};

    annotation_CCF{point,1} = ann;
    annotation_CCF{point,2} = name;
    annotation_CCF{point,3} = acr;

    % find the annotation, name, and acronym of the current ROI pixel
    % using Chon et al data synthesizing CCF and Franklin-Paxinos
    [ann_FP, name_FP, acr_FP] = CCF_to_FP(brain_points(point,1), brain_points(point,2), brain_points(point,3), ...
                                          CCFtoFPtable, FPtable, suppl_File1_labels);

    annotation_FP{point,1} = ann_FP;
    annotation_FP{point,2} = name_FP;
    annotation_FP{point,3} = acr_FP;
    
%     %chon region name
%     roi_location(:,5) = name_FP;
end

% argmin to get nearest slice
[m, idx] = min(abs(brain_points(1,1) - CCFtoFPtable.slice_num));
% get the label image name
curr_label_file = char(CCFtoFPtable.label_file(idx));

% get coordinates relative to bregm\
ap = -(brain_points(:,1)-bregma(1))*atlas_resolution;
dv = (brain_points(:,2)-bregma(2))*atlas_resolution;
ml = (brain_points(:,3)-bregma(3))*atlas_resolution;

% generate table
data_table = table(annotation_CCF(:,2),annotation_CCF(:,3), annotation_FP(:,2),annotation_FP(:,3),...
                        ap,dv,ml, annotation_CCF(:,1), annotation_FP(:,1),...
         'VariableNames', {'CCF_name', 'CCF_abbrv', 'FP_name', 'FP_abbrv', 'AP_location', 'DV_location', 'ML_location', 'CCF_index', 'FP_index'});

% display table
try
    disp(data_table(1:10,3:5))
catch
    disp(data_table(1,3:5))
end




