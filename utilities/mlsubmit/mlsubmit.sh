#!/bin/bash

#################
# The amount of time to allot for each job
JOBTIME='02:00:00'
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
SCSNLSCRIPTSPATH='/oak/stanford/groups/menon/scsnlscripts/'
#################


######### PLEASE DO NOT CHANGE BELOW THIS LINE 

#################
#check if user has specified matlab script file 
if [[ $# -eq 0 ]] ; then
    echo 'ERROR: Matlab script file not specified!'
    exit 1
fi
#################

#################
#check if user has specified configuration file 
if [[ $# -eq 1 ]] ; then
    echo 'ERROR: Configuration file not specified!'
    exit 1
fi
#################

#################
#check if configuration file exist
if [ ! -f $2 ]; then
    echo 'ERROR: Configuration file' $2 'not found!'
    exit 1
fi
mypwd=${PWD}
mlconfigfile=$(echo $2)
mlconfigfullfile=$(echo $mypwd'/'$2)
#################

#################
#check if user has specified matlab script file with extension
mlext='.m'
if [[ "$1" != *"$mlext"* ]]; then
    echo 'ERROR: Incorrect script name. Please add .m to the script name' $1 
    exit 1
fi
#################

#################
#find script name
mlscriptfile=$(echo $1)
scriptmname=$mlscriptfile
IFS="."
tokens=($scriptmname)
mlscriptname=${tokens[0]}
unset IFS
#################

echo '********************************************************'
echo ''
echo 'Running matlab script                 :' $mlscriptfile
echo 'Reading configuration parameters from :' $mlconfigfile


#################
#find spm version requested
strspmver=$(grep -nw ${mlconfigfile} -e 'paralist.spmversion')
if [ -z "$strspmver" ]; then
    echo 'Variable paralist.spmversion not found in configuration file' $mlconfigfile
    echo 'Assuming ' $mlscriptfile ' is a non-SPM matlab script' 
    strspmver="'_'"
fi
IFS="'"
tokens=($strspmver)
spmver=${tokens[1]}
unset IFS
#################

#################
#find project directory
strprojdir=$(grep -nw ${mlconfigfile} -e 'paralist.projectdir')
if [ -z "$strprojdir" ]; then
    echo 'ERROR: Variable paralist.projectdir not found in configuration file' $mlconfigfile 
    exit 1
fi
IFS="'"
tokens=($strprojdir)
projectdir=${tokens[1]}
unset IFS
#################

################# 
#find parallel or nonparallel 
strparallel=$(grep -nw ${mlconfigfile} -e 'paralist.parallel') 
if [ -z "$strparallel" ]; then 
    echo 'ERROR: Variable paralist.parallel not found in configuration file' $mlconfigfile  
    exit 1 
fi 
IFS="'" 
tokens=($strparallel) 
parallel=${tokens[1]}
unset IFS
################# 

#################
#find script directory
IFS="_"
tokens=($spmver)
srchspmver=${tokens[0]}
unset IFS
for f in $(find $SCSNLSCRIPTSPATH -name ${mlscriptfile}); do
      if [ -z "$srchspmver" ]; then
      	mlscriptfullfile=$(echo $f)
      else
      	if [[ $f = *"/${srchspmver}/"* ]]; then
      		mlscriptfullfile=$(echo $f)
      	fi
      fi
done

if [[ -z "${mlscriptfullfile+x}" ]]; then
    echo 'ERROR: ' ${mlscriptfile}' not found in' $SCSNLSCRIPTSPATH 
    echo 'Please correct matlab script name'
    exit 1
fi
scriptdir=$(dirname ${mlscriptfullfile})
#################


#################
#write to i/o
echo 'Absolute paths'
echo $scriptfullfile
echo $mlconfigfullfile
echo ''
echo 'SPM version                          :' $spmver
echo 'Parallel                             :' $parallel
echo ''
#################


#################
#load modules
module load matlab
module load biology
module load fsl
module load freesurfer
#################


#################
#create jobs directory, if it does not exist
jobdir=$(echo $projectdir'Jobs/')
if [ ! -d "$jobdir" ]; then
    echo 'WARNING: Job directory does not exist! Creating one!'
    mkdir -p $jobdir
fi
#################

#################
#read job submission flags from command line
shift
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

#################
#parallel or nonparallel job submit
if [ $parallel -eq 1 ]
then
	#################
	#determine the number of subjects
	strsubjlist=$(grep -nw ${mlconfigfile} -e 'paralist.subjectlist')
	if [ -z "$strsubjlist" ]; then
    		echo 'ERROR: Variable paralist.subjectlist not found in configuration file' $mlconfigfile 
    		exit 1
	fi
	IFS="'"
	tokens=($strsubjlist)
	numsubjects=$(cat ${tokens[1]} |wc -l)
	if [ ! -f ${tokens[1]} ]; then
    		echo 'ERROR: Subject list file' ${tokens[1]} 'not found!'
    		exit 1
	fi
	echo 'Reading subject list from    :' ${tokens[1]}
	numsubjects=$(expr ${numsubjects} - 1)
	if [ "$numsubjects" -lt 1 ]; then
    		echo 'ERROR: Subjects list' ${tokens[1]} 'is empty'  
    		exit 1
	fi
        unset IFS
	#################

	#################
	#read subjects list
	count=0
	while IFS=, read -r subj visit sess
	do
    		subject[$count]=$(echo PID-$subj'_visit'$visit'_session'$sess)
    		echo ${subject[$count]}
    		#echo $subj'_'$visit'_'$sess
    		count=$(expr $count + 1)
	done < ${tokens[1]}
	unset IFS
	#################

    #################
	#submit one job per subject
    echo ''
	echo 'Processing' ${numsubjects} 'subjects'
	subjnum=1 
	for (( i = 1; i <= $numsubjects; i++ ))
	do
    		echo ${subject[$subjnum]}

    		echo 'Submitting job for Subject' ${subject[$subjnum]%?}
    		JOBOUTPUT=$(echo $projectdir'/Jobs/'${mlscriptname}-${spmver}-%j'_'${subject[$subjnum]%?}'.out')
    		JOBERROR=$(echo $projectdir'/Jobs/'${mlscriptname}-${spmver}-%j'_'${subject[$subjnum]%?}'.err')

    		echo 'Saving job output to ' $JOBOUTPUT' and '$JOBERROR
    		sbatch -J $JOBNAME -o $JOBOUTPUT -e $JOBERROR -t $JOBTIME --mem-per-cpu=$JOBMEM -p $JOBPARTITION --wrap="matlab -nosplash -noFigureWindows -nodisplay -r $'addpath(\'$scriptdir\'); which $mlscriptfile; $mlscriptname($i,\'$mlconfigfullfile\'); exit;'"    		
            sleep 15
    		subjnum=$(expr $subjnum + 1)
		echo ''
	done
elif [ $parallel -eq 0 ]
then
	#submit job
	JOBOUTPUT=$(echo $projectdir'/Jobs/'${mlscriptname}-${spmver}-%j'.out')
	JOBERROR=$(echo $projectdir'/Jobs/'${mlscriptname}-${spmver}-%j'.err')
	echo ''
	echo 'Saving job output to ' $JOBOUTPUT' and '$JOBERROR

    sbatch -J $JOBNAME -o $JOBOUTPUT -e $JOBERROR -t $JOBTIME --mem-per-cpu=$JOBMEM -p $JOBPARTITION --wrap="matlab -nosplash -noFigureWindows -nodisplay -r $'addpath(\'$scriptdir\'); which $mlscriptfile; $mlscriptname(\'$mlconfigfullfile\'); exit;'"
fi
echo '********************************************************'
#################


