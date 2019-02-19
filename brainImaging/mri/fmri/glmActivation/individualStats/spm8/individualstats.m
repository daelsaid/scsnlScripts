% This script performs individual fMRI analysis
% It first loads configuration file containing individual stats parameters
%  
% This scripts are compatible with both Analyze and NIFTI formats
% To use either format, change the data type in individualstats_config.m
%
% To run individual fMRI analysis, type at Matlab command line: 
% >> individualstats('individualstats_config.m')
% 
% _________________________________________________________________________
% 2009-2012 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: individualstats.m 2012-06-06 $
% Yuan Zhang, 2018-02-08,  edited for better compatibility with vsochat
% -------------------------------------------------------------------------


function individualstats(SubjectI, ConfigFile)

% % container
% spmpreprocscript_path   = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/'; %'/oak/stanford/groups/menon/scsnlscripts_vsochat/fmri/spm/spm8/preprocessing/';
% sprintf('adding SPM based preprocessing scripts path: %s\n', spmpreprocscript_path);
% addpath(genpath(spmpreprocscript_path));
% spmanalysis_path = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/glmActivation/individualStats/spm8/'; %'/oak/stanford/groups/menon/scsnlscripts_vsochat/fmri/spm/spm8/analysis/';
% sprintf('adding SPM based analysis scripts path: %s\n', spmanalysis_path);
% addpath(genpath(spmanalysis_path));

