Run the script as

mlsubmit.sh preprocessmri preprocessmri_config.m


Main function:

Run SPM8 based preprocessing of MRI data


Features:

1. Includes three skullstrip options paralist.skullstrip: 0 "Not skullstrip"; 1 "Watershed freesurfer-based skullstrip"; 2 "SPM-based skullstrip"
2. Includes two segmentation options paralist.segment: 0 "No segmentation", 1 "SPM-based segmentation"
3. Includes option to specify spgrfile name for each subject in the file paralist.spgrlist. For example, one can specify spgr_1 if he/she wants to use spgr file from run1 for the subject, similarly spgr_2 for run2
4. The script now DOES NOT INCLUDE wild card characters such as '*'
5. Supports 4D NIFTI files. No support for 3D NIFTI and ANALYZE files
