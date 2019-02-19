%-Configuration file for rsa_wholebrain.m
%-Tianwen Chen, 2012-03-29
%-Yuan modified for Flora to analyze mathFUN data
%__________________________________________________________________________
% 2009-2012 Stanford Cognitive and Systems Neuroscience Laboratory
%--------------------------------------------------------------------------
%-Please specify parallel or nonparallel
%-e.g. for individualstats, set to 1 (parallel)
%-for groupstats, set to 0 (nonparallel)
paralist.parallel = '0';

% Please specify the path to the folder holding subjects
paralist.ServerPath = '/oak/stanford/groups/menon/projects/shelbyka/2017_TD_MD_mathfun/results/taskfmri/participants/';

% Please specify the path to your main project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/shelbyka/2017_TD_MD_mathfun/'

% Plese specify the list of subjects or a cell array
paralist.SubjectList = '/oak/stanford/groups/menon/projects/shelbyka/2017_TD_MD_mathfun/data/subjectlist/8015.csv';

% Please specify the stats folder name from SPM analysis
paralist.StatsFolder = 'stats_spm12_swgcar_comp_dot';
%paralist.StatsFolder = 'stats_spm12_swgcar'; % for the comp_num task


% Please specify whether to use t map or beta map ('tmap' or 'conmap')
paralist.MapType = 'conmap';

% Please specify the index of tmap or contrast map (only 2 allowed)
% If the second t map is spmT_0003.img, the number is 3 (from 003) in the 
% second slot
paralist.MapIndex = [1,3]; % I have a similar condition number between tasks

% Please specify the mask file, if it is empty, it uses the default one from SPM.mat
paralist.MaskFile = '';

% Please specify the path to the folder holding analysis results
paralist.OutputDir = '/oak/stanford/groups/menon/projects/shelbyka/2017_TD_MD_mathfun/results/taskfmri/participants';

% Please specify the version of spm to run
paralist.spmversion = 'spm12';

% Please specify whether or not you want it done in parallel
paralist.parallel = 0

%--------------------------------------------------------------------------
paralist.SearchShape = 'sphere';
paralist.SearchRadius = 6; % in mm
%--------------------------------------------------------------------------
