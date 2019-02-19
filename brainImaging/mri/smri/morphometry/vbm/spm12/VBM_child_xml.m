function VBM(SubjectI, ConfigFile)

% ruiyuan, 2018-11-01, VBM using CAT12 toolbox


    spm_version             = 'spm12';
    software_path           = '/oak/stanford/groups/menon/toolboxes/';
    spm_path                = fullfile(software_path, spm_version);
    spmpreprocscript_path   = '/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/smri/preprocessing/spm12';


    sprintf('adding SPM path: %s\n', spm_path);
    addpath(genpath(spm_path));
    sprintf('adding SPM based preprocessing scripts path: %s\n', spm_path);
    addpath(genpath(spmpreprocscript_path));

    currentdir = pwd;
    setenv('EDITOR','vim');
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
    SmoothWidth        = config.smoothwidth;
%    spgr_list          = strtrim(config.spgrlist);
%    skullstrip_flag    = config.skullstrip;
%    segment_flag       = config.segment;
%    template_path      = strtrim(config.batchtemplatepath);
    data_dir           = strtrim(config.rawdatadir);
    project_dir        = strtrim(config.projectdir);

    SPGR_folder        = 'anatomical';


disp('-------------- Contents of the Parameter List --------------------');
disp(config);
disp('==================================================================');
clear config;

%==========================================================================
%    subjectlist       = csvread(subjectlist,1);
%    subject           = subjectlist(subject_i);
%    subject           = char(string(subject));
%    subject           = char(pad(string(subject),4,'left','0'));
%    visit             = num2str(subjectlist(subject_i,2));
%    session           = num2str(subjectlist(subject_i,3));
%    spgr_list         = ReadList(spgr_list);
%    spgr_filename     = spgr_list{subject_i};
     subjectlist
     fileid   = fopen(subjectlist,'r'); 
     csvtable = textscan(fileid, '%s %d %d %s','delimiter',',','HeaderLines',1);
     csvtable
     subject  = csvtable{1}{subject_i};
     visit    = num2str(csvtable{2}(subject_i));
     session  = num2str(csvtable{3}(subject_i));
     spgr_filename = csvtable{4}{subject_i};

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
    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ---------    Segmentation   ------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    
    %%%---- update the seg input file -------------
    
    seg_dir = fullfile(output_dir, ['VBM', '_', spm_version]);
    
    if ~exist(seg_dir, 'dir')
        mkdir(seg_dir);
    %else    
    %   unix(sprintf('rm -rf %s', seg_dir));
    %   mkdir(seg_dir);
    end
    
    spgr_seg_input_file = spgr_infile;
    unix(sprintf('cp -f %s %s', spgr_seg_input_file, seg_dir));
    disp('-----------------------------------------------------------');
    fprintf('segmentation input file is : \n %s \n\n',spgr_seg_input_file);
    
    [tmp1, spgr_seg_input_file_name, extension] = fileparts(spgr_seg_input_file);
    
    if(strcmp(extension, '.gz'))
        unix(sprintf('gunzip -fq %s', fullfile(seg_dir, [spgr_seg_input_file_name, extension])));
        extension = '';
    end
    
    spgr_seg_input_file = fullfile(seg_dir, [spgr_seg_input_file_name, extension]);

    %VBM_CAT12(currentdir, spgr_seg_output_file, seg_dir,spm_path);
    % VBM_CAT12(CurrentDir, SpgrFile, OutputDir,spm_path)

       tpm_path = strcat(spm_path,'/tpm');
       cat12_path = '/oak/stanford/groups/menon/toolboxes/spm12/toolbox/cat12';
       addpath(genpath(cat12_path));

       % fprintf('++++ here is the fist line\n');
         fprintf('input is %s \n\n',spgr_seg_input_file);
        matlabbatch{1}.spm.tools.cat.estwrite.data = {spgr_seg_input_file};
        matlabbatch{1}.spm.tools.cat.estwrite.nproc = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.opts.tpm = {['/oak/stanford/groups/menon/toolboxes/spm8_R3028/toolbox/Seg/TPM.nii']};
        matlabbatch{1}.spm.tools.cat.estwrite.opts.affreg = 'mni';
        matlabbatch{1}.spm.tools.cat.estwrite.opts.biasstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.APP = 1070;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.LASstr = 0.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.gcutstr = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.registration.darteltpm = {[cat12_path,'/templates_1.50mm/Template_1_IXI555_MNI152.nii']};
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.registration.shootingtpm = {[cat12_path,'/templates_1.50mm/Template_0_IXI555_MNI152_GS.nii']};
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.registration.regstr = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.vox = 1.5;
        matlabbatch{1}.spm.tools.cat.estwrite.extopts.restypes.fixed = [1 0.1];
        matlabbatch{1}.spm.tools.cat.estwrite.output.surface = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.neuromorphometrics = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.lpba40 = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.cobra = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.hammers = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.native = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.mod = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.GM.dartel = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.native = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.mod = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.WM.dartel = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.bias.warped = 1;
        matlabbatch{1}.spm.tools.cat.estwrite.output.jacobian.warped = 0;
        matlabbatch{1}.spm.tools.cat.estwrite.output.warps = [0 0];

        fprintf('matlab batch is running  \n');

% Update and save batch
%[SPGRFileDir SPGRFileName SPGRExt] = fileparts(spgr_seg);
BatchFile = fullfile(seg_dir, [spgr_seg_input_file_name '_batch_VBM.mat']);
save(BatchFile, 'matlabbatch');

% Run batch of segmentation
%cd(OutputDir);
spm_jobman('run', BatchFile);
clear matlabbatch;
%cd(CurrentDir);

    
   % ------  check output files -------------
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ----------- Estimate TIV ---------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   disp('-----------------------------------------------------------');
   disp('+++++ Estimate TIV ++++++');
   
   xmlfile = fullfile(seg_dir,'report',['cat_',spgr_filename,'.xml',]);
   xml_list =dir(xmlfile);
   if isempty(xml_list) | length(xml_list)>1
   error('---- no xml file in %s',[seg_dir,'/report']);
   else
   xml_input = xml_list.name
   end
   matlabbatch{1}.spm.tools.cat.tools.calcvol.data_xml = {fullfile(seg_dir,'report',xml_input)};
   matlabbatch{1}.spm.tools.cat.tools.calcvol.calcvol_TIV = 1;
   matlabbatch{1}.spm.tools.cat.tools.calcvol.calcvol_name = [seg_dir,'/',spgr_filename,'_TIV.txt'];
   
   spm_jobman('run', matlabbatch);
   clear matlabbatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ----------   Smoothing -------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
   disp('-----------------------------------------------------------');
   disp('+++++ smoothing  ++++++');

    matlabbatch{1}.spm.spatial.smooth.data = { fullfile(seg_dir,'mri',['mwp1',spgr_filename,'.nii']);  fullfile(seg_dir,'mri',['mwp2',spgr_filename,'.nii'])  };
    matlabbatch{1}.spm.spatial.smooth.fwhm =  SmoothWidth;
    matlabbatch{1}.spm.spatial.smooth.dtype = 0;
    matlabbatch{1}.spm.spatial.smooth.im = 0;
    matlabbatch{1}.spm.spatial.smooth.prefix = 's';

   spm_jobman('run', matlabbatch);
   clear matlabbatch

   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cd(currentdir);

disp('==================================================================');
disp('VBM  finished');

delete(get(0, 'Children'));
%clear all;
close all;
disp('==================================================================');

end



