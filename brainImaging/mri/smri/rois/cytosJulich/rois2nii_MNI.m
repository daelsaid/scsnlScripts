% roi directory
roidir = '/mnt/mapricot/musk2/home/fmri/fmrihome/SPM/spm8_scripts/Cyto_ROIs/';

% roi list (here we get all .mat files in roidir, but you can just pass a list)
rois = dir([roidir '/*roi.mat']); 
addpath(genpath('/mnt/musk2/home/fmri/fmrihome/SPM/spm8/toolbox/marsbar/'))

if ~exist('MNI152_T1_2mm_brain.nii','file')
    unix('cp /mnt/musk2/local/fsl/data/standard/MNI152_T1_2mm.nii.gz .; gunzip MNI152_T1_2mm.nii.gz')
end

V = spm_vol('MNI152_T1_2mm.nii');
X = 0.*spm_read_vols(V);
o = maroi_image(struct('vol', spm_vol(V), 'binarize', 0, 'func', 'img'));
o = maroi_matrix(o);
MNI = native_space(o);

badrois = {};
for iroi = 1:length(rois)
    fname = rois(iroi).name;
    if exist([fname(1:end-4) '.nii'],'file')
	continue
    end
    X = 0.*X;

    roi = maroi(fullfile(roidir,fname));
    vp = voxpts(roi,MNI);
	if length(vp) == 0
		badrois = [badrois, fname];
		continue
	end	
    X(sub2ind(size(X),vp(1,:),vp(2,:),vp(3,:))) = 1.0;
    V.fname = [fname(1:end-4) '.nii'];
    spm_write_vol(V,X);
end
