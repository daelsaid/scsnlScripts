% This script performs contrast change for individual analysis results
% For new data structure
% _________________________________________________________________________
% 2009-2010 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: contrastchange.m 2010-09-24 $
% -------------------------------------------------------------------------

function contrastchange_extract_PNC(subject_i,ConfigFile)

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('Individual Contrast Change Multi starts at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');

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

 [ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
    eval(ConfigFile);
    clear ConfigFile;

spm_version             = strtrim(paralist.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
template_path  = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/',spm_version,'/preprocessfmrimodules/batchtemplates');

Common_scripts_path = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/',spm_version,'/utils/');
fprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
addpath(genpath(Common_scripts_path));

% Ignore white space if there is any
roi_name = ReadList(paralist.roi_name_list); %%
num_roi_name = length(roi_name); %%
roi_file = ReadList(paralist.roi_file_list);
num_roi_file = length(roi_file);
data_server = strtrim(paralist.projectdir); %%
result_dir = strtrim(paralist.result_dir);

subjectlist = csvread(paralist.subjectlist,1);
contrastmat         = strtrim(paralist.contrastmat);
stats_folder   = paralist.stats_folder;
% % template_path       = strtrim(paralist.template_path);
disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;


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

for subcnt = 1:numsub
    subject           = subjectlist(subject_i);
    subject           = char(pad(string(subject),2,'left','0'));
    visit             = num2str(subjectlist(subject_i,2));
    session           = num2str(subjectlist(subject_i,3));
    
    for k = 1:num_roi_name 
        subject_stats_dir = fullfile(data_server, '/results/taskfmri/participants',...
                            sprintf('%s',subject), ['visit',visit],['session',session],'glm', ['stats_', spm_version],...
                            [stats_folder, '_gPPI'], ['PPI_', roi_name{k}]);
                        
        fprintf('------> subject_stats_dir : %s \n',subject_stats_dir);
        fprintf('------> processing ROI#%d : %s \n', k, roi_name{k});
        
        cd(subject_stats_dir);
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
        matlabbatch{1}.spm.stats.con.spmmat{1} = fullfile(subject_stats_dir,'SPM.mat');
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
    
    fprintf('Changing back to the directory: %s \n', currentdir);
    c     = fix(clock);
    disp('==================================================================');
    fprintf('Individual Contrast Change finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
    disp('==================================================================');
    cd(currentdir);
    %diary off;
    delete(get(0,'Children'));
    
    c = fix(clock);
    disp('==================================================================');
    fprintf('Extract gPPI ROI stats starts at %d/%02d/%02d %02d:%02d:%02d \n',c);
    disp('==================================================================');

    target_roi_file = roi_file;
    num_target_roi  = length(target_roi_file);   

    load(fullfile(currentdir,contrastmat));   
    fprintf('>>>>> there are %d contrasts to extract \n',length(contrastNames)/2);
    
    if  length(contrastNames)> numTContrasts
       fprintf('------- There are %d T contrasts, and %d F contrasts  \n',numTContrasts,length(contrastNames)-numTContrasts);
    end
    
    if ~exist(result_dir, 'dir')
            mkdir(result_dir);
    end
    
    gPPI_matrix_allcons = zeros(num_roi_file,num_target_roi,length(contrastNames)/2); 
    gPPI_matrix_allcons_sym = zeros(num_roi_file,num_target_roi,length(contrastNames)/2); 
    cons_name = {};
    
    for nCon = 1:2:length(contrastNames)
         fprintf('>>> contrast %d (%s) \n',nCon, contrastNames{nCon});
         roi_stats_matrix = zeros(num_roi_file,num_target_roi);
         for j = 1:num_roi_file
            subdir = fullfile(data_server, '/results/taskfmri/participants',...
                            sprintf('%s',subject), ['visit',visit],['session',session],'glm', ['stats_', spm_version],...
                            [stats_folder, '_gPPI'], ['PPI_', roi_name{j}]);
            cd(subdir);
            fprintf('>>> seed#%d (%s) \n',j,roi_name{j});
        
            roi_stats_file = fullfile(subdir, ['con_',sprintf('%04d',nCon),'.img']);
            roi_stats = spm_read_vols(spm_vol(roi_stats_file));
            roi_stats = roi_stats(:); %%   

            for k = 1:num_target_roi
                target_roi_d = spm_read_vols(spm_vol(target_roi_file{k}));
                target_vox_idx = find(target_roi_d ~= 0);
                %fprintf('target#%d(%s): %d voxels with a valid value:\n', k, roi_name{k}, sum(~isnan(roi_stats(target_vox_idx)),1));
                roi_stats_matrix(k,j) = nanmean(roi_stats(target_vox_idx),1); %nanmean(roi_stats(target_vox_idx),1); %j to seed,  k to target
            end
         end
         
         %change diagonal into zeros
          gPPI_matrix = roi_stats_matrix(:,:) - diag(diag(roi_stats_matrix(:,:)));
          gPPI_matrix_allcons(:,:,(nCon+1)/2) = gPPI_matrix;
          temp = (triu(gPPI_matrix)' + tril(gPPI_matrix))./2; %Take the average of upper and lower triangular parts of the matrix
          ww = temp + temp'; %%Translate into a symetrical matrix
          gPPI_matrix_allcons_sym(:,:,(nCon+1)/2) = ww;
          clear gPPI_matrix ww temp;
          
          cons_name = [cons_name, contrastNames{nCon}];
          
    end
    outputfile = fullfile(result_dir,[sprintf('%s',subject),'_gPPI_matrix_allcons.mat']);
    save(outputfile, 'gPPI_matrix_allcons', 'gPPI_matrix_allcons_sym', 'roi_name','cons_name');
end

c     = fix(clock);
disp('======================================================================');
fprintf('Extract gPPI ROI stats finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('======================================================================');

clear all;
close all;

end
