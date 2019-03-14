'''
#############################################################################
#################### Config file for run_AROMA.py ###########################
############# Email jnichola@stanford.edu with questions/errors #############
#############################################################################

To run:

1) copy both run_AROMA.py and run_AROMA_config.py to your folder
2) run python run_AROMA.py


'''

# Location of the raw data directory (should be musk1)
raw_dir = '/oak/stanford/groups/menon/projects/lchen32/2018_MathFUN_mindset/data/'

# Jobs dir
jobs_dir='/oak/stanford/groups/menon/projects/lchen32/2018_MathFUN_mindset/Jobs/'

# List of your task folders
task_dirs = ['arithmetic_addition_1','arithmetic_addition_2','arithmetic_addition_1_redo','arithmetic_addition_2_redo','arithmetic_addition_2_redo2']

# 'nonaggr' to run the nonaggressive version of the algorithm and 'aggr' to run the aggressive version
aggr_signs = ['nonaggr']

# .csv file holding your subject list
subjectlist_file = '/oak/stanford/groups/menon/projects/lchen32/2018_MathFUN_mindset/data/subjectlist/ATL_T1/Subjectlist_Groupstats_V1_ATL.csv'

# specify which preliminary pipeline you have run (should be either 'swar' or 'swfar')
pipeline = 'swar'

# File with brain mask
brain_mask_fname = '/share/software/user/open/fsl/5.0.10/data/standard/MNI152_T1_2mm_brain_mask.nii.gz'

# TR of the task
tr = '2'
