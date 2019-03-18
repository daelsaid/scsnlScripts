#!/bin/bash
#SBATCH --job-name=github-cron
#SBATCH --begin=now+1days
#SBATCH --dependency=singleton
#SBATCH --time=00:02:00
#SBATCH --mail-type=FAIL
#SBATCH --partition=menon

## Insert the command to run below. Here, we're just storing the date in a
## cron.log file
date -R >> $HOME/cron.log
./github_scsnlscripts.sh

## Resubmit the job for the next execution
sbatch -e /dev/null -o /dev/null $0
