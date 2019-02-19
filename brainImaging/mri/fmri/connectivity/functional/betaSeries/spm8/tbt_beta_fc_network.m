%----Functional connectivity network constructed based on beta series------
%----Yuan Zhang edit on 2018-06-05----
%----Yuan Zhang test on 2018-06-11----

function tbt_beta_fc_network(SubjectI, ConfigFile)

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('Trial-by-Trial Beta Series Task Connectivity starts at %d/%02d/%02d %02d:%02d:%02d\n',c);
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
roi_dir = paralist.roi_dir;
roi_names = paralist.roi_names;
task_names = paralist.task_names;
mask_file = paralist.mask_file;
tbt_spm_data_dir = paralist.tbt_spm_data_dir;
result_dir = paralist.result_dir;
result_fname = paralist.result_fname;


disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;


% Read in subjects and sessions
% Get the subjects, sesses in cell array format
subjectlist       = csvread(subjectlist,1);
subject           = subjectlist(subject_i);
subject           =  sprintf('%04d',subject);
visit             = num2str(subjectlist(subject_i,2));
session           = num2str(subjectlist(subject_i,3));

numsub           = 1;

roi_names = ReadList(roi_names);
num_roi = length(roi_names);
num_task = length(task_names);
roi_index = cell(num_roi, 1);

mask_index = spm_read_vols(spm_vol(mask_file));
mask_index = find(mask_index ~= 0);

for iroi = 1:num_roi
  %roi_index_tmp = spm_read_vols(spm_vol(fullfile(roi_dir, [roi_names{iroi}, '.nii'])));
  roi_index_tmp = spm_read_vols(spm_vol(fullfile(roi_dir, roi_names{iroi})));
  roi_index_tmp = find(roi_index_tmp ~= 0);
  roi_index{iroi} = roi_index_tmp;
end

if ~exist(result_dir, 'dir')
  mkdir(result_dir);
end

%------------------------
C = {};
P = {};

for isubj = 1:numsub
  
  fprintf('processing subject %s\n\n', subject);
  
  subj_tbt_spm_dir = fullfile(tbt_spm_data_dir, subject, ['visit',visit],['session',session],'fmri',['stats_', spm_version]);
  cd(subj_tbt_spm_dir);
  load(fullfile(subj_tbt_spm_dir, 'SPM.mat'));
  col_names = SPM.xX.name;
  
  subj_mask_index = spm_read_vols(spm_vol(fullfile(subj_tbt_spm_dir, 'mask.img')));
  subj_mask_index = find(subj_mask_index ~= 0);
  subj_mask_index = intersect(subj_mask_index, mask_index);
  
  for iroi = 1:num_roi
    roi_index{iroi} = intersect(roi_index{iroi}, subj_mask_index);
  end
  
  num_sess = length(SPM.Sess);
  
  for itask = 1:num_task
    roi_task_betas = [];
    %task_whole_brain_betas = [];
    for isess = 1:num_sess
      iG_exp = ['^Sn\(', num2str(isess), ').', task_names{itask}];
      iG_match = regexpi(col_names, iG_exp);
      iG_match = ~cellfun(@isempty, iG_match);
      if sum(iG_match) == 0
        error('confound columns are not well defined or found');
      else
        iG = find(iG_match == 1);
      end
      
      task_beta_img_v = SPM.Vbeta(iG);
      task_beta_d = spm_read_vols(task_beta_img_v);
      img_dim = size(task_beta_d);
      task_beta_d = reshape(task_beta_d, prod(img_dim(1:3)), img_dim(4));
      task_beta_d = task_beta_d';
      
      roi_beta = [];     
      for iroi = 1:num_roi
        roi_beta = [roi_beta, mean(task_beta_d(:, roi_index{iroi}), 2)];
      end
      
      roi_beta = roi_beta - repmat(mean(roi_beta, 1), size(roi_beta, 1), 1);      
      roi_task_betas = [roi_task_betas; roi_beta];
      
    end
    
    roi_task_betas = roi_task_betas - repmat(mean(roi_task_betas, 1), size(roi_task_betas, 1), 1);
    roi_beta_series{itask} = roi_task_betas; 
    
    %network_cov_mtx = roi_task_betas'*roi_task_betas./(size(roi_task_betas,1)-1);    
    %roi_var = std(roi_task_betas);
    %network_var = roi_var'*roi_var;
    %network_R = network_cov_mtx./network_var;   
    [task_network_R, task_network_P] = corr(roi_task_betas);
    task_network_Z = 0.5*log((1+task_network_R)./(1-task_network_R));
    
    C{itask} = task_network_Z;
    P{itask} = task_network_P;
  end
  clear SPM;
  save(fullfile(result_dir,[result_fname,'_',subject,'.mat']),'C', 'P', 'roi_names','roi_beta_series');
end

cd(currentdir)

disp('==================================================================');
disp('Trial-by-Trial Beta Series Task Connectivity finished!');
