
% Yuan Zhang edit on 2018-07-05
% 

function ic_wholebrain_fc (SubjectI, ConfigFile)

% Show the system information and write log files
warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('IC - wholebrain connectivity starts at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

%% container
%% spmpreprocscript_path   = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/'; 
%% sprintf('adding SPM based preprocessing scripts path: %s\n', spmpreprocscript_path);
%% addpath(genpath(spmpreprocscript_path));
%spmanalysis_path = '/oak/stanford/groups/menon/projects/yuanzh/2018_test_pipeline/FunctionalConnectivity/Seed_WholeBrain'; 
%sprintf('adding SPM based analysis scripts path: %s\n', spmanalysis_path);
%addpath(genpath(spmanalysis_path));

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
ic_dir = strtrim(paralist.ic_dir);
numtrunc = paralist.numtrunc;

spm_version = strtrim(paralist.spmversion);
% spm version
software_path           = '/oak/stanford/groups/menon/toolboxes/';
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


V_mask = spm_vol('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/masks/whole_brain_mask.nii');
M = spm_read_vols(V_mask);
M = M(:);

for irun = 1:numrun
    %-Step 1: load ic time series
    ic_file = fullfile(ic_dir, 'participants', subject, 'ICN_indiv_TC_rui.txt'); % time points * ICs
    ic_ts = readtable(ic_file);
    ic_ts = table2array(ic_ts(:,1:40)); %time points * IC
    
    ic_ts = ic_ts(numtrunc(1)+1:end-numtrunc(2), :); %-Truncate
    numic = size(ic_ts,2);
    
    %-Step 2: load wholebrain voxelwise time series
    imagedir = fullfile(project_dir,'/data/imaging/participants', subject, ['visit',visit],['session',session], ...
        'fmri', runs{irun}, preprocessed_dir);
    
    disp('----------------------------------------------------------------');
    fprintf('Processing subject: %s \n', subject);
    
     % Create local folder holding temporary data
    temp_dir = fullfile('/scratch/users',getenv('LOGNAME'), subject, ...
    ['visit',visit],['session',session], 'rsfc_tmp_files');

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
    if bandpass_include == 1
        disp('Bandpass filtering data ......................................');
        bandpass_final_SPM(TR_value, fl_value, fh_value, temp_dir, pipeline, data_type);
        disp('Done');
        %-Prefix update for filtered data
        newpipeline = ['filtered', pipeline];
        nifti3Dto4D(temp_dir, newpipeline);
    end


    unix(sprintf('gunzip -fq %s', fullfile(temp_dir, [newpipeline, 'I.nii.gz'])));
    wholeBrain = fullfile(temp_dir, [newpipeline, 'I.nii']);
    V = spm_vol(wholeBrain);
    Y = spm_read_vols(V);
    Y = Y(:,:,:,numtrunc(1)+1:end-numtrunc(2));
    sz = size(Y);
    Y = reshape(Y, [], sz(end));
    %Y_m = Y(find(M~=0),:)'; % time points * voxels
    Y_m = Y'; % time points * voxels


%     unix(sprintf('gzip %s', fullfile(imagedir, [newpipeline, 'I.nii'])));
    
    
    %-Step 3: calculate ic-wholebrain FC and save to participants' folders
    subject_dir = fullfile(project_dir,'results',fmri_type,'participants', ...
                    subject,['visit',visit],['session',session], analysis, runs{irun}, ['stats_', spm_version], 'IC_FC_Maps'); 
    
    if exist(subject_dir,'dir')
        unix(sprintf('rm -rf %s', subject_dir));
    end
    mkdir(subject_dir);
    
    
%     fc_maps = corr(ic_ts,Y_m); % #IC * #voxels
%     fc_maps_z = 0.5*log((1+fc_maps)./(1-fc_maps)); % Fisher z transform
    
    for i=1:numic
        fc_map = corr(ic_ts(:,i),Y_m);
        fc_map_z = 0.5*log((1+fc_map)./(1-fc_map)); % Fisher z transform
        fc_map_z(find(M==0)) = 0;
        
        fc_map_z = reshape(fc_map_z,sz(1),sz(2),sz(3)); % convert back to 3D brain space
        
        vv.fname = fullfile(subject_dir, sprintf('IC_%d_map_z.nii',i));
        vv.dim = V.dim;
        vv.mat = V.mat;
        vv.dt = V.dt;
        vv.n = [1,1];
        vv.descrip = V.descrip;
        
        spm_write_vol(vv,fc_map_z);
    end
    
    % Delete temporary folder
    unix(sprintf('rm -rf %s', temp_dir));
    
    cd(currentdir);
end


c     = fix(clock);
disp('==================================================================');
fprintf('IC - wholebrain Connectivity finishes at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');
clear all;
close all;

end
