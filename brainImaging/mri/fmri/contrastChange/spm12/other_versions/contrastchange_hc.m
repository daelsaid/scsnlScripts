% This script performs contrast change for individual analysis results
% For new data structure 

function contrastchange_hc (Config_File)

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('Individual Contrast Change starts at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
fname = sprintf('contrastchange-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
diary(fname);
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

currentdir = pwd;
addpath(genpath('/oak/stanford/groups/menon/toolboxes/spm8_R3028'));

% -------------------------------------------------------------------------
% Check existence of the configuration file
% -------------------------------------------------------------------------

Config_File = strtrim(Config_File);
if ~exist(Config_File,'file')
  fprintf('Cannot find the configuration file ... \n');
  diary off; 
  return;
end
Config_File = Config_File(1:end-2);
eval(Config_File);
clear Config_File;
% Ignore white space if there is any
participant_path    = strtrim(paralist.stats_server);
subjectlist         = csvread(strtrim(paralist.subjectlist),1);
contrastmat         = strtrim(paralist.contrastmat);
stats_folders = paralist.stats_folder;
%stats_folder        = strtrim(paralist.stats_folder);
template_path       = strtrim(paralist.template_path);
disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

if ~exist(participant_path, 'dir')
  disp('Cannot find the stats_server with individualstats ...');
  diary off; return;
end

if ~exist(contrastmat, 'file')
  fprintf('Cannot find contrast definition file ... \n');
  diary off; return;
end
  
num_subj = size(subjectlist,1);

load(contrastmat);
spm_jobman('initcfg');
delete(get(0,'Children'));

for sf = stats_folders
stats_folder = sf{1};
  for subcnt = 1:num_subj
    PID = num2str(subjectlist(subcnt,1));
    VISIT = num2str(subjectlist(subcnt,2));
    SESSION = num2str(subjectlist(subcnt,3));
    subdir = fullfile(participant_path, PID, ['visit',VISIT], ['session',SESSION], ...
      'glm', 'stats_spm8', stats_folder);
    cd(subdir);
    if exist(contrastmat,'file')
      delete(contrastmat);
    end
    if exist('batch_contrastchange.mat', 'file')
      delete('batch_contrastchange.mat');
    end
    condir = fullfile(currentdir,contrastmat);
    unix(sprintf('/bin/cp -af %s contrasts.mat', condir));
    load(fullfile(template_path, 'batch_contrastchange.mat'));
    matlabbatch{1}.spm.stats.con.spmmat = {};
    matlabbatch{1}.spm.stats.con.spmmat{1} = fullfile(subdir,'SPM.mat');
    matlabbatch{1}.spm.stats.con.delete = 1;
    for i=1:length(contrastNames)
      if (i <= numTContrasts) 
        matlabbatch{1}.spm.stats.con.consess{i}.tcon.name   = contrastNames{i};
        matlabbatch{1}.spm.stats.con.consess{i}.tcon.convec = contrastVecs{i};
      elseif (i > numTContrasts)
        matlabbatch{1}.spm.stats.con.consess{i}.fcon.name = contrastNames{i};
        for j=1:length(contrastVecs{i}(:,1))
          matlabbatch{1}.spm.stats.con.consess{i}.fcon.convec{j} = ...
                                                        contrastVecs{i}(j,:);
        end
      end
    end
    save batch_contrastchange matlabbatch;
    clear matlabbatch;
    spm_jobman('run', './batch_contrastchange.mat');
  end
end

fprintf('Changing back to the directory: %s \n', currentdir);
c     = fix(clock);
disp('==================================================================');
fprintf('Individual Contrast Change finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
cd(currentdir);
diary off;
delete(get(0,'Children'));
clear all;
close all;

end
