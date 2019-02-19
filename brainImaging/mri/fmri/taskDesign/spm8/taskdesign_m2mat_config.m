%-Parallel or not
paralist.parallel = '1';

%-Subject list
paralist.subjectlist = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/fmrisubjectlist.csv'; 
%-Run list
paralist.runlist = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/runlist.txt'; 

%-Raw data directory (where task_design.m are saved)
paralist.rawdir =  '/oak/stanford/groups/menon/rawdata/scsnl'; 

%-Project directory (where task_design.mat should be saved for each subject)
paralist.projectdir = '/oak/stanford/groups/menon/projects/shelbyka/2017_TD_MD_mathfun/'; 

%-Please specify the task design m file
paralist.task_dsgn  = 'taskdesign_comparisondot.m';

%Please specify the name that you want to use for task design mat file
paralist.task_dsgn_mat = 'task_design_test.mat';

%-SPM version (this is not important for the current function; keep it in order to use mlsubmit.sh)
paralist.spmversion = 'spm8';
