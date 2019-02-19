#!/bin/bash
#################
#set a job name  
#SBATCH --job-name=fw_download
#################  
#cron stuff
##SBATCH --begin=now+2days
##SBATCH --dependency=singleton

#a file for job output, you can check job progress, append the job ID with %j to make it unique
#SBATCH --output=../logs/fw_download.%j.out
#################
# a file for errors from the job
#SBATCH --error=../logs/fw_download.%j.err
#################
#SBATCH --time=4:00:00
################# 
#SBATCH -p menon 
#################
#SBATCH --mem=30G
# to request multiple threads/CPUs use the -c option, on Sherlock we use 1 thread/CPU, 16 CPUs on each normal compute node 4Gigs RAM per CPU.  Here we will request just 1.
#SBATCH -c 1
#################
# Have SLURM send you an email when the job ends or fails, careful, the email could end up in your clutter folder
# Also, if you submit hundreds of jobs at once you will get hundreds of emails.
#SBATCH --mail-type=FAIL # notifications for job done & fail
# Remember to change this to your email
#SBATCH --mail-user=chamblin@stanford.edu

source activate fw2
ml biology fsl matlab spm
# You can use srun if your job is parallel
python download_from_flywheel.py

## Resubmit the job for the next execution
#sbatch $0

