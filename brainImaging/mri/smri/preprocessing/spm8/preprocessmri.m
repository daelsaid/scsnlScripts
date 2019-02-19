function preprocessmri(SubjectI, ConfigFile)

spm_version             = 'spm8';
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
spmpreprocscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/preprocessing/' spm_version];

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding SPM based preprocessing scripts path: %s\n', spm_path);
addpath(genpath(spmpreprocscript_path));

currentdir = pwd;

disp('==========================e========================================');
fprintf('Current directory: %s\n', currentdir);
fprintf('Script: %s\n', which('preprocessmri.m'));
fprintf('Configfile: %s\n', ConfigFile);
fprintf('\n');

if ~exist(ConfigFile, 'file')
    error('cannot find the configuration file')
end
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
eval(ConfigFile);
clear ConfigFile;

config             = paralist;
subject_i          = SubjectI;
subjectlist        = strtrim(config.subjectlist);
spgr_list          = strtrim(config.spgrlist);
skullstrip_flag    = config.skullstrip;
segment_flag       = config.segment;
template_path      = strtrim(config.batchtemplatepath);
data_dir           = strtrim(config.rawdatadir);
project_dir        = strtrim(config.projectdir);

SPGR_folder        = 'anatomical';


disp('-------------- Contents of the Parameter List --------------------');
disp(config);
disp('==================================================================');
clear config;

%==========================================================================
subjectlist       = csvread(subjectlist,1);
subject           = subjectlist(subject_i);
subject           = char(pad(string(subject),4,'left','0'));
visit             = num2str(subjectlist(subject_i,2));
session           = num2str(subjectlist(subject_i,3));
spgr_list         = ReadList(spgr_list);
spgr_filename     = spgr_list{subject_i};

spgr_dir = fullfile(data_dir, subject, ['visit',visit],['session',session], SPGR_folder);
if ~exist(spgr_dir, 'dir')
  error(sprintf('cannot find the spgr anatomical directory: %s\n', spgr_dir));
end

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

spm_jobman('initcfg');
delete(get(0, 'Children'));

fprintf('Processing subject: %s\n', subject);

%% Skullstrip
if skullstrip_flag == 0
    spgr_seg_input_file = spgr_outfile;
    fprintf('no skullstripping option used\n');
elseif skullstrip_flag == 1
    spgr_wsgz_file = fullfile(output_dir, 'watershed_spgr.nii.gz');
    if exist(spgr_wsgz_file, 'file')
        unix(sprintf('rm -rf %s', spgr_wsgz_file));
    end
    spgr_ws_file = fullfile(output_dir, 'watershed_spgr.nii');
    if exist(spgr_ws_file, 'file')
        unix(sprintf('rm -rf %s', spgr_ws_file));
    end
    preprocessmri_skullstrip_watershed(spgr_outfile, spgr_ws_file);
    spgr_seg_input_file = spgr_ws_file;
    fprintf('done with the skullstripping using watershed algorithm\n');
elseif skullstrip_flag == 2
    spgr_seg_input_file = spgr_outfile;
    %spm based skullstrip requires segmentation. perform that first and
    %then do skullstrip
end

%% Segment
if segment_flag == 1
    seg_dir = fullfile(output_dir, ['seg' '_' spm_version]);
    if ~exist(seg_dir, 'dir')
        mkdir(seg_dir);
        %unix(sprintf('/bin/rm -rf %s', seg_dir));
    end
    

    unix(sprintf('cp -f %s %s', spgr_seg_input_file, seg_dir));
    
    [tmp1 spgr_seg_input_file_name extension] = fileparts(spgr_seg_input_file);
    if(strcmp(extension, '.gz'))
        unix(sprintf('gunzip -f %s', fullfile(seg_dir, [spgr_seg_input_file_name extension])));
        extension = '';
    end
    spgr_seg_output_file = fullfile(seg_dir, [spgr_seg_input_file_name extension]);
    preprocessmri_segment(currentdir, template_path, spgr_seg_output_file, seg_dir)
end

if skullstrip_flag == 2
    if segment_flag == 0
        error('spm based skullstrip requires segmentation step. please set segment flag to 1 in the config file')
    end
    spgr_spmskullstrip_file = fullfile(output_dir, ['skullstrip_spgr' '_' spm_version '.nii']);
    if exist(spgr_spmskullstrip_file, 'file')
        unix(sprintf('rm -rf %s', spgr_spmskullstrip_file));
    end
    preprocessmri_skullstrip_spm(seg_dir, spgr_file, spgr_spmskullstrip_file)    


    spgr_sn_file = fullfile(seg_dir, ['spgr_seg_sn.mat']);
    skullstrip_sn_file = fullfile(seg_dir, ['skullstrip_spgr' '_' spm_version '_seg_sn.mat']);
    unix(sprintf('cp -f %s %s', spgr_sn_file, skullstrip_sn_file));
   
    spgr_inv_sn_file = fullfile(seg_dir, ['spgr_seg_inv_sn.mat']);
    skullstrip_inv_sn_file = fullfile(seg_dir, ['skullstrip_spgr' '_' spm_version '_seg_inv_sn.mat']);
    unix(sprintf('cp -f %s %s', spgr_inv_sn_file, skullstrip_inv_sn_file));


    fprintf('done with the skullstripping using spm\n');
end
%%-------------------------------------------------------------------------------

cd(currentdir);

disp('==================================================================');
disp('Preprocessing finished');

delete(get(0, 'Children'));
clear all;
close all;
disp('==================================================================');

end
