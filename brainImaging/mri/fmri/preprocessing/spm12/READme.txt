Run the script as

mlsubmit.sh preprocessfmri preprocessfmri_config.m


Main function:

Run SPM12 based preprocessing of fMRI data


Features:

1. Supports the following pipelines paralist.pipeline 
'swar',  'swavr', 'swaor', 'swgcar',  'swgcavr', 'swgcaor','swcar'
'swfar', 'swfavr', 'swfaor', 'swgcfar', 'swgcfavr', 'swgcfaor'
2. Allows preprocessing of multiple runs per subjects paralist.runlist
3. Includes an option to set custom slicetiming paralist.customslicetiming
4. Includes an option to set custom bounding box paralist.boundingboxdim
5. Includes an option to set custom smoothing kernel paralist.smoothwidth
6. Includes an option to set TR value paralist.trval
7. Includes an option to set the MRI pipeline to use when the pipeline includes a coregistration step paralist.spgrfilename: "spgr", "watershed_spgr" and "skullstrip_spgr_spm12"
8. The script now DOES NOT INCLUDE wild card characters such as '*'
9. Supports 4D NIFTI files. No support for 3D NIFTI and ANALYZE files
