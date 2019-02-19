%-Configfile for preprocessmri.m
%__________________________________________________________________________

%-SPM version
paralist.spmversion = 'spm12';

%-Please specify parallel or nonparallel
%-e.g. for preprocessing and individualstats, set to 1 (parallel)
%-for groupstats, set to 0 (nonparallel)
paralist.parallel = '1';

<<<<<<< HEAD
%-Subject list (full path to the csv file)
paralist.subjectlist = 'spgrsubjectlist.csv';
%---- example ----
%- PID, visit, session
%- 7014, 1 ,1
=======
%-Subject list
paralist.subjectlist = 'spgrsubjectlist.csv';
>>>>>>> 5bb1231cf7c68d3aff25067c42ff11a91ed415bd

%- List of smri images 
% (no .nii or .img extensions)
% i.e.--> 
%      spgr (name of spgr file for the 1st subject in paralist.subjectlist)
%	   spgr (name of spgr file for the 2nd subject in paralist.subjectlist)
%	   spgr (name of spgr file for the 3rd subject in paralist.subjectlist)
%	   spgr_1 (name of spgr file for the 4th subject in paralist.subjectlist)
%      ....
paralist.spgrlist = 'spgrnameslist.txt';

%- 0 - skull strip using spm12 ; 1 - skull strip using watershed; 
paralist.skullstrip = 0;

%- 0 - no segmentation; 1 - run segmentation using spm
paralist.segment = 1;

% I/O parameters
% - Raw data directory
paralist.rawdatadir = '/oak/stanford/groups/menon/rawdata/scsnl/';

% - Project directory - output of the preprocessing will be saved in the
% data/imaging folder of the project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/ruiyuan/rui/shelbyka/2017_TD_MD_mathfun/';

% MRI parameters
% - spm8 mri batch templates location
paralist.batchtemplatepath = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/preprocessing/spm12/batchtemplates';


