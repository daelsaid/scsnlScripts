% Script for computing functional connectivity (resting state + seed-based)
% _________________________________________________________________________
% 2009-2011 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: fconnect.m Tianwen Chen 2011-08-17 v1$
% -------------------------------------------------------------------------
% 11/09/2015 script was modified for seed-based fc anaysis which allows
% more general format parameters. modified by Weidong Cai, 11/09/2015
% -------------------------------------------------------------------------
% Yuan Zhang modified to make it work on Sherlock, 2018-06-26
% YZ: this is an advanced version of the analysis with more options to play with

function fconnect_gf (SubjectI, ConfigFile)

% Show the system information and write log files
warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('fMRI resting state connectivity starts at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');


% % container
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
NUMTRUNC = paralist.numtrunc;

%------------addiotional options--------------
temp_dir_name = paralist.temp_dir_name;

flag_wm_csf = paralist.flag_wm_csf;
deriord_wm_csf = paralist.deriord_wm_csf;
median_wm_csf = paralist.median_wm_csf;

flag_mov = paralist.flag_mov;
deriord_mov = paralist.deriord_mov;
flag_mov_bpfilter = paralist.flag_mov_bpfilter;

flag_gs = paralist.flag_gs;
deriord_gs = paralist.deriord_gs;

detrend_option = paralist.detrend_option; 

flag_name_fashion = paralist.flag_name_fashion;


% check white matter and csf masks and check whether masks exist
%-white matter and CSF roi files
wm_csf_roi_file = cell(2,1);
%-white matter roi
wm_csf_roi_file{1} = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/masks/white_mask_p08_d1_e1_roi.mat';
%-csf roi
wm_csf_roi_file{2} = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/masks/csf_mask_p08_d1_e1_roi.mat';
if flag_wm_csf
  if ~exist(wm_csf_roi_file{1}, 'file') || ~exist(wm_csf_roi_file{2}, 'file')
    error('cannot find white matter and/or csf mask files.');
  end
end

%--------------------------------------------
spm_version = strtrim(paralist.spmversion);
% spm version
software_path           = '/oak/stanford/groups/menon/software/';
spm_path                = fullfile(software_path, spm_version);
% add spm path
sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));


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


% check output folder names
if flag_name_fashion
    stats_folder = sprintf('gs%dderi%d_wmcsf%dderi%d_mov%dderi%dbp%d_dt%d', flag_gs,deriord_gs,flag_wm_csf,deriord_wm_csf,flag_mov,deriord_mov,flag_mov_bpfilter,detrend_option);
    reg_ts_all_folder = sprintf('timeseries_gs%dderi%d_wmcsf%dderi%d_mov%dderi%dbp%d_dt%d', flag_gs,deriord_gs,flag_wm_csf,deriord_wm_csf,flag_mov,deriord_mov,flag_mov_bpfilter,detrend_option);
else
    stats_folder = 'stats';
    reg_ts_all_folder = 'timeseries';
end


