Main function: preprocessfmri.m

Run SPM8 based preprocessing of fMRI data

Features:

1. Supports the following pipelines paralist.pipeline 
'swar',  'swavr', 'swaor', 'swgcar',  'swgcavr', 'swgcaor'
'swfar', 'swfavr', 'swfaor', 'swgcfar', 'swgcfavr', 'swgcfaor'
2. Allows preprocessing of multiple runs per subjects paralist.runlist
3. Includes an option to set custom slicetiming paralist.customslicetiming
4. Includes an option to set custom bounding box paralist.boundingboxdim
5. Includes an option to set custom smoothing kernel paralist.smoothwidth
6. Includes an option to set TR value paralist.trval
7. Includes an option to set the MRI pipeline to use when the pipeline includes a coregistration step paralist.spgrfilename: "spgr", "watershed_spgr" and "skullstrip_spgr"
8. The script now DOES NOT INCLUDE wild card characters such as '*'
9. Supports 4D NIFTI files. No support for 3D NIFTI and ANALYZE files

Note: To be able to use 'mlsubmit' directly in command line without including the full path of mlsubmit.sh file, you can include in the ~/.bashrc 
   alias mlsubmit='/oak/stanford/groups/menon/scsnlscripts/utilities/mlsubmit/mlsubmit.sh' 
   and install .bashrc by typing source ~/.bashrc in command line

Run the script as
mlsubmit preprocessfmri.m preprocessfmri_config.m

