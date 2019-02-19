function rsa_individual (Config_File)

% Compute representational similarity analysis matrix for each individual.
% _________________________________________________________________________
% 2009-2011 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: rsa_individual.m, Tianwen Chen, 2011-08-18, $v1.1$
% v1.1: add ROI names into result files
%       merge subject-wise results
%       covert r to z scores
%       skip averaged results
% -------------------------------------------------------------------------

warning('off', 'MATLAB:FINITE:obsoleteFunction')
disp(['Current directory is: ',pwd]);
c     = fix(clock);
disp('==================================================================');
fprintf(['Individual Representational Similarity Analysis starts ', ...
        '%d/%02d/%02d %02d:%02d:%02d\n'], c);
disp('$scsnl_id: rsa_individual.m, Tianwen Chen, 2011-08-18 v1.1$');
disp('==================================================================');
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

currentdir = pwd;

if ~exist(Config_File,'file')
  error('Cannot find the configuration file ... \n');
  return;
end

config = load(Config_File);
clear Config_File;

% project_dir = strtrim(config.project_dir);
% subjectlist = strtrim(config.roi_dir);
% roi_folder = strtrim(config.roi_dir);
% roilistfile = strtrim(config.roi_list);
% map_type = strtrim(config.map_type);
% map_index = strtrim(config.map_index);
% stats_folder = strtrim(config.stats_dir);
% spm_version = strtrim(config.spm_version);
% analysis_type = strtrim(config.analysis_type);
% modality = strtrim(config.modality);
% marsbar_path = strtrim(config.marsbar_path);
% output_dir = strtrim(config.output_dir);
% user_fname = strtrim(config.user_fname);
% 
% ServerPath   = strtrim(paralist.ServerPath); % Flora added from rsa_wholebrain script
% SubjectList  = strtrim(paralist.SubjectList);
% MapType      = strtrim(paralist.MapType);
% MapIndex     = paralist.MapIndex;
% MaskFile     = strtrim(paralist.MaskFile);
% StatsFolder  = strtrim(paralist.StatsFolder);
% OutputDir    = strtrim(paralist.OutputDir);
% SearchShape  = strtrim(paralist.SearchShape);
% SearchRadius = paralist.SearchRadius;
% SPM_Version  = paralist.spmversion;

%% Flora modified from rsa_individual.m to match paralist names
project_dir = strtrim(paralist.projectdir);
subjectlist = strtrim(paralist.subjectlist);
roi_folder = strtrim(paralist.roi_dir);
roilistfile = strtrim(paralist.roi_list);
map_type = strtrim(paralist.map_type);
map_index = strtrim(paralist.map_index);
stats_folder = strtrim(paralist.stats_dir);
spm_version = paralist.spm_version;
analysis_type = strtrim(paralist.analysis_type);
modality = strtrim(paralist.modality);
marsbar_path = strtrim(paralist.marsbar_path);
output_dir = strtrim(paralist.output_dir);
user_fname = strtrim(paralist.user_fname);

disp('-------------- Contents of the Parameter List --------------------');
disp(config);
disp('------------------------------------------------------------------');
clear config;

if ~exist(roi_folder, 'dir')
  error(sprintf('Folder does not exist: %s \n', roi_folder));
  return;
end

addpath(genpath(marsbar_path));

% Check ROI folder and load ROIs
if isempty(roilistfile)
  files = spm_select('FPList', roi_folder, '.*\.mat$');
  if isempty(files)
    error('ROI folder contains no ROIs');
    cd(currentdir);
    return;
  else
    rois = cell(size(files,1),1);
    for i = 1:size(files,1)
      rois{i} = deblank(files(i,:));
    end
  end
else
  roi_names = ReadList(roilistfile);
  pathstr = fileparts(roi_folder);
  if isempty(pathstr)
    roidir = fullfile(pwd, roi_folder);
  else
    roidir = roi_folder;
  end
  rois = cell(length(roi_names),1);
  for i = 1:length(roi_names)
    rois{i} = fullfile(roidir, roi_names{i});
  end
end

numrois = length(rois);
roi_list = maroi('load_cell', rois);

subjectlist = csvread(subjectlist,1);
numsub = size(subjectlist, 1);

