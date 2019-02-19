% Parameter configuration for functional connectivity
% _________________________________________________________________________
% 2009-2011 Stanford Cognitive and Systems Neuroscience Laboratory
% Yuan Zhang edit on 2018-03-21
% $Id: fconnect_config.m.template 2011-08-17$
% -------------------------------------------------------------------------

%-SPM version
paralist.spmversion = 'spm8';
%-Please specify parallel or nonparallel
paralist.parallel = '1';

%/Users/yuanzh/Desktop/Sherlock/     /oak/stanford/groups/menon/

%-Subject list
paralist.subjectlist = '/oak/stanford/groups/menon/projects/yuanzh/2018_Brain_Age_Prediction/scripts/restfmri/networkfc/final_sublist.csv';
%-Run list
paralist.runlist = '/oak/stanford/groups/menon/projects/yuanzh/2018_Brain_Age_Prediction/scripts/restfmri/networkfc/runlist.txt'; 
%-Only support 4D nifti.
paralist.data_type = 'nii';

% - Project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/chamblin/2018_brain_age_predict';
% Please specify the preprocessed output folder
paralist.preprocessed_dir = 'swar_spm8';

% Please specify the pipeline of preprocessing
paralist.pipeline = 'swar';
%-Analysis type (e.g., seedfc)
paralist.analysis = 'ic_wholbrain_fc';  
% fmri type (taskfmri, restfmri)
paralist.fmri_type = 'restfmri';

% Please specify the TR of your data (in seconds)
paralist.TR = 3;

% Please specify the option of bandpass filtering.
% Set to 1 to bandpass filter, 0 to skip.
paralist.bandpass_on = 1;     

% Please specify bandpass filter parameters 
% If not bandpassing (i.e. bandpass_on = 0), then these values are ignored.
% Lower frequency bound for filtering (in Hz)
paralist.fl = 0.008;
% Upper frequency bound for filtering (in Hz)
paralist.fh = 0.1;

% Please specify the folder of IC time series
paralist.ic_dir = '/oak/stanford/groups/menon/projects/ruiyuan/2018_PNC_ICA/data_0606/';


% Please specify the number of truncated images from the beginning and end
% (unit in SCANS not seconds, a two element vector, 1st slot for the beginning, 
% and 2nd slot for the end, 0 means no truncation)
paralist.numtrunc = [8 0];

% =========================================================================
