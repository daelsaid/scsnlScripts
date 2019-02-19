function nifti4Dto3D_HCP(datadir, imgprev)

% Datadir is the current directory
tempdir = pwd;
cd(datadir);
unix(sprintf('gunzip -fq %s', [imgprev, 'I.nii.gz']));
% Check whether 4-D Nifti file exists
nifti_file = spm_select('List', datadir, ['^', imgprev, 'I.nii']);
if isempty(nifti_file)
  fprintf('There is no NIFTI file in %s \n', datadir);
elseif size(nifti_file,1) > 1
  fprintf(['Warning: multiple NIFTI files with same image prefix in ', ...
           ' %s, aborting ... \n'], datadir);
else
  fprintf('Splitting 4-D nifti file: %s \n', deblank(nifti_file));
  unix(sprintf('fslsplit %s %s', ...
               deblank(nifti_file), [imgprev, 'I_']));  
  unix(sprintf('rm -rf %s', deblank(nifti_file)));
  unix(sprintf('gunzip -fq %s', [imgprev, 'I*.nii.gz']));
end
cd(tempdir);

% % Datadir is the current directory
% cd(datadir);
% % Check whether 4-D Nifti file exists
% % nifti_file = fullfile(datadir, [imgprev, '.nii.gz']);
% nifti_file = fullfile(datadir, [imgprev, '.nii']);
% 
% fprintf('Splitting 4-D nifti file: %s \n', deblank(nifti_file));
% unix(sprintf('fslsplit %s %s', deblank(nifti_file), [imgprev, '_']));
% unix(sprintf('/bin/rm -rf %s', [imgprev, '.nii']));
% unix(sprintf('gunzip -fq %s', [imgprev, '_*.nii.gz']));

end