for irun = 1:numrun
    % Create local folder holding temporary data
    temp_dir = fullfile('/scratch/users',getenv('LOGNAME'), subject, ...
    ['visit',visit],['session',session], temp_dir_name);

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
    newpipeline = pipeline;
    
    %-Step 0 ---------------------------------------------------------
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
    %-Extract nuisance timeseries
    CovMtx = [];
    allNuiMtx = [];
    gsMtx = [];
    wmcsfMtx = [];
    movMtx = [];
    
    %-2.1 Extract global signnals
    if flag_gs
        disp('Extract global signals .........................................');
        if ~deriord_gs % if no derivative, extracting from filtered data
          org_global_ts = ExtractGlobalSignal(data_type, newpipeline, temp_dir);
          gsMtx = [gsMtx org_global_ts];

          %- Truncate global signal
          gsMtx = gsMtx(NUMTRUNC(1)+1:end-NUMTRUNC(2), :);
          
        else  % if derivatives are required, extracting from raw data, then filter
          org_global_ts = ExtractGlobalSignal(data_type, pipeline, temp_dir);

          %-get the first derivative of global ts
          diff_global_ts = diff(org_global_ts);

          %- bandpass filter global signal
          if bandpass_include == 1
             org_global_ts = bandpass_final_SPM_ts(TR_value, fl_value, fh_value, org_global_ts); 
             diff_global_ts = bandpass_final_SPM_ts(TR_value, fl_value, fh_value, diff_global_ts);
          end

          diff_global_ts = [repmat(0,1,size(org_global_ts, 2)); diff_global_ts];
          gsMtx = [org_global_ts, diff_global_ts];
          gsMtx = gsMtx(NUMTRUNC(1)+1:end-NUMTRUNC(2), :);
        end
    end
    
    %-2.2 Extract white matter and CSF signals
    if flag_wm_csf
        disp('Extract white matter and CSF signals ...........................');
        if ~deriord_wm_csf  % if no derivative, extracting from filtered data
          if median_wm_csf
            [wm_csf_ts, wm_csf_roi_name] = extract_ROI_timeseries_median(wm_csf_roi_file, temp_dir, 1, ...
              0, newpipeline, data_type); 
          else
            [wm_csf_ts, wm_csf_roi_name] = extract_ROI_timeseries(wm_csf_roi_file, temp_dir, 1, ...
              0, newpipeline, data_type);
          end
          wm_csf_ts = wm_csf_ts';

          wmcsfMtx = [wmcsfMtx wm_csf_ts];

          %- Truncate white matter and CSF signal
          wmcsfMtx = wmcsfMtx(NUMTRUNC(1)+1:end-NUMTRUNC(2), :);

        else  % if derivatives are required, extracting from raw data, then filter
          if median_wm_csf
            [wm_csf_ts, wm_csf_roi_name] = extract_ROI_timeseries_median(wm_csf_roi_file, temp_dir, 1, ...
              0, pipeline, data_type);
          else
            [wm_csf_ts, wm_csf_roi_name] = extract_ROI_timeseries(wm_csf_roi_file, temp_dir, 1, ...
              0, pipeline, data_type);
          end
          wm_csf_ts = wm_csf_ts';
          diff_wm_csf_ts = diff(wm_csf_ts);

          %- bandpass filter white matter and CSF signals
          if bandpass_include == 1
            wm_csf_ts = bandpass_final_SPM_ts(TR_value, fl_value, fh_value, wm_csf_ts);
            diff_wm_csf_ts = bandpass_final_SPM_ts(TR_value, fl_value, fh_value, diff_wm_csf_ts);
          end

          diff_wm_csf_ts = [repmat(0,1,size(wm_csf_ts, 2)); diff_wm_csf_ts];
          wmcsfMtx = [wm_csf_ts, diff_wm_csf_ts];
          wmcsfMtx = wmcsfMtx(NUMTRUNC(1)+1:end-NUMTRUNC(2), :);
        end
    end
    
    
    %-2.3 movement parameters
    if flag_mov
        rp = dir(fullfile(mvmntdir, 'rp_I*.txt'));
        if ~isempty(rp)
            mvmnt = load(fullfile(mvmntdir, rp(1).name));
        else
            cd(currentdir);
            error(sprintf('Cannot find the movement file: %s \n', subject));
        end
        
        sq_mvmnt = mvmnt.^2;
        diff_mvmnt = diff(mvmnt);
        sq_diff_mvmnt = diff_mvmnt.^2;

        if flag_mov_bpfilter
          mvmnt = bandpass_final_SPM_ts(TR_value, fl_value, fh_value, mvmnt);
          sq_mvmnt = bandpass_final_SPM_ts(TR_value, fl_value, fh_value, sq_mvmnt);
          diff_mvmnt = bandpass_final_SPM_ts(TR_value, fl_value, fh_value, diff_mvmnt);
          sq_diff_mvmnt = bandpass_final_SPM_ts(TR_value, fl_value, fh_value, sq_diff_mvmnt);
        end

        movMtx = [movMtx, mvmnt]; 
        diff_mvmnt = [repmat(0,1,size(diff_mvmnt,2)); diff_mvmnt];
        sq_diff_mvmnt = [repmat(0,1,size(sq_diff_mvmnt,2)); sq_diff_mvmnt];

        if deriord_mov
          switch deriord_mov
            case 1
              movMtx = [movMtx, diff_mvmnt];
            case 2
              movMtx = [movMtx, diff_mvmnt, sq_diff_mvmnt];
            case 3
              movMtx = [movMtx, diff_mvmnt, sq_mvmnt, sq_diff_mvmnt];
          end
        end

        %- Truncate mov parameters
        movMtx = movMtx(NUMTRUNC(1)+1:end-NUMTRUNC(2), :);   
    end
    
    %-Truncate seed and nuisance timeseries, demean and detrend
    all_roi_ts = all_roi_ts(NUMTRUNC(1)+1:end-NUMTRUNC(2), :);
    NumVolsKept = size(all_roi_ts, 1);
    all_roi_ts_dt = spm_detrend(all_roi_ts, detrend_option);
  
    allNuiMtx = [gsMtx wmcsfMtx movMtx];
    allNuiMtx_dt = spm_detrend(allNuiMtx, detrend_option);
    CovMtx = [allNuiMtx_dt ones(NumVolsKept, 1)];
    
    %-Run through multiple ROIs
    for roicnt = 1:numroi
        rts = all_roi_ts_dt(:,roicnt);
        
        %-Step 3------
        %-Regress out nuisance signals from ROI timeseries
        rts = (eye(NumVolsKept) - CovMtx*pinv(CovMtx'*CovMtx)*CovMtx')*rts;
        %-Covariates
        ts  = [rts allNuiMtx];

        reg_ts_dir = fullfile(subject_dir, roi_name{roicnt}, reg_ts_all_folder);
        if ~exist(reg_ts_dir, 'dir')
            mkdir(reg_ts_dir);
        end

        reg_ts_all = fullfile(reg_ts_dir, 'roi_nuisance_ts.txt');
        save(reg_ts_all,'ts','-ascii','-tabs')

        %-STEP 4 --------------------------------------------------------------
        disp('Creating FC directories per subject ............................');
        final_FC_dir = fullfile(subject_dir, roi_name{roicnt},stats_folder);
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
        stats_fmri_fconnect_noscaling(temp_dir, data_type, NUMTRUNC, newpipeline, TR_value);
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
