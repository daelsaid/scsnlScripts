%-Configfile for preprocessmri.m
%__________________________________________________________________________

%-SPM version
paralist.spmversion = 'spm12';

%-Please specify parallel or nonparallel
%-e.g. for preprocessing and individualstats, set to 1 (parallel)
%-for groupstats, set to 0 (nonparallel)
paralist.parallel = '0';


%-Subject list (full path to the csv file)
paralist.subjectlist = 'spgrsubject_list.csv';
%---- example ----
%- PID, visit, session, file_name
%- 7014, 1 ,1, spgr
%=======
%- List of smri images 
% (no .nii or .img extensions)
% i.e.--> 
%      spgr (name of spgr file for the 1st subject in paralist.subjectlist)
%	   spgr (name of spgr file for the 2nd subject in paralist.subjectlist)
%	   spgr (name of spgr file for the 3rd subject in paralist.subjectlist)
%	   spgr_1 (name of spgr file for the 4th subject in paralist.subjectlist)
%      ....

% - Project directory - output of the preprocessing will be saved in the
% data/imaging folder of the project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/ruiyuan/2019_PD_ADRC/';

% MRI parameters
% - spm8 mri batch templates location
%paralist.batchtemplatepath = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/preprocessing/spm12/batchtemplates';


