% Configuration file for scsnl_groupoutlier.m
%__________________________________________________________________________
% 2009-2019 The Stanford Cognitive and Systems Neuroscience Laboratory
% Tianwen Chen, 02/02/2010
% Rui Yuan, 10/17/2018 

paralist.parallel = '0';

% Please specify the project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/ruiyuan/2018_opto';

% Please specify the parent folder
%paralist.parent_folder = [''];

% Please specify the subject list (file or cell array)
paralist.subject_list = '/oak/stanford/groups/menon/projects/ruiyuan/2018_opto/scripts/taskfmri/individualstats/CG/fmrisubjectlist_makeup2.csv';

% Please specify the stats folder name
paralist.stats_folder = 'CG_sgwra';
% Multiple stats folder
% paralist.stats_folder = {'addblock_stats', 'subblock_stats'};
paralist.output_folder_name = 'rui_test_0917';

% Please specify the contrast list (file or cell array), entry without .img
paralist.contrast_list = '/oak/stanford/groups/menon/projects/ruiyuan/2018_opto/scripts/taskfmri/individualstats/CG/contrast.mat';

% Please specify the peak/sum(contrast) value for each contrast
% A same single value for any combination of contrasts and stats_folder
paralist.pkcon_value = 1.3;
% Same values for stats_folders but different for contrasts
% paralist.pkcon_value = [1.3, 1.14, 1.15];

%--------------------------------------------------------------------------
% Please specify the path to the art_repair toolbox
paralist.art_repair_toolbox = '/home/fmri/fmrihome/SPM/spm8/toolbox/ArtRepair';

% Please specify the version of spm you want to use
paralist.spmversion = 'spm12';
% Please specify if you want this to run in parallel for all subejcts 
%paralist.parallel = 0;
