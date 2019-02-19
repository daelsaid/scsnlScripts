function preprocessfmri_FlipZ (OutputDir, ImgPrefix)
  unix('source /share/software/user/open/fsl/5.0.10/etc/fslconf/fsl.sh')
  unix(sprintf('/share/software/user/open/fsl/5.0.10/bin/fslreorient2std %s %s', ...
    fullfile(OutputDir, [ImgPrefix, 'I']), fullfile(OutputDir, ['f', ImgPrefix, 'I'])));
  unix(sprintf('gunzip -fq %s', fullfile(OutputDir, ['f', ImgPrefix, 'I.nii.gz'])));
   unix(sprintf('/share/software/user/open/fsl/5.0.10/bin/fslreorient2std %s %s', ...
    fullfile(OutputDir, 'meanI'), fullfile(OutputDir, 'meanI')));
  unix(sprintf('gunzip -fq %s', fullfile(OutputDir, 'meanI.nii.gz')));
  
end
