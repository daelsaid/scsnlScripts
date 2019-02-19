function preprocessfmri(SubjectI, ConfigFile)

% tianwenc, 2011-12-02,  created preprocessfmri.m
% ksupekar, 2018-02-08,  edited for better compatibility with vsochat
% container
% ksupekar&yuanzh, 2018-02-12, removed wildcard character *
% ksupekar&yuanzh, 2018-02-12, removed support for SPM analyze format
% ksupekar, 2018-02-21, added a check that spmversion in config file is
% correctly set to spm8

currentdir = pwd;

disp('==========================e========================================');
fprintf('Current directory: %s\n', currentdir);
fprintf('Script: %s\n', which('preprocessfmri.m'));
fprintf('Configfile: %s\n', ConfigFile);
fprintf('\n');

if ~exist(ConfigFile, 'file')
    error('cannot find the configuration file')
end
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
eval(ConfigFile);
clear ConfigFile;

config                  = paralist;
spm_version             = strtrim(config.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
spmpreprocscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/' spm_version]; %'/oak/stanford/groups/menon/scsnlscripts_vsochat/fmri/spm/spm8/preprocessing/';

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding SPM based preprocessing scripts path: %s\n', spmpreprocscript_path);
addpath(genpath(spmpreprocscript_path));

subject_i          = SubjectI;
spmversion         = strtrim(config.spmversion);
subjectlist        = strtrim(config.subjectlist);
runlist            = strtrim(config.runlist);
inputimgprefix     = strtrim(config.inputimgprefix);
wholepipeline      = strtrim(config.pipeline);
pipeline           = wholepipeline(1:end-length(inputimgprefix));
SPGRsubjectlist    = strtrim(config.spgrsubjectlist);
TR                 = double(config.trval);
custom_slicetiming = config.customslicetiming;
slicetiming_file   = strtrim(config.slicetimingfile);
smooth_width       = config.smoothwidth;
boundingboxdim     = config.boundingboxdim;
template_path      = strtrim(config.batchtemplatepath);
data_dir           = strtrim(config.rawdatadir);
project_dir        = strtrim(config.projectdir);
output_folder      = strtrim(config.outputdirname);

try
    SPGRfilename   = strtrim(config.spgrfilename);
catch e
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
if ~strcmp(spmversion, spm_version)
  error('spm version mismatch');
end

if (custom_slicetiming == 1) && isempty(slicetiming_file)
  error('need to specify the slice order file if customized');
end

if ~exist(template_path, 'dir')
  error('template folder does not exist!');
  return;
end

if ~isfloat(TR)
  error('TR must be a numerical float');
  return;
end

if ismember('f', wholepipeline)
  flipflag = 1;
else
  flipflag = 0;
end

subjectlist       = csvread(subjectlist,1);
subject           = subjectlist(subject_i);
subject           = char(pad(string(subject),4,'left','0'));
visit             = num2str(subjectlist(subject_i,2));
session           = num2str(subjectlist(subject_i,3));

numsubj           = 1;
runs              = ReadList(runlist);
numrun            = length(runs);

if ~isempty(SPGRsubjectlist)
  SPGRsubjectlist = csvread(SPGRsubjectlist,1);
  SPGRsubject     = SPGRsubjectlist(subject_i);
  SPGRsubject     = char(pad(string(SPGRsubject),4,'left','0'));
  numSPGRsubj     = 1;
  SPGRvisit       = num2str(SPGRsubjectlist(subject_i,2));
  SPGRsession     = num2str(SPGRsubjectlist(subject_i,3));
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

pipelinefamily = {'swar', 'swavr', 'swgcar', 'swgcavr', ...
  'swfar', 'swfavr', 'swgcfar', 'swgcfavr', ...
  'swaor', 'swgcaor', 'swfaor', 'swgcfaor'};

% if any(~ismember(wholepipeline, pipelinefamily))
%   disp('Error: unrecognized entire pipeline to be implemented');
%   return;
% end

spm('defaults', 'fmri');
spm_jobman('initcfg');
delete(get(0, 'Children'));

runcnt = 0;
for isubj = 1:numsubj
  fprintf('Processing subject: %s\n', subject);

  SPGRdir = fullfile(project_dir, '/data/imaging/participants/', SPGRsubject, ...
    ['visit',SPGRvisit], ['session',SPGRsession], SPGR_folder);
  
  SPGRfile_file = '';
  
  if ismember('c', wholepipeline)
    unix(sprintf('gunzip -fq %s', fullfile(SPGRdir, [SPGRfilename, '.nii.gz'])));
    listfile_file = dir(fullfile(SPGRdir, [SPGRfilename, '.nii']));
    SPGRfile_file = fullfile(SPGRdir, listfile_file(1).name);
  end

  for irun = 1:numrun
    runcnt = runcnt + 1;
    errcnt = 1;
    fprintf('---> run: %s\n', runs{irun});

    totalrun_dir{runcnt} = fullfile(data_dir, subject,['visit',visit],['session',session], 'fmri', ...
      runs{irun});
    if ~exist(totalrun_dir{runcnt}, 'dir')
      fprintf('run directory not exists: %s\n', runs{irun});
      continue;
    end
    
    % Put tmp directories in scratch in case  temp files get stuck.
    tmp_dir = fullfile('/scratch/users',getenv('LOGNAME'), 'tmp_files');
    tmp_dir
    if ~exist(tmp_dir, 'dir')
      mkdir(tmp_dir);
    end
      
    temp_dir = fullfile(tmp_dir, [subject,['visit',visit],['session',session], ...
      runs{irun},'_', tempname,'_', wholepipeline]);
    
    unnorm_dir = fullfile(totalrun_dir{runcnt}, unnorm_folder);

    if ~exist(unnorm_dir, 'dir')
      continue;
    end

    if isempty(inputimgprefix)
      if ~exist(temp_dir, 'dir')
        mkdir(temp_dir);
      else
        unix(sprintf('rm -rf %s', temp_dir));
        mkdir(temp_dir);
      end
      unix(sprintf('rm -rf %s', fullfile(temp_dir, '*')));
      unix(sprintf('cp -af %s %s', fullfile(unnorm_dir, ['I.', data_type, '*']), ...
        temp_dir));
      unix(sprintf('gunzip -fq %s', fullfile(temp_dir, 'I.nii.gz')));
      if ~exist(fullfile(temp_dir, 'I.nii'), 'file')
        continue;
      end
    end

   imaging_path = '/data/imaging/participants/';
   output_dir = fullfile(project_dir,imaging_path,subject,['visit',visit],['session',session],'fmri',...
       runs{irun}, output_folder);
     
    volrepairdir{runcnt} = temp_dir;

    if ~exist(output_dir, 'dir')
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
      listfile_file = dir(fullfile(temp_dir, 'meanI.nii*'));
      if isempty(listfile_file)
        error('Error: no meanI.nii* image found when inputimgprefix is not empty');
      else
        meanimg_file = fullfile(temp_dir, listfile_file(1).name);
      end
    end

    prevprefix = inputimgprefix;
    nstep = length(pipeline);

    for cnt = 1:nstep

      p = pipeline(nstep-cnt+1);

      switch p
        case 'r'
          listfile_file = dir(fullfile(temp_dir, [prevprefix, 'I.nii.gz']));
          if ~isempty(listfile_file)
            unix(sprintf('gunzip -fq %s', fullfile(temp_dir, [prevprefix, 'I.nii.gz'])));
          else
            [inputimg_file, selecterr] = preprocessfmri_selectfiles(temp_dir, prevprefix, data_type);
            if selecterr == 1
              error('Error: no scans selected');
            end
            preprocessfmri_realign(wholepipeline, currentdir, template_path, inputimg_file, temp_dir)
            unix(sprintf('/bin/rm -rf %s', fullfile(temp_dir, '*.mat')));
          end

          listfile_file = dir(fullfile(output_dir, ['rp_', prevprefix, 'I.txt.gz']));
          if ~isempty(listfile_file)
            unix(sprintf('gunzip -fq %', fullfile(output_dir, ['rp_', prevprefix, 'I.txt.gz'])));
          else
            listfile_file = dir(fullfile(output_dir, ['rp_', prevprefix, 'I.txt']));
            if isempty(listfile_file)
              unix(sprintf('cp -af %s %s', fullfile(temp_dir, ['rp_', prevprefix, 'I.txt']), output_dir));
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

        case 'v'
          volflag = preprocessfmri_VolRepair(temp_dir, data_type, prevprefix);
          volrepairflag(runcnt) = volflag;
          nifti3Dto4D(temp_dir, prevprefix);
          unix(sprintf('gunzip -fq %s', fullfile(temp_dir, ['v', prevprefix, 'I.nii.gz'])));

          if volflag == 1
            disp('Skipping Art_Global (v) step ...');
            break;
          else
            unix(sprintf('mv -f %s %s', fullfile(temp_dir, 'art_deweighted.txt'), output_dir));
            %unix(sprintf('mv -f %s %s', fullfile(temp_dir, 'ArtifactMask.nii'), output_log));
            unix(sprintf('mv -f %s %s', fullfile(temp_dir, 'art_repaired.txt'), output_log));
            unix(sprintf('mv -f %s %s', fullfile(temp_dir, '*.jpg'), output_log));
          end

         case 'o'
          volflag = preprocessfmri_VolRepair_OVersion(temp_dir, data_type, prevprefix);
          volrepairflag(runcnt) = volflag;
          %nifti3Dto4D(temp_dir, prevprefix);
          unix(sprintf('mv -f %s %s', fullfile(temp_dir, ['v', prevprefix, 'I.nii.gz']), fullfile(temp_dir, ['o', prevprefix, 'I.nii.gz'])));
          unix(sprintf('gunzip -fq %s', fullfile(temp_dir, ['o', prevprefix, 'I.nii.gz'])));


          if volflag == 1
            disp('Skipping Art_Global (o) step ...');
            break;
          else
            unix(sprintf('mv -f %s %s', fullfile(temp_dir, 'art_deweighted.txt'), fullfile(output_dir, 'art_deweighted_o.txt')));
            %unix(sprintf('mv -f %s %s', fullfile(temp_dir, 'ArtifactMask.nii'), output_log));
            unix(sprintf('mv -f %s %s', fullfile(temp_dir, 'art_repaired.txt'), fullfile(output_log, 'art_repaired_o.txt')));
            unix(sprintf('mv -f %s %s', fullfile(temp_dir, '*.jpg'), output_log));
          end


        case 'f'
          preprocessfmri_FlipZ(temp_dir, prevprefix);

        case 'a'
          [inputimg_file, selecterr] = preprocessfmri_selectfiles(temp_dir, prevprefix, data_type);
          if selecterr == 1
            error('Error: no scans selected');
          end
          preprocessfmri_slicetime(wholepipeline, template_path, inputimg_file, flipflag, temp_dir, TR, custom_slicetiming, slicetiming_file);

        case 'c'
          [inputimg_file, selecterr] = preprocessfmri_selectfiles(temp_dir, prevprefix, data_type);
          if selecterr == 1
            error('Error: no scans selected');
          end

          preprocessfmri_coreg(wholepipeline, template_path, data_type, SPGRfile_file, meanimg_file, temp_dir, inputimg_file, prevprefix);

        case 'w'
          if strcmp(spm_version, 'spm8')
            template_file = '/oak/stanford/groups/menon/software/spm8/templates/EPI.nii';
          end
          if strcmp(spm_version, 'spm12')
            template_file = '/oak/stanford/groups/menon/software/spm12/toolbox/OldNorm/EPI.nii';
          end

          if ~ismember('g', wholepipeline) && ~ismember('c', wholepipeline)
            w_img_file = fullfile(temp_dir, [prevprefix, 'I.nii']);
          end

          [inputimg_file, selecterr] = preprocessfmri_selectfiles(temp_dir, prevprefix, data_type);
          if selecterr == 1
            error('Error: no scans selected');
          end
          preprocessfmri_normalize(wholepipeline, currentdir, template_path, boundingboxdim, [pipeline, inputimgprefix], inputimg_file, meanimg_file, temp_dir, SPGRfile_file, spm_version);

        case 'g'
          listfile_file = dir(fullfile(SPGRdir, ['seg' '_' spm_version], [SPGRfilename '_seg_sn.mat']));
          if isempty(listfile_file)
            error('Error: no segmentation has been done, use preprocessfmri_seg.m');
          else
            if strcmp(data_type, 'img')
              error('Error: IMG format is not supported. Please convert your files to 4D NIFTI format');
            else
              listfile_file = dir(fullfile(temp_dir, [prevprefix, 'I.nii']));
              unix(sprintf('cp -af %s %s', fullfile(temp_dir, listfile_file(1).name), ...
                fullfile(temp_dir, ['g', listfile_file(1).name])));
            end
          end

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

    if strcmp(prevprefix(1), 's')
      for iinter = 2:length(prevprefix)
        interprefix = prevprefix(iinter:end);
        listfile_file = dir(fullfile(temp_dir, [interprefix, 'I.nii']));
        num_file = length(listfile_file);
        for iinter_file = 1:num_file
          unix(sprintf('rm -rf %s', fullfile(temp_dir, listfile_file(iinter_file).name)));
        end
      end
      unix(sprintf('rm -rf %s', fullfile(temp_dir, '*.mat')));
      unix(sprintf('gzip -fq %s', fullfile(temp_dir, [prevprefix, 'I.nii'])));
      unix(sprintf('gzip -fq %s', fullfile(temp_dir, 'meanI.nii')));
      unix(sprintf('mv -f %s %s', fullfile(temp_dir, 'meanI.nii.gz'), output_dir));
      if ismember('f', prevprefix)
        f_flist = dir(fullfile(temp_dir, [prevprefix, 'I.nii.gz']));
        fl_name = f_flist(1).name;
        f_file = fullfile(temp_dir, fl_name);
        f_part = strsplit(fl_name, 'f');
        new_flname = [f_part{1}, f_part{2}];
        unix(sprintf('mv -f %s %s', f_file, fullfile(output_dir, new_flname)));
      else
        unix(sprintf('mv -f %s %s', fullfile(temp_dir, [prevprefix, 'I.nii.gz']), output_dir));
      end
      unix(sprintf('mv -f %s %s', fullfile(temp_dir, 'log', 'batch_*.mat'), fullfile(output_dir, 'log')));
      listfile_file = dir(fullfile(output_dir, '*.mat*'));
      if ~isempty(listfile_file)
        unix(sprintf('rm -rf %s', fullfile(output_dir, '*.mat*')));
      end
      listfile_file = dir(fullfile(output_dir, '*.jpg*'));
      if ~isempty(listfile_file)
        unix(sprintf('rm -rf %s', fullfile(output_dir, '*.jpg*')));
      end
      unix(sprintf('rm -rf %s', temp_dir));
    end
  end
  if all(ismember('sc', [pipeline, inputimgprefix]))
    unix(sprintf('gzip -fq %s', SPGRfile_file));
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

end
