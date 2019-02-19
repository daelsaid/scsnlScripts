% Parameter configuration for functional connectivity
% _________________________________________________________________________
% 2009-2011 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: fconnect_config.m.template 2011-08-17$
% -------------------------------------------------------------------------
% adding more open parameters for flexible setting 
% - Weidong Cai, 11/09/2015
% -------------------------------------------------------------------------
% Yuan Zhang modified to make it work on Sherlock, 2018-06-26

%-SPM version
paralist.spmversion = 'spm12';
%-Please specify parallel or nonparallel
paralist.parallel = '1';

%-Subject list
paralist.subjectlist = '/oak/stanford/groups/menon/projects/yuanzh/2017_Autism_Anxiety/data/subjectlist/subjectlist_KKI_subset.csv';
%-Run list
paralist.runlist = '/oak/stanford/groups/menon/projects/yuanzh/2017_Autism_Anxiety/data/subjectlist/runlist.txt'; 
%-Only support 4D nifti.
paralist.data_type = 'nii';

% - Project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/yuanzh/2017_Autism_Anxiety';
% Please specify the preprocessed output folder
paralist.preprocessed_dir = 'smoothed_spm8';

% Please specify the pipeline of preprocessing
paralist.pipeline = 'swar';
%-Analysis type (e.g., seedfc)
paralist.analysis = 'seedfc';  
% fmri type (taskfmri, restfmri)
paralist.fmri_type = 'restfmri';

% Please specify the TR of your data (in seconds)
paralist.TR = 2.5;


% Please specify the ROI folders
paralist.roi_dir = '/oak/stanford/groups/menon/projects/yuanzh/2017_Autism_Anxiety/scripts/restfmri/funconn/Seeds';

% Please specify the ROI list (full file name with extensions)
paralist.roi_list = '/oak/stanford/groups/menon/projects/yuanzh/2017_Autism_Anxiety/scripts/restfmri/funconn/roi_list_test.txt';


% Please specify the option of bandpass filtering.
% Set to 1 to bandpass filter, 0 to skip.
paralist.bandpass_on = 1;  

% Please specify the number of truncated images from the beginning and end
% (unit in SCANS not seconds, a two element vector, 1st slot for the beginning, 
% and 2nd slot for the end, 0 means no truncation)
paralist.numtrunc = [8 0];
% Please specify bandpass filter parameters 
% If not bandpassing (i.e. bandpass_on = 0), then these values are ignored.
% Lower frequency bound for filtering (in Hz)
paralist.fl = 0.008;
% Upper frequency bound for filtering (in Hz)
paralist.fh = 0.1;


%------Addional Options----------
% Please specify temporal dir for interim data storage, incase running multiple fc analysis at the same time
paralist.temp_dir_name = 'temp_test1'; 

% Please specifiy nuisance options -------------------------------------
% whether to include white matter and csf regressor
% 0: no; 1: yes
paralist.flag_wm_csf = 1;
% whether to include derivative of white matter and csf regressor
% 0: none; 1: 1st derivative;
paralist.deriord_wm_csf = 1;
% whether to extract median insttead of mean for this regressor
paralist.median_wm_csf = 1;

% whether to include movement regressor
% 0: no; 1: yes
paralist.flag_mov = 1;
% whether to include derivative of movement regressor
% 0: no; 1: 1st derivative; 2: 1st derivative and square; 3: raw and 1st
% derivative and square
paralist.deriord_mov = 2;
% whether to bandpass filter mov parameters
paralist.flag_mov_bpfilter = 1;

% whether to include global signal
% 0: no; 1: yes
paralist.flag_gs = 1;
% whether to include derivative of global signal
% 0: no; 1: 1st derivative;
paralist.deriord_gs = 1;

% detrend option: 1-linear; 2-quadratic
paralist.detrend_option = 1; 

% output folder name fashion: 1 - encode nuisance options in folder name
paralist.flag_name_fashion = 1;
