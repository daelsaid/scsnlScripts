% _________________________________________________________________________
% Yuan Zhang modified to make it work on Sherlock, 2018-06-26
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

% container
spmanalysis_path = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/connectivity/functional/roiRoiNetwork'; 
sprintf('adding SPM based analysis scripts path: %s\n', spmanalysis_path);
addpath(genpath(spmanalysis_path));

currentdir = pwd;

ConfigFile = strtrim(ConfigFile);
if ~exist(ConfigFile, 'file')
    error('cannot find the configuration file')
end
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
eval(ConfigFile);
clear ConfigFile;

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

spm_version = strtrim(paralist.spmversion);
% spm version
software_path           = '/oak/stanford/groups/menon/software/';
spm_path                = fullfile(software_path, spm_version);
% add spm path
sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));

% output_dir = fullfile(project_dir,'results',fmri_type,'participants');

disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

% Read in subjects and sessions
% Get the subjects, sesses in cell array format
subjectlist       = csvread(subjectlist,1);
subject           = subjectlist(subject_i);
subject           = char(pad(string(subject),4,'left','0'));
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
    %-Demeaned ROI timeseries and global signals
    all_roi_ts = spm_detrend(all_roi_ts, 0); 
    global_ts = spm_detrend(global_ts, 0);
    
    NumVolsKept = length(global_ts);
    %-STEP 3 --------------------------------------------------------------
    %-nuisance matrix with head motion signals
    rp = dir(fullfile(mvmntdir, 'rp_I*.txt'));
    if ~isempty(rp)
        mvmnt = load(fullfile(mvmntdir, rp(1).name));
    else
        cd(currentdir);
        error(sprintf('Cannot find the movement file: %s \n', subject));
    end

    if bandpass_include == 1
        mvmnt = bandpass_final_SPM_ts(TR_value, fl_value, fh_value, mvmnt);
    end
    mvmnt = mvmnt(numtrunc(1)+1:end-numtrunc(2),:);
    %-Demaned motion signals
    mvmnt = mvmnt - repmat(mean(mvmnt, 1), NumVolsKept, 1);
  
    cov_mtx = [global_ts mvmnt ones(NumVolsKept, 1)];
    
    % ROI-ROI connectivity/network
    roi_res = zeros(size(all_roi_ts));
    for iroi = 1:numroi
        [b,bint,r,rint,stats] = regress(all_roi_ts(:,iroi), cov_mtx);
        roi_res(:,iroi) = r(:);
    end
  
    r2r_corr = corr(roi_res);
    r2r_corr_z = 0.5*log((1+r2r_corr)./(1-r2r_corr));
    subj_cov = cov(roi_res);
    r2r_cov = subj_cov;
    inv_cov = inv(subj_cov);
    sigmas = 1./sqrt(diag(inv_cov));
    norm_mtx = diag(sigmas);
    subj_pcorr = -norm_mtx * inv_cov * norm_mtx;
    subj_pcorr_z = 0.5*log((1+subj_pcorr)./(1-subj_pcorr));
    r2r_pcorr = subj_pcorr;
    r2r_pcorr_z = subj_pcorr_z;
  
    % save results into subject's folder
    stats_dir = fullfile(subject_dir, 'roi_roi_network');
    if ~exist(stats_dir, 'dir')
         mkdir(stats_dir);
    end
    outputf = fullfile(stats_dir,'roi_roi_correlation.mat');
    save(outputf,'r2r_corr','r2r_corr_z', 'r2r_cov','r2r_pcorr','r2r_pcorr_z',...
        'subject', 'roi_res', 'all_roi_ts', 'cov_mtx');
 
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
