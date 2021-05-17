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
CountItem = readtable('C:\Users\krisl\Documents\RootLab\R5.2_Coords\r5.2.f1137-1163_CM_HM_JM_2.22_EP_Photoshop.txt', opts);
ImportedData=str2double(table2array(CountItem)); %convert table to str then to number
writematrix(ImportedData,'C:\Users\krisl\Documents\RootLab\R5.2_Coords\r5.2.f1137-1163_CM_HM_JM_2.22_EP_Photoshop.csv');