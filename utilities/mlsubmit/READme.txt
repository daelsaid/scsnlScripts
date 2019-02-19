How to use mlsubmit.sh to submit jobs

/oak/stanford/groups/menon/scsnlscripts/utilities/mlsubmit.sh function_name config_file_name

By default this will submit to menon partition, 8G memory, and 

Examples:
- /oak/stanford/groups/menon/scsnlscripts/utilities/mlsubmit.sh preprocessfmri.m preprocessfmri_config.m
  this will submit one job for each subject (#jobs equals to #subjects)
- /oak/stanford/groups/menon/scsnlscripts/utilities/mlsubmit.sh groupstats.m groupstats_config.m
  this will submit only one job
