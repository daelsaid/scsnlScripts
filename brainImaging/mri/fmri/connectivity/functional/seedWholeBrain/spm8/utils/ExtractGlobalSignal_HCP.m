function [GSignal] = ExtractGlobalSignal(data_type, imagefilter, datadir)

unix(sprintf('gunzip -fq %s', fullfile(datadir, [imagefilter, '*.gz'])));

switch data_type
  case 'img'
    files = spm_select('ExtFPList', datadir, ['^',imagefilter,'.*\.img']);
    nscans       = size(files,1);            
  case 'nii'
    nifti_file = spm_select('ExtFPList', datadir, ['^',imagefilter,'.*\.nii']);
    V       = spm_vol(deblank(nifti_file));
    if length(V) == 4
      nframes = V.private.dat.dim(4);
      files = spm_select('ExtFPList', datadir, ['^',imagefilter,'.*\.nii'],1:nframes);
    else
      files = nifti_file;    
    end
    nscans = size(files, 1);
    clear nifti_file V nframes;
end

VY = spm_vol(files);
GSignal = zeros(nscans, 1);

% Yuan edits
mask_d = spm_read_vols(spm_vol(fullfile(datadir, 'brainmask_fs.2.nii')));
mask_idx = mask_d > 0;

for iScan = 1:nscans
%   GSignal(iScan) = spm_global(VY(iScan));
    iScan_d = spm_read_vols(VY(iScan)); % Yuan edits
    GSignal(iScan) = mean(iScan_d(mask_idx)); % Yuan edits
end

%unix(sprintf('gzip -fq %s', fullfile(datadir, [imagefilter, '*'])));

end