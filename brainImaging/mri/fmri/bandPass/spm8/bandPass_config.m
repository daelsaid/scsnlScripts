% Parameter configuration for bandPass filter
% _________________________________________________________________________
% Yuan Zhang edit on 2018-04-26
% % -------------------------------------------------------------------------

%-SPM version
paralist.spmversion = 'spm8';
%-Please specify parallel or nonparallel
paralist.parallel = '1';

%/Users/yuanzh/Desktop/Sherlock/     /oak/stanford/groups/menon/

%-Subject list
paralist.subjectlist = '/oak/stanford/groups/menon/projects/chamblin/2018_brain_age_predict/data/subjectlist/subject_list_full.csv';
%-Run list
paralist.runlist = '/oak/stanford/groups/menon/projects/chamblin/2018_brain_age_predict/data/subjectlist/runlist.txt'; 
%-Only support 4D nifti.
paralist.data_type = 'nii';

% - Project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/chamblin/2018_brain_age_predict';
% Please specify the preprocessed output folder
paralist.preprocessed_dir = 'swar_spm8';

% Please specify the pipeline of preprocessing
paralist.pipeline = 'swar';
% fmri type (taskfmri, restfmri)
paralist.fmri_type = 'restfmri';

% Please specify the TR of your data (in seconds)
paralist.TR = 3;

% Please specify bandpass filter parameters 
% If not bandpassing (i.e. bandpass_on = 0), then these values are ignored.
% Lower frequency bound for filtering (in Hz)
paralist.fl = 0.008;
% Upper frequency bound for filtering (in Hz)
paralist.fh = 0.1;


% =========================================================================
