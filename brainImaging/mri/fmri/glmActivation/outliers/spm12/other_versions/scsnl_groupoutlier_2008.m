function scsnl_groupoutlier (ConfigFile)
% It is a wrapper of art_groupoutlier by providing list of contrasts and
% other parameters
%__________________________________________________________________________
% 2009-2010 Stanford Cognitive and Systems Neuroscience Laboratory
% Tianwen Chen, 02/02/2010
scsnl_id = '$scsnl_groupoutlier.m r1$';

warning('off', 'MATLAB:FINITE:obsoleteFunction')
disp(['Current directory is: ',pwd]);
c     = fix(clock);
disp('==================================================================');
fprintf('art_groupoutlier starts: %d/%02d/%02d %02d:%02d:%02d\n', c);
disp('==================================================================');
fname = sprintf('scsnl_groupoutlier-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
diary(fname);
fprintf('\n');
fprintf('%s \n', scsnl_id);
fprintf('\n');
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

currentdir = pwd;

% -------------------------------------------------------------------------
% Check existence of the configuration file
% -------------------------------------------------------------------------
    ConfigFile = strtrim(ConfigFile);
%    if ~exist(fullfile(currentdir, ConfigFile), 'file')
%        fprintf('Cannot find the configuration file ... \n');
    %     diary off;
%        return;
%    end
%    ConfigFile = ConfigFile(1:end-2);

      if ~exist(ConfigFile,'file')
          fprintf('Cannot find the configuration file %s ..\n',ConfigFile);
          error('Cannot find the configuration file');
      end
  [ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
    eval(ConfigFile);
    clear ConfigFile;


%-Find and Run the configuration file
%--------------------------------------------------------------------------
%if ~exist(Config_File,'file')
%  fprintf('Cannot find the configuration file ... \n');
%  return;
%end
%Config_File = Config_File(1:end-2);
%eval(Config_File);


%-Read in configuration parameters
%--------------------------------------------------------------------------
server_path  = strtrim(paralist.server_path);
%parent_folder = strtrim(paralist.parent_folder);
subjectlist  = strtrim(paralist.subject_list);
stats_folder = strtrim(paralist.stats_folder);
contrastlist = strtrim(paralist.contrast_list);
pkcon_value  = paralist.pkcon_value;
path_artrepair = strtrim(paralist.art_repair_toolbox);
spm_version = strtrim(paralist.spmversion);
%addpath(genpath(path_artrepair));

% ADD SPM paths
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));

%-Read in subjects and their contrasts
%--------------------------------------------------------------------------
subjects = csvread(subjectlist,1);
numsubj = length(subjects);
contrasts = load(contrastlist);
numcontrast = contrasts.numTContrasts;
stats_folder = stats_folder;
% Currently only configured for one batch of stats folder 
num_stats = 1;%length(stats_folder);

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
    stats_dir{statscnt, subcnt} = fullfile(server_path, 'results','taskfmri','participants',num2str(subjects(subcnt,1)),['visit',num2str(subjects(subcnt,2))],['session',num2str(subjects(subcnt,3))], 'glm','stats_spm12', stats_folder);
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
                               
%-Loop all subjects and contrasts
%--------------------------------------------------------------------------
for concnt = 1:numcontrast
  disp('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
  fprintf('Checking: %s \n', contrasts.contrastNames{concnt});
  disp('----------------------------------------------------------------');
  ConImage = cell(numsubj*num_stats, 1);  
  count = 1;
  for statscnt = 1:num_stats
    for subcnt = 1:numsubj
      disp(stats_dir{statscnt, subcnt})
      disp(['con_000',num2str(concnt),'.img$'])
      ConImage{count} = spm_select('FPList', stats_dir{statscnt, subcnt}, ['con_000',num2str(concnt),'.img$']);
      if isempty(ConImage{count})
        fprintf('Cannot find contrast file: %s in %s \n', contrasts{concnt}, ...
                stats_dir{statscnt, subcnt});
        continue;
      end
      count = count + 1;
    end
  end
  Groupscale(1) = pkcon_value(concnt);
  Groupscale(2) = 1;
  MaskImage = spm_select('FPList', stats_dir{1, 1}, '^mask.*\.img$');
  ScaleFactorX = art_percentscale(ConImage{1}, MaskImage);
  Groupscale(3) = ScaleFactorX(3);
  art_groupoutlier(ConImage, 0, Groupscale, pwd)
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
