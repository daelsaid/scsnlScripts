% Preprocess fMRI data - co-registration
%__________________________________________________________________________
%-SCSNL, Rui Yuan, 2018-02-06



function preprocessfmri_coreg(WholePipeLine, TemplatePath, DataType, SPGRfile_FILE, MeanImgFile, OutputDir, InputImgFile, ImgPrefix)

  %%%%%---------  using .mat -----------------
%             load(fullfile(TemplatePath, 'batch_coregistration.mat'));
%             matlabbatch{1}.spm.spatial.coreg.estimate.ref{1} = SPGRfile_FILE;
%             matlabbatch{1}.spm.spatial.coreg.estimate.source{1} = MeanImgFile;
%             matlabbatch{1}.spm.spatial.coreg.estimate.other = InputImgFile;

   %%%%%---------  using direct batch -----------------
       fprintf('inputimage is : \n %s \n\n',InputImgFile{1});
       fprintf('reference image is :\n %s \n\n',SPGRfile_FILE);
       
            matlabbatch{1}.spm.spatial.coreg.estimate.ref{1} = SPGRfile_FILE;
            matlabbatch{1}.spm.spatial.coreg.estimate.source = {MeanImgFile};
            matlabbatch{1}.spm.spatial.coreg.estimate.other = InputImgFile;
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];


BatchFile = fullfile(OutputDir, 'log', ['batch_coregistration_', WholePipeLine, '.mat']);
save(BatchFile, 'matlabbatch');
spm_jobman('run', BatchFile);

%switch DataType
%  case 'img'
%    ImgFile = dir(fullfile(OutputDir, [ImgPrefix, 'I*.img*']));
%    NumImgFile = length(ImgFile);
%    HdrFile = dir(fullfile(OutputDir, [ImgPrefix, 'I*.hdr*']));
%    for iImg = 1:NumImgFile
%      unix(sprintf('cp -af %s %s', fullfile(OutputDir, ImgFile(iImg).name), ...
%        fullfile(OutputDir, ['c', ImgFile(iImg).name])));
%      unix(sprintf('cp -af %s %s', fullfile(OutputDir, HdrFile(iImg).name), ...
%        fullfile(OutputDir, ['c', HdrFile(iImg).name])));
%    end
%  case 'nii'
    NiiFile = dir(fullfile(OutputDir, [ImgPrefix, 'I.nii*']));
    unix(sprintf('cp -af %s %s', fullfile(OutputDir, NiiFile(1).name), ...
      fullfile(OutputDir, ['c', NiiFile(1).name])));
  
    MatFile = dir(fullfile(OutputDir, [ImgPrefix, 'I.mat']));
    unix(sprintf('cp -af %s %s', fullfile(OutputDir, MatFile(1).name), ...
      fullfile(OutputDir, ['c', MatFile(1).name])));
  
%end

clear matlabbatch;
end
