% This is the configuration template file for movementstatsfmri 
% _________________________________________________________________________
% 2009-2012 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: movementstatfmri_config.m.template, Kaustubh Supekar, 2018-03-16 $
% -------------------------------------------------------------------------

%-Please specify parallel or nonparallel
paralist.parallel = '0';

%-Subject list
paralist.subjectlist = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/fmrisubjectlist.csv';

%-Run list
paralist.runlist = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/runlist.txt'; 

% I/O parameters
% - Raw data directory
paralist.rawdatadir = '/oak/stanford/groups/menon/rawdata/scsnl/';

% - Project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/shelbyka/2017_TD_MD_mathfun/';

% Please specify the foler for preprocessed data via standard pipeline
paralist.preprocessed_folder    = 'smoothed_spm8';

%-Scan-to-scan threshold (unit in voxel)
paralist.scantoscancrit = 0.5;

%-SPM version
paralist.spmversion = 'spm12';
