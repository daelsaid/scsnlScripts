function [VolFlag] = preprocessfmri_VolRepair_OVersion(OutputDir, DataType, ImgPrefix)

%---modifed by Rui Yuan 07/03/2018

addpath(genpath('/oak/stanford/groups/menon/software/spm8/toolbox/ArtRepair'));
VolFlag = 0;

nifti4Dto3D_rui(OutputDir, ImgPrefix);

DataType = 'nii';

imgfiles = spm_select('FPList', OutputDir, ['^', ImgPrefix, 'I_.*\.nii']);
realignfile = spm_select('FPList', OutputDir, 'rp_I.txt');

subflag = scsnl_art_global_OVersion(imgfiles, realignfile, 1, 2, 0);

delete([ImgPrefix,'I_*.nii']);


if subflag == 1
  VolFlag = 1;
else
  nifti3Dto4D (OutputDir, ['v', ImgPrefix])
end

end
