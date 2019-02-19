function scsnl_gPPI_volrep_mask(SubjectI,Config_File)
%-gPPI analysis for SCSNL data and analysis pipeline
%-modified for spm8 on sherlock 2/Matlab2017b
%-fix matlab2017 compatibility issues: P.VOI2 and dlmwrite
%-add function to delete existing subject_roi_gppi_stats folder 
%-add function to delete existing files in subject_gppi_stats folder
%-Weidong Cai, 03/30/2018

%04/24/2018 HC: script modified to be equivalent to 'scsnl_gPPI_volrep_mask.m' version in old server. 

%currentdir = pwd;
current_dir = pwd;
warning('off', 'MATLAB:FINITE:obsoleteFunction')
c = fix(clock);
disp('==================================================================');
fprintf('gPPI analysis started at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
fname = sprintf('scsnl_gPPI-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
%disp(['Current directory is: ',currentdir]);
disp(['Current directory is: ',current_dir]);
%fprintf('Script: %s\n', which('scsnl_gPPI_wc.m'));

%%%HC changed the name of the script
fprintf('Script: %s\n', which('scsnl_gPPI_volrep_mask.m'));

fprintf('Configfile: %s\n', Config_File);
fprintf('\n')
%diary(fname);
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

 
%==========================================================================

%-Check existence of the configuration file
Config_File = strtrim(Config_File);
%
%if ~exist(Config_File,'file')
%  fprintf('Cannot find the configuration file ... \n');
%  diary off;
%  return;
%end
%
%Config_File = Config_File(1:end-2);

if ~exist(Config_File,'file')
    fprintf('Cannot find the configuration file %s ..\n',Config_File);
    error('Cannot find the configuration file');
end
[Config_FilePath, Config_File, Config_FileExt] = fileparts(Config_File);

%-Read individual stats parameters

eval(Config_File);
clear Config_File;


spm_version = strtrim(paralist.spmversion); %'spm8_R3028';

%%%HC added old-server version PPPI toolbox and modified PPPI script that allows empty conditions

%spmgppi_path =  fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/connectivity/effective/gppi/',spm_version);

spm_path = fullfile('/oak/stanford/groups/menon/toolboxes/',spm_version);

%PPPI_core_scripts_path = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/connectivity/effective/gppi/',spm_version,'/utils/PPPIv13.1');
%PPPI_core_scripts_path = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/connectivity/effective/gppi/',spm_version,'/utils/PPPI_v2012_1_22/');
%old_PPPI_template_path = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/connectivity/effective/gppi/',spm_version,'/utils/PPPI_v2012_1_22/example_structure_inputs/');
%Common_scripts_path = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/',spm_version,'/utils/');

Common_scripts_path = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm8/utils/');

fprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
%fprintf('adding SPM based individual stats scripts path: %s\n', spmgppi_path);
%addpath(spmgppi_path);
%addpath(genpath(PPPI_core_scripts_path));
%addpath(genpath(old_PPPI_template_path));
addpath(genpath('/oak/stanford/groups/menon/projects/changh/2018_miscellaneous/toolboxes/PPPI_v2012_1_22'));
addpath(genpath(Common_scripts_path));
addpath('/oak/stanford/groups/menon/projects/changh/2018_miscellaneous/toolboxes/gPPI_mask_misc');

%-Load parameters
data_server = strtrim(paralist.projectdir);
%subjects = ReadList(strtrim(paralist.subject_list));
subjectlist = csvread(strtrim(paralist.subjectlist),1);
stats_folder = strtrim(paralist.stats_folder);
num_subj = size(subjectlist,1);
roi_file = ReadList(paralist.roi_file_list);
roi_name = ReadList(paralist.roi_name_list);
num_roi_name = length(roi_name);
num_roi_file = length(roi_file);
tasks_to_include = paralist.tasks_to_include;
confound_names = paralist.confound_names;

%%%HC specified mask file in config file
mask_file = paralist.mask_file;


%%%HC specified volume repair pipeline used in config file
prep_pipeline = strtrim(paralist.prep_pipeline);

%maskdir = paralist.maskdir;

    disp('-------------- Contents of the Parameter List --------------------');
    disp(paralist);
    disp('------------------------------------------------------------------');
    clear paralist;



if num_roi_name ~= num_roi_file
    error('number of ROI files not equal to number of ROI names');
end

for i_roi = 1:num_roi_file
    
    fprintf('===> gPPI for ROI: %s\n', roi_name{i_roi});
    
    load('ppi_master_template.mat');

    P.VOI = roi_file{i_roi};
    P.Region = roi_name{i_roi};
    P.extract = 'eig';
    P.CompContrasts = 0;
    P.Tasks = tasks_to_include;
    P.FLmask = 1;
    P.equalroi = 0;
    %P.maskdir = maskdir;
    
    fprintf('subjectI is %d \n',SubjectI);
    subject           = num2str(subjectlist(SubjectI,1));
    visit             = num2str(subjectlist(SubjectI,2));
    session           = num2str(subjectlist(SubjectI,3));
    num_subj = 1
    
    for i_subj = 1:num_subj
        
%         subject           = num2str(subjectlist(i_subj,1));
%         visit             = num2str(subjectlist(i_subj,2));
%         session           = num2str(subjectlist(i_subj,3));
        
        fprintf('------> processing subject: %s\n', subject);
             
        %-directory of SPM.mat file

        %%%HC changed stats folder to be under 'stats_spm8' (not under 'stats_spm8_R3028')
        %subject_stats_dir = fullfile(data_server, '/results/taskfmri/participants', subject, ['visit',visit],['session',session],'glm', ['stats_', spm_version], stats_folder);
        subject_stats_dir = fullfile(data_server, '/results/taskfmri/participants', subject, ['visit',visit],['session',session],'glm', ['stats_spm8'], stats_folder);
        fprintf('------> subject_stats_dir : %s \n',subject_stats_dir);

        %subject_gPPI_stats_dir = fullfile(data_server, '/results/taskfmri/participants', subject, ['visit',visit],['session',session],'glm', ['stats_', spm_version], [stats_folder, '_gPPI']);
        subject_gPPI_stats_dir = fullfile(data_server, '/results/taskfmri/participants', subject, ['visit',visit],['session',session],'glm', ['stats_spm8'], [stats_folder, '_gPPI_mask']);
        subject_gPPI_stats_dir_temp = fullfile(data_server, '/results/taskfmri/participants', subject, ['visit',visit],['session',session],'glm', ['stats_spm8'], [stats_folder, '_gPPI_mask'], 'tempstats');
        
        %---- remove the previous folder, create a new one ------
        if ~exist(subject_gPPI_stats_dir, 'dir')
            mkdir(subject_gPPI_stats_dir);
        %else
        % rmdir(subject_gPPI_stats_dir,'s');
        % mkdir(subject_gPPI_stats_dir);
        end
        
        %%%HC added temp stats
        if ~exist(subject_gPPI_stats_dir_temp, 'dir')
        mkdir(subject_gPPI_stats_dir_temp);
        end

        cd(subject_gPPI_stats_dir_temp);
    
        unix(sprintf('/bin/cp -af %s %s', fullfile(subject_stats_dir, 'SPM.mat'), ...
            subject_gPPI_stats_dir_temp));
        unix(sprintf('/bin/cp -af %s %s', fullfile(subject_stats_dir, '*.img'), ...
            subject_gPPI_stats_dir_temp));
        unix(sprintf('/bin/cp -af %s %s', fullfile(subject_stats_dir, '*.hdr'), ...
            subject_gPPI_stats_dir_temp));

        P.subject = subject;
        P.directory = subject_gPPI_stats_dir_temp;
    
%{
        cd(subject_gPPI_stats_dir);
        %delete existing files in gPPI stats folder
        unix('rm -rf *.*');
        
        subject_roi_gPPI_stats_dir = sprintf('%s/PPI_%s', subject_gPPI_stats_dir, roi_name{i_roi});
        
        % delete gPPI roi stats folder if it exists
        if exist(subject_roi_gPPI_stats_dir, 'dir')
            unix(sprintf('rm -rf %s', subject_roi_gPPI_stats_dir));
        end
        
        unix(sprintf('/bin/cp -af %s %s', fullfile(subject_stats_dir, 'SPM.mat'), ...
            subject_gPPI_stats_dir));
        
        unix(sprintf('/bin/cp -af %s %s', fullfile(subject_stats_dir, '*.img'), ...
            subject_gPPI_stats_dir));

        unix(sprintf('/bin/cp -af %s %s', fullfile(subject_stats_dir, '*.hdr'), ...
            subject_gPPI_stats_dir));
        
        P.subject = subject;
        P.directory = subject_gPPI_stats_dir;
        
%}

        %-Update the SPM path for gPPI analysis
        load('SPM.mat');
        SPM.swd = pwd;

        iG = [];
        col_name = SPM.xX.name;
        num_sess = numel(SPM.Sess);
        num_confound = length(confound_names);

        %%%HC updated 
        checkiG = 1;            
               
        for i_c = 1:num_confound

            %iG_exp = ['^Sn\(.*\).', confound_names{i_c}, '$'];
            iG_exp = ['^Sn\(.\).', confound_names{i_c}, '$'];
            iG_match = regexpi(col_name, iG_exp);
            iG_match = ~cellfun(@isempty, iG_match);
            if sum(iG_match) == 0
                error('confound columns are not found');
            elseif sum(iG_match) > 1
            warning('confound columns are not unique -- this is OK if you have multisession data')
            checkiG = 0;
            else
                iG = [iG find(iG_match == 1)];
             end
            end

            if checkiG && length(iG) ~= 6
                error('number of confound columns is larger than 6');
            end


            %if length(iG) ~= num_confound*num_sess
            %    error('number of confound columns does not match SPM design');
            %end

            num_col = size(SPM.xX.X, 2);
            FCon = ones(num_col, 1);
            FCon(iG) = 0;
            FCon(SPM.xX.iB) = 0;
            FCon = diag(FCon);
        
            num_con = length(SPM.xCon);
       
        %-make F contrast and run it
        SPM.xCon(end+1)= spm_FcUtil('Set', 'effects_of_interest', 'F', 'c', FCon', SPM.xX.xKXs);
        spm_contrasts(SPM, num_con+1);
        
        P.contrast = num_con + 1;
        
        SPM.xX.iG = sort(iG);
        for g = 1:length(iG)
            SPM.xX.iC(SPM.xX.iC==iG(g)) = [];
        end

        img_name = cell(num_sess, 1);
        img_path = cell(num_sess, 1);
        num_scan = [1, SPM.nscan];
        
        for i_sess = 1:num_sess
            first_scan_sess = sum(num_scan(1:i_sess));
            img_name{i_sess} = SPM.xY.VY(first_scan_sess).fname;
            img_path{i_sess} = fileparts(img_name{i_sess});
            unix(sprintf('gunzip -fq %s', [img_name{i_sess}, '.gz']));
        end
                     
        save SPM.mat SPM;
        clear SPM;
        %User input required (change analysis to be more specific)
        save(['gPPI_', subject, '_analysis_', roi_name{i_roi}, '.mat'], 'P');

        %%%HC changed to PPPI script modified to use the mask
        %PPPI_wc(['gPPI_', subject, '_analysis_', roi_name{i_roi}, '.mat']);
        PPPI_mask(['gPPI_', subject, '_analysis_', roi_name{i_roi}, '.mat'],['gPPI_', subject, '_analysis_', roi_name{i_roi}, '.mat'],mask_file);

        %%%HC changed to run analysis on volume repaired images
        gPPI_roi_dir = fullfile(subject_gPPI_stats_dir, ['PPI_', roi_name{i_roi}]);
        if ~exist(gPPI_roi_dir, 'dir')
            mkdir(gPPI_roi_dir);
        end

        scsnl_art_redo_mask(fullfile(subject_gPPI_stats_dir_temp, ['PPI_', roi_name{i_roi}]), prep_pipeline, gPPI_roi_dir, img_path, mask_file);

        for i_sess = 1:num_sess
            unix(sprintf('gzip -fq %s', img_name{i_sess}));
        end
        
        cd(subject_gPPI_stats_dir_temp);
        unix(sprintf('/bin/rm -rf %s', 'SPM.mat'));
        
        %%%HC changes
        %unix(sprintf('/bin/rm -rf %s', '*.img'));
        %unix(sprintf('/bin/rm -rf %s', '*.hdr'));
        %unix(sprintf('/bin/mv -f %s %s', '*.txt', ['PPI_', roi_name{i_roi}]));
        %unix(sprintf('/bin/mv -f %s %s', '*.mat', ['PPI_', roi_name{i_roi}]));
        %unix(sprintf('/bin/mv -f %s %s', '*.log', ['PPI_', roi_name{i_roi}]));

        unix(sprintf('/bin/mv -f %s %s', '*.txt', gPPI_roi_dir));
        unix(sprintf('/bin/mv -f %s %s', '*.mat', gPPI_roi_dir));
        unix(sprintf('/bin/mv -f %s %s', '*.log', gPPI_roi_dir));
        unix(sprintf('/bin/rm -rf %s', subject_gPPI_stats_dir_temp));
    end
    cd(current_dir);
end

cd(current_dir);
disp('------------------------------------------------------------------');
fprintf('Changing back to the directory: %s \n', current_dir);
c     = fix(clock);
disp('==================================================================');
fprintf('gPPI analysis finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');

diary off;
clear all;
close all;
end
