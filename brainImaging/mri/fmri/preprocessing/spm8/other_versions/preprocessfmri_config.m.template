%-Configfile for preprocessfmri.m
%__________________________________________________________________________

%-SPM version. 
%-Please use spm8_R3028 if compatibility with old servers is desired
paralist.spmversion = 'spm8';

%-Please specify parallel or nonparallel
%-e.g. for preprocessing and individualstats, set to 1 (parallel)
%-for groupstats, set to 0 (nonparallel)
paralist.parallel = '1';

%-Subject list
paralist.subjectlist = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/fmrisubjectlist.csv';

%-Run list; make sure this is a .txt file
paralist.runlist = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/runlist.txt';

%-The entire preprocessing to be completed
%-Choose from: 'swar',  'swavr', 'swaor', 'swgcar',  'swgcavr', 'swgcaor'
%-             'swfar', 'swfavr', 'swfaor', 'swgcfar', 'swgcfavr', 'swgcfaor'
%-"s" is smoothing; "w" is normalization; "a": slice timing correction ; "r": realignment
%-"c" is coregistration; "g" is use segmented t1 images while
%coregistration
%-"v" is the 1st version and "o" is the 2nd version of VolRepair pipeline
%-"f" is for fmri images that were acquired flipped
paralist.pipeline = 'swar';

% I/O parameters
% - Raw data directory
paralist.rawdatadir = '/oak/stanford/groups/menon/rawdata/scsnl/';

% - Project directory - output of the preprocessing will be saved in the
% data/imaging folder of the project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/shelbyka/2017_TD_MD_mathfun/';

% - Output directory name
paralist.outputdirname = 'smoothed_spm8';

% fMRI parameters
% - spm8 batch templates location
paralist.batchtemplatepath = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/preprocessfmrimodules/batchtemplates/';

% - prefix for the unnormalized file name. for scsnl lab. this value is
% usually empty
paralist.inputimgprefix = '';

% - TR value
paralist.trval = 2;

% - Custom slice timing
paralist.customslicetiming = 0;

% - file that specifies the slice timing, in case customslicetiming is
% equal to 1
paralist.slicetimingfile = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/sliceorder.txt';

% - smoothing kernel
paralist.smoothwidth       = [6 6 6];

% - bounding box
paralist.boundingboxdim     = [-90 -126 -72; 90 90 108];

% Coregistration Parameters:
% spgrsubjectlist used for swgc** pipelines. 
% by default this value is empty indicating that spgrsubjectlist is identical to subjectlist. 
% in case it is not please create a separate file and specify here.
paralist.spgrsubjectlist = ''

% name of the T1w volume:
% 'skullstrip_spgr' for brains stripped with SPM pipeline
% 'watershed_spgr' for brains stripped with mri_watershed (new standard as of 12/2015)
%paralist.spgrfilename = 'skullstrip_spgr_spm8'
%paralist.spgrfilename = 'watershed_spgr';
paralist.spgrfilename = 'spgr';
