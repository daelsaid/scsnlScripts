%-Configfile for individualstats.m
%__________________________________________________________________________


%-Please specify parallel or nonparallel
%-e.g. for preprocessing and individualstats, set to 1 (parallel)
%-for groupstats, set to 0 (nonparallel)
paralist.parallel = '1';

% fMRI parameters
%-spm batch templates location
paralist.batchtemplatepath = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm12/preprocessfmrimodules/batchtemplates/'; %'/oak/stanford/groups/menon/scsnlscripts_vsochat/fmri/spm/spm8/preprocessing/preprocessfmrimodules/batchtemplates/';
%-SPM version
paralist.spmversion = 'spm12'; 

%-Subject list (full path to csv file)
paralist.subjectlist = '/oak/stanford/groups/menon/projects/ruiyuan/2018_preproc_fMRI/fmrisubjectlist.csv';
%---- example ----
%- PID, visit, session
%- 7014, 1 ,1

%-Run list (full path to txt file)
paralist.runlist = '/oak/stanford/groups/menon/projects/ruiyuan/2018_preproc_fMRI/runlist.txt';

% Please specify the data type of preprocessed images
% 'nii' for Nifti 4-D format, 'img' for Analyze 7.5 format
% If you would like the script to decide which type to use, uncomment the 
% second line and comment the first line
paralist.data_type = 'nii';
% paralist.data_type = [''];

% Please indicate whether to use head movements (1:Yes; 0:No)
paralist.include_mvmnt = 1;

%-Please specify the standard preprocessing pipeline you have used
paralist.pipeline = 'swgcar';


% -------------------------------------------------------------------------
% I/O parameters
% - Project directory - output of the individualstats will be saved in the
% results/taskfmri folder of the project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/ruiyuan/rui/shelbyka/2017_TD_MD_mathfun/';

% Please specify the folder containing the preprocessed data 
% (preprocessed via a standard pipeline like swcar)
paralist.preprocessed_folder    = 'smoothed_spm12_swgcar';

% Please specify the folder to hold the statistics results (below 'stats_spmX', which is generated by default) 
% If you include_volrepair = 1 below, set stats_folder = 'temp_stats';
paralist.stats_folder = 'comparisondot_swcar';
% paralist.stats_folder = 'temp_stats';


% task and contrast parameters
%-Please specify the task design file (*.m)
%-If task design *.mat file already exists, please specify as a mat file (e.g., task_design.mat)
paralist.task_dsgn          = 'task_design.mat'; %'taskdesign_comparisondot.m';

%-Please specify the file holding contrasts
%-This should be in your scripts/taskfmri/individualstats folder
paralist.contrastmat        = 'contrasts_comparisondot.mat';
% paralist.contrastmat = ['']; 

%-Please specify the TR otherwise the default is 2.0 s
paralist.TR = 2.0;

%-Please specify the type of serial correlations
%-other options are 'none', 'FAST'
paralist.cvi = 'AR(1)';

%-please specify the whole brain mask
%paralist.whole_brain_mask =[''];


% Please indicate whether it is based on VolRepair pipeline
% 1: use volrepair pipeline data for individual stats
% 0: use standard pipeline data
% If you set volrepair = 1, set up VolRepair section below
% If you set volrepair = 0, do not set up VolRepair section below 
paralist.include_volrepair = 0;

% -------------------------------------------------------------------------
% VolRepair Preprocessing Setup
% -------------------------------------------------------------------------

% Please specify the volrepair preprocessing pipeline
paralist.volpipeline = 'swcar';

% Please specify the volrepair preprocessed folder
paralist.volrepaired_folder = 'volrepair_spm12';

% Please specify the folder for VolRepaired data (swavrI*)
% the stats folder is under 'stats_spm8' folder (generated by default)
paralist.repaired_stats   = 'stats_spm12_VolRepair';
