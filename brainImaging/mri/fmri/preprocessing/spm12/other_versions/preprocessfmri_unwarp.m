function preprocessfmri_unwarp(run_name,subj_prefix,subject,visit,session,temp_dir,project_dir)
    addpath(genpath('/home/users/daelsaid/bin/afni_local/'));
    
    unwarp_script      = ('/oak/stanford/groups/menon/projects/daelsaid/2019_met_unwarpepi/scsnl_script_implementation/unwarpepi.py');
    raw_dir            = ('/oak/stanford/groups/menon/projects/daelsaid/2019_met_unwarpepi/scsnl_script_implementation/subj/');
    unnormed_dirname   = 'unnormalized';
    data_dir           = fullfile(project_dir,'/data/imaging/participants/',subject,['visit',visit],['session',session],run_name);
    unnorm_dir         = fullfile(raw_dir, subject, ['visit',visit],['session',session],'fmri', run_name, unnormed_dirname);
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
        fprintf('Cannot find the PE Polar folder: %s\n', pepolar_dir);
    end
    
    cd(temp_dir);
    system(sprintf('python %s -f %s -r %s -d %s',unwarp_script,[subj_prefix '.nii' '[' '0..20' ']'],[subj_prefix '_rev.nii'], [subj_prefix '.nii']));
end
