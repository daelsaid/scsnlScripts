function scsnl_groupoutlier(ConfigFile)
% It is a wrapper of art_groupoutlier by providing list of contrasts and
% other parameters
%__________________________________________________________________________
% 2009-2010 Stanford Cognitive and Systems Neuroscience Laboratory
% Tianwen Chen, 02/02/2010
% Rui Yuan, 10/18/2018


%paralist = Config_File
%scsnl_id = '$scsnl_groupoutlier.m r1$';

warning('off', 'MATLAB:FINITE:obsoleteFunction')
disp(['Current directory is: ',pwd]);
c     = fix(clock);
disp('==================================================================');
fprintf('art_groupoutlier starts: %d/%02d/%02d %02d:%02d:%02d\n', c);
disp('==================================================================');
fname = sprintf('scsnl_groupoutlier-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
%diary(fname);
fprintf('\n');
fprintf('%s \n', getenv('LOGNAME'));
fprintf('\n');
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

currentdir = pwd;

%-Find and Run the configuration file
%--------------------------------------------------------------------------
ConfigFile = strtrim(ConfigFile);

if ~exist(ConfigFile,'file')
  fprintf('Cannot find the configuration file ... \n');
  return;
end
%Config_File = Config_File(1:end-2);

   [ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
    eval(ConfigFile);
    clear ConfigFile;

%-Read in configuration parameters
%--------------------------------------------------------------------------
spm_version             = strtrim(paralist.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
addpath(genpath('/oak/stanford/groups/menon/toolboxes/ArtRepair'));

%server_path    = strtrim(paralist.server_path);
project_folder  = strtrim(paralist.projectdir);
subjectlist    = strtrim(paralist.subject_list);
stats_folder   = strtrim(paralist.stats_folder);
contrastlist   = strtrim(paralist.contrast_list);
pkcon_value    = paralist.pkcon_value;
output_folder_name = strtrim(paralist.output_folder_name);
%path_artrepair = strtrim(paralist.art_repair_toolbox);
%addpath(genpath(path_artrepair));

%-Read in subjects and their contrasts
%--------------------------------------------------------------------------
subjectlist = csvread(subjectlist,1,0);
numsubj = size(subjectlist,1);
contrasts = load(contrastlist);
numcontrast = contrasts.numTContrasts;
stats_folder = stats_folder;
num_stats = 1;%length(stats_folder);

fprintf('>>>>> the num of contrasts is %d\n ',numcontrast);
%-Make a full matrix for pkcon_value
%--------------------------------------------------------------------------
switch size(pkcon_value,2)
  case 1
    disp('Use a single pkcon_value for all contrasts');
    pkcon_value = repmat(pkcon_value, 1, numcontrast);
  case numcontrast
    disp('Use a distinct pkcon_value for each contrast');
  otherwise
    disp('The number of pkcon_vale is not 1 or the number of contrasts');
    diary off; return;
end
  
%-Contruct paths of each stats folder
%--------------------------------------------------------------------------
stats_dir = cell(num_stats, numsubj);
%if isempty(parent_folder)
  for statscnt = 1:num_stats
    for subcnt = 1:numsubj
        subject           = subjectlist(subcnt,1);
        subject           = char(string(subject));
        subject           = char(pad(string(subject),4,'left','0'));%<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        visit             = num2str(subjectlist(subcnt,2));
        session           = num2str(subjectlist(subcnt,3));
      
      stats_dir{statscnt, subcnt} = fullfile(project_folder, 'results','taskfmri','participants',subject,...
                                      ['visit',visit],['session',session], 'glm', 'stats_spm12', stats_folder);

      fprintf('-----> stats_dir : \n  %s \n',stats_dir{statscnt, subcnt});  
    end
  end
%else
%  for statscnt = 1:num_stats
%    for subcnt = 1:numsubj
%      stats_dir{statscnt, subcnt} = fullfile(server_path, ...
%                                             subjects{subcnt}, 'fmri', ...
%                                             'stats_spm12', stats_folder);
%    end
%  end
%end

%- output path 
%------------------------------------------------------------------------
output_dir = fullfile(project_folder, 'results','taskfmri', 'groupstats', output_folder_name);
if ~exist(output_dir,'dir')
    mkdir(output_dir);
    fprintf('output_dir is %s \n',output_dir);
else
    fprintf('file exists %s \n',output_dir);
end

%------------------------------------------------------------------------
%--- write out fin mask -----------------------
tmp_v_mask = spm_vol(fullfile(stats_dir{1,1},'mask.nii'));
all_mask = zeros(tmp_v_mask.dim);
fin_mask = zeros(tmp_v_mask.dim);

for subcnt = 1: numsubj
    tmp_v_mask = spm_vol(fullfile(stats_dir{1,subcnt},'mask.nii'));
    tmp_mask = spm_read_vols(tmp_v_mask);
    all_mask = tmp_mask+all_mask;
end

fin_mask_index = find(all_mask>0.99*numsubj);
fin_mask(fin_mask_index) = 1;

%tmp_v_mask.fname = fullfile(output_dir,'mean_mask.nii');
%spm_write_vol(tmp_v_mask,all_mask./numsubj);

tmp_v_mask.fname = fullfile(output_dir,'group_mask.nii');
spm_write_vol(tmp_v_mask,fin_mask);
                               
%-Loop all subjects and contrasts
%--------------------------------------------------------------------------
for concnt = 1:numcontrast
  disp('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
  fprintf(' The Name of the contrast: %s \n', contrasts.contrastNames{concnt});
  disp('----------------------------------------------------------------');
  ConImage = cell(numsubj*num_stats, 1);  
  count = 1;
  for statscnt = 1:num_stats
    for subcnt = 1:numsubj
      ConImage{count} = spm_select('FPList', stats_dir{statscnt, subcnt}, ...
                                   ['^', ['con_',sprintf('%04d',concnt)], '.*\.nii']);
      if isempty(ConImage{count})
        fprintf('Cannot find contrast file: %s in %s \n', sprintf('%04d',concnt), ...
                stats_dir{statscnt, subcnt});
        continue;
      end
      count = count + 1;
    end
  end
  ConImage
  Groupscale(1) = pkcon_value(concnt);
  Groupscale(2) = 1;
  MaskImage = fullfile(output_dir,'group_mask.nii');
  %MaskImage = spm_select('FPList', stats_dir{1, 1}, '^mask.*\.nii');
  ScaleFactorX = scsnl_art_percentscale([ConImage{1}], MaskImage);
  Groupscale(3) = ScaleFactorX(3);
  scsnl_art_groupoutlier(ConImage, MaskImage ,Groupscale, output_dir,  contrasts.contrastNames{concnt});
end

%-Change back to the directory from where you started
%--------------------------------------------------------------------------
fprintf('Changing back to the directory: %s \n', currentdir);
c     = fix(clock);
disp('==================================================================');
fprintf('art_groupoutlier ends at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
cd(currentdir);
diary off;
clear all;
close all;

end
