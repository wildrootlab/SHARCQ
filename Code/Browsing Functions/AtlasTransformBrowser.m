function f = AtlasTransformBrowser(f, templateVolume, annotationVolume, structureTree, slice_figure, save_location, plane)
% ------------------------------------------------
% Browser for the allen atlas ccf data in matlab.
% ------------------------------------------------
%
% Inputs templateVolume, annotationVolume, and structureTree are the data describing the atlas.
% The annotation volume should be the "by_index" version
%

% print instructions
display_controls

% create figure and adjust to user's screen size
% f = figure('Name','Atlas Viewer'); 
figure(f);
try; screen_size = get(0,'ScreenSize'); screen_size = [max(screen_size(3:4)) min(screen_size(3:4))]./[2560 1440];
catch; screen_size = [1900 1080]./[2560 1440];
end 
set(f,'Position', [1050*screen_size(1) 660*screen_size(2) 880*screen_size(1) 650*screen_size(2)])
movegui(f,'onscreen')

% initialize user data variables held by the figure
ud.plane = plane;
ud.bregma = allenCCFbregma; 
ud.currentSlice = ud.bregma(1); 
ud.currentAngle = zeros(2,1);
ud.scrollMode = 0;

ud.transform_type = 'projective'; %can change to 'affine' or 'pwl'

ud.oldContour = [];
ud.showContour = false;
ud.showOverlay = false; ud.overlayAx = [];
ud.pointList = cell(1,3); ud.pointList{1} = zeros(0,3); 
ud.pointHands = cell(1,3);
ud.pointText = [];
ud.pointnum = 0;
ud.getPoint_for_transform =false; ud.pointList_for_transform = zeros(0,2); ud.pointHands_for_transform = [];
ud.current_pointList_for_transform = zeros(0,2); ud.curr_slice_num = 1;
ud.clicked = false;
ud.showAtlas = false;
ud.nextAtlas = false;
ud.previousAtlas = false;
ud.viewColorAtlas = false;
ud.histology_overlay = 0; 
ud.atlasAx = axes('Position', [0.05 0.05 0.9 0.9]);
ud.transform = [];
ud.transformed_slice_figure = [];
ud.slice_shift = 0;
ud.loaded_slice = 0;
ud.slice_at_shift_start = 1;
ud.text = [];

reference_image = squeeze(templateVolume(ud.currentSlice,:,:));
ud.im = plotTVslice(reference_image);
ud.ref_size = size(reference_image);
ud.ref = uint8(squeeze(templateVolume(ud.currentSlice,:,:)));
ud.curr_im = uint8(squeeze(templateVolume(ud.currentSlice,:,:)));
ud.curr_slice_trans = uint8(squeeze(templateVolume(ud.currentSlice,:,:)));
ud.im_annotation = squeeze(annotationVolume(ud.currentSlice,:,:));
ud.atlas_boundaries = zeros(ud.ref_size,'uint16');
ud.offset_map = zeros(ud.ref_size);
ud.loaded = 0;

% create functions needed to interact with the figure
set(ud.im, 'ButtonDownFcn', @(f,k)atlasClickCallback(f, k, slice_figure));
ud.bregmaText = annotation('textbox', [0 0.95 0.4 0.05], ...
    'String', '[coords]', 'EdgeColor', 'none', 'Color', 'k');

ud.angleText = annotation('textbox', [.7 0.95 0.4 0.05], ...
    'EdgeColor', 'none', 'Color', 'k');

allData.tv = templateVolume;
allData.av = annotationVolume;
allData.st = structureTree;
hold(ud.atlasAx, 'on');
set(ud.atlasAx, 'HitTest', 'off');
set(f, 'UserData', ud);
set(f, 'KeyPressFcn', @(f,k)hotkeyFcn(f, slice_figure, k, allData, save_location));
set(f, 'WindowScrollWheelFcn', @(src,evt)updateSlice(f, evt, allData, slice_figure, save_location));
set(f, 'WindowButtonMotionFcn',@(f,k)fh_wbmfcn(f, allData, slice_figure, save_location)); % Set the motion detector.

% display user controls in the console
function display_controls
fprintf(1, '\n Controls: \n');
fprintf(1, '--------- \n');

fprintf(1, 'Navigation: Atlas Viewer \n');
fprintf(1, '1: scroll along A/P axis \n');
fprintf(1, '2: scroll through D/V angles \n');
fprintf(1, '3: scroll through M/L angles \n');
fprintf(1, 'Right arrow: advance to new atlas for next slice registration \n');
fprintf(1, 'Left arrow: return to previous slice registration \n \n');

fprintf(1, 'Navigation: Slice Viewer \n');
fprintf(1, 'right arrow: advance to next slice to register) \n');
fprintf(1, 'left arrow: return to previous slice \n \n');

fprintf(1, 'Registration: Atlas Viewer\n');
fprintf(1, 't: toggle mode for transform point clicking \n');
fprintf(1, 'h: toggle histology registration/transformation (automatically saves)\n');
fprintf(1, 'x: save transform and current atlas location \n');
fprintf(1, 'l: load transform for current slice \n');
fprintf(1, 'd: delete most recent transform point \n \n');

fprintf(1, 'Registration: Slice Viewer\n');
fprintf(1, 't: toggle mode for transform point clicking \n \n');

