% Preprocess fMRI data - smoothing
%__________________________________________________________________________
%-SCSNL, Rui Yuan, 2018-02-06

function preprocessfmri_smooth(WholePipeLine, TemplatePath, InputImgFile, OutputDir, SmoothWidth)


      %%% ----- spm 12 using .mat file -----------------------
        load(fullfile(TemplatePath, 'batch_smooth.mat'));
        matlabbatch{1}.spm.spatial.smooth.fwhm = SmoothWidth;
        matlabbatch{1}.spm.spatial.smooth.data = InputImgFile;

      %%% ----- spm 12 using direct batch ---------------------   
%         matlabbatch{1}.spm.spatial.smooth.data = InputImgFile;
%         matlabbatch{1}.spm.spatial.smooth.fwhm =  SmoothWidth;
%         matlabbatch{1}.spm.spatial.smooth.dtype = 0;
%         matlabbatch{1}.spm.spatial.smooth.im = 0;
%         matlabbatch{1}.spm.spatial.smooth.prefix = 's';


        BatchFile = fullfile(OutputDir, 'log', ['batch_smooth_', WholePipeLine, '.mat']);
        save(BatchFile, 'matlabbatch');
        spm_jobman('run', BatchFile);
        clear matlabbatch;

end