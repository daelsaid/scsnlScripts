#!/bin/bash


#daelsaid 04/12/2019
# script takes AFNI's UnWarpEPI motion file (.motion.1D) and converts it to an SPM formatted motion file
Usage() {
    echo "Usage: unwarp_motionfile_convert.sh <file_to_convert>"
    echo ""
    echo "<file_to_convert> full path to file including filename, or filename"
    echo ""
    exit 1;
}

if [ $# -lt 1 ]; then
    Usage
fi

file_to_convert=$1
file_dir=$(dirname ${file_to_convert})

cp ${file_to_convert} ${file_to_convert}_
sed 1d ${file_to_convert}_ >> ${file_to_convert}_tmp1;
sed 1d ${file_to_convert}_tmp1 >> ${file_to_convert}_nohdr_tmp;

cat ${file_to_convert}_nohdr_tmp | sed 's/ /   /g' | sed 's/ -/-/g' > ${file_to_convert}_nohdr
