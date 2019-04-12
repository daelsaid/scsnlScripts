function preprocessfmri_unwarp(run_name,subj_prefix,subject,visit,session,temp_dir, data_dir)
    addpath(genpath('/oak/stanford/groups/menon/toolboxes/afni/'));
    unwarp_script      = ('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/spm12/preprocessfmrimodules/scripts/unwarpepi.py');

    raw_dir            = data_dir;
    unnormed_dirname   = 'unnormalized';
    func_nii           = fullfile(temp_dir, 'I.nii');
    temp_nii           = fullfile(temp_dir,[subj_prefix,'.nii']);

    pepolar_suffix     = '_pepolar';
    pepolar_dirname    = [run_name,pepolar_suffix];
    pepolar_dir        = fullfile(raw_dir,subject,['visit',visit],['session',session],'fmri',pepolar_dirname);
    pepolar_orig_nii   = fullfile(pepolar_dir,unnormed_dirname,'I.nii.gz')
    pepolar_gzipnii    = fullfile(temp_dir,[subj_prefix,'_rev.nii.gz']);
    pepolar_nii	       = fullfile(temp_dir,[subj_prefix,'_rev.nii']);

    copyfile(pepolar_orig_nii,pepolar_gzipnii);
    system(sprintf('gunzip %s', pepolar_gzipnii));
    copyfile(func_nii,temp_nii);

    if ~exist(pepolar_dir, 'dir')
        fprintf('Cannot find the PE Polar directory: %s\n', pepolar_dir);
        error('Check for PE polar scan in %s %s directory',subject,run_name);
    else
        cd(temp_dir);
        system(sprintf('python %s -f %s -r %s -d %s',unwarp_script,[subj_prefix '.nii' '[' '0..20' ']'],[subj_prefix '_rev.nii'], [subj_prefix '.nii']));
    end
end