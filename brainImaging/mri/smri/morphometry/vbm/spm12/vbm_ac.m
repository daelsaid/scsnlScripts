function vbm_ac (ConfigFile)

% Reset the origin to AC, call the GUI in SPM12
% _________________________________________________________________________
% 2018 Stanford Cognitive and Systems Neuroscience Laboratory
%
% 2018-11-19
% -------------------------------------------------------------------------
warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('Resetting the origin started at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
fname = sprintf('vbm_ac-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
diary(fname);

spm_version             = 'spm12';
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
spmvbm_path             = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/morphometry/vbm/spm12/';


sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding SPM based vbm scripts path: %s\n', spmvbm_path);
addpath(genpath(spmvbm_path));

currentdir = pwd;
setenv('EDITOR','vim');
disp('==========================e========================================');
[v,r] = spm('Ver','',1);
fprintf('>>>-------- This SPM is %s V%s ---------------------\n',v,r);
fprintf('Current directory: %s\n', currentdir);
fprintf('Script: %s\n', which('vbm_ac.m'));
fprintf('Configfile: %s\n', ConfigFile);
fprintf('\n');

if ~exist(ConfigFile, 'file')
    error('cannot find the configuration file')
end

%  ConfigFile = ConfigFile(1:end-2);
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
fprintf('ConfigFile run as: %s \n',ConfigFile);
eval(ConfigFile);
clear ConfigFile;

config             = paralist;
subjectlist        = strtrim(config.subjectlist);
data_dir           = strtrim(config.rawdatadir);
project_dir        = strtrim(config.projectdir);

SPGR_folder        = 'anatomical';

disp('-------------- Contents of the Parameter List --------------------');
disp(config);
disp('==================================================================');
clear config;

subjectlist
fileid   = fopen(subjectlist,'r');
csvtable = textscan(fileid, '%s %d %d %s','delimiter',',','HeaderLines',1);
numsubj = length(csvtable{1})
problem_subj = zeros(numsubj, 1);
for i=1:numsubj
    subject  = csvtable{1}{i};
    fprintf('---> Setting the origin for: %s \n', subject);
    visit    = num2str(csvtable{2}(i));
    session  = num2str(csvtable{3}(i));
    spgr_filename = csvtable{4}{i};
    
    %%%%% ----- check anatomical input file and image --------------
    spgr_dir = fullfile(data_dir, subject, ['visit',visit],['session',session], SPGR_folder);
    if ~exist(spgr_dir, 'dir')
        error(sprintf('cannot find the spgr anatomical directory: %s\n', spgr_dir));
    end
    
    fprintf('Spgr filename of subject is %s\n  ', spgr_filename);
    
    spgr_filelist = dir(fullfile(spgr_dir, [spgr_filename, '.nii*']));
    if length(spgr_filelist) == 0
        error('cannot find the specified spgr file');
    end
    if length(spgr_filelist) > 1
        error('found more than 1 specified spgr files');
    end
    
    spgr_file = spgr_filelist(1).name;
    spgr_infile = fullfile(spgr_dir, spgr_file);
    
    output_dir = fullfile(project_dir, 'data/imaging/participants', subject, ...
        ['visit',visit],['session',session], 'anatomical');
    
    if ~exist(output_dir, 'dir')
        mkdir(output_dir)
    end
    
    fext = extractBetween(spgr_file, '.', length(spgr_file));
    fname = strcat('spgr.', fext);
    spgr_outfile = fullfile(output_dir, fname{1});
    if exist(spgr_outfile, 'file')
        unix(sprintf('rm -rf %s', spgr_outfile));
    end
    
    unix(sprintf('cp -f %s %s', spgr_infile, spgr_outfile));
    
    cd(output_dir)
    unix('gunzip -fq spgr.nii.gz');
    t1_file = 'spgr.nii';
    try
        vbm_spm_image('init', t1_file);
        if(i < numsubj)
            fprintf('After you are finished, please press any key to proceed to the next subject \n');
        else
            fprintf('This is the last subject. Please press any key after you are finished.\n');
        end
        
        pause;
        unix('mv spgr.nii ac_spgr.nii');
        unix('gzip -fq *.nii');
        close all;
    catch
        problem_subj(i) = 1;
        fprintf('%s is flagged as problematic subject \n', subject);
        close all;
    end
end

close all;
cd(currentdir);

%-Write out subjects with errors
if sum(problem_subj) > 0
    fid = fopen('vbm_ac_warning_subjects.txt', 'w+');
    subj_index = find(problem_subj == 1);
    num_prom_subj = length(subj_index);
    for i = 1:num_prom_subj
        fprintf(fid, '%s\n', csvtable{1}(subj_index(i)));
    end
    fclose(fid);
end

disp('==================================================================');
c = fix(clock);
fprintf('VBM AC alignment finished at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');
diary off;
end
