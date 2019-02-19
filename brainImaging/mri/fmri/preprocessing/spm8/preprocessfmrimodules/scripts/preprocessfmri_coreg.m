function preprocessfmri_coreg(WholePipeLine, TemplatePath, DataType, SPGRFile, MeanImgFile, OutputDir, InputImgFile, ImgPrefix)

load(fullfile(TemplatePath, 'batch_coregistration.mat'));
matlabbatch{1}.spm.spatial.coreg.estimate.ref{1} = SPGRFile;
matlabbatch{1}.spm.spatial.coreg.estimate.source{1} = MeanImgFile;
matlabbatch{1}.spm.spatial.coreg.estimate.other = InputImgFile;
BatchFile = fullfile(OutputDir, 'log', ['batch_coregistration_', WholePipeLine, '.mat']);
save(BatchFile, 'matlabbatch');
spm_jobman('run', BatchFile);

switch DataType
  case 'img'
    error('Error: IMG format is not supported. Please convert your files to 4D NIFTI format');
  case 'nii'
    NiiFile = dir(fullfile(OutputDir, [ImgPrefix, 'I.nii*']));
    unix(sprintf('cp -af %s %s', fullfile(OutputDir, NiiFile(1).name), ...
      fullfile(OutputDir, ['c', NiiFile(1).name])));
end

clear matlabbatch;
end