function preprocessfmri_normalize(WholePipeLine, CurrentDir, TemplatePath, BoundingBoxDim, PipeLine, InputImgFile, MeanImgFile, OutputDir, SPGRFile, spm_version)

if ismember('g', PipeLine)
  load(fullfile(TemplatePath, 'batch_normalize_seg.mat'));
  matlabbatch{1}.spm.spatial.normalise.write.roptions.bb = BoundingBoxDim;
  matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {};
  matlabbatch{1}.spm.spatial.normalise.write.subj.resample = InputImgFile;
  matlabbatch{1}.spm.spatial.normalise.write.subj.matname = {};
  [SPGRDir SPGRFileName SPGRExt] = fileparts(SPGRFile);
  SegDir = fullfile(SPGRDir, ['seg' '_' spm_version]);
  ListFile = dir(fullfile(SegDir, [SPGRFileName '_seg_sn.mat']));
  matlabbatch{1}.spm.spatial.normalise.write.subj.matname{1} = fullfile(SegDir, ListFile(1).name);
else
  load(fullfile(TemplatePath, 'batch_normalize_fmri_epi.mat'));
  matlabbatch{1}.spm.spatial.normalise.estwrite.roptions.bb = BoundingBoxDim;
  matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = {};
  matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = InputImgFile;
  matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source = {};
  if ~ismember('c', PipeLine)
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source{1} = MeanImgFile;
    if strcmp(spm_version, 'spm8')
      template_file = '/oak/stanford/groups/menon/software/spm8/templates/EPI.nii,1';
    end
    if strcmp(spm_version, 'spm12')
      template_file = '/oak/stanford/groups/menon/software/spm12/toolbox/OldNorm/EPI.nii,1';
    end
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template{1} = template_file;
  else
    matlabbatch{1}.spm.spatial.normalise.estwrite.subj.source{1} = SPGRFile;
    if strcmp(spm_version, 'spm8')
      template_file = '/oak/stanford/groups/menon/software/spm8/templates/T1.nii,1';
    end
    if strcmp(spm_version, 'spm12')
      template_file = '/oak/stanford/groups/menon/software/spm12/toolbox/OldNorm/T1.nii,1';
    end
    matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.template{1} = template_file;
  end    
end

BatchFile = fullfile(OutputDir, 'log', ['batch_normalize_', WholePipeLine, '.mat']);
cd(OutputDir);
save(BatchFile, 'matlabbatch');
spm_jobman('run', BatchFile);
cd(CurrentDir);
unix(sprintf('ps2pdf13 %s %s', fullfile(OutputDir, 'spm_*.ps'), fullfile(OutputDir, 'log', ['spatial_normalize_' spm_version '_', WholePipeLine, '.pdf'])));
unix(sprintf('/bin/rm -rf %s', fullfile(OutputDir, 'spm_*.ps')));

clear matlabbatch;

end
