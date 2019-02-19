%-Configfile for preprocessmri.m
%__________________________________________________________________________

%-SPM version
paralist.spmversion = 'spm8';

%-Please specify parallel or nonparallel
%-e.g. for preprocessing and individualstats, set to 1 (parallel)
%-for groupstats, set to 0 (nonparallel)
paralist.parallel = '1';

%-Subject list
paralist.subjectlist = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/preprocessing/spm8/spgrsubjectlist.csv';

%- List of smri images 
% (no .nii or .img extensions)
% i.e.--> 
%      spgr (name of spgr file for the 1st subject in paralist.subjectlist)
%	   spgr (name of spgr file for the 2nd subject in paralist.subjectlist)
%	   spgr (name of spgr file for the 3rd subject in paralist.subjectlist)
%	   spgr_1 (name of spgr file for the 4th subject in paralist.subjectlist)
%      ....
% make sure this is a .txt file
paralist.spgrlist = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/preprocessing/spm8/spgrnameslist.txt';

%- 0 - no skullstripping; 1 - skull strip using watershed; 2 - skull strip using spm
paralist.skullstrip = 0;

%- 0 - no segmentation; 1 - run segmentation using spm
paralist.segment = 1;

% I/O parameters
% - Raw data directory
paralist.rawdatadir = '/oak/stanford/groups/menon/rawdata/scsnl/';

% - Project directory - output of the preprocessing will be saved in the
% data/imaging folder of the project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/shelbyka/2017_TD_MD_mathfun/';

% MRI parameters
% - spm8 mri batch templates location
paralist.batchtemplatepath = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/preprocessing/spm8/preprocessmrimodules/batchtemplates/';


