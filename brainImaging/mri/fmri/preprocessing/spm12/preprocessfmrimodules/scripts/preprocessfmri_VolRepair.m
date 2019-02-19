function [VolFlag] = preprocessfmri_VolRepair(OutputDir, DataType, ImgPrefix)

addpath(genpath('/oak/stanford/groups/menon/software/spm8/toolbox/ArtRepair'));
VolFlag = 0;

nifti4Dto3D_rui(OutputDir, ImgPrefix);

DataType = 'nii';
imgfiles = spm_select('FPList', OutputDir, ['^', ImgPrefix, 'I_*.nii']);
realignfile = spm_select('FPList', OutputDir, 'rp_I.txt');

subflag = scsnl_art_global(imgfiles, realignfile, 1, 2, 0);

if subflag == 1
  VolFlag = 1;
else
  nifti3Dto4D (OutputDir, ['v', ImgPrefix])
end

end
