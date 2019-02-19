function [InputImgFile, SelectErr] = preprocessfmri_selectfiles(FileDir, PrevPrefix, DataType)

SelectErr = 0;

switch DataType
  case 'img'
    error('Error: IMG format is not supported. Please convert your files to 4D NIFTI format');
  case 'nii'
    InputImgFile = spm_select('ExtFPList', FileDir, ['^', PrevPrefix, 'I.nii']);
    V = spm_vol(InputImgFile);
    nframes = V(1).private.dat.dim(4);
    InputImgFile = spm_select('ExtFPList', FileDir, ['^', PrevPrefix, 'I.nii'], (1:nframes));
    clear V nframes;
end

InputImgFile = deblank(cellstr(InputImgFile));

if isempty(InputImgFile{1})
  SelectErr = 1;
end

end