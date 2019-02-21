function export_spmresults (Config_File)
%
%-Extract results from SPM.mat after thresholding and save relevant
%-informations into a txt file
%
%-Change Log:
%- Initially designed for extracting group stats info
%- Correct empty mask error
% _________________________________________________________________________
% 2009-2012 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: export_spmresults.m 2012-03-19 $
% edited by LC 2019-02-20
% for single folder with multiple self-defined contrasts
% -------------------------------------------------------------------------

%LC added lab-written scripts
out_path = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/utilities/';
sprintf('adding required scripts to output spmresults: %s\n', out_path);
addpath(genpath(out_path));

scsnl_id = '$scsnl_id: export_spmresults.m 2010-11-04 v2 $';

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('Exporting SPM results started at %d/%02d/%02d %02d:%02d:%02d\n',c);
fprintf('%s \n', scsnl_id);
disp('==================================================================');
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

%current_dir = strtrim(paralist.currentdir); %pwd;

[ConfigFilePath, Config_File, ConfigFileExt] = fileparts(Config_File);

if ~exist(Config_File,'file')
  fprintf('Cannot find the configuration file ... \n');
  return;
end

% Make it a function name by dropping '.m'
%Config_File = Config_File(1:end-2);
eval(Config_File);
clear Config_File;

%HC added SPM toolbox to matlab search path
spm_version             = strtrim(paralist.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path)); 

%-Load configurations
%--------------------------------------------------------------------------
current_dir = strtrim(paralist.currentdir);
stats_list = strtrim(paralist.stats_folder_path_list);
contrast_list = strtrim(paralist.contrast_folder_list);
contrast_index = paralist.contrast_index;
mask_file = strtrim(paralist.mask_file);
multiple_correction = strtrim(paralist.multiple_correction);
pval = paralist.pval;
spatial_extent = paralist.spatial_extent;
user_input = strtrim(paralist.user_input);
NumMax = paralist.NumMax;
DisMax = paralist.DisMax;

disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

%-Add a fullpath to mask file
%--------------------------------------------------------------------------
if ~isempty(mask_file)
  [pathstr, maskfname] = fileparts(mask_file);
  if isempty(pathstr)
    mask_file = fullfile(current_dir, mask_file);
  end
end

%-Contrast folders
%--------------------------------------------------------------------------
if isempty(stats_list)
  stats_folder{1} = current_dir;
else
  stats_folder = ReadList(stats_list);
end
nstats_folder = length(stats_folder);
contrast_folder = ReadList(contrast_list);
ncontrast_folder = length(contrast_folder);
nstats = nstats_folder * ncontrast_folder;
stats_dir = cell(nstats, 1);
cnt = 1;
for i = 1:nstats_folder
  for j = 1:ncontrast_folder
    stats_dir{cnt} = fullfile(current_dir,stats_folder{i}, contrast_folder{j});
    cnt = cnt + 1;
  end
end

%-Threshold information
%--------------------------------------------------------------------------
threshold_info.method = multiple_correction;
threshold_info.u = pval;
threshold_info.k = spatial_extent;

%-Contrast index and names
%--------------------------------------------------------------------------
%get the contrast info
% loop through the SPM file to find all defined contrasts
spm_file = fullfile(stats_dir{i}, 'SPM.mat');
load(spm_file)
if isempty(contrast_index)
  contrast_index = 1:length(SPM.xCon);
  contrast_types ={};
  % use the contrast name as the file name
  for i = 1:length(SPM.xCon)
       contrast_types {i} = SPM.xCon(i).name;
  end
elseif contrast_index == 1
  contrast_types = {'pos'};
elseif contrast_index == 2
  contrast_types = {'neg'};
else
  error('Contrast index is not correct');
end

%-Correction method
%--------------------------------------------------------------------------
if strcmpi(multiple_correction, 'none')
  cm = 'unc';
else
  cm = lower(multiple_correction);
end
pvalstr = num2str(pval);
pvalstr = pvalstr(2:end);

%-Loop through all SPM.mat
%--------------------------------------------------------------------------
for i = 1:nstats
  cd(stats_dir{i});
  spm_file = fullfile(stats_dir{i}, 'SPM.mat');
  fprintf('Processing: %s \n', stats_dir{i});
  if ~exist(spm_file, 'file')
    fprintf('No SPM.mat exists! \n');
    continue;
  end
  [pathstr, contrast_fname] = fileparts(stats_dir{i});
  ncontrast = length(contrast_index);
  file_dir = fileparts(spm_file);
  for iconst = 1:ncontrast
    fname = [user_input, '_', contrast_fname, '_', contrast_types{iconst}, ...           
      '_', 'p_', cm, pvalstr, '_', num2str(spatial_extent), 'vox'];
    [TabData xSPM] = get_xspm_hc(spm_file, contrast_index(iconst), ...
      threshold_info, mask_file, NumMax, DisMax);
    Vo = write_thresholded_img(xSPM.Z, xSPM.XYZ, xSPM.DIM, xSPM.M,...
      fname, fullfile([fname, '.nii']));
    file_name = fullfile([fname, '.txt']);
    PrintData(TabData, file_name);
    clear SPM xSPM Vo;
  end
  cd(current_dir);
  disp('----------------------------------------------------------------');
end

cd(current_dir);
disp('==================================================================');
c = fix(clock);
fprintf('Exporting SPM results finished at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');

end

%
%stats_dir{i},
%file_dir, 