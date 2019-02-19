#!/bin/bash 
#
#SBATCH --job-name=BSDS
#SBATCH --output=test.%j.out
#SBATCH --error=test.%j.err
#SBATCH --time=59:59
##SBATCH --qos=long
#SBATCH -p menon
##SBATCH --gres gpu:1
#SBATCH --nodes=1
#SBATCH --mem=32000
#SBATCH --mail-type=FAIL 
#SBATCH --mail-user=SUNETID@stanford.edu
module load matlab
srun matlab -nodesktop < ./test.m
#srun  matlab ./test
