global currentdir idata_type run_img;
cd '/oak/stanford/groups/menon/projects/daelsaid/2019_met_unwarpepi/scsnl_script_implementation/';
currentdir = pwd;

%%set and gen paths
addpath(genpath('/oak/stanford/groups/menon/projects/daelsaid/2019_met_unwarpepi/scsnl_script_implementation/'));
addpath(genpath('/home/users/daelsaid/bin/afni_local/'));
ConfigFile='/oak/stanford/groups/menon/projects/daelsaid/2019_met_unwarpepi/scsnl_script_implementation/preprocessfmri_config_oak.m';
SubjectI='9182'; %remove

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('fMRI preprocessing start: %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');

fprintf('Current directory is: %s\n',currentdir);
fprintf('Script: %s\n', which('preprocessfmri_unwarp.m'));
fprintf('Configfile: %s\n', ConfigFile);
fprintf('\n');
disp('------------------------------------------------------------------');

% -------------------------------------------------------------------------
% Check existence of the configuration file
% -------------------------------------------------------------------------
ConfigFile = strtrim(ConfigFile);

if ~exist(ConfigFile,'file')
    fprintf('Cannot find the configuration file %s ..\n',ConfigFile);
    error('Cannot find the configuration file');
end

[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
eval(ConfigFile);
pause(2);
clear ConfigFile;

%%tools
spm_version             = strtrim(paralist.spmversion);
software_path           = ('/oak/stanford/groups/menon/toolboxes/');
spm_path                = fullfile(software_path, spm_version);
spmpreprocscript_path   = fullfile('/oak/stanford/groups/menon/projects/daelsaid/2019_met_unwarpepi/scsnl_script_implementation/preprocessing/',spm_version);
% spmpreprocscript_path   = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/',spm_version);

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding SPM based preprocessing scripts path:  %s\n',spmpreprocscript_path);
addpath(genpath(spmpreprocscript_path));

%% Read in preprocessing config file
config             = paralist;
subject_i          = SubjectI;
subjectlist        = strtrim(config.subjectlist);
runlist            = strtrim(config.runlist);
inputimgprefix     = strtrim(config.inputimgprefix);
wholepipeline      = strtrim(config.pipeline);
pipeline           = wholepipeline(1:end-length(inputimgprefix));
SPGRsubjectlist    = strtrim(config.spgrsubjectlist);
TR                 = double(config.trval);
custom_slicetiming = config.customslicetiming;
slicetiming_file   = strtrim(config.slicetimingfile);
sliceacq           = strtrim(config.sliceacq);
smooth_width       = config.smoothwidth;
boundingboxdim     = config.boundingboxdim;
template_path      = strtrim(config.batchtemplatepath);
data_dir           = strtrim(config.rawdatadir);
project_dir        = strtrim(config.projectdir);
output_folder      = strtrim(config.outputdirname);

try
    SPGRfilename   = strtrim(config.spgrfilename);
catch
    SPGRfilename   = 'spgr';
end

data_type          = 'nii';
SPGR_folder        = 'anatomical';
unnorm_folder      = 'unnormalized';

disp('-------------- Contents of the Parameter List --------------------');
disp(config);

disp('==================================================================');
clear config;

%==========================================================================
if (custom_slicetiming == 1) && isempty(slicetiming_file)
  error('need to specify the slice order file if customized');
end

if ~isfloat(TR)
  error('TR must be a numerical float');
  return;
end

if ismember('u', wholepipeline)
  flipflag = 1;
else
  flipflag = 0;
end

subjectlist       = csvread(subjectlist,1);
subject           = subjectlist(1);

%subject           = subjectlist(subject_i);
subject           = char(pad(string(subject),4,'left','0'));
visit             = num2str(subjectlist(2));
session           = num2str(subjectlist(3));
% visit             = num2str(subjectlist(subject_i,2)); session
% = num2str(subjectlist(subject_i,3));
numsubj           = 1;
runs              = ReadList(runlist);
numrun            = length(runs);

if ~isempty(SPGRsubjectlist)
  SPGRsubjectlist = csvread(SPGRsubjectlist,1);
  SPGRsubject     = SPGRsubjectlist(1);

  %SPGRsubject     = SPGRsubjectlist(subject_i);
  SPGRsubject     = char(pad(string(SPGRsubject),4,'left','0'));
  numSPGRsubj     = 1;
  %SPGRvisit       = num2str(SPGRsubjectlist(subject_i,2));
  %SPGRsession     = num2str(SPGRsubjectlist(subject_i,3));
  SPGRvisit       = num2str(SPGRsubjectlist(2));
  SPGRsession     = num2str(SPGRsubjectlist(3));
else
  SPGRsubject     = subject;
  SPGRvisit       = visit;
  SPGRsession     = session;
  numSPGRsubj     = numsubj;
end

if numSPGRsubj ~= numsubj
  disp('Number of functional subjects is not equal to the number of SPGR subjects');
  return;
end

numtotalrun = numsubj*numrun;
totalrun_dir = cell(numtotalrun, 1);

volrepairflag = zeros(numtotalrun, 1);
volrepairdir = cell(numtotalrun, 1);

pipelinefamily = {'swar','swau','swcau', 'swavr', 'swgcar', 'swgcavr', ...
  'swfar', 'swfavr', 'swgcfar', 'swcar','swgcfavr', 'swcaor'...
  'swaor', 'swgcaor', 'swfaor', 'swgcfaor','swcfaor','swcr'}; %how to adjust?

if any(~ismember(wholepipeline, pipelinefamily))
  disp('Error: unrecognized entire pipeline to be implemented');
  return;
end

spm('defaults', 'fmri');
spm_jobman('initcfg');
delete(get(0, 'Children'));

%%start preproc

runcnt = 0;
for isubj = 1:numsubj
    
  fprintf('Processing subject: %s\n', subject);
  disp('--------------------------------------------------------------');

  %%%%--------- check anatomical folder image at output side --------

   SPGRdir = fullfile(project_dir, '/data/imaging/participants/', SPGRsubject, ['visit',SPGRvisit], ['session',SPGRsession], SPGR_folder);
     if ~exist(SPGRdir,'dir')
     mkdir(SPGRdir);
     end

   SPGRfile_file = '';

  %%%% -------- using the raw anatomical data ---------------------
   SPGRdir_raw = fullfile(data_dir, SPGRsubject,['visit',visit],['session',session], SPGR_folder);
   SPGRfile_file = '';

  %%%---------- locate the anatomical image ------------------------
  if ismember('c', wholepipeline)

     if ismember('g',wholepipeline)

          if isempty(dir(fullfile(SPGRdir, ['seg' ,'_', spm_version],['y_',SPGRfilename,'.nii'])))
            fprintf('>>>>> the deformation of user specified anatomical image is %s \n',fullfile(SPGRdir, ['seg' ,'_', spm_version], ['y_',SPGRfilename,'.nii']));
            error('Error: the deformation of user specified anatomical image is not found, use preprocessmri.m');
          else
            system(sprintf('gunzip -fq %s',fullfile(SPGRdir, ['seg' ,'_', spm_version],[SPGRfilename,'.nii'])));
            SPGRfile_file = fullfile(SPGRdir, ['seg' ,'_', spm_version],[SPGRfilename,'.nii']);
          end

     else
         system(sprintf('gunzip -fq %s', fullfile(SPGRdir, [SPGRfilename, '*.gz'])));
         listfile_file = dir(fullfile(SPGRdir, [SPGRfilename, '.nii']));

         if isempty(listfile_file)
             if strcmp(SPGRfilename,'spgr')

              %%%----- copy original spgr to proprocess folder
              system(sprintf('cp -f %s %s', fullfile(SPGRdir_raw,'spgr.nii*'),SPGRdir));
              system(sprintf('gunzip -fq %s', fullfile(SPGRdir, [SPGRfilename, '*.gz'])));

              else
               %%%---  cannot find the specfic image
              error('<<<<<<<< Please specif anatomical image as spgr or use swgcar  >>>>>>>' );
             end
         end

 %----- update list, check input spgr file again -----

        listfile_file = dir(fullfile(SPGRdir, [SPGRfilename, '.nii']));
        if isempty(listfile_file)
          fprintf('>>>>>> cannot find file: \n  %s \n \n ',fullfile(SPGRdir,[SPGRfilename,'.nii']));
        end
        if length(listfile_file)==1
          SPGRfile_file = fullfile(SPGRdir, listfile_file(1).name);
        elseif length(listfile_file)>1
         error('found more than 1 specified anatomical files' );
        end
     end
     fprintf(' SPGRfile_file is %s \n',SPGRfile_file);
   end

  for irun = 1:numrun
    runcnt = runcnt + 1;

    fprintf('---> run: %s\n', runs{irun});

    totalrun_dir{runcnt} = fullfile(data_dir, subject,['visit',visit],['session',session], 'fmri', runs{irun});
    fullfile(data_dir, subject,['visit',visit],['session',session], 'fmri', runs{irun}) %remove

    if ~exist(totalrun_dir{runcnt}, 'dir')
        
      fprintf('run directory not exists: %s\n', runs{irun});
      
      continue;
    end

    %----- Put tmp directories in scratch in case temp files get stuck.
    fullfile('/scratch/users',getenv('LOGNAME'), 'tmp_files'); %remove
    tmp_dir = fullfile('/scratch/users',getenv('LOGNAME'), 'tmp_files');

    if ~exist(tmp_dir, 'dir')
      mkdir(tmp_dir);
    end

    temp_dir = fullfile(tmp_dir, [subject,['visit',visit],['session',session], runs{irun},'_', tempname,'_', wholepipeline]);
    unnorm_dir = fullfile(totalrun_dir{runcnt}, unnorm_folder);

    if ~exist(unnorm_dir, 'dir')
      continue;
    end

    if isempty(inputimgprefix)
      if ~exist(temp_dir, 'dir')
        mkdir(temp_dir);
      else
        system(sprintf('rm -rf %s', temp_dir));
        mkdir(temp_dir);
      end

      system(sprintf('rm -rf %s', fullfile(temp_dir, '*')));
      system(sprintf('cp -af %s %s', fullfile(unnorm_dir, ['*', data_type, '*']), temp_dir));
      system(sprintf('gunzip -fq %s', fullfile(temp_dir, 'I.nii.gz')));

      if ~exist(fullfile(temp_dir, 'I.nii'), 'file')
        error('<<<<<<<<<< Cannot find I.nii at subject tmp folder in scrath >>>>>>>>>>>>');
      end
    end

    %%%--------------- check output folder-------------------

    output_dir = fullfile(relative_imging_dir,subject,['visit',visit],['session',session],'fmri',runs{irun},output_folder);
    volrepairdir{runcnt} = temp_dir;
    output_dir %remove

    if ~exist(output_dir, 'dir')
       mkdir(output_dir);
    else
     fprintf('>>> ---- the output folder exists----- \n ');

     system(sprintf('rm -rf %s',output_dir));
     mkdir(output_dir);
    end

    output_log = fullfile(output_dir, 'log');

    if ~exist(output_log, 'dir')
       mkdir(output_log);
    end

    if ~isempty(inputimgprefix)
       if ~exist(temp_dir, 'dir')
           error(sprintf('Directory does not exist: %s\n', temp_dir));
       end

       listfile_file = dir(fullfile(temp_dir, 'meanI*'));
       
       if isempty(listfile_file)
           
           error('Error: no meanI* image found when inputimgprefix is not empty');
       else
           meanimg_file = fullfile(temp_dir, listfile_file(1).name);
       end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%  Main Section Start  %%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    prevprefix = inputimgprefix;
    nstep = length(pipeline);

    for cnt = 1:nstep

      p = pipeline(nstep-cnt+1);
      fprintf('+++ at stage %s\n',p);
      switch p

       %%%%%%--------------------------------------------------------------
       %%%%%%------------------------ unwarp ------------------------------
       %%%%%%--------------------------------------------------------------
       
       case 'u'
            listfile_file = dir(fullfile(temp_dir, [prevprefix, 'I.nii.gz']));
            
            run_name=runs{irun};
            subj_prefix=[subject,'_',visit,'_',session,'_',run_name];

            unwarp_output_dir=fullfile(temp_dir,'unWarpOutput_TS');
            tmp_unwarp_output_nii=fullfile(unwarp_output_dir,['06_TS_',subj_prefix,'.nii_HWV.nii.gz']);
            tmp_unwarp_motparams=fullfile(unwarp_output_dir,['TS_',subj_prefix,'.nii_HWV.motion.1D']);
            converted_unwarped_motparams=fullfile(temp_dir,'rp_I.txt');
            
            unwarp_output_nii=fullfile(temp_dir,'meanI.nii.gz');
            unwarp_motparams=fullfile(temp_dir,'rp_I.txt');

            preprocessfmri_unwarp(run_name,subj_prefix,subject,visit,session,temp_dir,project_dir);
                
            if ~exist(unwarp_output_dir,'dir')
                fprintf('No UnWarp output folder exists in scratch dir %s ..\n',temp_dir);
                error('Cannot copy output files the configuration file');
            else
                system(sprintf('bash %s %s %s', fullfile(spmpreprocscript_path,'utils','unwarp_motionfile_convert.sh'),tmp_unwarp_motparams,output_dir));

                copyfile(tmp_unwarp_output_nii,unwarp_output_nii);
                copyfile(converted_unwarped_motparams,output_dir);
                
                listfile_file = dir(fullfile(temp_dir, ['mean', prevprefix, 'I.', data_type]));
                meanimg_file = fullfile(temp_dir, listfile_file(1).name);

                p = fullfile(unwarp_output_nii);
                vy = spm_vol(p);
                numscan = length(vy);
                
                disp('calculating the global signals ...');
                
                fid = fopen(fullfile(output_dir, 'VolumRepair_GlobalSignal.txt'), 'w+');
                for iscan = 1:numscan
                    fprintf(fid, '%.4f\n', spm_global(vy(iscan)));
                end
                fclose(fid);
            end

       %%%%%%---------------------------------------------------
       %%%%%%---------realign ----------------------------------
       %%%%%%---------------------------------------------------
        case 'r'
          
            listfile_file = dir(fullfile(temp_dir, [prevprefix, 'I.nii.gz']));
            if ~isempty(listfile_file)
                system(sprintf('gunzip -fq %s', fullfile(temp_dir, [prevprefix, 'I.nii.gz'])));
            else
                [inputimg_file, selecterr] = preprocessfmri_selectfiles(temp_dir, prevprefix, data_type);
                if selecterr == 1
                    error('Error: no scans selected');
                end
                preprocessfmri_realign(wholepipeline, currentdir,template_path, inputimg_file, temp_dir)
                system(sprintf('/bin/rm -rf %s', fullfile(temp_dir, '*.mat')));
            end

          %%%%----------- copy head motion file from tmp file to output dir -----
          
              listfile_file = dir(fullfile(output_dir, ['rp_', prevprefix, 'I.txt.gz']));
              if ~isempty(listfile_file)
                  system(sprintf('gunzip -fq %', fullfile(output_dir, ['rp_', prevprefix, 'I.txt.gz'])));
              else
                  listfile_file = dir(fullfile(output_dir, ['rp_', prevprefix, 'I.txt']));
                  if isempty(listfile_file)
                      system(sprintf('cp -af %s %s', fullfile(temp_dir, ['rp_', prevprefix, 'I.txt']), output_dir));
                  end
              end

              listfile_file = dir(fullfile(temp_dir, ['mean', prevprefix, 'I.', data_type]));
              meanimg_file = fullfile(temp_dir, listfile_file(1).name);

              
              if strcmpi(data_type, 'img')
                error('Error: IMG format is not supported. Please convert your files to 4D NIFTI format');
              else
                p = fullfile(temp_dir, ['r', prevprefix, 'I.nii']);
              end
              vy = spm_vol(p);
              numscan = length(vy);
              disp('calculating the global signals ...');
              
              fid = fopen(fullfile(output_dir, 'VolumRepair_GlobalSignal.txt'), 'w+');
              
              for iscan = 1:numscan
                fprintf(fid, '%.4f\n', spm_global(vy(iscan)));
              end
              
              fclose(fid);
              
      %%%%%%---------------------------------------------------
      %%%%%%---------Volume Repair-----------------------------
      %%%%%%---------------------------------------------------
        
       case 'v'
              volflag = preprocessfmri_VolRepair(temp_dir, data_type, prevprefix);
              volrepairflag(runcnt) = volflag;
              nifti3Dto4D(temp_dir, prevprefix);
              system(sprintf('gunzip -fq %s', fullfile(temp_dir, ['v', prevprefix, 'I.nii.gz'])));
              
              if volflag == 1
                  disp('Skipping Art_Global (v) step ...');
                  break;
              else
                  system(sprintf('mv -f %s %s', fullfile(temp_dir, 'art_deweighted.txt'), output_dir));
                  system(sprintf('mv -f %s %s', fullfile(temp_dir, 'art_repaired.txt'), output_log));
                  system(sprintf('mv -f %s %s', fullfile(temp_dir, '*.jpg'), output_log));
              end

      %%%%%%---------------------------------------------------
      %%%%%%---------Volume Repair Version O-------------------
      %%%%%%---------------------------------------------------     
          
         case 'o'
          volflag = preprocessfmri_VolRepair_OVersion(temp_dir, data_type, prevprefix);
          volrepairflag(runcnt) = volflag;
          system(sprintf('mv -f %s %s', fullfile(temp_dir, ['v', prevprefix, 'I.nii.gz']), fullfile(temp_dir, ['o', prevprefix, 'I.nii.gz'])));
          system(sprintf('gunzip -fq %s', fullfile(temp_dir, ['o', prevprefix, 'I*.gz'])));


          if volflag == 1
            disp('Skipping Art_Global (o) step ...');
            
            break;
          else
            system(sprintf('mv -f %s %s', fullfile(temp_dir, 'art_deweighted.txt'), fullfile(output_dir, 'art_deweighted_o.txt')));
            system(sprintf('mv -f %s %s', fullfile(temp_dir, 'art_repaired.txt'), fullfile(output_log, 'art_repaired_o.txt')));
            system(sprintf('mv -f %s %s', fullfile(temp_dir, '*.jpg'), output_log));
          end

      %%%%%%---------------------------------------------------
      %%%%%%---------Flip Z direction  ------------------------
      %%%%%%---------------------------------------------------     
        case 'f'
          preprocessfmri_FlipZ(temp_dir, prevprefix);
          
          
      %%%%%%---------------------------------------------------
      %%%%%%--------- Slice timing correction -----------------
      %%%%%%---------------------------------------------------     
      
        case 'a'
          [inputimg_file, selecterr] = preprocessfmri_selectfiles(temp_dir, prevprefix, data_type);
          if selecterr == 1
            error('Error: no scans selected');
          end
          preprocessfmri_slicetime(wholepipeline, template_path, inputimg_file, flipflag, temp_dir, TR, custom_slicetiming, slicetiming_file,sliceacq);

      %%%%%%---------------------------------------------------
      %%%%%%--------- Co-registration  ------------------------
      %%%%%%---------------------------------------------------         
          
        case 'c'
          [inputimg_file, selecterr] = preprocessfmri_selectfiles(temp_dir, prevprefix, data_type);
          if selecterr == 1
            error('Error: no scans selected');
          end
          fprintf('>>>> SPGRfile_file is : %s \n',SPGRfile_file);
          preprocessfmri_coreg(wholepipeline, template_path, data_type, SPGRfile_file, meanimg_file, temp_dir, inputimg_file, prevprefix);

      %%%%%%---------------------------------------------------
      %%%%%%--------- Normalization  ------------------------
      %%%%%%---------------------------------------------------        
             
        case 'w'

          if strcmp(spm_version, 'spm12')
              fprintf('checking version %s \n',which('spm'));
          else
              error('Error: please specify spm_version as spm12');
          end
         
          [inputimg_file, selecterr] = preprocessfmri_selectfiles(temp_dir, prevprefix, data_type);
          if selecterr == 1
            error('Error: no scans selected');
          end
          preprocessfmri_normalize(wholepipeline, currentdir, template_path, boundingboxdim, [pipeline, inputimgprefix], inputimg_file, meanimg_file, temp_dir, SPGRfile_file, spm_path);

       %%%%%%---------------------------------------------------
       %%%%%%--------- Segmentation check  ---------------------
       %%%%%%--segmentation run by other script ----------------
       %%%%%%---------------------------------------------------     
          
        case 'g'

          listfile_file = dir(fullfile(SPGRdir, ['seg' ,'_', spm_version],[ 'y_',SPGRfilename,'.nii']));
          if isempty(listfile_file)
            error('Error: no segmentation has been done, use preprocessmri.m');
          else
            disp('------------------------------------------------------------------');
           fprintf('Segmentation file locates at: \n %s \n \n ',fullfile(SPGRdir, ['seg' '_' spm_version],listfile_file(1).name));


               %%% --- copy y_*.nii to tmp file
              system(sprintf('cp -af %s %s',fullfile(SPGRdir, ['seg' '_' spm_version], listfile_file(1).name),temp_dir));
              
               %%% --- copy arI.nii to tmp file as garI.nii
              listfile_file = dir(fullfile(temp_dir, [prevprefix, 'I.nii']));
              system(sprintf('cp -af %s %s', fullfile(temp_dir, listfile_file(1).name), fullfile(temp_dir, ['g', listfile_file(1).name])));
              
          end

     %%%%%%---------------------------------------------------
     %%%%%%----------------- Smoothing -----------------------
     %%%%%%---------------------------------------------------         
      
        case 's'
          [inputimg_file, selecterr] = preprocessfmri_selectfiles(temp_dir, prevprefix, data_type);
          if selecterr == 1
            error('Error: no scans selected');
          end
          preprocessfmri_smooth(wholepipeline, template_path, inputimg_file, temp_dir, smooth_width);

      end
      prevprefix = [pipeline((nstep-cnt+1):nstep), inputimgprefix];
      disp('------------------------------------------------------------');
    end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%  Main Section End  %%%%%%%%%%%%%%%%%%%%%%%
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    
  
     %%%%%%---------------------------------------------------
     %%%%%%-------Cleaning and copy output--------------------
     %%%%%%---------------------------------------------------      
    if strcmp(prevprefix(1), 's')
        
         %%%%%%--------- delete intermediate images ------------------ 
         
            for iinter = 2:length(prevprefix)
                interprefix = prevprefix(iinter:end);
                listfile_file = dir(fullfile(temp_dir, [interprefix, 'I.nii']));
                num_file = length(listfile_file);
                for iinter_file = 1:num_file
                    system(sprintf('rm -rf %s', fullfile(temp_dir, listfile_file(iinter_file).name)));
                end
            end
            system(sprintf('rm -rf %s', fullfile(temp_dir, '*.mat')));

            
      
         %%%%%%--------- compresss and copy final images to output dir ------------ 
          
          system(sprintf('gzip -fq %s', fullfile(temp_dir, [prevprefix, 'I*.nii'])));
          system(sprintf('gzip -fq %s', fullfile(temp_dir, 'meanI*.nii')));
          system(sprintf('cp -af %s %s', fullfile(temp_dir, 'meanI*'), output_dir));

          if ismember('f', prevprefix)
              f_flist = dir(fullfile(temp_dir, [prevprefix, 'I.nii.gz']));
              fl_name = f_flist(1).name;
              f_file = fullfile(temp_dir, fl_name);
              f_part = strsplit(fl_name, 'f');
              new_flname = [f_part{1}, f_part{2}];
              system(sprintf('mv -f %s %s', f_file, fullfile(output_dir, new_flname)));
          else
              system(sprintf('cp -af %s %s', fullfile(temp_dir, [prevprefix, 'I.nii.gz']), output_dir));
          end
      
          system(sprintf('cp -af %s %s', fullfile(temp_dir, 'log', '*.mat'), fullfile(output_dir, 'log')));
          
         %%%%%---------- mv *.nii to mirroring folder  in scratch partition -------------------------
         
         div_project_dir = regexp(project_dir,filesep,'split');
         div_project_dir
         
         scratch_folder =  fullfile('/scratch/groups/menon/projects/',div_project_dir{end-2},div_project_dir{end-1},'/data/imaging/participants/',subject,['visit',visit],['session',session],'fmri', runs{irun});
         fprintf('scratch output folder is : \n %s \n ', scratch_folder);
         mkdir(scratch_folder,output_folder);

         system(sprintf('mv -f  %s %s', fullfile(output_dir, [prevprefix, 'I.nii.gz']), fullfile(scratch_folder,output_folder)));          
         system(sprintf('ln -sT %s %s ',fullfile(scratch_folder,output_folder,[prevprefix,'I.nii.gz']),fullfile(output_dir,[prevprefix,'I.nii.gz'])));          

         %%%%%--------completely deletet the tmp folder -------------------   
         system(sprintf('rm -rf %s', temp_dir));
          
    end 
  end
      
end

cd(currentdir);

disp('==================================================================');
if ~strcmp(prevprefix(1), 's') && ismember('c', wholepipeline)
  disp('Please check coregistration quality');
else
  disp('Preprocessing finished');
end

delete(get(0, 'Children'));
clear all;
close all;
disp('==================================================================');
      
       