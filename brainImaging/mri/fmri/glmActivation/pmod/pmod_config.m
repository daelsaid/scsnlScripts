% This is the configuration file for parametric modulation: pmod_design.m
% _________________________________________________________________________
% 2019 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: $ 03-18-19 Carlo de los Angeles
% -------------------------------------------------------------------------

% Please put your spm version (8 or 12)
paralist.spmversion = 'spm12';

% Please select parallelization 
paralist.parallel = '1';

% Please write your project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/cdla/test_project/';

% Please specify your subject list file
paralist.subjectlist = 'subjectlist.csv'

% Please specify your run list file
paralist.runlist = 'runlist.txt'

% Please specify the task design file
paralist.task_design = 'task_design.mat'

% Please specify pmod_script file 
paralist.pmod_script = 'pmod.m'