% Preprocess MRI data - segment
%__________________________________________________________________________

function preprocessmri_segment(CurrentDir, TemplatePath, SpgrFile, OutputDir)

tpm_dir = '/oak/stanford/groups/menon/software/spm8/tpm';

% Load default batch
load(fullfile(TemplatePath, 'batch_segmentation.mat'));

% Update batch parameters
matlabbatch{1}.spm.spatial.preproc.opts.tpm{1} = fullfile(tpm_dir, 'grey.nii');
matlabbatch{1}.spm.spatial.preproc.opts.tpm{2} = fullfile(tpm_dir, 'white.nii');
matlabbatch{1}.spm.spatial.preproc.opts.tpm{3} = fullfile(tpm_dir, 'csf.nii');
matlabbatch{1}.spm.spatial.preproc.data = {};
matlabbatch{1}.spm.spatial.preproc.data{1} = SpgrFile;

% Update and save batch
[SPGRFileDir SPGRFileName SPGRExt] = fileparts(SpgrFile);
BatchFile = fullfile(OutputDir, [SPGRFileName '_batch_segmentation.mat']);
save(BatchFile, 'matlabbatch');

% Run batch of segmentation
cd(OutputDir);
spm_jobman('run', BatchFile);
clear matlabbatch;
cd(CurrentDir);


end
