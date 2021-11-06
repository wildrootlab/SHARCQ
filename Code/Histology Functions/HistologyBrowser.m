function HistologyBrowser(histology_figure, save_folder, image_folder, coords_folder, image_file_names, coords_file_names, folder_processed_images, ...
                use_already_downsampled_image, microns_per_pixel, microns_per_pixel_after_downsampling, gain)

% display image and set up user controls for contrast change        
ud.show_original = 0; 
ud.adjusting_contrast = 0;
ud.file_num = 1;
ud.num_files = length(image_file_names);
ud.save_folder = folder_processed_images;
ud.coords_folder = coords_folder;
ud.image_folder = image_folder;
ud.microns_per_pixel = microns_per_pixel;
ud.microns_per_pixel_after_downsampling = microns_per_pixel_after_downsampling;
ud.gain = gain;

% load histology image
disp(['loading image ' num2str(ud.file_num) '...'])

% load first image
loadimage = imread(fullfile(ud.image_folder,image_file_names{ud.file_num}));
ROI_location = fullfile(ud.coords_folder,coords_file_names{ud.file_num});
ROI_values = readmatrix(ROI_location);
ROI_table = readtable(ROI_location);

if ~use_already_downsampled_image
    % resize (downsample) image and ROI to reference atlas size
    disp('adding ROI layer...')
    disp('downsampling image...')
    original_image_size = size(loadimage);
    loadimage = imresize(loadimage, [round(original_image_size(1)*microns_per_pixel/microns_per_pixel_after_downsampling)  NaN]);
    sz = size(squeeze(loadimage(:,:,1)));
    ROI = zeros(sz);
    
    % Root Lab Specific
    %B = rot90(ROI);
    %ROI = B;

    if size(ROI_values,2) == 2
        X = 1;
        Y = 2;
    else
        X = find(strcmpi(ROI_table.Properties.VariableNames,'X'));
        Y = find(strcmpi(ROI_table.Properties.VariableNames,'Y'));
    end
        
    % ROI_values contains the data from the ROI coordinate file.
    % If this file was obtained through 'multi-point' tool on FIJI and 
    % analyze->measure, then the X,Y data will be in the 6th and 7th col
    x = round(ROI_values(:,X)*(sz(1,1)/original_image_size(1,1)));
    y = round(ROI_values(:,Y)*(sz(1,2)/original_image_size(1,2)));
    % Create binary ROI matrix 'image' and populate pixels with values if 
    % they represent labeled cell locations. If downsampled size causes two
    % cell locations to overlap, move one pixel away until empty space 
    for i = 1:length(ROI_values(:,1))
        if ROI(y(i),x(i)) == 0
             ROI(y(i),x(i)) = 10;
        else
             if ROI(y(i)+1,x(i)) == 0
                ROI(y(i)+1,x(i)) = 10;
             else
                    ROI(y(i)-1,x(i)) = 10;
             end
        end
    end
    
    % Root Lab Specific
    %B = rot90(ROI,3);
    %ROI = B;
    
else
    % images are already downsampled to the atlas resolution 10um/px
    disp('adding ROI layer...');
    sz = size(squeeze(loadimage(:,:,1)));
    ROI = zeros(sz);
    x = round(ROI_values(:,6));
    y = round(ROI_values(:,7));
    for i = 1:length(ROI_values(:,1))
        if ROI(y(i),x(i)) == 0
             ROI(y(i),x(i)) = 10;
        else
             if ROI(y(i)+1,x(i)) == 0
                ROI(y(i)+1,x(i)) = 10;
             else
                    ROI(y(i)-1,x(i)) = 10;
             end
        end
    end
end
ud.file_name_suffix = '_processed';
ud.channel = min( 3, size(loadimage,3));
original_image = loadimage(:,:,1:ud.channel)*gain;

imshow(original_image);
title(['Adjusting channel ' num2str(ud.channel) ' on image ' num2str(ud.file_num) ' / ' num2str(ud.num_files)],...
                    'color',[1==ud.channel 2==ud.channel 3==ud.channel])
                
ud.original_image = original_image;
ud.adjusted_image = original_image;

% save pre-processed image and ROI
imwrite(ud.adjusted_image, fullfile(ud.save_folder, [image_file_names{ud.file_num}(1:end-4) ud.file_name_suffix '.tif']))
writematrix(ROI,fullfile(ud.save_folder, [image_file_names{ud.file_num}(1:end-4) ud.file_name_suffix '.csv']));

set(histology_figure, 'UserData', ud);

set(histology_figure, 'KeyPressFcn', @(histology_figure,keydata)HistologyHotkeyFcn(histology_figure, keydata, image_file_names, coords_file_names, use_already_downsampled_image));

fprintf(1, '\n Controls: adjust contrast for any RGB channel on any image \n \n');
fprintf(1, 'space: adjust contrast for current channel / return to image-viewing mode \n');
fprintf(1, 'e: view original version \n');
fprintf(1, 'any key: return to modified version \n');
fprintf(1, 'r: reset to original \n');
fprintf(1, 'c: move to next channel \n');
fprintf(1, 's: save image \n');
fprintf(1, 'left/right arrow: save and move to next slide image \n \n');




% --------------------
% Respond to keypress
% --------------------
function HistologyHotkeyFcn(fig, keydata, image_file_names, coords_file_names, use_already_downsampled_image)

ud = get(fig, 'UserData');

if strcmp(lower(keydata.Key), 'space') % adjust contrast
    ud.adjusting_contrast = ~ud.adjusting_contrast;

    if ud.adjusting_contrast
        disp(['adjust contrast on channel ' num2str(ud.channel)])
        imshow(ud.adjusted_image(:,:,ud.channel))
        imcontrast(fig)
    else
        adjusted_image_channel = fig.Children.Children.CData;
        ud.adjusted_image(:,:,ud.channel) = adjusted_image_channel;
    end   

