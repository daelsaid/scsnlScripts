#!/bin/bash

ml biology freesurfer 
source $FREESURFER_HOME/SetUpFreeSurfer.sh 
SUBJECTS_DIR=$1
SUBJ_ID=$2
recon-all -autorecon-all -subjid $2 -i $3