subdir = cell(numsub,1);
subjects = cell(numsub, 1);
visits = cell(numsub, 1);
sessions = cell(numsub, 1);
% Create cell array of paths to spm stats folder
for subcnt = 1:numsub
  subject = subjectlist(subcnt, 1);
  subject = char(pad(string(subject),4,'left','0'));
  visit   = num2str(subjectlist(subcnt, 2));
  session = num2str(subjectlist(subcnt, 3));
  subjects{subcnt} = subject;
  visits{subcnt} = visit;
  sessions{subcnt} = session;
  subdir{subcnt} = fullfile(project_dir, 'results', modality, 'participants', ...
    subject, visit, session, analysis_type, ['stats_', spm_version], stats_folder);
end

% The number of t maps
num_map = numel(map_index);
RSA = struct('SubjectID', {}, 'RSData', {});
% Conditions are the same across sessions
for subcnt = 1:numsub
  disp('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
  fprintf('Processing: PID: %s | Visit: %s | Session: %s \n', ...
    subjects{subcnt}, visits{subcnt}, sessions{subcnt});
  disp('----------------------------------------------------------------');
  if ~exist(subdir{subcnt}, 'dir')
    mkdir(subdir{subcnt});
  end
  RSA(subcnt).PID = subjects{subcnt};
  RSA(subcnt).Visit = visits{subcnt};
  RSA(subcnt).Session = sessions{subcnt}
  load(fullfile(subdir{subcnt}, 'SPM.mat'));
  RSM = struct('roi_name', {}, 'map_names', {}, 'zscore', {}, 'corr', {}, 'euclidean', {});
  map_names = cell(num_map,1);
  MapVols = struct('Vol', {}, 'Name', {});
  for roicnt = 1:numrois
    MapVal = [];
    DRoi = maroi(roi_list{roicnt});
    roi_label = label(DRoi);
    fprintf('Running RSA for ROI: %s \n', roi_label);
    switch lower(map_type)
      case 'tmap'
        for i = 1:num_map
          MapVols(i).Vol = SPM.xCon(map_index(i)).Vspm;
          map_names{i} = SPM.xCon(map_index(i)).name;
        end
      case 'conmap'
        for i = 1:num_map
          MapVols(i).Vol = SPM.xCon(map_index(i)).Vcon;
          map_names{i} = SPM.xCon(map_index(i)).name;
        end
    end
    for map_cnt = 1:num_map
      temp = getdata(DRoi, fullfile(subdir{subcnt}, MapVols(map_cnt).Vol.fname));
      MapVal = [MapVal temp']; %#ok<AGROW>
    end
    corr_val = corr(MapVal);
    eu_val = squareform(pdist(MapVal'));
    RSM(roicnt).roi_name = roi_label;
    RSM(roicnt).map_names = map_names;
    RSM(roicnt).corr = corr_val;
    RSM(roicnt).zscore = 0.5.*log((1+RSM(roicnt).corr)./(1-RSM(roicnt).corr));
    RSM(roicnt).euclidean = eu_val;
    fprintf('.................Done \n');
  end
  clear SPM;
  %-All subjects data
  RSA(subcnt).RSData = RSM;
end

clear MapVal;

if ~exist(output_dir, 'dir');
  mkdir(output_dir);
end

if isempty(user_fname)
  individual_fname = [lower(map_type), '_IndividualRSA'];
else
  individual_fname = [user_fname, '_', lower(map_type), '_IndividualRSA'];
end
fprintf('Saving individual RSA ......\n');
save(fullfile(output_dir, [individual_fname, '.mat']), 'RSA');
writeIndividualRSA(output_dir, [individual_fname, '_zscore.txt'], RSA, 'zscore');
writeIndividualRSA(output_dir, [individual_fname, '_corr.txt'], RSA, 'corr');
writeIndividualRSA(output_dir, [individual_fname, '_euclidean.txt'], RSA, 'euclidean');

%--------------------------------------------------------------------------

disp('-----------------------------------------------------------------');
fprintf('Changing back to the directory: %s \n', currentdir);
cd(currentdir);
c     = fix(clock);
disp('==================================================================');
fprintf('Individual Representational Similarity Analysis finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
clear all;
close all;

end