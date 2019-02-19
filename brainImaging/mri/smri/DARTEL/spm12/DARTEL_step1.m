function DARTEL_step1(ConfigFile)

% ruiyuan, 2019-01-31, 


    spm_version             = 'spm12';
    software_path           = '/oak/stanford/groups/menon/toolboxes/';
    spm_path                = fullfile(software_path, spm_version);
    spmpreprocscript_path   = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/preprocessing/spm12';


    sprintf('adding SPM path: %s\n', spm_path);
    addpath(genpath(spm_path));
    sprintf('adding SPM based preprocessing scripts path: %s\n', spm_path);
    addpath(genpath(spmpreprocscript_path));

    currentdir = pwd;

    disp('==================================================================');
    [v,r] = spm('Ver','',1);
    fprintf('>>>-------- This SPM is %s V%s ---------------------\n',v,r);
    fprintf('Current directory: %s\n', currentdir);
    fprintf('Script: %s\n', which('preprocessmri.m'));
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
    %subject_i          = SubjectI;
    subjectlist        = strtrim(config.subjectlist);
%    spgr_list          = strtrim(config.spgrlist);
%    skullstrip_flag    = config.skullstrip;
%    segment_flag       = config.segment;
%    template_path      = strtrim(config.batchtemplatepath);
    %data_dir           = strtrim(config.rawdatadir);
    project_dir        = strtrim(config.projectdir);

    SPGR_folder        = 'anatomical';


disp('-------------- Contents of the Parameter List --------------------');
disp(config);
disp('==================================================================');
clear config;

%==========================================================================
 %   subjectlist       = csvread(subjectlist,1);
 %   subject           = subjectlist(subject_i);
 %   subject           = char(string(subject));
 %   subject           = char(pad(string(subject),4,'left','0'));
 %   visit             = num2str(subjectlist(subject_i,2));
 %   session           = num2str(subjectlist(subject_i,3));
 %   spgr_list         = ReadList(spgr_list);
 %   spgr_filename     = spgr_list{subject_i};

     subjectlist
     fileid   = fopen(subjectlist,'r');
     csvtable = textscan(fileid, '%s %d %d %s','delimiter',',','HeaderLines',1);
     csvtable
     
   for subject_i = 1: length(csvtable{1})
       
     subject  = csvtable{1}{subject_i};
     visit    = num2str(csvtable{2}(subject_i));
     session  = num2str(csvtable{3}(subject_i));
     spgr_filename = csvtable{4}{subject_i};

    %%%%% ----- check anatomical input file and image --------------
%     spgr_dir = fullfile(project_dir, subject, ['visit',visit],['session',session], SPGR_folder);
%     if ~exist(spgr_dir, 'dir')
%       error(sprintf('cannot find the spgr anatomical directory: %s\n', spgr_dir));
%     end
% 
%     fprintf('Spgr filename of subject %s\n  ', spgr_filename);
% 
%     spgr_filelist = dir(fullfile(spgr_dir, [spgr_filename, '.nii*']));
%     if length(spgr_filelist) == 0
%       error('cannot find the specified spgr file');
%     end
%     if length(spgr_filelist) > 1
%       error('found more than 1 specified spgr files');
%     end
% 
     
%     spgr_infile = fullfile(spgr_dir, spgr_file);
%     fprintf('spgr_infile is %s \n',spgr_infile);
    
    %%%%%% ------- check input directory -----------
    output_dir = fullfile(project_dir, 'data/imaging/participants', subject,['visit',visit],['session',session], 'anatomical','seg_spm12');

    if ~exist(output_dir, 'dir')
      error(sprintf('cannot find the Segmentation output directory: %s\n', output_dir));
    end
    fprintf('+ Checking Spgr filename of subject %s\n  ', num2str(subject_i));
    
    seg_file1 = fullfile(output_dir,'rc1spgr.nii'); 

    if ~exist(seg_file1, 'file')
      error(sprintf('cannot find the Segmentation rc1* file : %s\n', seg_file1))
    end

    seg_file2 = fullfile(output_dir,'rc2spgr.nii'); 

    if ~exist(seg_file2, 'file')
      error(sprintf('cannot find the Segmentation rc1* file : %s\n', seg_file2))
    end

    warp_images_list_r1{subject_i,1} = fullfile(output_dir,'rc1spgr.nii,1');
    warp_images_list_r2{subject_i,1} = fullfile(output_dir,'rc2spgr.nii,1');
   end
   

    fprintf('>>>>>>>> finish checking segmentation results >>>>>>>>>>\n')

 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ---------    Segmentation   ------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% for j=1:length(csvtable{1})
%           
%           warp_images_list_r1{j,1} = fullfile(output_dir,'rc1spgr.nii');
%           warp_images_list_r2{j,1} = fullfile(output_dir,'rc2spgr.nii');
% end

   
 %fprintf('path: %s\n',output_dir);
 
 spm('defaults','fmri') ;      
 spm_jobman('initcfg');   

matlabbatch{1}.spm.tools.dartel.warp.images = {
                                               warp_images_list_r1
                                               warp_images_list_r2
                                               }';
matlabbatch{1}.spm.tools.dartel.warp.settings.template = 'Template';
matlabbatch{1}.spm.tools.dartel.warp.settings.rform = 0;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).its = 3;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).rparam = [4 2 1e-06];
matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).K = 0;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).slam = 16;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).its = 3;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).rparam = [2 1 1e-06];
matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).K = 0;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).slam = 8;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).its = 3;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).rparam = [1 0.5 1e-06];
matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).K = 1;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).slam = 4;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).its = 3;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).rparam = [0.5 0.25 1e-06];
matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).K = 2;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).slam = 2;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).its = 3;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).rparam = [0.25 0.125 1e-06];
matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).K = 4;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).slam = 1;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).its = 3;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).rparam = [0.25 0.125 1e-06];
matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).K = 6;
matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).slam = 0.5;
matlabbatch{1}.spm.tools.dartel.warp.settings.optim.lmreg = 0.01;
matlabbatch{1}.spm.tools.dartel.warp.settings.optim.cyc = 3;
matlabbatch{1}.spm.tools.dartel.warp.settings.optim.its = 3;


%spm_jobman('run',matlabbatch);

%end
%%-------------------------------------------------------------------------------

cd(currentdir);

disp('==================================================================');
disp('Preprocessing finished');

delete(get(0, 'Children'));
%clear all;
%close all;
disp('==================================================================');

%-------------------------------  COPY to result folder -------------------------
[filepath,name,ext] = fileparts(warp_images_list_r1{1,1}); 
D_output_folder = filepath; 
%/oak/stanford/groups/menon/projects/ruiyuan/2019_PD_ADRC/results/smri
output_dir = fullfile(project_dir,'results','smri','DARTEL');
if ~exist(output_dir,'dir')
 mkdir output_dir;
end

copyfile([D_output_folder,'/Template*.nii'],output_dir);
fprintf('>>>> copy template* files to :\n \t  %s \n', output_dir );

end



