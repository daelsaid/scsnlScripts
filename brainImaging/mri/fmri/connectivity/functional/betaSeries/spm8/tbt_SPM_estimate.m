%-trial by trial SPM estimation
%-Yuan Zhang edit on 2018-04-05

function tbt_SPM_estimate(SubjectI, ConfigFile)

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('Trial by trial estimation starts at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

currentdir = pwd;

ConfigFile = strtrim(ConfigFile);
if ~exist(ConfigFile, 'file')
    error('cannot find the configuration file')
end
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
eval(ConfigFile);
clear ConfigFile;


% container
spm_version             = strtrim(paralist.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
spmfcscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/connectivity/functional/betaSeries' spm_version];

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding trial-by-trial spm estimate scripts path: %s\n', spmfcscript_path);
addpath(genpath(spmfcscript_path));


% -------------------------------------------------------------------------
% Read in parameters
% -------------------------------------------------------------------------
subject_i          = SubjectI;
subjectlist        = strtrim(paralist.subjectlist);
original_spm_data_dir = paralist.participant_path; 
analysis = strtrim(paralist.analysis);
tbt_spm_data_dir = paralist.tbt_spm_data_dir; 
pipeline = paralist.pipeline;      
task_to_split = paralist.task_names; 
stats_dir = paralist.stats_dir;

disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;


if ~exist(tbt_spm_data_dir, 'dir')
    mkdir(tbt_spm_data_dir);
end

% Read in subjects and sessions
% Get the subjects, sesses in cell array format
subjectlist       = csvread(subjectlist,1);
subject           = subjectlist(subject_i);
subject           =  sprintf('%04d',subject);
visit             = num2str(subjectlist(subject_i,2));
session           = num2str(subjectlist(subject_i,3));

numsub           = 1;
num_task_in = length(task_to_split);
%==========================================================================

spm('defaults', 'fmri');
spm_jobman('initcfg');

for isubj = 1:numsub
    fprintf('~~~~~~~~~Working on subject %s~~~~~~~~~~~\n', subject); 
    subj_original_spm_dir = fullfile(original_spm_data_dir, subject, ['visit',visit],['session',session], ...
        analysis,  ['stats_', spm_version], stats_dir);
    temp_subj_tbt_spm_dir = fullfile(tbt_spm_data_dir, subject, ['visit',visit],['session',session],'fmri',['stats_', spm_version],'temp');
    subj_tbt_spm_dir = fullfile(tbt_spm_data_dir, subject, ['visit',visit],['session',session],'fmri',['stats_', spm_version]);
    
    if ~exist(subj_tbt_spm_dir, 'dir')
        mkdir(subj_tbt_spm_dir);
    end
    
    if ~exist(temp_subj_tbt_spm_dir, 'dir')
        mkdir(temp_subj_tbt_spm_dir);
    end
    
    load(fullfile(subj_original_spm_dir, 'batch_stats.mat'));
    
    num_sess = length(matlabbatch{1}.spm.stats.fmri_spec.sess);
    
    matlabbatch(3) = [];
    matlabbatch{1}.spm.stats.fmri_spec.dir{1} = temp_subj_tbt_spm_dir;
    
    smoothed_data_dir = cell(num_sess, 1);
    for isess = 1:num_sess
        if(num_sess > 1) 
            task_design = load(fullfile(subj_original_spm_dir, ['task_design_run', num2str(isess), '.mat']));
        else
            task_design = load(fullfile(subj_original_spm_dir, 'task_design.mat'));
        end
        
        smoothed_data_dir{isess} = fileparts(matlabbatch{1}.spm.stats.fmri_spec.sess(isess).scans{1});
        unix(sprintf('gunzip -fq %s', fullfile(smoothed_data_dir{isess}, [pipeline 'I.nii.gz'])));
        num_task = length(task_design.names);
        [~, task_in_loc] = ismember(task_to_split, task_design.names);
        task_out_loc = 1:num_task;
        task_out_loc(task_in_loc) = [];
        new_task_names = {};
        new_task_onsets = {};
        new_task_durations = {};
        for itask_in = 1:num_task_in
            num_trial = length(task_design.onsets{task_in_loc(itask_in)});
            for itrial = 1:num_trial
                new_task_names = [new_task_names, {[task_design.names{task_in_loc(itask_in)}, '_', num2str(itrial)]}];
                new_task_onsets = [new_task_onsets, {task_design.onsets{task_in_loc(itask_in)}(itrial)}];
                new_task_durations = [new_task_durations, {task_design.durations{task_in_loc(itask_in)}(1)}];
            end
        end
        
        sess_name = task_design.sess_name;
        names = [new_task_names, task_design.names(task_out_loc)];
        onsets = [new_task_onsets, task_design.onsets(task_out_loc)];
        durations = [new_task_durations, task_design.durations(task_out_loc)];
        reg_file = task_design.reg_file;
        reg_names = task_design.reg_names;
        reg_vec = task_design.reg_vec;
        
        
        if(num_sess > 1) 
            new_task_design_file = fullfile(subj_tbt_spm_dir,['task_design_run', num2str(isess), '.mat']);
        else
            new_task_design_file = fullfile(subj_tbt_spm_dir,'task_design.mat');
        end
        save(new_task_design_file, 'sess_name', 'names', 'onsets', 'durations', 'reg_file', 'reg_names', 'reg_vec');
        matlabbatch{1}.spm.stats.fmri_spec.sess(isess).multi{1} = new_task_design_file;
        
    end
    
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{2}.spm.stats.fmri_est.spmmat{1} = fullfile(temp_subj_tbt_spm_dir, 'SPM.mat');
    
    save(fullfile(temp_subj_tbt_spm_dir, 'batch_stats.mat'), 'matlabbatch');
    
    clear matlabbatch;
    
    delete(get(0,'Children'));
    
    spm_jobman('run', fullfile(temp_subj_tbt_spm_dir, 'batch_stats.mat'));
    
    %%scsnl_art_redo(temp_subj_tbt_spm_dir, pipeline,  subj_tbt_spm_dir, smoothed_data_dir);
    
    % copy contrasts.mat, task_design, batch_stats
    unix(sprintf('/bin/cp -af %s %s', fullfile(temp_subj_tbt_spm_dir, '*'), subj_tbt_spm_dir));
    % remove temporary stats
    unix(sprintf('/bin/rm -rf %s', temp_subj_tbt_spm_dir));
    
    for isess = 1:num_sess
        unix(sprintf('gzip -fq %s', fullfile(smoothed_data_dir{isess}, [pipeline 'I.nii'])));
    end
    
end