fprintf(1, 'Viewing modes: \n');
fprintf(1, 'o: toggle overlay of current region extent \n');
fprintf(1, 'a: toggle viewing region boundaries \n');
fprintf(1, 'v: toggle color atlas mode \n');
fprintf(1, 'g: toggle gridlines \n \n');

fprintf(1, 'space: display controls \n \n');

% ------------------------
% react to keyboard press
% ------------------------
function hotkeyFcn(f, slice_figure, keydata, allData, save_location)

% retrieve user data from figure
ud = get(f, 'UserData');
ud_slice = get(slice_figure, 'UserData');


key_letter = lower(keydata.Key);
switch key_letter  
% space -- display controls    
    case 'space'
        display_controls
% o -- toggle showing brain region overlay
    case 'o'
        ud.showOverlay = ~ud.showOverlay;
        if ~ud.showOverlay
            delete(ud.overlayAx); ud.overlayAx = [];
            disp('Overlay OFF');
        elseif ~ud.viewColorAtlas; disp('Overlay on!');
        end
% g -- toggle showing Gridlines    
    case 'g' 
        if ~isfield(ud, 'gridlines') || isempty(ud.gridlines)
            axes(ud.atlasAx); hold on;
            gridY = 100:100:ud.ref_size(1); % assuming the size of the atlas for this for now
            gridX = 70:100:ud.ref_size(2); 
            xl = xlim(); yl = ylim();
            gx = arrayfun(@(x)plot(x*[1 1], yl, 'w'), gridX, 'uni', false);
            gy = arrayfun(@(y)plot(xl, y*[1 1], 'w'), gridY, 'uni', false);
            ud.gridlines = [gx gy];
        elseif strcmp(get(ud.gridlines{1}, 'Visible'), 'on')
            cellfun(@(x)set(x, 'Visible', 'off'), ud.gridlines);
        elseif strcmp(get(ud.gridlines{1}, 'Visible'), 'off')
            cellfun(@(x)set(x, 'Visible', 'on'), ud.gridlines);
        end         
