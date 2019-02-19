#!/bin/bash

#################
# The amount of time to allot for each job
JOBTIME='24:00:00'
#################
# Amount of memory to allocate per CPU
JOBMEM=8G
#################
# Partition to run your job on
# Options are:
#   - owners: access to all nodes
#   - menon: access to our lab nodes
#   - normal: the normal queue
JOBPARTITION='menon'
#################
#set a job name
JOBNAME=$1
################
#enter project directory
PROJECT_DIR='/oak/stanford/groups/menon/projects/ksupekar/2018_Test_FreeSurfer/'
#################

################
#specify raw directory
RAW_DIR='/oak/stanford/groups/menon/rawdata/scsnl/'
#################

#################
#check if user has specified subjects list file
if [[ $# -eq 0 ]] ; then
    echo 'ERROR: Subjects list file not specified!'
    exit 1
fi
#################

echo '********************************************************'

IFS="'"
tokens=($1)
numsubjects=$(cat ${tokens} |wc -l)
if [ ! -f ${tokens[1]} ]; then
        echo 'ERROR: Subject list file' ${tokens} 'not found!'
        exit 1
fi
echo 'Reading subject list from    :' ${tokens}
numsubjects=$(expr ${numsubjects} - 1)
if [ "$numsubjects" -lt 1 ]; then
        echo 'ERROR: Subjects list' ${tokens} 'is empty'
        exit 1
fi
unset IFS

#################
#read subjects list
count=0
while IFS=, read -r subj visit sess
do
        subject[$count]=$(echo $subj'_visit'$visit'_session'$sess)
        spgrloc[$count]=$(echo $RAW_DIR'/'$subj'/visit'$visit'/session'$sess'/anatomical/spgr.nii.gz')
        #echo ${subject[$count]}
        #echo ${spgrloc[$count]}
        count=$(expr $count + 1)
done < ${tokens}
unset IFS
#################

#################
#read job submission flags from command line
shift
while getopts ":p:t:m:" opt; do
  case $opt in
    p)
      echo "-p was triggered, setting JOBPARTITION to : $OPTARG" >&2
      JOBPARTITION=$OPTARG
      ;;
    t)
      echo "-t was triggered, setting JOBTIME to : $OPTARG" >&2
      JOBTIME=$OPTARG
      ;;
    m)
      echo "-m was triggered, setting JOBMEM to : $OPTARG" >&2
      JOBMEM=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
#################



ml biology freesurfer

#################
#submit one job per subject
SUBJECTS_DIR=$(echo $PROJECT_DIR'/data/imaging/participants/')
projectdir=$(echo $PROJECT_DIR)
echo ''
echo 'Processing' ${numsubjects} 'subjects'
subjnum=1
for (( i = 1; i <= $numsubjects; i++ ))
do
        echo ${subject[$subjnum]}
        echo 'Submitting job for Subject' ${subject[$subjnum]%?}
        JOBOUTPUT=$(echo $projectdir'/Jobs/'fs-recon-all-%j'_'${subject[$subjnum]%?}'.out')
        JOBERROR=$(echo $projectdir'/Jobs/'fs-recon-all-%j'_'${subject[$subjnum]%?}'.err')
        echo 'Saving job output to ' $JOBOUTPUT' and '$JOBERROR
	echo ${subject[$subjnum]}
	echo ${spgrloc[$subjnum]}
        #sbatch -J $JOBNAME -o $JOBOUTPUT -e $JOBERROR -t $JOBTIME --mem-per-cpu=$JOBMEM -p $JOBPARTITION --wrap="ml biology freesurfer; source $FREESURFER_HOME/SetUpFreeSurfer.sh; SUBJECTS_DIR=$SUBJECTS_DIR; SUBJ_ID=${subject[$subjnum]} ; recon-all -autorecon-all -subjid $SUBJ_ID -i ${spgrloc[$subjnum]}"
        sbatch -J $JOBNAME -o $JOBOUTPUT -e $JOBERROR -t $JOBTIME --mem-per-cpu=$JOBMEM -p $JOBPARTITION --wrap="./runFreeSurferForOneSubj.sh $SUBJECTS_DIR ${subject[$subjnum]} ${spgrloc[$subjnum]}"
        sleep 15
        subjnum=$(expr $subjnum + 1)
        echo ''
done
echo '********************************************************'
