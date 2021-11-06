function importXY(coords_folder,k)
% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 4);
% Specify range and delimiter
opts.DataLines = [2, Inf]; %start at second row to get rid of Xpos and Ypos
opts.Delimiter = ["\t", ",", "px"]; %delimit tab, comma, and px
% Specify column names and types
opts.VariableNames = ["Var1", "Var2", "VarName3", "Var4"];
opts.SelectedVariableNames = ["Var2" "VarName3"]; %grab x and y columns
opts.VariableTypes = ["string", "string", "string", "string"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.ConsecutiveDelimitersRule = "join";
% Specify variable properties
opts = setvaropts(opts, ["Var1", "Var2", "VarName3", "Var4"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "Var2", "VarName3", "Var4"], "EmptyFieldRule", "auto");
% Import the data
folder_contents = dir(fullfile(coords_folder,'*.txt'));
file = folder_contents(k).name;
if(file == "README.txt")
    return
end
[~,name,ext] = fileparts(file);
CountItem = readtable(file, opts);
ImportedData=str2double(table2array(CountItem)); %convert table to str then to number
datawrite = fullfile(coords_folder,append(name,'.csv'));
writematrix(ImportedData,datawrite);
end