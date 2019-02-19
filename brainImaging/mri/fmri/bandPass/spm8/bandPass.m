% Script for bandpass filtering
%
% _________________________________________________________________________
% % Yuan Zhang edit on 2018-04-26
% -------------------------------------------------------------------------

function bandPass (SubjectI, ConfigFile)

% Show the system information and write log files
warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('fMRI resting state band-pass filter starts at %d/%02d/%02d %02d:%02d:%02d\n',c);
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
spmfcscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/bandPass/' spm_version];

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding SPM based band pass filter scripts path: %s\n', spmfcscript_path);
addpath(genpath(spmfcscript_path));


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

TR_value = double(paralist.TR);
fl_value = double(paralist.fl);
fh_value = double(paralist.fh);

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
    imagedir = fullfile(project_dir,'/data/imaging/participants', subject, ['visit',visit],['session',session], ...
        'fmri', runs{irun}, preprocessed_dir);

    disp('----------------------------------------------------------------');
    fprintf('Processing subject: %s \n', imagedir);
    
    % Create local folder holding temporary data
    temp_dir = fullfile(imagedir, 'rsfc_tmp_files');

    if exist(temp_dir,'dir')
        unix(sprintf('rm -rf %s', temp_dir));
    end
    mkdir(temp_dir);
     
    
    cd(imagedir);
    fprintf('Copy files from: %s \n', pwd);
    fprintf('to: %s \n', temp_dir);

    unix(sprintf('cp -af %s %s', [pipeline, 'I.nii*'], temp_dir));

    cd(temp_dir);
    unix(sprintf('gunzip -fq %s %s', [pipeline, 'I.nii.gz']))
    newpipeline = pipeline;

    %-Bandpass filter data if it is set to 'ON'
    disp('Bandpass filtering data ......................................');
    bandpass_final_SPM(TR_value, fl_value, fh_value, temp_dir, pipeline, data_type);
    disp('Done');
    %-Prefix update for filtered data
    newpipeline = ['filtered', pipeline];
    
    nifti3Dto4D(temp_dir, newpipeline);
    unix(sprintf('cp -af %s %s', [newpipeline, 'I.nii.gz'], imagedir));

    cd(imagedir);
    % Delete temporary folder
    unix(sprintf('rm -rf %s', temp_dir));
end

cd(currentdir);

c     = fix(clock);
disp('==================================================================');
fprintf('bandpass filter finishes at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');
clear all;
close all;

end
