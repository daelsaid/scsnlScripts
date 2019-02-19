
function preprocessfmri_slicetime_PNC(WholePipeLine, TemplatePath, ImgFiles, OutputDir)
% THIS FUNCTION IS DESIGNED STRICTLY FOR PNC DATA
%   DO NOT USE FOR ANY OTHER PURPOSE
TR = 3.0;

load(fullfile(TemplatePath, 'batch_slice_timing.mat'));

matlabbatch{1}.spm.temporal.st.scans{1} = {};
matlabbatch{1}.spm.temporal.st.scans{1} = ImgFiles;
V = spm_vol(ImgFiles{1})
nslices = V.dim(3);
matlabbatch{1}.spm.temporal.st.nslices = nslices;
matlabbatch{1}.spm.temporal.st.tr = TR;
matlabbatch{1}.spm.temporal.st.ta = TR - TR/nslices;
matlabbatch{1}.spm.temporal.st.refslice = ceil(nslices/2);
%matlabbatch{1}.spm.temporal.st.prefix = 'a';

% Siemens interleave convention:
%   if the total# of slices is even, the first slice in the sequence is #2
% see: http://www.healthcare.siemens.com/siemens_hwem-hwem_ssxa_websites-context-root/wcm/idc/siemens_hwem-hwem_ssxa_websites-context-root/wcm/idc/groups/public/@global/@imaging/@mri/documents/download/mdaz/nzmy/~edisp/mri_60_graessner-01646277.pdf
if mod(nslices,2) == 0
  matlabbatch{1}.spm.temporal.st.so = [2:2:nslices,1:2:nslices];
else
  matlabbatch{1}.spm.temporal.st.so = [1:2:nslices,2:2:nslices];
end

LogDir = fullfile(OutputDir, 'log');
if ~exist(LogDir, 'dir')
  mkdir(LogDir);
end

% Update and save batch
BatchFile = fullfile(LogDir, ['batch_slice_timing_', WholePipeLine, '.mat']);
save(BatchFile, 'matlabbatch');

% Run batch of slice_timing
spm_jobman('run', BatchFile);
clear matlabbatch;
