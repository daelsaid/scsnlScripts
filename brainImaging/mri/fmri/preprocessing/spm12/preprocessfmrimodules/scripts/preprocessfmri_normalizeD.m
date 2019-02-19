%-----------------------------------------------------------------------
% Preprocess fMRI data - normalization
%__________________________________________________________________________
%-SCSNL, Rui Yuan, 2018-02-06 update to SPM12 new normalization
%-SCSNL, Rui Yuan, 2019-02-03 add DARTEL module

function preprocessfmri_normalizeD(WholePipeLine, CurrentDir, TemplatePath, BoundingBoxDim, PipeLine, InputImgFile, MeanImgFile, OutputDir, SPGRfile_FILE, spm_path,project_dir)

 if ismember('g', PipeLine)
       
    %%%---- Anatomical image exists and segmentation was performed -----------------------
          
       %%%%% using .mat file
    
%             load(fullfile(TemplatePath, 'batch_normalize_seg.mat'));
%             matlabbatch{1}.spm.spatial.normalise.write.roptions.bb = BoundingBoxDim;
%             matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {};
%             matlabbatch{1}.spm.spatial.normalise.write.subj.resample = InputImgFile;
%             matlabbatch{1}.spm.spatial.normalise.write.subj.matname = {};

%             SPGRDir = fileparts(SPGRfile_FILE);
%             SegDir = fullfile(SPGRDir, 'seg12');
%             ListFile = dir(fullfile(SegDir, 'y_*'));
%             
% %             matlabbatch{1}.spm.spatial.normalise.write.subj.matname{1} = fullfile(SegDir, ListFile(1).name);
% 
%                              
      %%% ------  SWGCAR

             tmpDir = fileparts(InputImgFile{1,1});
             fprintf('input image file %s \n', InputImgFile{1,1});
             fprintf('tmpDir is : %s \n',tmpDir);
             y_ListFile = dir(fullfile(tmpDir, 'y_*.nii'));
      
             if isempty(y_ListFile)
                 error('cannot find the specified y_* file');
             end
             if length(y_ListFile) > 1
                 error('found more than 1 specified y_* files');
             end

            matlabbatch{1}.spm.spatial.normalise.write.subj.def = {fullfile(tmpDir, y_ListFile(1).name)};
            matlabbatch{1}.spm.spatial.normalise.write.subj.resample = InputImgFile;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = BoundingBoxDim;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
            matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';

     %%% ------- SWDGCAR ----
      
         if   ismember('d', PipeLine)
              

                tmpDir = fileparts(InputImgFile{1,1});
                fprintf('input image file %s \n', InputImgFile{1,1});
                fprintf('tmpDir is : %s \n',tmpDir);
                u_ListFile = dir(fullfile(tmpDir, 'u_rc1*.nii'));

                if isempty(u_ListFile)
                 error('cannot find the specified u_rc1* file');
                end
                if length(u_ListFile) > 1
                 error('found more than 1 specified u_rc1* files');
                end

                DARTEL_template = [project_dir,'/results/smri/DARTEL/Template_6.nii'];

                if ~exist(DARTEL_template,'file')
                   error('Cannot find the DARTEL_template');
                end
		matlabbatch{1}.spm.tools.dartel.mni_norm.template = {DARTEL_template};
		matlabbatch{1}.spm.tools.dartel.mni_norm.data.subjs.flowfields = {fullfile(tmpDir,u_ListFile(1).name)};
		%matlabbatch{1}.spm.tools.dartel.mni_norm.data.subj.images = {[sub_dir,'/c3MP2RAGE_UNI.nii']
		%                                                              [sub_dir,'/c2MP2RAGE_UNI.nii']
		%                                                              [sub_dir,'/c1MP2RAGE_UNI.nii']
		%                                                           }; 
		%matlabbatch{1}.spm.tools.dartel.mni_norm.data.subjs.images = {{[sub_dir,'/done_rest.nii']}};
		matlabbatch{1}.spm.tools.dartel.mni_norm.data.subjs.images =  InputImgFile;
		matlabbatch{1}.spm.tools.dartel.mni_norm.vox = [2 2 2];
		%matlabbatch{1}.spm.tools.dartel.mni_norm.bb = [-90 -126 -72
                %                               90 90 108];
		matlabbatch{1}.spm.tools.dartel.mni_norm.bb = BoundingBoxDim;
                matlabbatch{1}.spm.tools.dartel.mni_norm.preserve = 0;
		matlabbatch{1}.spm.tools.dartel.mni_norm.fwhm = [0 0 0];

         end 
           
            
   else
       
          
      %%%----- spm12 old-norm direct batch--------------------
           
              if ~ismember('c', PipeLine)
                
                %%%------ SWAR      
                template_file = strcat(spm_path,'/toolbox/OldNorm/EPI.nii,1');
                matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.source = {MeanImgFile};
                matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.wtsrc = '';
                matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {};
                matlabbatch{1}.spm.tools.oldnorm.estwrite.subj.resample = InputImgFile;
                matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.template = {template_file};
                matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.weight = '';
                matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.smosrc = 8;
                matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.smoref = 0;
                matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.regtype = 'mni';
                matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.cutoff = 25;
                matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.nits = 16;
                matlabbatch{1}.spm.tools.oldnorm.estwrite.eoptions.reg = 1;
                matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.preserve = 0;
                matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.bb = BoundingBoxDim;
                matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.vox = [2 2 2];
                matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.interp = 1;
                matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.wrap = [0 0 0];
                matlabbatch{1}.spm.tools.oldnorm.estwrite.roptions.prefix = 'w';


              else
                 
                     
            %%%%% anatomical image exits no segmentation was performed
            %%%----- SWCAR
             
                    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.vol = {SPGRfile_FILE};
                    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {};
                    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = InputImgFile;
                    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasreg = 0.0001;
                    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60;
                    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.tpm = {[spm_path,'/tpm/TPM.nii']};
                    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.affreg = 'mni';
                    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = [0 0.001 0.5 0.05 0.2];
                    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.fwhm = 0;
                    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.samp = 3;
                    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.bb =BoundingBoxDim ;
                    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.vox = [2 2 2];
                    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.interp = 4;
                    matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.prefix = 'w';
            
                 
     
       
              end

             
 end
 
BatchFile = fullfile(OutputDir, 'log', ['batch_normalize_', WholePipeLine, '.mat']);
cd(OutputDir);
save(BatchFile, 'matlabbatch');
spm_jobman('run', BatchFile);


%%% ---- clean up -----for SWCAR ---------
if strcmp(WholePipeLine,'swcar')
   [file_path,file,file_ext]=fileparts(SPGRfile_FILE);

    fprintf('file_path : %s \n',file_path);
   
    unix(sprintf('rm -f %s',fullfile(file_path,'y_*.nii')))
    
end
%%% --------------------------------------

cd(CurrentDir);
clear matlabbatch;

end









