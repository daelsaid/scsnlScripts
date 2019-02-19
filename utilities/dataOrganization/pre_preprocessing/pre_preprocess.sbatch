#set a job name  
#SBATCH --job-name=pre_preprocess_$1
################# 

#a file for job output, you can check job progress, append the job ID with %j to make it unique
#SBATCH --output=logs/jobs/pre_preprocess_$1.out
#################
# a file for errors from the job
#SBATCH --error=logs/jobs/pre_preprocess_$1.err
#################
#SBATCH --time=15:00
################# 
#SBATCH -p menon 
#################
#SBATCH --mem=8G
# to request multiple threads/CPUs use the -c option, on Sherlock we use 1 thread/CPU, 16 CPUs on each normal compute node 4Gigs RAM per CPU.  Here we will request just 1.
#SBATCH -c 1
#################
# Have SLURM send you an email when the job ends or fails, careful, the email could end up in your clutter folder
# Also, if you submit hundreds of jobs at once you will get hundreds of emails.
#SBATCH --mail-type=FAIL # notifications for job done & fail
# Remember to change this to your email
#SBATCH --mail-user=chamblin@stanford.edu

# You can use srun if your job is parallel
module load matlab
module load biology fsl spm dcm2niix
srun python pre_preprocess.py $1


