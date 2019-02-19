Created by yuanzh 2018-02-13

Main function:
convert task_design.m (this should be saved under raw data) to task_design.mat (this will be saved under project directory)
----------------------------------------------------------------------

taskdesign_m2mat_config.m -> configuration file to run taskdesign_m2mat
taskdesign_m2mat.m 	  -> execution file for taskdesign_m2mat (DO NOT TOUCH)

----------------------------------------------------------------------

Notes:
1. You can specify which task design m file you want to convert in config file
2. You can specify the name of output task design mat file
3. The script will automatically load m file, convert to mat file and save it to the correct path (e.g., $oak/projects/SUNET/PROJECT/data/imaging/participants/SUBID/visit*/session*/fmri/RUNNAME/task_design/)
4. If you have multiple task design m files to convert, do it one by one and remember to provide a different name to mat file each time. Otherwise, mat file will be overwritten.
5. To be able to use 'mlsubmit' directly in command line without including the full path of mlsubmit.sh file, you can include in the ~/.bashrc 
   alias mlsubmit='/oak/stanford/groups/menon/scsnlscripts/utilities/mlsubmit/mlsubmit.sh' 
   and install .bashrc by typing source ~/.bashrc in command line

Run the script as
mlsubmit taskdesign_m2mat.m taskdesign_m2mat_config.m



