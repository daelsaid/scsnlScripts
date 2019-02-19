Created by yuanzh 2018-02-12

Main function:
Run SPM8 based groupstats
----------------------------------------------------------------------

groupstats_config.m 	  -> configuration file to run groupstats
groupstats.m	 	  -> execution file for groupstats (DO NOT TOUCH)

----------------------------------------------------------------------

Notes: 
1. The script DOES NOT INCLUDE wild card characters such as '*'
2. The script support (1) one group analysis with/without covariates; (2) two group analysis without covariates
3. To be able to use 'mlsubmit' directly in command line without including the full path of mlsubmit.sh file, you can include in the ~/.bashrc 
   alias mlsubmit='/oak/stanford/groups/menon/scsnlscripts/utilities/mlsubmit/mlsubmit.sh' 
   and install .bashrc by typing source ~/.bashrc in command line

Run the script as
mlsubmit groupstats.m groupstats_config.m

