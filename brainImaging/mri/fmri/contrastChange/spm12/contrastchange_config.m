% This is the configuration file for individual contrast change 
% More information can be found in the HELP section below
% _________________________________________________________________________
% 2009-2010 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: contrastchange_config.m.template 2010-09-24 $
% -------------------------------------------------------------------------
paralist.spmversion = 'spm12';
paralist.parallel = '1';

paralist.projectdir = '/oak/stanford/groups/menon/projects/ruiyuan/2018_opto';
% Please specify participant folder name in full path
paralist.participant_path = '/oak/stanford/groups/menon/projects/ruiyuan/2018_opto/results/taskfmri/participants/';

% Please specify the subject list file

paralist.subjectlist = 'fmrisubjectlist.csv';

% Please specify the contrast definition file
paralist.contrastmat = 'contrasts_gPPI.mat';

% Please specify the stats folder to look for SPM.mat
%paralist.stats_folder = {'SST_2runs_swar_gPPI/PPI_lSTN','SST_2runs_swar_gPPI/PPI_rAI','SST_2runs_swar_gPPI/PPI_rCau','SST_2runs_swar_gPPI/PPI_rIFG','SST_2runs_swar_gPPI/PPI_rMFG','SST_2runs_swar_gPPI/PPI_rPreSMA','SST_2runs_swar_gPPI/PPI_rSMG','SST_2runs_swar_gPPI/PPI_rSTN'};
paralist.stats_folder = {'AI_gPPI/PPI_AI_task'};

% Please specify the folder holding batch templates
paralist.template_path    = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm12/preprocessfmrimodules/batchtemplates';
