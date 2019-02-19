#!/bin/bash
# this script takes a single argument which is a file with line seperated full paths to nifti files. The script will deface all these files, placing the
# defaced version of the file in the same folder as the original file.
# To run this script simply type './deface_images /full/path/to/imagelist.txt'


ml biology fsl
source /oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/anonymization/deface/lin64/bin/maskface_setup.sh
python deface_images.py $1