global currentdir idata_type run_img;
currentdir = pwd;

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('fMRI IndividualStats start at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
%fname = sprintf('individualstats-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
%diary(fname);
disp(['Current directory is: ',currentdir]);
fprintf('Script: %s\n', which('individualstats.m'));
fprintf('Configfile: %s\n', ConfigFile);
fprintf('\n')
disp('------------------------------------------------------------------');


% -------------------------------------------------------------------------
% Check existence of the configuration file
% -------------------------------------------------------------------------
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
spmindvstatsscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/glmActivation/individualStats/' spm_version];

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding SPM based individual stats scripts path: %s\n', spmindvstatsscript_path);
addpath(genpath(spmindvstatsscript_path));


% -------------------------------------------------------------------------
% Read individual stats parameters
% -------------------------------------------------------------------------
% Ignore white space if there is any
subject_i          = SubjectI;
subjectlist        = strtrim(paralist.subjectlist);
runlist            = strtrim(paralist.runlist);
idata_type         = strtrim(paralist.data_type);
include_mvmnt       = paralist.include_mvmnt;
pipeline           = strtrim(paralist.pipeline);

include_artrepair   = paralist.include_volrepair;
artpipeline        = strtrim(paralist.volpipeline);
repaired_folder     = strtrim(paralist.volrepaired_folder);
repaired_stats      = strtrim(paralist.repaired_stats);

% raw_dir            = strtrim(paralist.rawdir);
project_dir        = strtrim(paralist.projectdir);
preprocessed_folder = strtrim(paralist.preprocessed_folder);
stats_folder        = strtrim(paralist.stats_folder);
task_dsgn           = strtrim(paralist.task_dsgn);
contrastmat         = strtrim(paralist.contrastmat);
template_path      = strtrim(paralist.batchtemplatepath);
TR                 = double(paralist.TR);


disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

if ~exist(template_path,'dir')
  disp('Template folder does not exist!');
  return;
end

% -------------------------------------------------------------------------
% Read in subjects and sessions
% Get the subjects, sesses in cell array format
subjectlist       = csvread(subjectlist,1);
subject           = subjectlist(subject_i);
%subject           = char(pad(string(subject),4,'left','0'));
subject     =  sprintf('%04d',subject);
visit             = num2str(subjectlist(subject_i,2));
session           = num2str(subjectlist(subject_i,3));

numsub           = 1;
runs              = ReadList(runlist);
numrun            = length(runs);

if isempty(contrastmat) && (numrun > 1)
  disp('Contrastmat file is not specified for more than two runs.');
%   diary off; 
  return;
end

% -------------------------------------------------------------------------
% Start Individual Stats Processing
% -------------------------------------------------------------------------
for subcnt = 1:numsub
  fprintf('Processing Subject: %s \n',subject);
  disp('--------------------------------------------------------------');
  sub_dir = fullfile(project_dir, '/results/taskfmri/participants', subject, ['visit',visit],['session',session],'glm');
  sub_stats_dir = fullfile(sub_dir, ['stats_', spm_version], stats_folder);
  
  % Create stats folder.
  fprintf('Creating the directory: %s \n', sub_stats_dir);
  mkdir(sub_stats_dir);
  
  % Change to stats folder
  fprintf('Changing to directory: %s \n', sub_stats_dir);
  cd (sub_stats_dir);
  
  % If stats folder contains SPM.mat file and others, they will be deleted
  if exist('SPM.mat', 'file')
    disp('The stats directory contains SPM.mat. It will be deleted.');
    unix('/bin/rm -rf *');
  end
  
  run_img = cell(numrun,1);
  run_raw_dir = cell(numrun,1);
  
  % In the stats folder
  for irun = 1:numrun
     % run folder (preprocessed)
     run_raw_dir{irun} = fullfile(project_dir, '/data/imaging/participants/', subject, ...
                        ['visit',visit], ['session',session], 'fmri', runs{irun});
    % run_img: directory of subject/run in stats server
    run_img{irun} = fullfile(run_raw_dir{irun}, preprocessed_folder);
    run_img_dir = run_img{irun};

%     % If there is a ".m" at the end remove it.
%     if(~isempty(regexp(task_dsgn, '\.m$', 'once' )))
%       task_dsgn = task_dsgn(1:end-2);
%     end
    
    % Load task_design file 
    addpath(fullfile(run_raw_dir{irun}, 'task_design'));
    str = which(task_dsgn);
    if isempty(str)
       disp('Cannot find task design file in task_design folder.');
       cd(currentdir);
%        diary off; 
       return;
    end
    
    [filepath,name,ext] = fileparts(task_dsgn);
    if(strcmp(ext,'.mat'))
        load(str);
    else
        fprintf('task design file type should be *.mat');
    end
        rmpath(fullfile(run_raw_dir{irun}, 'task_design'));
    
%     if(strcmp(ext,''))
%         fprintf('Running the task design file: %s \n',str);
%         eval(task_dsgn);
%     elseif(strcmp(ext,'.mat'))
%         load(str);
%     else
%         fprintf('Wrong task design file');
%     end

    
    % Check the existence of preprocessed folder
    if ~exist(run_img_dir, 'dir')
      fprintf('Cannot find %s \n', run_img_dir);
      cd(currentdir);
%       diary off; 
      return;
    end
    % Unzip files if needed
    unix(sprintf('gunzip -fq %s', fullfile(run_img_dir, ...
                 [pipeline, 'I.nii.gz'])));

    % Update the design with the movement covariates
    if(include_mvmnt == 1)       
%       load task_design
      reg_file = spm_select('FPList', run_img_dir, '^rp_I');
      unix(sprintf('gunzip -fq %s', reg_file));
      reg_file = spm_select('FPList', run_img_dir, '^rp_I');
      if isempty(reg_file)
          disp('Cannot find the movement files');
          cd(currentdir);
%           diary off; 
          return;
      end
      % Regressor names, ordered according regressor file structure
      reg_names = {'movement_x','movement_y','movement_z','movement_xr','movement_yr','movement_zr'}; 
      % 0 if regressor of no interest, 1 if regressor of interest
      reg_vec   = [0 0 0 0 0 0];
      disp('Updating the task design with movement covariates');     
      save task_design.mat sess_name names onsets durations rest_exists reg_file reg_names reg_vec
    end
    
    if(numrun > 1)
      % Rename the task design file
      newtaskdesign = ['task_design_run' num2str(irun) '.mat'];
      movefile('task_design.mat', newtaskdesign);
    end
    % clear the variables used in input task_design.m file
    clear sess_name names onsets durations rest_exists reg_file reg_names reg_vec
  end
  
  %---------------------------------------------------------------------
  % Get the contrast file
  %[pathstr, contrast_fname, contrast_fext, versn] = fileparts(contrastmat);
  [pathstr, contrast_fname, contrast_fext] = fileparts(contrastmat);
  
  if(isempty(pathstr) && ~isempty(contrast_fname))
    contrastmat = [currentdir '/' contrastmat];
  end
  
  cd(sub_stats_dir);
  foname    = cell(1,2);
  foname{1} = template_path;
  foname{2} = preprocessed_folder;
  % Call the N session batch script
  individualfmri(pipeline, numrun, contrastmat,foname, TR);
  
  % Redo analysis using ArtRepaired images and deweighting
  if include_artrepair == 1
    repaired_folder_dir = cell(numrun, 1);
    for scnt = 1:numrun
      repaired_folder_dir{scnt} = fullfile(run_raw_dir{scnt}, ...
                                           repaired_folder);
      unix(sprintf('gunzip -fq %s', fullfile(repaired_folder_dir{scnt}, ...
                     '*.txt.gz')));
      unix(sprintf('gunzip -fq %s', fullfile(repaired_folder_dir{scnt}, ...
                     [artpipeline,'I*'])));
    end
    repaired_stats_dir = fullfile(sub_dir, ['stats_', spm_version], repaired_stats);
    if exist(repaired_stats_dir, 'dir')
      disp('------------------------------------------------------------');
      fprintf('%s already exists! Get deleted \n', repaired_stats_dir);
      disp('------------------------------------------------------------');
      unix(sprintf('/bin/rm -rf %s', repaired_stats_dir));
    end
    mkdir(repaired_stats_dir);
    scsnl_art_redo(sub_stats_dir, artpipeline, repaired_stats_dir, ...
                   repaired_folder_dir);
    % copy contrasts.mat, task_design, batch_stats
    unix(sprintf('/bin/cp -af %s %s', fullfile(sub_stats_dir, ['contrasts', '*']), ...
                 repaired_stats_dir));
    unix(sprintf('/bin/cp -af %s %s', fullfile(sub_stats_dir, ['task_design', '*']), ...
                 repaired_stats_dir));
    unix(sprintf('/bin/cp -af %s %s', fullfile(sub_stats_dir, 'batch_stats*'), ...
                 repaired_stats_dir));
    % remove temporary stats
    unix(sprintf('/bin/rm -rf %s', sub_stats_dir));
    for scnt = 1:numrun
      unix(sprintf('gzip -fq %s', fullfile(repaired_folder_dir{scnt}, ...
                 [artpipeline,'I*'])));
    end
  end

end

% Change back to the directory from where you started.
fprintf('Changing back to the directory: %s \n', currentdir);
c     = fix(clock);
disp('==================================================================');
fprintf('fMRI Individual Stats finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
cd(currentdir);
% diary off;
delete(get(0,'Children'));
clear all;
close all;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% individualfmri is called by invidualstats.m to creates individual fMRI
% model.
% It updates batch file with model specification, estimation and contrasts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function individualfmri (pipeline,numsess,contrastmat,foname,TR)

% -------------------------------------------------------------------------
% Initialization
% -------------------------------------------------------------------------
spm('defaults', 'fmri');
global idata_type run_img;

% Subject statistics folder
statsdir = pwd;
template_path = foname{1};

% -----------------------------------------------------------------------------
% fMRI design specification
% -----------------------------------------------------------------------------
load(fullfile(template_path,'batch_stats.mat'));

%% Get TR value: initialized to 2 but will be update by calling GetTR.m
%% TR = 2;
display('------- please check TR  TR  TR  ! --------------');
fprintf('>>>>> TR is %d  \n',TR);
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR; 
% Initializing scans
matlabbatch{1}.spm.stats.fmri_spec.sess(1).scans = {};

for sess = 1:numsess
  % Set preprocessed folder
  datadir = run_img{sess};
    
  %------------------------------------------------------------------------
  % Check the data type
  if isempty(idata_type)
    fselect = spm_select('List',datadir,['^',pipeline,'I']);
    [strpath, fname, fext] = fileparts(fselect(1,:));
    if ismember(fext, {'.img', '.hdr'})
      data_type = 'img';
    else
      data_type = 'nii';
    end
  else
    data_type = idata_type;
  end
  %------------------------------------------------------------------------
  
  switch data_type
    case 'img'
      error('IMG is not supported. Please convert to 4D nifti.');           
    case 'nii'
      
      nifti_file = spm_select('ExtFPList', datadir, ['^',pipeline,'I.nii']);
      V       = spm_vol(deblank(nifti_file));
      nframes = V(1).private.dat.dim(4);
      files = spm_select('ExtFPList', datadir, ['^',pipeline,'I.nii'],1:nframes);
      nscans = size(files,1);
      clear nifti_file V nframes;
  end
  
  matlabbatch{1}.spm.stats.fmri_spec.sess(sess) = ...
                                matlabbatch{1}.spm.stats.fmri_spec.sess(1);
  matlabbatch{1}.spm.stats.fmri_spec.sess(sess).scans = {};

  % Input preprocessed images
  for nthfile = 1:nscans
    matlabbatch{1}.spm.stats.fmri_spec.sess(sess).scans{nthfile} = ...
      deblank(files(nthfile,:)); 
  end

  
  if(numsess == 1)
    taskdesign_file = fullfile(statsdir, 'task_design.mat');
  else
    taskdesign_file = sprintf('%s/task_design_run%d.mat', statsdir, sess);
  end
  
  reg_file = '';
  load(taskdesign_file);
  matlabbatch{1}.spm.stats.fmri_spec.sess(sess).multi{1}  = taskdesign_file;  
  matlabbatch{1}.spm.stats.fmri_spec.sess(sess).multi_reg = {reg_file};
  
end
matlabbatch{1}.spm.stats.fmri_spec.dir{1} = statsdir;

%--------------------------------------------------------------------------
% Estimation Setup
%--------------------------------------------------------------------------
matlabbatch{2}.spm.stats.fmri_est.spmmat{1} = strcat(statsdir,'/SPM.mat'); 

%--------------------------------------------------------------------------
% Contrast Setup
%--------------------------------------------------------------------------
matlabbatch{3}.spm.stats.con.spmmat{1} = strcat(statsdir,'/SPM.mat'); 

% Built the standard contrats only if the number of sessions is one
% else use the user provided contrast file
if isempty(contrastmat)
  if (numsess >1 )
    disp(['The number of session is more than 1, No automatic contrast' ...
          ' generation option allowed, please spcify the contrast file']);
%     diary off; 
    return;
  else
    build_contrasts(matlabbatch{1}.spm.stats.fmri_spec.sess);
  end
else
  copyfile(contrastmat, './contrasts.mat');
end

load contrasts.mat;

for i=1:length(contrastNames)
  if (i <= numTContrasts)
    matlabbatch{3}.spm.stats.con.consess{i}.tcon.name   = contrastNames{i};
    matlabbatch{3}.spm.stats.con.consess{i}.tcon.convec = contrastVecs{i};
  elseif (i > numTContrasts)
    matlabbatch{3}.spm.stats.con.consess{i}.fcon.name = contrastNames{i};
    for j=1:length(contrastVecs{i}(:,1))
      matlabbatch{3}.spm.stats.con.consess{i}.fcon.convec{j} = ...
	  contrastVecs{i}(j,:);
    end
  end
end

save batch_stats matlabbatch
% Initialize the batch system
spm_jobman('initcfg');
delete(get(0,'Children'));
% Run analysis
spm_jobman('run', './batch_stats.mat');

for sess = 1:numsess
  % Set scan data and stats directory
  datadir = run_img{sess}; 
  unix(sprintf('gzip -fq %s', fullfile(datadir, [pipeline, 'I.nii'])));
end

end