% ignore commands while adjusting contrast    
elseif ~ud.adjusting_contrast     
    switch lower(keydata.Key)    
        case 'e' % show original
            ud.show_original = ~ud.show_original;
            if ud.show_original 
                disp('showing original image (press any key to return)')
                imshow(ud.original_image)
            end    
        case 'r' % return to original
            disp('revert to original image')
            ud.adjusted_image = ud.original_image;    
        case 'c' % break
            disp('next channel')
            ud.channel = ud.channel + 1 - (ud.channel==3)*3;

        case 's' % save image
            disp(['saving processed image ' num2str(ud.file_num)]);
            imwrite(ud.adjusted_image, fullfile(ud.save_folder, [image_file_names{ud.file_num}(1:end-4) ud.file_name_suffix '.tif']))
            imshow(ud.adjusted_image)
        case 'leftarrow' % save image and move to previous image
            disp(['saving processed image ' num2str(ud.file_num)]);
            imwrite(ud.adjusted_image, fullfile(ud.save_folder, [image_file_names{ud.file_num}(1:end-4) ud.file_name_suffix '.tif']))
        
            if ud.file_num > 1
                ud.file_num = ud.file_num - 1;
                move_on = true;
            else
                move_on = false;
            end
        case 'rightarrow' % save image and move to next image
            disp(['saving processed image ' num2str(ud.file_num)]);
            imwrite(ud.adjusted_image, fullfile(ud.save_folder, [image_file_names{ud.file_num}(1:end-4) ud.file_name_suffix '.tif']))
             
            if ud.file_num < ud.num_files;
                ud.file_num = ud.file_num + 1;
                move_on = true;        
            else
                fprintf('\n');
                disp('That''s all for now - please close the figure to continue')
                move_on = false;
            end
    end
    if (strcmp(lower(keydata.Key),'leftarrow') || strcmp(lower(keydata.Key),'rightarrow')) && move_on

        % load image
        loadimage = imread(fullfile(ud.image_folder, image_file_names{ud.file_num}) );
        ROI_location = fullfile(ud.coords_folder,coords_file_names{ud.file_num});
        ROI_values = readmatrix(ROI_location);
        ROI_table = readtable(ROI_location);
        disp(['image ' num2str(ud.file_num) ' loaded'])
        
        if ~use_already_downsampled_image
            % resize (downsample) image to reference size
            disp('downsampling image...')
            original_image_size = size(loadimage);
            loadimage = imresize(loadimage, [round(original_image_size(1)*0.5/10)  NaN]);
            disp('adding ROI layer...')
            sz = size(squeeze(loadimage(:,:,1)));
            ROI = zeros(sz);
            
            % Root Lab Specific
            %B = rot90(ROI);
            %ROI = B;
            
            if size(ROI_values,2) == 2
                X = 1;
                Y = 2;
            else
                X = find(strcmpi(ROI_table.Properties.VariableNames,'X'));
                Y = find(strcmpi(ROI_table.Properties.VariableNames,'Y'));
            end
            
            x = round(ROI_values(:,X)*(sz(1,1)/original_image_size(1,1)));
            y = round(ROI_values(:,Y)*(sz(1,2)/original_image_size(1,2)));
            for i = 1:length(ROI_values(:,1))
                if ROI(y(i),x(i)) == 0
                    ROI(y(i),x(i)) = 10;
                else
                    if ROI(y(i)+1,x(i)) == 0
                        ROI(y(i)+1,x(i)) = 10;
                    else
                        ROI(y(i)-1,x(i)) = 10;
                    end
                end
            end
            
            % Root Lab Specific
            %B = rot90(ROI,3);
            %ROI = B;
            
        else
            % images are already downsampled to the atlas resolution 10um/px
            disp('adding ROI layer...');
            sz = size(squeeze(loadimage(:,:,1)));
            ROI = zeros(sz);
            x = round(ROI_values(:,6));
            y = round(ROI_values(:,7));
            for i = 1:length(ROI_values(:,1))
                if ROI(y(i),x(i)) == 0
                    ROI(y(i),x(i)) = 10;
                else
                    if ROI(y(i)+1,x(i)) == 0
                        ROI(y(i)+1,x(i)) = 10;
                    else
                        ROI(y(i)-1,x(i)) = 10;
                    end
                end
            end
        end        
        
        original_image = loadimage*ud.gain;

        ud.original_image = original_image;
        ud.adjusted_image = original_image;

        % save immediately
        imwrite(ud.adjusted_image, fullfile(ud.save_folder, [image_file_names{ud.file_num}(1:end-4) ud.file_name_suffix '.tif']))
        writematrix(ROI,fullfile(ud.save_folder, [image_file_names{ud.file_num}(1:end-4) ud.file_name_suffix '.csv']));

    end
else % if pressing commands while adjusting contrast
    disp(' ')
    disp('Please press space to exit contrast adjustment before issuing other commands')
    disp('If you are dissatisfied with your changes, you can then press ''r'' to revert to the original image')
end


% show the image, unless in other viewing modes
figure(fig)
if ~(ud.adjusting_contrast || (strcmp(lower(keydata.Key),'e')&&ud.show_original) )
    imshow(ud.adjusted_image)
end
title(['Adjusting channel ' num2str(ud.channel) ' on image ' num2str(ud.file_num) ' / ' num2str(ud.num_files)],...
            'color',[1==ud.channel 2==ud.channel 3==ud.channel])

set(fig, 'UserData', ud);


