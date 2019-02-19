% Configuration file for scsnl_gPPI.m
% _________________________________________________________________________
% 2013 Stanford Cognitive and Systems Neuroscience Laboratory

paralist.spmversion = 'spm8_R3028';
paralist.parallel = '1';
% Please specify the data server path
paralist.projectdir = '/oak/stanford/groups/menon/projects/changh/2018_Short_Intervention_Study/';

% Please specify the parent folder of the static data
% For YEAR data structure, use the first one
% For NONE YEAR data structure, use the second one
paralist.parent_folder        = [''];
% paralist.parent_folder = 'UCSFBoxer';

% Please specify the subject list file (.txt) or a cell array

paralist.subjectlist = 'pilot_test_one.csv';

% Please specify the stats folder name (eg., stats_spm8) 
paralist.stats_folder = 'volume_repair_4cond_swgcavr_whiz_4run_6dur_spm_3028';

%HC changes
% Please specify the artrepair pipeline
paralist.prep_pipeline = 'swgcavr';
%HC changes

% Please specify the .nii file(s) for the ROI(s)
paralist.roi_file_list = {'list_23ROIs_n22.txt'};

% Please specify the name of the ROI
paralist.roi_name_list = {'list_names_23ROIs_n22.txt'};

% Please specify the task to include
% tasks_to_include = { '1', 'task1', 'task2', 'task3'} -> must exist in all sessions
% tasks_to_include = { '0', 'task1', 'task2', 'task3'} -> does not need to exist in all sessions
paralist.tasks_to_include = {'1','Trained_Acc','Trained_InAcc','Untrained_Acc','UnTrained_InAcc'};%UnTrained_InAcc

% mask file, restricting the analysis on voxels within the mask
paralist.mask_file = '/oak/stanford/groups/menon/projects/changh/2018_Short_Intervention_Study/scripts/taskfmri/testing/all_ROIs/mask_23ROIs.nii';

%-------------------------------------------------------------------------%
% Confound names: leave these as default unless you have reason to change them
paralist.confound_names = {'R1', 'R2', 'R3', 'R4', 'R5', 'R6'};
