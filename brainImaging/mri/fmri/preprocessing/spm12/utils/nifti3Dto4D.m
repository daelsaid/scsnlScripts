function nifti3Dto4D (datadir, imgprev)

unix('source /share/software/user/open/fsl/5.0.10/etc/fslconf/fsl.sh')
tempdir = pwd;
cd(datadir);
unix(sprintf('gzip -fq %s', [imgprev, 'I_*.nii'])); 
% Check whether 4-D Nifti file exists
nifti_file = spm_select('List', datadir, ['^', imgprev, 'I_.*\.nii.gz']);
if isempty(nifti_file)
  fprintf('No Nifti files found in %s \n', datadir);
else
  fprintf('Merging 3D Nifti files into a 4-D Nifti file \n');

  unix(sprintf('/share/software/user/open/fsl/5.0.10/bin/fslmerge -t %s %s', ...
               [imgprev, 'I.nii'], [imgprev, 'I_*.nii.gz']));
  unix(sprintf('/bin/rm -rf %sI_*.nii.gz', imgprev));
end
cd(tempdir);
end