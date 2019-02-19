% Script for computing functional connectivity (resting state + seed-based)
%
% A template configuration file can be found at
% /home/fmri/fmrihome/SPM/spm8_scripts/FunctionalConnectivity/fconnect_config.m.template
%
% To run conversion: type at Matlab command line:
% >> fconnect(config_file)
% _________________________________________________________________________
% 2009-2011 Stanford Cognitive and Systems Neuroscience Laboratory
% Yuan Zhang edit on 2018-03-21
% $Id: fconnect.m Tianwen Chen 2011-08-17 v1$
% -------------------------------------------------------------------------

function fconnect (SubjectI, ConfigFile)

% Show the system information and write log files
warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('fMRI resting state connectivity starts at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

% % container
% % spmpreprocscript_path   = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/'; 
% % sprintf('adding SPM based preprocessing scripts path: %s\n', spmpreprocscript_path);
% % addpath(genpath(spmpreprocscript_path));
% spmanalysis_path = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/FunctionalConnectivity/Seed_WholeBrain'; 
% sprintf('adding SPM based analysis scripts path: %s\n', spmanalysis_path);
% addpath(genpath(spmanalysis_path));

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
spmfcscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/connectivity/functional/seedWholeBrain/' spm_version];

fprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
fprintf('adding SPM based seed whole brain scripts path: %s\n', spmfcscript_path);
addpath(genpath(spmfcscript_path));
fprintf('adding Readlist Utility path');
addpath(genpath('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/connectivity/functional/seedWholeBrain/spm12/utils'));


% -------------------------------------------------------------------------
% Read in parameters
% -------------------------------------------------------------------------
subject_i          = SubjectI;
subjectlist        = strtrim(paralist.subjectlist);
runlist            = strtrim(paralist.runlist);
data_type         = strtrim(paralist.data_type);
pipeline           = strtrim(paralist.pipeline);
project_dir        = strtrim(paralist.projectdir);
preprocessed_dir   = strtrim(paralist.preprocessed_dir);
fmri_type = strtrim(paralist.fmri_type);
analysis = strtrim(paralist.analysis);

TR_value = double(paralist.TR);
bandpass_include = paralist.bandpass_on;
fl_value = double(paralist.fl);
fh_value = double(paralist.fh);
roi_dir = strtrim(paralist.roi_dir);
roi_list = strtrim(paralist.roi_list);
numtrunc = paralist.numtrunc;

% output_dir = fullfile(project_dir,'results',fmri_type,'participants');

disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

% Read in subjects and sessions
% Get the subjects, sesses in cell array format
subjectlist       = csvread(subjectlist,1);
subject           = subjectlist(subject_i);
subject     =  sprintf('%04d',subject);
visit             = num2str(subjectlist(subject_i,2));
session           = num2str(subjectlist(subject_i,3));

numsub           = 1;
runs              = ReadList(runlist);
numrun            = length(runs);


for irun = 1:numrun
    % Create local folder holding temporary data
    temp_dir = fullfile('/scratch/users',getenv('LOGNAME'), subject, ...
    ['visit',visit],['session',session], 'rsfc_tmp_files');

    if exist(temp_dir,'dir')
        unix(sprintf('rm -rf %s', temp_dir));
    end
    mkdir(temp_dir);

    %-update roi list
    if ~isempty(roi_list)
        ROIName = ReadList(roi_list);
        NumROI = length(ROIName);
        roi_file = cell(NumROI, 1);
        for iROI = 1:NumROI
            ROIFile = spm_select('List', roi_dir, ['^', ROIName{iROI}]);
            if isempty(ROIFile)
                error('Folder contains no ROIs');
            end
            roi_file{iROI} = fullfile(roi_dir, ROIFile);
        end
    end

    imagedir = fullfile(project_dir,'/data/imaging/participants', subject, ['visit',visit],['session',session], ...
        'fmri', runs{irun}, preprocessed_dir);

    mvmntdir = fullfile(project_dir,'/data/imaging/participants', subject, ['visit',visit],['session',session], ...
        'fmri', runs{irun}, preprocessed_dir);

    subject_dir = fullfile(project_dir,'results',fmri_type,'participants', ...
                    subject,['visit',visit],['session',session], analysis, runs{irun}, ['stats_', spm_version]); 

    disp('----------------------------------------------------------------');
    fprintf('Processing subject: %s \n', subject_dir);

    cd(imagedir);
    fprintf('Copy files from: %s \n', pwd);
    fprintf('to: %s \n', temp_dir);

    unix(sprintf('cp -af %s %s', [pipeline, 'I.nii*'], temp_dir));

    cd(temp_dir);
    unix(sprintf('gunzip -fq %s %s', [pipeline, 'I.nii.gz']))
    % unix('gunzip -fq *.gz');
    newpipeline = pipeline;

    %-Bandpass filter data if it is set to 'ON'
    if bandpass_include == 1
        disp('Bandpass filtering data ......................................');
        bandpass_final_SPM(TR_value, fl_value, fh_value, temp_dir, pipeline, data_type);
        disp('Done');
        %-Prefix update for filtered data
        newpipeline = ['filtered', pipeline];
    end

    %-Step 1 ----------------------------------------------------------------
    %-Extract ROI timeseries
    disp('Extracting ROI timeseries ......................................');
    [all_roi_ts, roi_name] = extract_ROI_timeseries(roi_file, temp_dir, 1, ...
        0, newpipeline, data_type);
    all_roi_ts = all_roi_ts';

    % Total number of ROIs
    numroi = length(roi_name);

    %-Step 2 ----------------------------------------------------------------
    %-Extract global signnals
    disp('Extract global signals .........................................');
    org_global_ts = ExtractGlobalSignal(data_type, newpipeline, temp_dir);

    %-Truncate ROI and global timeseries
    all_roi_ts = all_roi_ts(numtrunc(1)+1:end-numtrunc(2), :);
    global_ts = org_global_ts(numtrunc(1)+1:end-numtrunc(2));
    %-Run through multiple ROIs
    for roicnt = 1:numroi
        rts = all_roi_ts(:,roicnt);

        %-STEP 3 --------------------------------------------------------------
        %-Save covariates for each ROI
        disp('Making .txt file with timeseries and global signal ...........');
        rp = dir(fullfile(mvmntdir, 'rp_I*.txt'));
        if ~isempty(rp)
            mvmnt = load(fullfile(mvmntdir, rp(1).name));
        else
            error(sprintf('Cannot find the movement file: %s \n', subject));
        end

        %-Demeaned ROI timeseries and global signals
        rts = rts - mean(rts)*ones(size(rts, 1), 1);
        global_ts = global_ts - mean(global_ts)*ones(size(global_ts, 1), 1);
        NumVolsKept = length(global_ts);
        mvmnt = mvmnt(numtrunc(1)+1:numtrunc(1)+NumVolsKept, :);
        CovMtx = [global_ts mvmnt ones(NumVolsKept, 1)];

        %-Regress out global signals from ROI timeseries
        rts = (eye(NumVolsKept) - CovMtx*pinv(CovMtx'*CovMtx)*CovMtx')*rts;

        %-Covariates
        ts  = [rts global_ts mvmnt];

        reg_ts_dir = fullfile(subject_dir, roi_name{roicnt}, 'timeseries');
        if ~exist(reg_ts_dir, 'dir')
            mkdir(reg_ts_dir);
        end

        reg_ts_all = fullfile(reg_ts_dir, 'roi_global_mvmnt.txt');
        save(reg_ts_all,'ts','-ascii','-tabs')

        %-STEP 4 --------------------------------------------------------------
        disp('Creating FC directories per subject ............................');
        final_FC_dir = fullfile(subject_dir, roi_name{roicnt},'stats');
        mkdir(final_FC_dir);
        cd   (final_FC_dir);
        if exist(fullfile(pwd,'SPM.mat'), 'file')
            unix('rm -rf *');
        end

        %-STEP 5 --------------------------------------------------------------
        disp('Creating task_design.mat for FC ................................');
        task_design_FC(reg_ts_all, 1)


        %-STEP 6 --------------------------------------------------------------
        disp('Running FC .....................................................');
        stats_fmri_fconnect_noscaling(temp_dir, data_type, numtrunc, newpipeline, TR_value);
        cd(currentdir)
    end
    % Delete temporary folder
    unix(sprintf('rm -rf %s', temp_dir));
end

cd(currentdir);

c     = fix(clock);
disp('==================================================================');
fprintf('Functional Connectivity finishes at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');
clear all;
close all;

end
