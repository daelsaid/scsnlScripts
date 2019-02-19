% This script performs contrast change for individual analysis results
% For new data structure
% _________________________________________________________________________
% 2009-2010 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: contrastchange.m 2010-09-24 $
% -------------------------------------------------------------------------

function contrastchange_multi(subject_i,ConfigFile)

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('Individual Contrast Change Multi starts at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
% fname = sprintf('contrastchange_multi-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
% diary(fname);
% disp(['Current directory is: ',pwd]);
% disp('------------------------------------------------------------------');

currentdir = pwd;

% -------------------------------------------------------------------------
% Check existence of the configuration file
% -------------------------------------------------------------------------

ConfigFile = strtrim(ConfigFile);
if ~exist(ConfigFile,'file')
    fprintf('Cannot find the configuration file ... \n');
    diary off;
    return;
end
% Config_File = Config_File(1:end-2);
% eval(Config_File);
% clear Config_File;
 [ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
    eval(ConfigFile);
    clear ConfigFile;

spm_version             = strtrim(paralist.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);

%Common_scripts_path = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/preprocessing/spm12/utils/';
%spm_version = 'spm12';
Common_scripts_path = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/',spm_version,'/utils/');
fprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
addpath(genpath(Common_scripts_path));



% Ignore white space if there is any
participant_path    = strtrim(paralist.participant_path);
%subjectlist         = strtrim(paralist.subjectlist);
subjectlist = csvread(paralist.subjectlist,1);
contrastmat         = strtrim(paralist.contrastmat);
stats_folder_list   = paralist.stats_folder;
template_path       = strtrim(paralist.template_path);
disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

if ~exist(participant_path, 'dir')
    disp('Cannot find the stats_server with individualstats ...');
    %diary off; 
    return;
end

if ~exist(contrastmat, 'file')
    fprintf('Cannot find contrast definition file ... \n');
    %diary off; 
    return;
end

 numsub =  1; 
%numsub = size(subjectlist,1);

load(contrastmat);
spm_jobman('initcfg');
delete(get(0,'Children'));

for k = 1:length(stats_folder_list)
    stats_folder = stats_folder_list{k} ;
    for subcnt = 1:numsub
        %year_id = ['20', subjects{subcnt}(1:2)];
        %subdir = fullfile(participant_path, year_id, subjects{subcnt}, ...
        %  'fmri', 'stats_spm8', stats_folder{1});
        subject           = subjectlist(subject_i);
        subject           = char(pad(string(subject),4,'left','0'));
        visit             = num2str(subjectlist(subject_i,2));
        session           = num2str(subjectlist(subject_i,3));
        
        subdir = fullfile(participant_path, subject, ['visit', visit], ['session', session], 'glm', ['stats_', spm_version], stats_folder);
        fprintf('subdir is %s \n',subdir);
        cd(subdir);
        if exist(contrastmat,'file')
            delete(contrastmat);
        end
        if exist('batch_contrastchange.mat', 'file')
            delete('batch_contrastchange.mat');
        end
        condir = fullfile(currentdir,contrastmat);
        fprintf('condir is %s \n',condir);
        
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
%diary off;
delete(get(0,'Children'));
clear all;
close all;

end
