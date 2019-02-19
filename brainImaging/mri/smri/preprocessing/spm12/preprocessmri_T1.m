function preprocessmri(SubjectI, ConfigFile)

% tianwenc, 2011-12-02,  created preprocessfmri.m
% ruiyuan, 2018-02-10, updated segmentation 


    spm_version             = 'spm12';
    software_path           = '/oak/stanford/groups/menon/toolboxes/';
    spm_path                = fullfile(software_path, spm_version);
    spmpreprocscript_path   = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/preprocessing/spm12';


    sprintf('adding SPM path: %s\n', spm_path);
    addpath(genpath(spm_path));
    sprintf('adding SPM based preprocessing scripts path: %s\n', spm_path);
    addpath(genpath(spmpreprocscript_path));

    currentdir = pwd;

    disp('==========================e========================================');
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
    subject_i          = SubjectI;
    subjectlist        = strtrim(config.subjectlist);
    spgr_list          = strtrim(config.spgrlist);
    skullstrip_flag    = config.skullstrip;
    segment_flag       = config.segment;
    template_path      = strtrim(config.batchtemplatepath);
    data_dir           = strtrim(config.rawdatadir);
    project_dir        = strtrim(config.projectdir);

    SPGR_folder        = 'anatomical/orig_3D_Volume';


disp('-------------- Contents of the Parameter List --------------------');
disp(config);
disp('==================================================================');
clear config;

%==========================================================================
    subjectlist       = csvread(subjectlist,1);
    subject           = subjectlist(subject_i);
    subject           = char(string(subject));
    subject           = char(pad(string(subject),4,'left','0'));
    visit             = num2str(subjectlist(subject_i,2));
    session           = num2str(subjectlist(subject_i,3));
    spgr_list         = ReadList(spgr_list);
    spgr_filename     = spgr_list{subject_i};

    %%%%% ----- check anatomical input file and image --------------
    spgr_dir = fullfile(data_dir, subject, ['visit',visit],['session',session], SPGR_folder);
    if ~exist(spgr_dir, 'dir')
      error(sprintf('cannot find the spgr anatomical directory: %s\n', spgr_dir));
    end

    fprintf('Spgr filename of subject %s\n  ', spgr_filename);

    spgr_filelist = dir(fullfile(spgr_dir, [spgr_filename, '.nii*']));
    if length(spgr_filelist) == 0
      error('cannot find the specified spgr file');
    end
    if length(spgr_filelist) > 1
      error('found more than 1 specified spgr files');
    end

    spgr_file = spgr_filelist(1).name;
    spgr_infile = fullfile(spgr_dir, spgr_file);
    fprintf('spgr_infile is %s \n',spgr_infile);
    
    %%%%%% ------- check output directory -----------
    output_dir = fullfile(project_dir, 'data/imaging/participants', subject,['visit',visit],['session',session], 'anatomical');

    if ~exist(output_dir, 'dir')
      mkdir(output_dir)
    end
    
    fext = extractBetween(spgr_file, '.', length(spgr_file));
    fname = strcat('spgr.', fext);
    spgr_outfile = fullfile(output_dir, fname{1});

 
    %spgr_outfile = fullfile(output_dir, spgr_file);
    if exist(spgr_outfile, 'file')
      unix(sprintf('rm -rf %s', spgr_outfile));
    end

    copyfile(spgr_infile, spgr_outfile); %-- rui--
    %unix(sprintf('cp -f %s  %s', spgr_infile, spgr_outfile));

    spm_jobman('initcfg');
    delete(get(0, 'Children'));

    fprintf('Processing subject: %s\n', subject);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ----------Skullstrip ------------------%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%     if skullstrip_flag == 0
%         spgr_seg_input_file = spgr_outfile;
%         fprintf('no skullstripping option used\n');
%     elseif skullstrip_flag == 1
%         spgr_wsgz_file = fullfile(output_dir, 'watershed_spgr.nii.gz');
%         if exist(spgr_wsgz_file, 'file')
%             unix(sprintf('rm -rf %s', spgr_wsgz_file));
%         end
%         spgr_ws_file = fullfile(output_dir, 'watershed_spgr.nii');
%         if exist(spgr_ws_file, 'file')
%             unix(sprintf('rm -rf %s', spgr_ws_file));
%         end
%         
%         preprocessmri_skullstrip_watershed(spgr_outfile, spgr_ws_file);
%         
%         spgr_seg_input_file = spgr_ws_file;
%         fprintf('done with the skullstripping using watershed algorithm\n');
%     elseif skullstrip_flag == 2
%         spgr_seg_input_file = spgr_outfile;
%         %spm based skullstrip requires segmentation. perform that first and
%         %then do skullstrip
%     end


     if skullstrip_flag == 0
        spgr_seg_input_file = spgr_outfile;
       % fprintf('no skullstripping option used\n');
    
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
 %    elseif skullstrip_flag == 2
 %        spgr_seg_input_file = spgr_outfile;
 %        spm based skullstrip requires segmentation. perform that first and
 %        then do skullstrip
    end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ---------    Segmentation   ------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if segment_flag == 1
    
    %%%---- update the seg input file -------------
    
    seg_dir = fullfile(output_dir, ['seg', '_', spm_version]);
    
    if ~exist(seg_dir, 'dir')
        mkdir(seg_dir);
    %else    
    %   unix(sprintf('rm -rf %s', seg_dir));
    %   mkdir(seg_dir);
    end
    

    unix(sprintf('cp -f %s %s', spgr_seg_input_file, seg_dir));
    disp('-----------------------------------------------------------');
    fprintf('segmentation input file is : \n %s \n\n',spgr_seg_input_file);
    
    [tmp1, spgr_seg_input_file_name, extension] = fileparts(spgr_seg_input_file);
    
    if(strcmp(extension, '.gz'))
        unix(sprintf('gunzip -fq %s', fullfile(seg_dir, [spgr_seg_input_file_name, extension])));
        extension = '';
    end
    
    spgr_seg_output_file = fullfile(seg_dir, [spgr_seg_input_file_name, extension]);
    preprocessmri_segment(currentdir, template_path, spgr_seg_output_file, seg_dir,spm_path,skullstrip_flag)
end

if skullstrip_flag == 0
    if segment_flag == 0
        error('spm based skullstrip requires segmentation step. please set segment flag to 1 in the config file')
    end
    spgr_spmskullstrip_file = fullfile(seg_dir, ['skullstrip_spgr' '_' spm_version '.nii']);
     
    if exist(spgr_spmskullstrip_file, 'file')
        unix(sprintf('rm -rf %s', spgr_spmskullstrip_file));
    end
    
     preprocessmri_skullstrip_spm(seg_dir, spgr_seg_input_file_name, spgr_spmskullstrip_file)

    %-------- copy skullstrip_spgr_spm12.nii to anatomical folder ----------
    
   % unix(sprintf('cp -af %s %s',spgr_spmskullstrip_file,fullpath(output_dir,['skullstrip_spgr_',spm_version,'.nii'])));

    % ------- copy y_spgr.nii to y_skullstrip_spgr.nii ----------------------
    unix(sprintf('cp -af %s %s ',fullfile(seg_dir,'y_spgr.nii'),fullfile(seg_dir,'y_skullstrip_spgr_spm12.nii') ));  
    unix(sprintf('cp -af %s %s', fullfile(seg_dir,'iy_spgr.nii'),fullfile(seg_dir,'iy_skullstrip_spgr_spm12.nii')));

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



