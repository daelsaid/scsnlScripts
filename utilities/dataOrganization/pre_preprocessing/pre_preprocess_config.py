'''config script for pre-preprocessing subjects, first thing is just fill out the subject list for subjects you want to process in .fromlucas folder'''

from subprocess import call
import pickle
'''
subjects = ['8078_1_1.3T3','0227_4_1.3T3','0275_3_1.3T3','0426_2_2.3T3','7950_2_1.3T3','7983_2_1.3T3','8082_1_1.3T3','8086_2_1.3T3','8101_1_1.3T3',
'0227_4_2.3T3','0275_3_2.3T3','7833_3_1.3T3','7964_2_1.3T3','8083_1_1.3T3','8104_1_1.3T3','0254_2_1.3T3','0356_3_1.3T3','7877_3_1.3T3',
'7968_3_1.3T3','8083_2_1.3T3','0085_2_1.3T3','0254_2_2.3T3','0426_2_1.3T3','7941_3_1.3T3','7976_2_1.3T3','8086_1_1.3T3','8100_1_1.3T3']
'''


subjects = ['8078_1_1.3T3']
data_path = '/oak/stanford/groups/menon/rawdata/public/PNC_redownload'





run_params = {}
pickle.dump

for subject in subjects:
	call('./pre_preprocess.sbatch %s'%subject,shell=True)
