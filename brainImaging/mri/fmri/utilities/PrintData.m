function PrintData (TabDat, file_name)

%-Print out local maximum information into a txt file

fid = fopen(file_name, 'w+');
c = 1;

%-Print the filename
%------------------------------------------------------------------
fprintf(fid, 'Filename: %s \n', file_name);

%-Table Title
%------------------------------------------------------------------
fprintf(fid, '\n\nSTATISTICS: %s\n', TabDat.tit);
fprintf(fid, '%c', repmat('=',1,80));
fprintf(fid, '\n');

%-Table header
%------------------------------------------------------------------
fprintf(fid, '%s\t',TabDat.hdr{1,c:end-1});
fprintf(fid, '%s\n',TabDat.hdr{1,end});
fprintf(fid, '%s\t',TabDat.hdr{2,c:end-1});
fprintf(fid, '%s\n',TabDat.hdr{2,end});
fprintf(fid, '%c',repmat('-',1,80));
fprintf(fid, '\n');

%-Table data
%------------------------------------------------------------------
for i = 1:size(TabDat.dat,1)
  for j=c:size(TabDat.dat,2)
    fprintf(fid, TabDat.fmt{j},TabDat.dat{i,j});
    fprintf(fid, '\t');
  end
  fprintf(fid, '\n');
end
for i=1:max(1,12-size(TabDat.dat,1))
  fprintf(fid, '\n');
end
fprintf(fid, '%s\n',TabDat.str);
fprintf(fid, '%c',repmat('-',1,80));
fprintf(fid, '\n');

%-Table footer
%------------------------------------------------------------------
fprintf(fid, '%s\n',TabDat.ftr{:});
fprintf(fid, '%c',repmat('=',1,80));
fprintf(fid, '\n\n');

fclose(fid);

end