% t -- toggle mode to register clicks as Points   
    case 't' 
        ud.getPoint_for_transform = ~ud.getPoint_for_transform;
        ud.loaded = false;
        
        if ud.getPoint_for_transform
            disp('atlas transform point mode ON'); 

            % launch transform point mode
            if ~size(ud.current_pointList_for_transform,1)% ) (ud.curr_slice_num ~= (ud.slice_at_shift_start+ud.slice_shift) ||  && ~ud.loaded 
                ud.curr_slice_num = ud.slice_at_shift_start+ud.slice_shift; %ud_slice.slice_num;
                ud.current_pointList_for_transform = zeros(0,2);
                set(ud.pointHands_for_transform(:), 'Visible', 'off'); 
                num_hist_points = size(ud_slice.pointList,1);
                template_point = 1; template_points_shown = 0;
                updateBoundaries(f,ud, allData); ud = get(f, 'UserData');
            end
        else; disp('atlas transform point mode OFF');    
        end     
% a -- toggle viewing of annotation boundaries  
    case 'a' 
        
        ud.showAtlas = ~ud.showAtlas;
        
        if ud.showAtlas % superimpose boundaries           
            updateBoundaries(f,ud, allData);
        else % return to image
            set(ud.im, 'CData', ud.ref);
            ud.curr_im = ud.ref; set(f, 'UserData', ud); 
            set(ud.im, 'CData', ud.curr_im)
        end
        
% v -- toggle viewing of Color Atlas        
    case 'v' 
        ud.viewColorAtlas = ~ud.viewColorAtlas;
        ud.histology_overlay = 0;
        
        if ud.viewColorAtlas  
            % remove overlay
            ud.showOverlay = 0;
            ref_mode = false;
            delete(ud.overlayAx); ud.overlayAx = [];            
            set(ud.im, 'CData', ud.im_annotation)
            ud.curr_im = ud.im_annotation;
            cmap = allen_ccf_colormap('2017');
            colormap(ud.atlasAx, cmap); caxis(ud.atlasAx, [1 size(cmap,1)]);   
            fill([5 5 250 250],[5 50 50 5],[1 1 1],'edgecolor',[1 1 1]);
        else           
            set(ud.im, 'CData', ud.ref)
            ud.curr_im = ud.ref;
            colormap(ud.atlasAx, 'gray'); caxis(ud.atlasAx, [0 400]);
            fill([5 5 250 250],[5 50 50 5],[0 0 0]);
        end       
        
        if ud.showAtlas % superimpose boundaries           
            updateBoundaries(f,ud, allData);
        end

    case '1' % scroll along A/P axis
        ud.scrollMode = 0;
        if strcmp(ud.plane,'coronal')
            disp('switch scroll mode -- scroll along A/P axis')
        elseif strcmp(ud.plane,'sagittal')
            disp('switch scroll mode -- scroll along M/L axis')
        elseif strcmp(ud.plane,'transverse')
            disp('switch scroll mode -- scroll along D/V axis')
        end
        
    case '2' % scroll angles along M/L axis
        ud.scrollMode = 1;
        if strcmp(ud.plane,'coronal')
            disp('switch scroll mode -- tilt D/V')
        elseif strcmp(ud.plane,'sagittal')
            disp('switch scroll mode -- tilt D/V')
        elseif strcmp(ud.plane,'transverse')
            disp('switch scroll mode -- tilt M/L')
        end
        
    case '3' % scroll angles along A/P axis
        ud.scrollMode = 2;
        if strcmp(ud.plane,'coronal')
            disp('switch scroll mode -- tilt M/L')
        elseif strcmp(ud.plane,'sagittal')
            disp('switch scroll mode -- tilt A/P')
        elseif strcmp(ud.plane,'transverse')
            disp('switch scroll mode -- tilt A/P')
        end
        
    case 'rightarrow' % move to next atlas for new image registration
        update.VerticalScrollCount = 0; 
        temp_scroll_mode = ud.scrollMode; 
        ud.scrollMode = 3;
        ud.nextAtlas = true;
        if ~ud.slice_at_shift_start
            ud.slice_at_shift_start = ud_slice.slice_num;
            ud.slice_shift = 0;
        end
        set(f, 'UserData', ud);
        updateSlice(f, update, allData, slice_figure, save_location); 
        ud = get(f, 'UserData');
        ud.scrollMode = temp_scroll_mode;
        ud.nextAtlas = false;
        set(f, 'UserData', ud);
        
    case 'leftarrow' % return to previous registration
        update.VerticalScrollCount = 0; 
        temp_scroll_mode = ud.scrollMode; 
        ud.scrollMode = 3;
        ud.previousAtlas = true;
        if ~ud.slice_at_shift_start
            ud.slice_at_shift_start = ud_slice.slice_num;
            ud.slice_shift = 0;
        end
        set(f, 'UserData', ud);
        updateSlice(f, update, allData, slice_figure, save_location); 
        ud = get(f, 'UserData');
        ud.scrollMode = temp_scroll_mode;
        ud.previousAtlas = false;
        set(f, 'UserData', ud);

% h -- toggle viewing of histology / histology overlay
    case 'h'
        disp('  ');
        % remove color atlas
        ud.viewColorAtlas = false;
        set(ud.im, 'CData', ud.ref)
        colormap(ud.atlasAx, 'gray'); caxis(ud.atlasAx, [0 400]);
        % remove overlay
        ud.showOverlay = 0;
        ref_mode = false;
        delete(ud.overlayAx); ud.overlayAx = [];
        % toggle which mode is active
        if ~ud.clicked || ~ud.histology_overlay
            ud.histology_overlay = ud.histology_overlay + 1 - 3*(ud.histology_overlay==2);
        end
        ud.clicked = false;
        % get clicked points and slice info from the slice figure
        slice_points = ud_slice.pointList;
        slice_name = ud_slice.processed_image_names{ud.slice_at_shift_start+ud.slice_shift}(1:end-4);
        folder_transformations = [save_location filesep 'transformations' filesep];
        if size(ud.current_pointList_for_transform,1)  && size(slice_points,1) && ud.slice_at_shift_start+ud.slice_shift == ud_slice.slice_num 
            key_letter = 'x'; % save transform automatically
        end
        % if in one of the transformation modes, perform the transform
        if (ud.histology_overlay == 1 || ud.histology_overlay == 2) && ...
                ( (size(ud.current_pointList_for_transform,1) && size(slice_points,1)) || ud.loaded)
            try
                if ud.slice_shift > 0
                    ud.curr_slice_trans = imread([folder_transformations slice_name '_transformed.tif']);
                else
                    set(ud.text,'Visible','off');
                    fill([5 5 250 250],[5 50 50 5],[0 0 0]); ud.text(end+1) = text(5,15,['Slice ' num2str(ud.slice_at_shift_start+ud.slice_shift)],'color','white');            

                    reference_points = ud.current_pointList_for_transform;
                    slice_points = ud_slice.pointList;

                    current_slice_image = flip(get(ud_slice.im, 'CData'),1);
                    
                    % ** this is where the transform happens, using the
                    % clicked points from the reference and histology images
                    if ~ud.loaded  % use loaded version if 'l' was just pressed 
                        ud.transform = fitgeotrans(slice_points,reference_points,ud.transform_type); %can use 'affine', 'projective', 'polynomial', or 'pwl'
                    end
                    R = imref2d(size(ud.ref));
                    ud.curr_slice_trans = imwarp(current_slice_image, ud.transform, 'OutputView',R);
                end
            
                image_blend =  imfuse(uint8(ud.ref*.6), ud.curr_slice_trans(:,:,:),'blend','Scaling','none');
                if ud.histology_overlay == 2 % 2 ~ blend
                    disp('Slice + Reference mode!');
                    set(ud.im, 'CData', image_blend);
                    ud.curr_im = image_blend;
                else % 1 ~ just see slice
                    disp('Slice mode!');
                    set(ud.im, 'CData', ud.curr_slice_trans); 
                    ud.curr_im = ud.curr_slice_trans;
                end
                
            % if wrong number of points clicked
            catch
                ref_mode = true;
                disp(['Unable to transform -- ' num2str(size(ud_slice.pointList,1)) ...
                     ' slice points and ' num2str(size(ud.current_pointList_for_transform,1)) ' reference points']);
                key_letter = 'h'; 
            end
        end
        % if not doing transform, just show reference atlas
        if ud.histology_overlay == 0 || ref_mode
            ud.histology_overlay = 0;
            disp('Reference mode!');
            set(ud.im, 'CData', ud.ref);
            ud.curr_im = ud.ref; set(f, 'UserData', ud);
        end
     
% l -- load transform and current slice position and angle        
    case 'l' 
        slice_name = ud_slice.processed_image_names{ud_slice.slice_num}(1:end-4);
        folder_transformations = fullfile(save_location, ['transformations' filesep]);
        ud.clicked = false;
        try
        if ud.loaded_slice+ud.slice_shift ~= ud_slice.slice_num
            
            ud.curr_slice_num = ud_slice.slice_num;
            
            % remove overlay
            ud.showOverlay = 0;
            delete(ud.overlayAx); ud.overlayAx = [];
            
            % load transform data
            transform_data = load(fullfile(folder_transformations, [slice_name '_transform_data.mat']));  
            transform_data = transform_data.save_transform;

            % load new transform
            ud.transform = transform_data.transform;
           
            if ~isempty(transform_data.transform_points{1}) && ~isempty(transform_data.transform_points{2})
                ud.current_pointList_for_transform = transform_data.transform_points{1};
                ud_slice.pointList = transform_data.transform_points{2};
                set(slice_figure, 'UserData', ud_slice);
            end            
            
            % load allen ref location
            ud.currentSlice = transform_data.allen_location{1}; ud.currentAngle = transform_data.allen_location{2};

            % create transformed histology image
            current_slice_image = flip(get(ud_slice.im, 'CData'),1); R = imref2d(size(ud.ref));
            ud.curr_slice_trans = imwarp(current_slice_image, ud.transform, 'OutputView',R);

            % update figure
            update.VerticalScrollCount = 0; temp_scroll_mode = ud.scrollMode; ud.scrollMode = 4; set(f, 'UserData', ud);
            updateSlice(f, update, allData, slice_figure, save_location); ud = get(f, 'UserData');
            ud.scrollMode = temp_scroll_mode;
            ud.loaded = true;

            ud.slice_at_shift_start = ud_slice.slice_num; ud.slice_shift = 0;
            ud.loaded_slice = ud_slice.slice_num;
            
            if ~isempty(ud.text)
                set(ud.text,'Visible','off');
                fill([5 5 250 250],[5 50 50 5],[0 0 0]); ud.text(end+1) = text(5,15,['Slice ' num2str(ud.slice_at_shift_start+ud.slice_shift)],'color','white');            
            end
            
            disp('transform loaded');
        end
        
        ud.slice_shift = 0;
        catch 
            disp(['loading failed']); 
        end
% d -- delete current transform point          
    case 'd' 
        if ud.getPoint_for_transform
%             ud.current_pointList_for_transform = zeros(0,2); set(ud.pointHands_for_transform(:), 'Visible', 'off'); 
%             ud.pointHands_for_transform = []; ud_slice.pointList = []; set(slice_figure, 'UserData', ud_slice);
%             disp('current transform erased');
            
            % Try to delete only the most recent point
            ud.current_pointList_for_transform = ud.current_pointList_for_transform(1:end-1,:);
            set(slice_figure, 'UserData', ud_slice);
            if ud.pointHands_for_transform
                % remove circle for most recent point
                set(ud.pointHands_for_transform(end), 'Visible', 'off');
                set(ud.pointText(end),'Visible','off');
                ud.pointHands_for_transform = ud.pointHands_for_transform(1:end-1); 
                ud.pointList = ud.pointList(1:end-1,:); 
                ud.pointText = ud.pointText(1:end-1);
                ud.pointnum = ud.pointnum - 1;
                if ud.pointHands_for_transform
                    % recolor points
                    set(ud.pointHands_for_transform(end), 'color', [0 .9 0]);
                end
            end
            
            disp('transform point deleted');
        end
end
% x -- save transform and current slice position and angle
if strcmp(key_letter,'x') 
        
        % find or create folder location for transformations
        try
        folder_transformations = fullfile(save_location, ['transformations' filesep]);
        if ~exist(folder_transformations)
            mkdir(folder_transformations)
        end
    
        % find name of slice
        if ud.slice_shift || ud.slice_at_shift_start ~= ud_slice.slice_num
            slice_name = ud_slice.processed_image_names{(ud.slice_at_shift_start+ud.slice_shift)}(1:end-4);
        else
            slice_name = ud_slice.processed_image_names{ud_slice.slice_num}(1:end-4);
        end
        

        if isempty(ud.current_pointList_for_transform)
            ud.transform = [];
        end
        % store transform, if applicable
        save_transform.transform = ud.transform;
        
        % store transform points
        transform_points = cell(2,1); transform_points{1} = ud.current_pointList_for_transform;
        if ~isempty(ud_slice.pointList)
            transform_points{2} = ud_slice.pointList;
        end
        
        save_transform.transform_points = transform_points;
        % store reference location
        allen_location = cell(2,1); allen_location{1} = ud.currentSlice; allen_location{2} = ud.currentAngle; 
        save_transform.allen_location = allen_location;
        % save all this
        save(fullfile(folder_transformations, [slice_name '_transform_data.mat']), 'save_transform');
        disp('atlas location saved')
        
        % save transformed histology image
        current_slice_image = imread(fullfile(save_location, [slice_name '.tif']));
%         current_slice_image = flip(get(ud_slice.im, 'CData'),1);
        R = imref2d(size(ud.ref));
        curr_slice_trans = imwarp(current_slice_image, ud.transform, 'OutputView',R);
        imwrite(curr_slice_trans, fullfile(folder_transformations, [slice_name '_transformed.tif']))
        
        disp('transform saved')
        catch
            disp('transform not saved')
        end
        
        
        
        ud.showAtlas = true;
        updateBoundaries(f,ud,allData);
                
        % save atlas image with boundaries
        atlas_image = fullfile(save_location, 'transformations',[slice_name '_atlas.tif']);
        img = getimage(f);
        imwrite(img,atlas_image);
end
        
set(f, 'UserData', ud);

% -----------------------------------------
% Update slice (from scrolling or loading)
% -----------------------------------------
function updateSlice(f, evt, allData, slice_figure, save_location)

ud = get(f, 'UserData');


% scroll through slices
if ud.scrollMode==0
    ud.currentSlice = ud.currentSlice+evt.VerticalScrollCount*3;

    if ud.currentSlice>size(allData.tv,1); ud.currentSlice = 1; end %wrap around
    if ud.currentSlice<1; ud.currentSlice = size(allData.tv,1); end %wrap around
    
% scroll through D/V angles        
elseif ud.scrollMode==1 %&&  abs(ud.currentAngle(1)) < 130
  ud.currentAngle(1) = ud.currentAngle(1)+evt.VerticalScrollCount*3;

% scroll through M/L angles
elseif ud.scrollMode==2 %&&  abs(ud.currentAngle(2)) < 130
  ud.currentAngle(2) = ud.currentAngle(2)+evt.VerticalScrollCount*3; 
  
% move through slices
elseif ud.scrollMode == 3
  set(ud.pointHands_for_transform(:), 'Visible', 'off'); 
  set(ud.pointText, 'Visible', 'off');
  ud.pointText = [];
  ud.pointnum = 0;
  ud.showOverlay = 0;
  delete(ud.overlayAx); ud.overlayAx = [];  
  ud_slice = get(slice_figure, 'UserData');
  
%   persistent atlasCount;
%   persistent atlasDecrement;
%   if(isempty(atlasCount))
%       atlasCount = 0;
%   end
%   if(isempty(atlasDecrement))
%       atlasDecrement = 0;
%   end
  if ud.nextAtlas
%     atlasCount = atlasCount + 1;
%     ud.slice_shift = ud.slice_shift + atlasCount - atlasDecrement;
    ud.slice_shift = ud.slice_shift + 1;
    try
        slice_name = ud_slice.processed_image_names{ud.slice_at_shift_start+ud.slice_shift}(1:end-4);
    catch
        slice_name = ud_slice.processed_image_names{1}(1:end-4);
%         atlasCount = 0;
%         atlasDecrement = 0;
        ud.slice_shift = 0;
    end
  elseif ud.previousAtlas
%     atlasDecrement = atlasDecrement + 1;
%     ud.slice_shift = ud.slice_shift + atlasCount - atlasDecrement;
    ud.slice_shift = ud.slice_shift - 1;
    try 
        slice_name = ud_slice.processed_image_names{ud.slice_at_shift_start+ud.slice_shift}(1:end-4);
    catch
        slice_name = ud_slice.processed_image_names{1}(1:end-4);
%         atlasDecrement = 0;
%         atlasCount = 0;
        ud.slice_shift = 0;
    end
  end

  folder_transformations = fullfile(save_location, ['transformations' filesep]);
  
    ud.current_pointList_for_transform = zeros(0,2);
    try load([folder_transformations slice_name '_transform_data.mat']);
       
        ud.clicked = false;
        
        % load transform data
        transform_data = load(fullfile(folder_transformations, [slice_name '_transform_data.mat']));  
        transform_data = transform_data.save_transform;
        
        % load new transform
        ud.transform = transform_data.transform;
        
        if ~isempty(transform_data.transform_points{1}) && ~isempty(transform_data.transform_points{2})
            ud.current_pointList_for_transform = transform_data.transform_points{1};
            ud_slice.pointList = transform_data.transform_points{2};
        else
            ud_slice.pointList = [];           
        end
        set(slice_figure, 'UserData', ud_slice);
        
        % load allen ref location
        ud.currentSlice = transform_data.allen_location{1}; ud.currentAngle = transform_data.allen_location{2};

        % create transformed histology image
        ud.curr_slice_trans = imread([folder_transformations slice_name '_transformed.tif']);
       
        % update figure
        update.VerticalScrollCount = 0; set(f, 'UserData', ud);
        ud.loaded = true;
        
        ud.curr_slice_num = ud.slice_at_shift_start+ud.slice_shift;
        
        ud.histology_overlay = 1;
        
        set(ud.text,'Visible','off');
        fill([5 5 350 350],[5 50 50 5],[0 0 0]); ud.text(end+1) = text(5,15,['Slice ' num2str(ud.slice_at_shift_start+ud.slice_shift)],'color','white');
    catch
        % if no transform, just show reference
        ud.histology_overlay = 0;
        ud.current_pointList_for_transform = zeros(0,2);
        set(ud.im, 'CData', ud.ref);
        ud.curr_im = ud.ref; set(f, 'UserData', ud);   
        set(ud.text,'Visible','off');
        fill([5 5 350 350],[5 50 50 5],[0 0 0]); ud.text(end+1) = text(5,15,['Slice ' num2str(ud.slice_at_shift_start+ud.slice_shift) ' - no transform'],'color','white');        
    end  
        
end  

% update coordinates at the top
pixel = getPixel(ud.atlasAx);
updateStereotaxCoords(ud.currentSlice, pixel, ud.bregma, ud.bregmaText, ud.angleText, ud.currentSlice, ud.currentAngle(1), ud.currentAngle(2), ud.ref_size, ud.plane);
    
% ----------------------------------------
% if no angle, just change reference slice
% ----------------------------------------
if ud.currentAngle(1) == 0 && ud.currentAngle(2) == 0
    
    reference_slice = squeeze(allData.tv(ud.currentSlice,:,:));
    ud.im_annotation = squeeze(allData.av(ud.currentSlice,:,:));    
 
    if ud.viewColorAtlas
        set(ud.im, 'CData', ud.im_annotation);
    else
        set(ud.im, 'CData', reference_slice);
    end 
    
    
   % update title/overlay with brain region
    [name, acr, ann] = getPixelAnnotation(allData, pixel, ud.currentSlice);
    updateTitle(ud.atlasAx, name, acr)
    if ud.showOverlay    
        updateOverlay(f, allData, ann, slice_figure, save_location);
    end  
    ud.ref = uint8(reference_slice);
    set(ud.pointHands_for_transform(:), 'Visible', 'off'); 
    ud.offset_map = zeros(ud.ref_size); 
    set(f, 'UserData', ud);
    
% ---------------------------
% if angle, angle the atlas
% ---------------------------
else 
  
  image_size = size(squeeze(allData.av(ud.currentSlice,:,:)));
  angle_slice = zeros(image_size);
  
  if ud.currentAngle(1)==0; offset_DV = 0;
  else; offset_DV = -ud.currentAngle(1):sign(ud.currentAngle(1)):ud.currentAngle(1);
  end; start_index_DV = 1; 
 
  
  % loop through AP offsets
  num_DV_iters_add_ind = floor( (image_size(1) - floor( image_size(1) / length(offset_DV))*length(offset_DV)) / 2);
  for curr_DV_iter = 1:length(offset_DV)
      cur_offset_DV = offset_DV(curr_DV_iter);
      if cur_offset_DV == ud.currentAngle(1)
          end_index_DV = image_size(1);
      elseif curr_DV_iter <= num_DV_iters_add_ind  || length(offset_DV - curr_DV_iter) < num_DV_iters_add_ind
          end_index_DV = start_index_DV + floor( image_size(1) / length(offset_DV));
      else
          end_index_DV = start_index_DV + floor( image_size(1) / length(offset_DV)) - 1;
      end
      
       if ud.currentAngle(2)==0;  offset_ML = 0;
       else; offset_ML = -ud.currentAngle(2):sign(ud.currentAngle(2)):ud.currentAngle(2);
       end; start_index_ML = 1;
    % nested: loop through ML offsets
  num_ML_iters_add_ind = floor( (image_size(2) - floor( image_size(2) / length(offset_ML))*length(offset_ML)) / 2);
  for curr_ML_iter = 1:length(offset_ML)
      cur_offset_ML = offset_ML(curr_ML_iter);
      if cur_offset_ML == ud.currentAngle(2)
          end_index_ML = image_size(2);
      elseif curr_ML_iter <= num_ML_iters_add_ind  || length(offset_ML - curr_ML_iter) < num_ML_iters_add_ind
          end_index_ML = start_index_ML + floor( image_size(2) / length(offset_ML));
      else
          end_index_ML = start_index_ML + floor( image_size(2) / length(offset_ML)) - 1;
      end
          
      % update current slice
      try
     angle_slice(start_index_DV:end_index_DV, start_index_ML:end_index_ML) = ...
         squeeze(allData.tv(ud.currentSlice + cur_offset_DV + cur_offset_ML,start_index_DV:end_index_DV,start_index_ML:end_index_ML));
      catch
          disp('')
      end
    
      ud.im_annotation(start_index_DV:end_index_DV,start_index_ML:end_index_ML) = squeeze(allData.av(ud.currentSlice + cur_offset_DV + cur_offset_ML,...
                                                            start_index_DV:end_index_DV,start_index_ML:end_index_ML));
      ud.offset_map(start_index_DV:end_index_DV, start_index_ML:end_index_ML) = cur_offset_DV + cur_offset_ML;
      
      start_index_ML = end_index_ML + 1;
    end
      start_index_DV = end_index_DV + 1;
  end     
  if ud.viewColorAtlas
      set(ud.im, 'CData', ud.im_annotation);
  elseif ~ud.showAtlas  
      set(ud.im, 'CData', angle_slice);
  end  

  ud.ref = uint8(angle_slice);
  set(ud.pointHands_for_transform(:), 'Visible', 'off'); 
end


% in all cases. update histology overlay
if ud.histology_overlay == 1 || ud.histology_overlay == 2
    updateHistology(f,ud); ud = get(f, 'UserData');
else
    if ud.viewColorAtlas
        ud.curr_im = ud.im_annotation;
    else
        ud.curr_im = ud.ref;
    end    
end

% then update boundary overlay
if ud.showAtlas
    updateBoundaries(f,ud, allData)
end
  set(f, 'UserData', ud);

% ---------------------------------------------------------------
% update the image shown if histology is currently being overlaid
% ---------------------------------------------------------------
function updateHistology(f, ud)
    if ud.histology_overlay == 2
        image_blend =  imfuse(uint8(ud.ref*.6), ud.curr_slice_trans(:,:,:),'blend','Scaling','none');
        set(ud.im, 'CData', image_blend);
        ud.curr_im = image_blend;
    elseif ud.histology_overlay == 1
        set(ud.im, 'CData', ud.curr_slice_trans);
        ud.curr_im = ud.curr_slice_trans;
    end
    set(f, 'UserData', ud);

    
% -------------------------------------------------    
% update the position of the region boundary image
% -------------------------------------------------
function updateBoundaries(f, ud, allData)
    if ud.currentAngle(1) == 0 && ud.currentAngle(2) == 0
        curr_annotation = squeeze(allData.av(ud.currentSlice,:,:));
    else
        curr_annotation = ud.im_annotation;
    end
    
    atlas_vert_1 = double(curr_annotation(1:end-2,:));
    atlas_vert_2 = double(curr_annotation(3:end,:));
    atlas_vert_offset = abs( atlas_vert_1 - atlas_vert_2 ) > 0;
    shifted_atlas_vert1 = zeros(size(curr_annotation(:,:)));
    shifted_atlas_vert1(3:end,:) = atlas_vert_offset;
    shifted_atlas_vert2 = zeros(size(curr_annotation(:,:)));
    shifted_atlas_vert2(1:end-2,:) = atlas_vert_offset;

    atlas_horz_1 = double(curr_annotation(:,1:end-2));
    atlas_horz_2 = double(curr_annotation(:,3:end));
    atlas_horz_offset = abs( atlas_horz_1 - atlas_horz_2 )>0;
    shifted_atlas_horz1 = zeros(size(curr_annotation(:,:)));
    shifted_atlas_horz1(:,3:end) = atlas_horz_offset;
    shifted_atlas_horz2 = zeros(size(curr_annotation(:,:)));
    shifted_atlas_horz2(:,1:end-2) = atlas_horz_offset;

    shifted_atlas = shifted_atlas_horz1 + shifted_atlas_horz2 + shifted_atlas_vert1 + shifted_atlas_vert2;

    atlas_boundaries = (shifted_atlas>0); ud.atlas_boundaries = atlas_boundaries;

    if ud.showAtlas
        image_blend =  uint8( imfuse(ud.curr_im, atlas_boundaries/3.5*(1+.35*isa(ud.curr_im,'uint16')),'blend','Scaling','none') )* 2;
        set(ud.im, 'CData', image_blend); 
    end
    
    set(f, 'UserData', ud);
    
% ----------------
% react to clicks
% ----------------
function atlasClickCallback(im, keydata, slice_figure)
f = get(get(im, 'Parent'), 'Parent');
ud = get(f, 'UserData');
ud_slice = get(slice_figure, 'UserData');

% transform mode    
if ud.getPoint_for_transform
    clickX = round(keydata.IntersectionPoint(1));
    clickY = round(keydata.IntersectionPoint(2));
    if ud.showOverlay; clickY = size(ud.ref,1) - clickY; end
    
    if ud.curr_slice_num ~= ud.slice_at_shift_start+ud.slice_shift 
        if ~ud.loaded
            ud.current_pointList_for_transform = zeros(0,2);
            disp('transforming new slice');
        end
    end
    ud.pointList_for_transform(end+1, :) = [clickX, clickY];
    ud.current_pointList_for_transform(end+1, :) = [clickX, clickY];
    set(ud.pointHands_for_transform(:), 'color', [.7 .3 .3]);
    ud.pointHands_for_transform(end+1) = plot(ud.atlasAx, clickX, clickY, 'ro', 'color', [0 .9 0],'LineWidth',2,'markers',4);    
    ud.pointnum = ud.pointnum + 1;
    ud.pointText(end+1) = text(clickX,clickY,num2str(ud.pointnum),'Color','white');
        
    ud.slice_at_shift_start = ud_slice.slice_num;
    ud.slice_shift = 0;
    ud.curr_slice_num = ud.slice_at_shift_start+ud.slice_shift;
    ud.loaded = 0;
    ud.clicked = true;
end
set(f, 'UserData', ud);

% ------------------------
% react to mouse hovering
% ------------------------
function fh_wbmfcn(f, allData, slice_figure, save_location)
% WindowButtonMotionFcn for the figure.

ud = get(f, 'UserData');
ax = ud.atlasAx;
pixel = getPixel(ax);

%get offset due to angling
if 0<pixel(1) && pixel(1)<=ud.ref_size(1) && 0<pixel(2) && pixel(2)<=ud.ref_size(2)
    offset = ud.offset_map(pixel(1),pixel(2));
else; offset = 0;
end

% show bregma coords
updateStereotaxCoords(ud.currentSlice + offset, pixel, ud.bregma, ud.bregmaText, ud.angleText, ud.currentSlice, ud.currentAngle(1), ud.currentAngle(2), ud.ref_size, ud.plane);

% get annotation for this pixel
[name, acr, ann] = getPixelAnnotation(allData, pixel, ud.currentSlice+offset);

updateTitle(ax, name, acr);

if ~isempty(name)
    if ud.showContour
        if ~isempty(ud.oldContour)
            delete(ud.oldContour);
        end
        [~,ch] = contour(squeeze(allData.av(ud.currentSlice,:,:)==ann), 1, 'r');
        ud.oldContour = ch;
        set(f, 'UserData', ud);
    end
    
    if ud.showOverlay
        updateOverlay(f, allData, ann, slice_figure, save_location)
    end    
end

% ---------------------------------------------
% update the coordinates shown in the top left
% ---------------------------------------------
function updateStereotaxCoords(currentSlice, pixel, bregma, bregmaText, angleText, slice_num, ap_angle, ml_angle, ref_size, plane)
atlasRes = 0.010; % mm
if strcmp(plane,'coronal')
    ap = -(currentSlice-bregma(1))*atlasRes;
    dv = (pixel(1)-bregma(2))*atlasRes;
    ml = (pixel(2)-bregma(3))*atlasRes;
    set(angleText, 'String', ['Slice ' num2str(bregma(1) - slice_num) ', DV angle ' num2str(round(atand(ap_angle/(ref_size(1)/2)),1)) '^{\circ}, ML angle ' num2str(round(atand(ml_angle/(ref_size(2)/2)),1)) '^{\circ}']);
elseif strcmp(plane,'sagittal')
    ap = -(pixel(2)-bregma(1))*atlasRes;
    dv = (pixel(1)-bregma(2))*atlasRes;
    ml = -(currentSlice-bregma(3))*atlasRes;
    set(angleText, 'String', ['Slice ' num2str(bregma(1) - slice_num) ', DV angle ' num2str(round(atand(ap_angle/(ref_size(1)/2)),1)) '^{\circ}, AP angle ' num2str(round(atand(ml_angle/(ref_size(2)/2)),1)) '^{\circ}']);
elseif strcmp(plane,'transverse')
    ap = -(pixel(2)-bregma(1))*atlasRes;
    dv = (currentSlice-bregma(2))*atlasRes;
    ml = -(pixel(1)-bregma(3))*atlasRes;
    set(angleText, 'String', ['Slice ' num2str(bregma(1) - slice_num) ', ML angle ' num2str(round(atand(ap_angle/(ref_size(1)/2)),1)) '^{\circ}, AP angle ' num2str(round(atand(ml_angle/(ref_size(2)/2)),1)) '^{\circ}']);
end
set(bregmaText, 'String', sprintf('%.2f AP, %.2f DV, %.2f ML', ap, dv, ml));

% ---------------------------------
% update the current mouse location
% ---------------------------------
function pixel = getPixel(ax)

currPoint = get(ax,'currentpoint');  % The current point w.r.t the axis.

Cx = currPoint(1,1); Cy = currPoint(1,2);
pixel = round([Cy Cx]);

% ---------------------------------
% update the overlaid brain region
% ---------------------------------
function updateOverlay(f, allData, ann, slice_figure, save_location)
ud = get(f, 'UserData');
if isempty(ud.overlayAx) % first time
    if ud.currentAngle(1) == 0 && ud.currentAngle(2) == 0
        avo = plotAVoverlay(fliplr(squeeze(allData.av(ud.currentSlice,:,:))'), ann, ud.atlasAx);
    else
        avo = plotAVoverlay(fliplr(ud.im_annotation)', ann, ud.atlasAx);
    end
    ud.overlayAx = avo;
    set(ud.overlayAx, 'HitTest', 'off');
    set(f, 'UserData', ud);
else
    ovIm = get(ud.overlayAx, 'Children');
%     set(ovIm, 'HitTest', 'off');
    
    if ud.currentAngle(1) == 0 && ud.currentAngle(2) == 0
        thisSlice = squeeze(allData.av(ud.currentSlice,:,:));
    else
        thisSlice = ud.im_annotation;
    end

    set(ovIm, 'CData', flipud(thisSlice));    
    plotAVoverlay(fliplr(thisSlice'), ann, ud.atlasAx, ud.overlayAx);
    set(ovIm, 'ButtonDownFcn', @(f,k)atlasClickCallback(f, k, slice_figure));

end

% ---------------------------------
% find the region being hovered on
% ---------------------------------
function [name, acr, ann] = getPixelAnnotation(allData, pixel, currentSlice)
if pixel(1)>0&&pixel(1)<size(allData.av,2) && pixel(2)>0&&pixel(2)<=size(allData.av,3)
    ann = allData.av(currentSlice,pixel(1),pixel(2));
    name = allData.st.safe_name(ann);
    acr = allData.st.acronym(ann);
else
    ann = []; name = []; acr = [];
end

% ---------------------------------
% update the title, showing region
% ---------------------------------
function updateTitle(ax, name, acr)
if ~isempty(name)
    title(ax, [name{1} ' (' acr{1} ')']);
else
    title(ax, 'not found');
end
