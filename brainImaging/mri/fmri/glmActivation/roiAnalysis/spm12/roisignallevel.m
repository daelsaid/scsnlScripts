function roisignallevel(ConfigFile)


spm_version             = 'spm12';
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
spmroiscript_path    = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/glmActivation/roiAnalysis/' spm_version];

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding SPM based roianalysis scripts path: %s\n', spmroiscript_path);
addpath(genpath(spmroiscript_path));

CurrentDir = pwd;

warning('off', 'MATLAB:FINITE:obsoleteFunction')
disp(['Current directory is: ',pwd]);
c     = fix(clock);
disp('==================================================================');
fprintf('ROI Signal Level Analysis start at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');
fname = sprintf('roisignallevel-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
diary(fname);
disp(['Current directory is: ',pwd]);
fprintf('Script: %s\n', which('roisignallevel.m'));
fprintf('Configfile: %s\n', ConfigFile);
disp('------------------------------------------------------------------');

%-Load configuration file
%-------------------------------------------------------------------------
if ~exist(ConfigFile,'file')
    fprintf('Cannot find the configuration file ... \n');
    return;
end
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
eval(ConfigFile);
clear ConfigFile;

%-Read in parameters
%--------------------------------------------------------------------------
spmversion          = strtrim(paralist.spmversion);
subjectlist         = strtrim(paralist.subjectlist);
exp_runlist         = strtrim(paralist.runlist);
raw_dir             = strtrim(paralist.rawdatadir);
project_dir         = strtrim(paralist.projectdir);
stats_dir           = strtrim(paralist.stats_folder);
roi_dir             = strtrim(paralist.roi_folder);
roi_result_dir      = strtrim(paralist.roiresult_folder);
roilist             = strtrim(paralist.roilist);
tscore_threshold    = paralist.tscorethreshold;


disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

%-Check the roi_dir
%--------------------------------------------------------------------------
if ~exist(roi_dir, 'dir')
    fprintf('Folder does not exist: %s \n', roi_dir);
    diary off;
    return;
end

%-Check for spm version mismatch
%--------------------------------------------------------------------------
if ~strcmp(spmversion, spm_version)
    error('spm version mismatch');
end

%-ROI list
if ~isempty(roilist)
    ROIName = ReadList(roilist);
    NumROI = length(ROIName);
    roi_file = cell(NumROI, 1);
    for iROI = 1:NumROI
        ROIFile = spm_select('List', roi_dir, ROIName{iROI});
        if isempty(ROIFile)
            error('Folder contains no ROIs');
        end
        roi_file{iROI} = fullfile(roi_dir, ROIFile);
    end
end

subjectlist = csvread(subjectlist,1);
NumSubjs = size(subjectlist, 1);
Conditions = ReadList(exp_runlist);
NumConds = length(Conditions);

if (NumConds > 1)
  disp('The paralist.runlist file should only contain one run')
  return;
end

% default, measure sc using entire event duration as coded in task_design
event_duration          = [];

%--------------------------------------------------------------------------
% for each condition, run through all the subjects...
for iCond = 1:NumConds    
    for isubj = 1:NumSubjs
        subject = subjectlist(isubj, 1);
        subject = char(pad(string(subject),4,'left','0'));
        visit   = num2str(subjectlist(isubj, 2));
        session = num2str(subjectlist(isubj, 3));
        
        sub_stats_dir = fullfile(project_dir,'/results/taskfmri/participants', ...
            subject,['visit',visit],['session',session], 'glm', ...
            ['stats_',spmversion], ...
            stats_dir);
        if ~exist(sub_stats_dir, 'dir')
            fprintf('Folder does not exist: %s \n', sub_stats_dir);
            cd(CurrentDir);
            diary off; return;
        end
        % get percent signal change
        [signalchange{isubj}] = roi_signalchange_onesubject_scsnl(roi_file, sub_stats_dir, event_duration);
        
        % get tscore average and percent voxels activated in ROI
        [tscore_average{isubj}, tscore_percent_voxels{isubj}] = roi_tscore_onesubject(roi_file,sub_stats_dir,tscore_threshold);
        
        % get beta average in ROI
        [beta_average{isubj}] = roi_beta_onesubject(roi_file,sub_stats_dir);
        
    end
    % make a folder to hold roi statistics
    cond_roi_result_dir = strcat(roi_result_dir ,filesep, Conditions(iCond));
    
    unix(sprintf('mkdir -p %s', char(cond_roi_result_dir)));
    cd([CurrentDir,'/' ,char(cond_roi_result_dir)])
    
    % get summary data and stats for percent signal change,
    signal = signalchange; % change to generic name before saving
    [signal_means, signal_stderr, signal_stats] = roi_stats_activation(signal, [], []); % get stats for all ROIs and events
    save signalchange signal signal_means signal_stderr signal_stats
    
    % get summary data and stats for tscore_average
    signal = tscore_average; % change to generic name before saving
    [signal_means, signal_stderr, signal_stats] = roi_stats_activation(signal, [], []); % get stats for all ROIs and events
    save tscore_average signal signal_means signal_stderr signal_stats
    
    % get summary data and stats for tscore_percent_voxels
    signal = tscore_percent_voxels; % change to generic name before saving
    [signal_means, signal_stderr, signal_stats] = roi_stats_activation(signal, [], []); % get stats for all ROIs and events
    save tscore_percent_voxels signal signal_means signal_stderr signal_stats
    
    % get summary data and stats for tscore_average
    signal = beta_average; % change to generic name before saving
    [signal_means, signal_stderr, signal_stats] = roi_stats_activation(signal, [], []); % get stats for all ROIs and events
    save beta_average signal signal_means signal_stderr signal_stats
    
    PrintROIResults('signalchange');
    PrintROIResults('tscore_average');
    PrintROIResults('tscore_percent_voxels');
    PrintROIResults('beta_average');
    clear signalchange tscore_average beta_average
    cd(CurrentDir);
end

disp('-----------------------------------------------------------------');
c     = fix(clock);
disp('==================================================================');
fprintf('ROI Signal Level Analysis finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
diary off;
clear all;
close all;

end
