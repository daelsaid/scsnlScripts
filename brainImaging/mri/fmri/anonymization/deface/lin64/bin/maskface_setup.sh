# Source this file to enable face masking script.
RT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTDIR="$( cd $RT && cd ../ && pwd )"

MASKFACE_HOME=$SCRIPTDIR
C=$MASKFACE_HOME
BIN=$C/bin
MASKFACE_MATLAB_ROOT=$C/matlab
FSLOUTPUTTYPE=NIFTI_PAIR

#set up your MATLAB path here
#set up your XNAT client tools (XNATRestClient)  path here
#set up your FSL environment here (FSLDIR)
#set up your dcm2nii (MRICron bin) directory here

PATH=${BIN}:${PATH}
export PATH MASKFACE_HOME FSLOUTPUTTYPE MASKFACE_MATLAB_ROOT
