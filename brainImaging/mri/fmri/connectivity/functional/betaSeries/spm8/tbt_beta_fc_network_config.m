%----Functional connectivity network constructed based on beta series------
%----Yuan Zhang edit on 2018-06-05----

%-SPM version
paralist.spmversion = 'spm8';
%-Please specify parallel or nonparallel
paralist.parallel = '1';
% - Project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess';


% Please specify the participant folder
paralist.participant_path = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess/results/taskfmri/participants/';

% Please specify the subject list file
paralist.subjectlist = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess/scripts/taskfmri/preprocess/subjs_PNC_2test.csv';

% Please specify the directory containing ROIs under investigation
paralist.roi_dir = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess/scripts/taskfmri/ROI_Neurosynth';

% Please specify your ROIs (ROI files must be .nii)
paralist.roi_names = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess/scripts/taskfmri/ROI_files_5test.txt';

% Directory with trial-by-trial beta estimates
paralist.tbt_spm_data_dir = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess/data/beta_ts_corr_test';

% Task Names
paralist.task_names = {'neutral_face','fear_face','angry_face','sad_face','happy_face'}; 

% Mask
paralist.mask_file = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/connectivity/functional/betaSeries/spm8/vbm_grey_mask.nii';

% Result directory
paralist.result_dir = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess/results/taskfmri/beta_ts_corr/';

% Result filename
paralist.result_fname = 'BetaCorr_network_EID55';
