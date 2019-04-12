#!/bin/bash

#daelsaid 04/12/2019
# script takes AFNI's UnWarpEPI motion file (.motion.1D) and converts it to an SPM formatted motion file
Usage() {
    echo "Usage: unwarp_motionfile_convert.sh <file_to_convert> <output_path>"
    echo ""
    echo "<file_to_convert> full path to file including filename, or filename"
    echo ""
    echo "<output_path> full path to location of desired converted fileoutput"
    echo ""
    exit 1;
}

if [ $# -lt 2 ]; then
    Usage
fi

file_to_convert=$1
output_path=$2

file_dir=$(dirname ${file_to_convert})

cp -vr ${file_to_convert} ${file_to_convert}_temp;
sed 1d ${file_to_convert}_temp >> ${file_to_convert}_temp2;
sed 1d ${file_to_convert}_temp2 >> ${file_to_convert}_no_hdr_rows;
cat ${file_to_convert}_no_hdr_rows | sed 's/ /   /g' | sed 's/ -/-/g' >> ${output_path}/rp_I.txt;

cp -vr ${file_to_convert}_no_hdr_rows $(dirname ${file_dir})/rp_I.txt;