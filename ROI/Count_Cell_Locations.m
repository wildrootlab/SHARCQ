% create horizonal bar plot of region counts

[GC,GR] = groupcounts(roi_annotation(:,2));
X = categorical(GR);
X = reordercats(X,GR);
Y = GC;
barh(X,Y);

GC = num2cell(GC);
newdata = [GC,GR];
C = readcell('R5_1.xls');
updated = vertcat(C,newdata);

writecell(updated,'R5_1.xls');






