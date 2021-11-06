% ------------------------------------------------------------------------
%          UPDATED SHARP-Track: REGISTER Images to Atlas
%
%   This script can use the SliceViewer and AtlasViewer to warp the
%   histology image to the Allen Atlas. The transformation data from this
%   warping is saved in the transformation folder.
%
% ------------------------------------------------------------------------


function Navigate_Atlas_and_Register_Slices(save_folder, annotation_volume_location, structure_tree_location, template_volume_location, plane)
%% Processed File Locations

% directory of histology
processed_images_folder = fullfile(save_folder, 'processed'); 


%% LOAD ATLAS AND SLICE VIEWER FIGURES

% load the reference brain and region annotations
if ~exist('av','var') || ~exist('st','var') || ~exist('tv','var')
    disp('loading reference atlas...')
    av = readNPY(annotation_volume_location);
    st = loadStructureTree(structure_tree_location);
    tv = readNPY(template_volume_location);
end

% select the plane for the viewer
if strcmp(plane,'coronal')
    av_plot = av;
    tv_plot = tv;
elseif strcmp(plane,'sagittal')
    av_plot = permute(av,[3 2 1]);
    tv_plot = permute(tv,[3 2 1]);
elseif strcmp(plane,'transverse')
    av_plot = permute(av,[2 3 1]);
    tv_plot = permute(tv,[2 3 1]);
end

% create Atlas viewer figure
f = figure('Name','Atlas Viewer'); 

% show histology in Slice Viewer
try; figure(slice_figure_browser); title('');
catch; slice_figure_browser = figure('Name','Slice Viewer'); end
reference_size = size(tv_plot);
sliceBrowser(slice_figure_browser, processed_images_folder, f, reference_size);


% % use application in Atlas Transform Viewer
% % use this function if you have a processed_images_folder with appropriately processed .tif histology images
f = AtlasTransformBrowser(f, tv_plot, av_plot, st, slice_figure_browser, processed_images_folder, plane);


% use the simpler version, which does not interface with processed slice images
% just run these two lines instead of the previous 5 lines of code
% 
  %save_location = processed_images_folder;
  %f = allenAtlasBrowser(f, tv, av, st, save_location, plane);
end
