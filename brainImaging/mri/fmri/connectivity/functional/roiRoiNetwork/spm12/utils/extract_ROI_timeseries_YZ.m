function timeseries = extract_ROI_timeseries_YZ(ROIs, datadir, ...
                                  filter, NUMTRUNC, imagefilter, data_type, extract_opt)

% % Add path of marsbar functions 
% addpath /oak/stanford/groups/menon/toolboxes/spm8/toolbox/marsbar

% Unzip images if necessary
unix(sprintf('gunzip -fq %s', fullfile(datadir, [imagefilter, '*.gz'])));

% Select files
switch data_type
  case 'img'
    files = spm_select('ExtFPList', datadir, ['^',imagefilter,'I.*\.img']);
    nscans       = size(files,1);            
  case 'nii'
    nifti_file = spm_select('ExtFPList', datadir, ['^',imagefilter,'I.*\.nii']);
    V       = spm_vol(deblank(nifti_file(1,:)));
    if length(V.private.dat.dim) == 4
      nframes = V.private.dat.dim(4);
      files = spm_select('ExtFPList', datadir, ['^',imagefilter,'I.*\.nii'],1:nframes);
    else
      files = nifti_file;    
    end
    nscans = size(files, 1);
    clear nifti_file V nframes;
end 
if nscans == 0
  error('No image data found');
end

% Truncate selected files
truncpoint = NUMTRUNC+1;
select_data = files(truncpoint:end,:);

% Get ROIs
% ROI_list = get_roilist(ROIs);
% nrois = length(ROI_list);

roi_d = spm_read_vols(spm_vol(ROIs));
uni_val = setdiff(unique(roi_d(:)),[0]);
nrois = length(unique(roi_d(:)))-1;%max(roi_d(:));

if nrois==0
  error('No ROIs specified')
end

% Get Timeseries for each ROI
timeseries = [];

for j = 1:nrois

  roi_idx = roi_d(:) == uni_val(j);
  roi_obj = create_roi(ROIs, roi_idx);
  roi_data_obj = get_marsy(roi_obj, select_data, extract_opt);
  roi_ts = summary_data(roi_data_obj);
  
  % Zero-mean and linear detrend if specified
  if filter 
    roi_ts = roi_ts - mean(roi_ts);
    roi_ts = detrend(roi_ts);
  end
  timeseries = [timeseries; roi_ts'];
end

disp('ROI timeseries extraction - Done');
%unix(sprintf('gzip -fq %s', fullfile(datadir, '*.nii')));

end


% ----------------------------------------------------------------------------------
function roi = create_roi(atlas, roi_ind)

VM = atlas;
VM = char(VM); 
VM = spm_vol(VM); % 91*109*91

%-Get space details
%--------------------------------------------------------------------------
M            = VM(1).mat;                          %-voxels to mm matrix
iM           = inv(M);                             %-mm to voxels matrix
DIM          = VM(1).dim;                          %-image dimensions
[x,y,z]      = ndgrid(1:DIM(1), 1:DIM(2), 1:DIM(3));
XYZ          = [x(:)';y(:)';z(:)']; clear x y z    %-voxel coordinates {vx}
XYZmm        = M(1:3, :)*[XYZ; ones(1, size(XYZ,2))];%-voxel coordinates {mm}

coord = XYZ(:,roi_ind); % find the XYZ coordinate of ROI voxels
tmp = XYZmm(:,roi_ind); % to check left-right issue
params = struct('XYZ', coord, 'mat', M);
roi = maroi_pointlist(params, 'vox');
% saveroi(roi, 'tmp.mat');
end