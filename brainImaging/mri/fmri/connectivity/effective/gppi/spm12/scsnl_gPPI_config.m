% Configuration file for scsnl_gPPI.m
% _________________________________________________________________________
% 2013 Stanford Cognitive and Systems Neuroscience Laboratory

paralist.spmversion = 'spm12';
paralist.parallel = '1';
% Please specify the data server path
paralist.projectdir = '/oak/stanford/groups/menon/projects/wdcai/2018_pipeline_test_HW_SST/';

% Please specify the parent folder of the static data
% For YEAR data structure, use the first one
% For NONE YEAR data structure, use the second one
paralist.parent_folder        = [''];
% paralist.parent_folder = 'UCSFBoxer';

% Please specify the subject list file (.txt) or a cell array

paralist.subjectlist = 'fmrisubjectlist_test2.csv';

% Please specify the stats folder name (eg., stats_spm8) 
paralist.stats_folder = 'SST_2runs_swar';

% Please specify the .nii file(s) for the ROI(s)
paralist.roi_file_list = {'roilist.txt'};

% Please specify the name of the ROI
paralist.roi_name_list = {'roilist_names.txt'};

% Please specify the task to include
% tasks_to_include = { '1', 'task1', 'task2', 'task3'} -> must exist in all sessions
% tasks_to_include = { '0', 'task1', 'task2', 'task3'} -> does not need to exist in all sessions
paralist.tasks_to_include = {'1', 'goCorrect', 'stopCorrect', 'stopFail', 'trash'};

%-------------------------------------------------------------------------%
% Please specify the confound names
paralist.confound_names = {'R1', 'R2', 'R3', 'R4', 'R5', 'R6'};
