Created by yuanzh 2018-02-12

Main function:
Run SPM8 based individualstats of preprocessed fMRI data
----------------------------------------------------------------------

individualstats_config.m -> configuration file to run individualstats
individualstats.m 	  -> execution file for individualstats (DO NOT TOUCH)

----------------------------------------------------------------------

Notes:
1. The script now DOES NOT INCLUDE wild card characters such as '*'
2. Supports 4D NIFTI files. No support for 3D NIFTI and ANALYZE files
3. Only support .mat format of task design file. Please put your task design folder under 
$oak/projects/SUNET/PROJECT/data/imaging/participants/SUBID/visit*/session*/fmri/RUNNAME/task_design
4. Artrepair has been deprecated. Do NOT change "volrepair" related parameters in config file
5. To be able to use 'mlsubmit' directly in command line without including the full path of mlsubmit.sh file, you can include in the ~/.bashrc 
   alias mlsubmit='/oak/stanford/groups/menon/scsnlscripts/utilities/mlsubmit/mlsubmit.sh' 
   and install .bashrc by typing source ~/.bashrc in command line


Run the script as
mlsubmit individualstats.m individualstats_config.m


