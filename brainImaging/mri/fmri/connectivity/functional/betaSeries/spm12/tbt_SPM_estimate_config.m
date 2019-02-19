%----Trial by trial SPM estimate------
%----Yuan Zhang edit on 2018-04-05----

%-SPM version
paralist.spmversion = 'spm12';
%-Please specify parallel or nonparallel
paralist.parallel = '1';
% - Project directory
paralist.projectdir = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess';

% Subject list file
paralist.subjectlist = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess/scripts/taskfmri/preprocess/subjs_PNC_2test.csv';

% Participant path 
paralist.participant_path = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess/results/taskfmri/participants/';

% Analysis type (e.g. glm)
paralist.analysis = 'glm';

% Output directory
paralist.tbt_spm_data_dir = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/test_PNC_preprocess/data/beta_ts_corr_test';

% Image pipeline
paralist.pipeline = 'swar';

% Names of tasks to estimate
paralist.task_names = {'neutral_face','fear_face','angry_face','sad_face','happy_face'};

% First level SPM stats directory
paralist.stats_dir = 'EI_D55';
