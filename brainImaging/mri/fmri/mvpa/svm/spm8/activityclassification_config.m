%-Configfile for activityclassification.m
%__________________________________________________________________________

%-Please specify parallel or nonparallel
%-e.g. for preprocessing and individualstats, set to 1 (parallel)
%-for groupstats, set to 0 (nonparallel)
paralist.parallel = '0';

%-SPM version
paralist.spmversion = 'spm8';

%-Subject list
paralist.subjectlist = '/oak/stanford/groups/menon/projects/mcsnyder/2018_Short_Intervention/data/subjectlist/pilot_test.csv';

%-Run list
paralist.runlist = '/oak/stanford/groups/menon/projects/mcsnyder/2018_Short_Intervention/data/subjectlist/sessions.txt';

%-Output directory
paralist.output_dir = ''

% contrast files (ful path to img file)
paralist.contrast_1 = 'spmT_0001.img'
paralist.contrast_2 = 'spmT_0002.img'

% -------------------------------------------------------------------------
% I/O parameters
% - Project directory - output of the individualstats will be saved in the
% results/taskfmri folder of the project directory

paralist.project_dir = '/oak/stanford/groups/menon/projects/ruiyuan/rui/shelbyka/2017_TD_MD_mathfun/';

paralist.maskfile = '/oak/stanford/groups/menon/projects/mcsnyder/2018_Short_Intervention/activity_classification/fsl41_greymatter_bin.img';
