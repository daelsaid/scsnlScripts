%-use FDR to threshold classification maps
clear all; close all; clc;

mask_file = '$OAK/deprecatedGems/scsnlscripts_2018_02_20/spm_scripts/Masks/vbm_grey_mask.nii'

classification_result_img = '/$OAK/projects/mcsnyder/2018_Short_Intervention/results/taskfmri/activity_classification/average_classification_accuracy.nii';

output_dir = '/$OAK/projects/mcsnyder/2018_Short_Intervention/results/taskfmri/activity_classification'

output_file_name = 'ClassificationOutput_05_100_vals.nii';

num_sample = 22;

voxel_pval = 0.05;

cluster_threshold = 100;

set_conn = 18; % 6:face only, % 18: face or edge % 26: face or edge or corner
%==========================================================================
mask_img = spm_read_vols(spm_vol(mask_file));

result_cva = spm_read_vols(spm_vol(classification_result_img));
cva_thresh = binoinv(1 - voxel_pval, num_sample, 0.5);
cva_thresh = cva_thresh/num_sample;

cva_thresh_map = result_cva > cva_thresh;
cva_thresh_map = result_cva .* double(cva_thresh_map);

map_inmask = double(cva_thresh_map .* (mask_img ~= 0));

[L, Num] = spm_bwlabel(map_inmask, set_conn);
for k = 1:Num
  Ix = find(L == k);
  if size(Ix,1) < cluster_threshold
    L(Ix) = 0;
  else
    L(Ix) = 1;
  end
end

map_thresh = map_inmask .* L;

%V = spm_vol(mask_file);
V = spm_vol(classification_result_img);

%V.fname = fullfile(output_dir, ['set_conn_', num2str(set_conn), ...
%  '_pval_', num2str(voxel_pval), '_cluster_', num2str(cluster_threshold), '_', ...
%  output_file_name]);
V.fname = fullfile(output_dir,output_file_name);
V.private.dat.fname = V.fname;

spm_write_vol(V, map_thresh);

