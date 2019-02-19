function scsnl_gPPI_auto(SubjectI,Config_File)
%-Complete gPPI analysis for SCSNL data and analysis pipeline
%-Rui Yuan, 08/21/2018 Beta Version 

currentdir = pwd;
warning('off', 'MATLAB:FINITE:obsoleteFunction');
c = fix(clock);
disp('==================================================================');
fprintf('gPPI analysis started at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
%fname = sprintf('scsnl_gPPI-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
disp(['Current directory is: ',currentdir]);
fprintf('Script: %s\n', which('scsnl_gPPI_auto.m'));
fprintf('Configfile: %s\n', Config_File);
fprintf('\n');
%diary(fname);
%disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');

%----------Check existence of the configuration file -----------------
Config_File = strtrim(Config_File);

%if ~exist(Config_File,'file')
%  fprintf('Cannot find the configuration file ... \n');
%  diary off;
%  return;
%end
%Config_File = Config_File(1:end-2);

if ~exist(Config_File,'file')
    	fprintf('Cannot find the configuration file %s ..\n',Config_File);
    	error('Cannot find the configuration file');
end
	
[Config_FilePath, Config_File, Config_FileExt] = fileparts(Config_File);

%-----------------------Load  parameters ---------------------------
current_dir = pwd;
eval(Config_File);
clear Config_File;

%-------------- add SPM toolbox to search path ----------------------------
spm_version = strtrim(paralist.spmversion); %'spm12';
spm_path = fullfile('/oak/stanford/groups/menon/toolboxes/',spm_version);
PPPI_core_scripts_path = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/connectivity/effective/gppi/',spm_version,'/utils/PPPI_v2012_1_22/');
Common_scripts_path = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/',spm_version,'/utils/');
template_path  = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/',spm_version,'/preprocessfmrimodules/batchtemplates');

fprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
addpath(genpath(PPPI_core_scripts_path));
addpath(genpath(Common_scripts_path));


data_server    		  = strtrim(paralist.projectdir);
%subjects       	  = ReadList(strtrim(paralist.subject_list));
subjectlist     	  = csvread(strtrim(paralist.subjectlist),1);
stats_folder    	  = strtrim(paralist.stats_folder);
gPPI_output_folder        = paralist.gPPI_output_folder;
num_subj        	  = size(subjectlist,1);
roi_file        	  = ReadList(paralist.roi_file_list);
roi_name        	  = ReadList(paralist.roi_name_list);
num_roi_name    	  = length(roi_name);
num_roi_file    	  = length(roi_file);
tasks_to_include	  = paralist.tasks_to_include;
confound_names  	  = paralist.confound_names;
contrastmat     	  = strtrim(paralist.contrastmat);
copy_type       	  = paralist.copy_type;
mask_file       	  = paralist.maskfile;
extract_type              = paralist.extract_type; 


if num_roi_name ~= num_roi_file
        error('number of ROI files not equal to number of ROI names');
end


fprintf('subjectI is %d \n',SubjectI);
subject_i         = SubjectI;
subject           = subjectlist(subject_i);
subject           = char(pad(string(subject),4,'left','0'));
%    subject           = num2str(subjectlist(subject_i,1));
visit             = num2str(subjectlist(subject_i,2));
session           = num2str(subjectlist(subject_i,3));
num_subj  = 1;

disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

%----------------------Preparing folder and files ----------------------------------    
    
for i_subj = 1:num_subj
        
    fprintf('------> processing subject: %s\n', subject);

% -------------------- create tmp file in scratch -------------------------------
    tmp_dir = fullfile('/scratch/users',getenv('LOGNAME'), 'tmp_files');
    if ~exist(tmp_dir, 'dir')
      mkdir(tmp_dir);
    end

    temp_dir = fullfile(tmp_dir, [sprintf('%s',subject),['visit',visit],['session',session], ...
                         stats_folder,'_spm12_gPPI', tempname]);

      if ~exist(temp_dir, 'dir')
        mkdir(temp_dir);
      else
        remdir(temp_dir,'s');
        mkdir(temp_dir);
      end

    fprintf('------> temp_dir is : %s  \n', temp_dir);
  
%------------------------prepare SPM folder and input files ---------------------
             
        %-directory of SPM.mat file
        subject_stats_dir = fullfile(data_server, '/results/taskfmri/participants',...
                            sprintf('%s',subject), ['visit',visit],['session',session],'glm', ['stats_', spm_version], stats_folder);
        fprintf('------> subject_stats_dir : %s \n',subject_stats_dir);

       if isempty(gPPI_output_folder)
        subject_gPPI_stats_dir = fullfile(data_server, '/results/taskfmri/participants',sprintf('%s',subject),...
                                  ['visit',visit],['session',session],'glm', ['stats_', spm_version], [stats_folder, '_gPPI']);
       else
         subject_gPPI_stats_dir = fullfile(data_server, '/results/taskfmri/participants',sprintf('%s',subject),...
                                  ['visit',visit],['session',session],'glm', ['stats_', spm_version], gPPI_output_folder);
       end
        fprintf('------> subject_gPPI_stats_dir : %s \n',subject_gPPI_stats_dir); 
   
        %---- remove the previous folder, create a new one ------
        if ~exist(subject_gPPI_stats_dir, 'dir')
            mkdir(subject_gPPI_stats_dir);
        %else
        % rmdir(subject_gPPI_stats_dir,'s');
        % mkdir(subject_gPPI_stats_dir);
        end
        
        %cd(subject_gPPI_stats_dir);
        %-------delete existing files in gPPI stats folder
        %unix('rm -rf *.*');
        %copyfile(fullfile(subject_stats_dir, 'SPM.mat'), subject_gPPI_stats_dir,'f') ;
       % pause(10);

        cd(temp_dir);
        copyfile(fullfile(subject_stats_dir, 'SPM.mat'), temp_dir,'f') ;

        load('SPM.mat');
        SPM.swd = pwd;
        
        copyfile(fullfile(subject_stats_dir, '*.nii'), temp_dir,'f') ;
        
        %-Update the SPM path for gPPI analysis
        
        num_sess = numel(SPM.Sess);
        
        img_name = cell(num_sess, 1);
        img_path = cell(num_sess, 1);
        num_scan = [1, SPM.nscan];
        
        for i_sess = 1:num_sess
            first_scan_sess = sum(num_scan(1:i_sess));
            img_name{i_sess} = SPM.xY.VY(first_scan_sess).fname;
            img_path{i_sess} = fileparts(img_name{i_sess});
            unix(sprintf('gunzip -fq %s', [img_name{i_sess}, '.gz']));
        end
    
 %---------------------- loop through all ROIs ------------------------------
    
 for i_roi = 1:num_roi_file
 
   disp('  ');
   disp('>>>>>>  >>>>>>>  >>>>>>  >>>>>>  >>>>>>  >>>>>>  >>>>>>>  >>>>>>>  >>>>>>>  >>>>>>>>  >>>>>>>  >>>>>>');
    %----  set up inputs from individual stats ---------------    
       % cd(subject_gPPI_stats_dir);
        %--delete existing files in gPPI stats folder
       % unix('rm -rf *.nii');
       
       % copyfile(fullfile(subject_stats_dir, 'SPM.mat'), subject_gPPI_stats_dir,'f');
       % pause(10); 
       
       % copyfile(fullfile(subject_stats_dir, '*.nii'), subject_gPPI_stats_dir,'f') ;
       % pause(10);

        
        cd(temp_dir);
       % unix('rm -rf *.nii');
        copyfile(fullfile(subject_stats_dir, 'SPM.mat'), temp_dir,'f');
       % pause(10);
       % copyfile(fullfile(subject_stats_dir, '*.nii'), temp_dir,'f') ;
       % pause(10);


        load('SPM.mat');
        SPM.swd = pwd;
           
       % subject_roi_gPPI_stats_dir = sprintf('%s/PPI_rui_%s',subject_gPPI_stats_dir,roi_name{i_roi});
         subject_roi_gPPI_stats_dir = sprintf('%s/PPI_%s',temp_dir,roi_name{i_roi});
       
        fprintf('\n');
        fprintf('subject_roi_gPPI_stats_dir is %s \n',subject_roi_gPPI_stats_dir);

        if exist(subject_roi_gPPI_stats_dir,'dir')   
            rmdir(subject_roi_gPPI_stats_dir,'s');
        end

    %   [status, msg, msgID] = mkdir(subject_roi_gPPI_stats_dir);
        
      %  ------  set up P --------------------------
         
           fprintf('===> gPPI for ROI: %s \n', roi_name{i_roi});
         
           load('ppi_master_template.mat');
           P.SPMver = spm_version;
           P.Estimat = 1;
           P.contrast = {'Omnibus F-test for PPI Analyses'};
           P.subject = subject;
           %P.directory = subject_gPPI_stats_dir; 
           P.directory = temp_dir;
           P.VOI = roi_file{i_roi};
           P.Region = roi_name{i_roi};
           P.Weights = 0;
           P=rmfield(P,'VOI2'); 
          % P.Region = [roi_name{i_roi},' ',roi_name{i_roi2}];
            %P.extract = 'eig';
            %P.extract = 'mean';
            P.extract= extract_type;
            P.CompContrasts = 0;
            P.Tasks = tasks_to_include;
              P.FLmask = 1;

            P.equalroi = 0;
            %P.outdir = subject_roi_gPPI_stats_dir;
            P.analysis = 'psy';  % 'psy', 'phys','psyphy';
            P.method = 'cond'; 
           %P.maskdir = maskdir;
            
      % --------Set up confounds--------------------
               
        iG = [];
        col_name = SPM.xX.name;
        
        num_confound = length(confound_names);
        
        for i_c = 1:num_confound
            iG_exp = ['^Sn\(.*\).', confound_names{i_c}, '$'];
            iG_match = regexpi(col_name, iG_exp);
            iG_match = ~cellfun(@isempty, iG_match);
            if sum(iG_match) == 0
                error('confound columns are not well defined or found');
            else
                iG = [iG find(iG_match == 1)];
            end
        end
        
        if length(iG) ~= num_confound*num_sess
            error('number of confound columns does not match SPM design');
        end
        
     % ------add one more contrast --------------------------

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
        
        save SPM.mat SPM;
        clear SPM;


       % ------------ run PPPI -------------------------------------------

        %User input required (change analysis to be more specific)
        
        if ~isempty(mask_file)
            if exist(mask_file,'file') == 0
                 error('>>>>>>>> cannot the mask file');
            end
         P.FLmask =1;
         P.maskdir=mask_file;
         save(['gPPI_', subject, '_analysis_', roi_name{i_roi},'.mat'], 'P');
         PPPI_rui(['gPPI_', subject, '_analysis_', roi_name{i_roi},'.mat']);

        else
          save(['gPPI_', subject, '_analysis_', roi_name{i_roi},'.mat'], 'P');
          PPPI_rui(['gPPI_', subject, '_analysis_', roi_name{i_roi},'.mat']);
   
        end
      %------------------------------------------------------------------

%        cd(subject_gPPI_stats_dir);i
        cd(temp_dir);
        delete('SPM.mat');
        unix(sprintf('/bin/mv -f %s %s', '*.mat', ['PPI_', roi_name{i_roi}]));
        unix(sprintf('/bin/mv -f %s %s', '*.log', ['PPI_', roi_name{i_roi}]));
               
   %end   
 end    
       
        delete('*.nii');  
        for i_sess = 1:num_sess
            unix(sprintf('gzip -fq %s', img_name{i_sess}));
        end
       

c = fix(clock);
disp('=====================================================================');
fprintf('gPPI step_1 finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('=====================================================================');

    cd(temp_dir);
 %-------------- check all results ----------------------
 % examinate whether the  number of folder matches with ROIs
      results_list= dir('PPI_*');
      ifolder= [results_list(:).isdir];
      name_list = {results_list(ifolder).name}';
      name_list(ismember(name_list,{'.','..'})) = [];
      celldisp(name_list);

      fprintf('>>> user specify %d ROI names \n',length(roi_name));
      fprintf('>>> In total, there are %d seed ROIs folder \n',size(name_list,1));
     
      if size(name_list,1) ~= length(roi_name)
          error('It seems some ROIs got lost !!!! ');

      end
    disp('------ complete checking ----- now we are 100% sure ');
 %-------- copy files ---------------     
    % fprintf('>>> copying from %s \n >>> to %s \n',temp_file, subject_gPPI_stats_dir);
    % for ii = 1: size(name_list,1) 
    % cp_status= copyfile(name_list{i},subject_gPPI_stats_dir,'f');
    % fprintf('copying %s \n',name_list{i});
    %    if cp_status ~= 1
    %     error('file copying fails');
    %    end 
    % end

  
c = fix(clock);
disp('========================================================================');
fprintf('gPPI Contrast Change Multi starts at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('========================================================================');

%paralist.participant_path = '/oak/stanford/groups/menon/projects/ruiyuan/2018_opto/results/taskfmri/participants/';
%paralist.contrastmat = 'contrasts_gPPI_nomvt.mat';
%paralist.stats_folder = {'CG_sgwra_gPPI/PPI_seed_CG'};
%template_path       = strtrim(paralist.template_path);


	if ~exist(fullfile(current_dir,contrastmat), 'file')
   		 error('Cannot find contrast definition file ... \n');
	end


	load(fullfile(current_dir,contrastmat));
	spm_jobman('initcfg');
	delete(get(0,'Children'));

  for k_roi = 1:num_roi_file

        subdir = fullfile(temp_dir,['PPI_', roi_name{k_roi}]);
        fprintf('>>> subdir is %s \n',subdir);
        cd(subdir);

        if exist(contrastmat,'file')
            delete(contrastmat);
        end

        if exist('contrasts.mat','file') 
             delete('contrasts.mat');       
        end

        if exist('batch_contrastchange.mat', 'file')
            delete('batch_contrastchange.mat');
        end

        condir = fullfile(currentdir,contrastmat);
        fprintf('condir is %s \n',condir);

        copyfile(condir,'contrasts.mat');
        %unix(sprintf('/bin/cp -af %s contrasts.mat', condir));

   % -------------------------------------------------------------------------
        load(fullfile(template_path, 'batch_contrastchange.mat'));

        matlabbatch{1}.spm.stats.con.spmmat = {};
        matlabbatch{1}.spm.stats.con.spmmat{1} = fullfile(subdir,'SPM.mat');
        matlabbatch{1}.spm.stats.con.delete = 1;
        for ii =1:length(contrastNames)
            if (ii <= numTContrasts)
                matlabbatch{1}.spm.stats.con.consess{ii}.tcon.name   = contrastNames{ii};
                matlabbatch{1}.spm.stats.con.consess{ii}.tcon.convec = contrastVecs{ii};
            elseif (ii > numTContrasts)
                matlabbatch{1}.spm.stats.con.consess{ii}.fcon.name = contrastNames{ii};
                for j=1:length(contrastVecs{i}(:,1))
                    matlabbatch{1}.spm.stats.con.consess{i}.fcon.convec{j} = ...
                        contrastVecs{ii}(j,:);
                end
            end
        end
        save batch_contrastchange matlabbatch;
        clear matlabbatch;
        spm_jobman('run', './batch_contrastchange.mat');
    
 end

c = fix(clock);
disp('==================================================================');
fprintf('gPPI Contrast Change finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');

 %--------check contrast output files -------------------
    cd(temp_dir);
 %-------------- check all results ----------------------
 % examinate whether the  number of folder matches with ROIs
  for k_roi = 1:num_roi_file
      subdir = fullfile(temp_dir,['PPI_', roi_name{k_roi}]);
      cd(subdir)
      results_list= dir('con_*.nii');
      if length(contrastNames) == length(results_list)
           fprintf('%s \n contains all con maps \n',subdir);
      else
          error('in ROI folder %s \n some contrasts are missing \n',subdir); 
     end
  end

 disp('------ complete checking of contrasts----- now we are 100% sure ');
 disp(' ');
   
c = fix(clock);
disp('==================================================================');
fprintf('Extract gPPI ROI stats starts at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');


   target_roi_file = roi_file;
   num_target_file  = length(target_roi_file);   

    load(fullfile(current_dir,contrastmat));   
    fprintf('>>>>> there are %d contrasts \n',length(contrastNames));
    
    if  length(contrastNames)> numTContrasts
       fprintf('------- There are %d T contrasts, and %d F contrasts  \n',numTContrasts,length(contrastNames)-numTContrasts);
    end

    roi_stats_matrix = zeros(num_target_file,num_roi_file,length(contrastNames));

     for j = 1:num_roi_file
         subdir = fullfile(temp_dir,['PPI_', roi_name{j}]);
         cd(subdir);
         fprintf('>>> working on %s \n',subdir);
         for nCon = 1:length(contrastNames)
            fprintf('>>> contrast %d \n',nCon);
            roi_stats_file = fullfile(temp_dir, ['PPI_', roi_name{j}], ['con_',sprintf('%04d',nCon),'.nii']);
            roi_stats = spm_read_vols(spm_vol(roi_stats_file));
   
           %roi_stats(any(any(isnan(roi_stats),3),2),:,:) = 0; %Take out NaN
           % roi_stats = roi_stats(:);
           
              for k = 1:num_target_file
                target_roi_d = spm_read_vols(spm_vol(target_roi_file{k}));
                target_vox_idx = find(target_roi_d);
                roi_stats_matrix(k,j,nCon) = nanmean(roi_stats(target_vox_idx)); %j to seed,  k to target
              end
         end
      end       
           %change diagonal into zeros
%          gPPI_matrix = gPPI(nCon).roi_stats_matrix(:,:,i) - diag(diag(gPPI(nCon).roi_stats_matrix(:,:,i)));
%          allSubj_gPPI_matrix1(:,:,i) = gPPI_matrix;
%          temp = (triu(gPPI_matrix)' + tril(gPPI_matrix))./2; %Take the average of upper and lower triangular parts of the matrix
%          ww = temp + temp'; %%Translate into a symetrical matrix
%          allSubj_gPPI_matrix2(:,:,i) = ww;
%          clear gPPI_matrix ww temp;
    cd(temp_dir);
    for nCon = 1: length(contrastNames)
          gppi_matrix = squeeze(roi_stats_matrix(:,:,nCon));
          fprintf('the size of gPPI_matrix: %d %d \n',size(gppi_matrix,1),size(gppi_matrix,2));
          save(['gPPI_matrix_con_',sprintf('%04d',nCon),'.mat'],'gppi_matrix');
         % dlmwrite(['gPPI_matrix_con_',sprintf('%04d',nCon),'.txt'],gppi_matrix ); % avoid dlmwrite due to matlab version issue 
         try
         outfileID = fopen(['gPPI_matrix_con_',sprintf('%04d',nCon),'.txt'],'w');
         fmt = [repmat('%f ',1,size(gppi_matrix,2)),'\n'];
         fprintf(outfileID,fmt,gppi_matrix');  %  fprintf write in column-wise, output will be transposed  
         fclose(outfileID);
         catch
         warning('It is so sad that we still cannot write out text file from matlab; at line 504');
         end
    end 


c     = fix(clock);
disp('======================================================================');
fprintf('Extract gPPI ROI stats finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('======================================================================');


    cd(temp_dir);
 %--------------------- check results ---------------------------
 %----- examinate whether the  number of folder matches with ROIs
  
      results_list= dir('gPPI_matrix_con_*.mat');
      if length(contrastNames) == length(results_list)
           fprintf('%s \n contains all gPPI matrices \n',temp_dir);
      else
          error('In ROI folder %s \n some contrasts are missing \n',subdir);
      end
  

disp('------ complete checking of gPPI matrix ----- now we are 100% sure ');


c     = fix(clock);
disp('======================================================================');
fprintf('Copying results back to $OAK starts at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('======================================================================');

     switch copy_type
      
          case '1' % all files
    
    	    fprintf('>>> copying  %s \n >>> to %s \n',temp_dir, subject_gPPI_stats_dir);
    		 %for ii = 1: size(name_list,1)
    		 cp_status= copyfile(temp_dir,subject_gPPI_stats_dir,'f');
    		 %fprintf('copying %s \n',name_list{ii});
    		    if cp_status ~= 1
    		     error('file copying fails');
    		    end
    		 %end

          case '2' % only matrices
            
             fprintf('>>> copying  %s \n >>> to %s \n',[temp_dir,'/gPPI_matrix_con*.mat'], subject_gPPI_stats_dir);
                 for nCon = 1: length(contrastNames)
                   % status= copyfile([temp_dir,'/gPPI_matrix_con_*.*'],subject_gPPI_stats_dir,'f');
                    status= copyfile([temp_dir,'/gPPI_matrix_con_',sprintf('%04d',nCon),'.mat'],subject_gPPI_stats_dir,'f');
                    if status ~= 1
                     error('file copying fails');
                    end
                   try
                    status= copyfile([temp_dir,'/gPPI_matrix_con_',sprintf('%04d',nCon),'.txt'],subject_gPPI_stats_dir,'f');
                   catch
                    warning('no .txt file to copy'); 
                   end
                 end
       
          case '3' % copy files at each stage 
            
            fprintf('>>> copying '); 

            %--- under construction ------
    
     
          otherwise 
           error('Error: undetermined copy type');
   
     end

c     = fix(clock);
disp('======================================================================');
fprintf('Copying results back to $OAK finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('======================================================================');


  
end % end of each subject 

cd(current_dir);
disp('------------------------------------------------------------------');
fprintf('Changing back to the directory: %s \n', current_dir);



c     = fix(clock);
disp(' ');
disp('///////////////////////////////////////////////////////////////////////');
disp('/////////////////////////////// FINAL /////////////////////////////////');
disp('///////////////////////////////////////////////////////////////////////');
disp('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
fprintf('gPPI analysis finished at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');

%diary off;
clear all;
close all;
end
