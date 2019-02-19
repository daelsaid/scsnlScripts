function nifti4Dto3D_rui (datadir, imgprev)

%unix('source /share/software/user/open/fsl/5.0.10/etc/fslconf/fsl.sh')

% Datadir is the current directory
tempdir = pwd;
cd(datadir);
%unix(sprintf('cp %s %s',[imgprev,'I.nii'],'backup.nii'));
%unix(sprintf('gzip -fq %s', [imgprev, 'I.nii.gz']));

% Check whether 4-D Nifti file exists
nifti_file = spm_select('List', datadir, ['^', imgprev, 'I.nii']);

if isempty(nifti_file)
  fprintf('There is no NIFTI file in %s \n', datadir);
elseif size(nifti_file,1) > 1
  fprintf(['Warning: multiple NIFTI files with same image prefix in ', ...
           ' %s, aborting ... \n'], datadir);
else
  fprintf('Splitting 4-D nifti file: %s \n', deblank(nifti_file));
  
  Vt = spm_vol(nifti_file);
  spm_file_split(Vt);
  
  %unix(sprintf('/share/software/user/open/fsl/5.0.10/bin/fslsplit %s %s', ...
  %             deblank(nifti_file), [imgprev, 'I_']));
         
  %unix(sprintf('/bin/rm -rf %s', deblank(nifti_file)));
  %unix(sprintf('gunzip -fq %s', [imgprev, 'I_*.nii.gz']));
end

cd(tempdir);

end
