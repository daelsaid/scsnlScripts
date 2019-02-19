#!/bin/bash


#################
# Files to move
FILESTOMOVEWILDCARD='sw*.nii*'
#################


#################
#check if user has specified the project directory
if [[ $# -eq 0 ]] ; then
    echo 'ERROR: Project directory not specified!'
    echo 'Usage: ./move_to_piscratch.sh YOUR_PROJECT_DIRECTORY'
    exit 1
fi
#################

#################
#check if user specified project directory exists
if [ ! -d $1 ] ; then
    echo 'ERROR: ' $1 ' does not exists. Please specify a valid project directory'
    exit 1
fi
#################

PROJECTDIR=$(echo $1)

echo ''
echo '********************************************************'
echo ''
echo 'Searching files ' "$FILESTOMOVEWILDCARD" 'in ' $PROJECTDIR
echo ''

oakmenon='/oak/stanford/groups/menon/'
currdir=$PWD
find $PROJECTDIR -name "$FILESTOMOVEWILDCARD" -type f  -print0 | 
    while IFS= read -r -d $'\0' line; do 
        echo 'Moving file ' $line
        fname=$(basename $line)
        fdir=$(dirname $line)
        projectdir=${fdir#"$oakmenon"}
        outdir=${PI_SCRATCH}/${projectdir}
        #echo $fname $fdir $projectdir
        echo 'to' $outdir
        mkdir -p $outdir
        mv $line $outdir
        cd $fdir
        ln -sT ${outdir}/${fname} $fname
        cd $currdir
        echo ''
    done

echo ''
echo 'Move to PI_SCRATCH finished!'
echo ''
echo '********************************************************'
echo ''

