%% Generate data for all sections analyzed and create horizonal bar plot of region counts
function Count_Cell_Locations(image_folder,atlas_name)
if atlas_name == "chon"
    location = fullfile(image_folder,'Chon Data');
    rois = dir([location filesep '*.txt']);
    rois = natsortfiles({rois.name});
    data = [];
    for i=1:length(rois)
        file = fullfile(image_folder,'Chon Data',rois(i));
        file = string(file);
        result = readtable(file,'Delimiter','\t','ReadVariableNames',true);
        data = vertcat(data,result);
    end
end
if atlas_name == "allen"
    location = fullfile(image_folder,'Allen Data');
    rois = dir([location filesep '*.txt']);
    rois = natsortfiles({rois.name});
    data = [];
    for i=1:length(rois)
        file = fullfile(image_folder,'Allen Data',rois(i));
        file = string(file);
        result = readtable(file,'Delimiter','\t','ReadVariableNames',false);
        data = vertcat(data,result);
    end
end
data = table2array(data);
[GC,GR] = groupcounts(data);
GR = string(GR);
GR = strrep(GR,'_',' ');
X = categorical(GR);
X = reordercats(X,GR);
Y = GC;
% Yfilter = [];
% Xfilter = categorical();
% for i = 1:length(Y)
%     if Y(i) > 75 && X(i) ~= "not found"
%         Yfilter(end+1) = Y(i);
%         Xfilter(end+1) = X(i);
%     end
% end
% barh(Xfilter,Yfilter);
barh(X,Y);
if atlas_name == "chon"
    writecell(data,fullfile(image_folder,'Chon_Region_Data.csv'));
end
if atlas_name == "allen"
    writecell(data,fullfile(image_folder,'Allen_Region_Data.csv'));
end
end





