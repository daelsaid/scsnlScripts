%-Configuration file for rsa_wholebrain.m
%-Tianwen Chen, 2012-03-29
%__________________________________________________________________________
% 2009-2012 Stanford Cognitive and Systems Neuroscience Laboratory
%--------------------------------------------------------------------------

% Please specify the path to the folder holding subjects
paralist.ServerPath = '$OAK/projects/mcsnyder/2018_Short_Intervention/results/taskfmri/participants';

% Please specify the path to your main project directory
paralist.projectdir = '$OAK/projects/mcsnyder/2018_Short_Intervention/'

% Plese specify the list of subjects or a cell array
paralist.SubjectList = '$OAK/projects/mcsnyder/2018_Short_Intervention/data/subjectlist/pilot_test.csv';

% Please specify the stats folder name from SPM analysis
paralist.StatsFolder = 'volume_repair_4cond_swgcavr_whiz_4run_6dur_spm_3028';

% Please specify whether to use t map or beta map ('tmap' or 'conmap')
paralist.MapType = 'conmap';

% Please specify the index of tmap or contrast map (only 2 allowed)
% If the second t map is spmT_0003.img, the number is 3 (from 003) in the 
% second slot
paralist.MapIndex = [1,3];

% Please specify the mask file, if it is empty, it uses the default one from SPM.mat
paralist.MaskFile = '';

% Please specify the path to the folder holding analysis results
paralist.OutputDir = '$OAK/projects/mcsnyder/2018_Short_Intervention/results/taskfmri/participants';

% Please specify the version of spm to run
paralist.spmversion = 'spm8';

% Please specify whether or not you want it done in parallel
paralist.parallel = 0

%--------------------------------------------------------------------------
paralist.SearchShape = 'sphere';
paralist.SearchRadius = 6; % in mm
%--------------------------------------------------------------------------
