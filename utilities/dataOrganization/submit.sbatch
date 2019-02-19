#!/bin/bash
#################
#set a job name  
#SBATCH --job-name=projects_rsync
#################  
#cron stuff
##SBATCH --begin=now+2days
##SBATCH --dependency=singleton

#a file for job output, you can check job progress, append the job ID with %j to make it unique
#SBATCH --output=projects_rsync.%j.out
#################
# a file for errors from the job
#SBATCH --error=projects_rsync.%j.err
#################
#SBATCH --time=16:00:00
################# 
#SBATCH -p menon 
#################
#SBATCH --mem=15G
# to request multiple threads/CPUs use the -c option, on Sherlock we use 1 thread/CPU, 16 CPUs on each normal compute node 4Gigs RAM per CPU.  Here we will request just 1.
#SBATCH -c 1
#################
# Have SLURM send you an email when the job ends or fails, careful, the email could end up in your clutter folder
# Also, if you submit hundreds of jobs at once you will get hundreds of emails.
#SBATCH --mail-type=FAIL # notifications for job done & fail
# Remember to change this to your email
#SBATCH --mail-user=chamblin@stanford.edu

rsync -av /oak/stanford/groups/menon/projects/ /oak/stanford/groups/menon/mcsnyder-Projects/

