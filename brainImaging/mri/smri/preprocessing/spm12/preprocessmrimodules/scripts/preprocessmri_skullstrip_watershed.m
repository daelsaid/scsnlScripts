% Preprocess MRI data - skullstrip using watershed
%__________________________________________________________________________

function preprocessmri_skullstrip_watershed(SpgrFile, SpgrWSFile)

unix('ml load biology freesurfer')
setenv('FREESURFER_HOME', '/share/software/user/open/freesurfer/6.0.0')
unix(sprintf('/share/software/user/open/freesurfer/6.0.0/bin/mri_watershed %s %s', SpgrFile, SpgrWSFile));

end
