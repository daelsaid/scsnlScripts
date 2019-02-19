'''
Random forest classifier for IQM - visual validation
Input:
	- Vector of binary (0 for include, 1 for exclude) visual assesment scores for each image
	- Vector of IQM statistics for each image
'''

import os,sys,csv,pdb
import os.path as op
import pandas as pd
from sklearn.ensemble import RandomForestClassifier

# True labels 
TL = pd.read_csv('/oak/stanford/groups/menon/projects/chamblin/2018_brain_age_predict/data/imaging/mriqc/reports/maddie/PNC_true_labels.csv')
TL_dict = {}
exclude_bin = []
for i,sub in TL.iterrows():
	TL_dict[str(sub['PID'])] = sub['exclude']
	exclude_bin.append(sub['exclude'])

# IQM training data, binarized based on ST
IQM = pd.read_csv('/oak/stanford/groups/menon/projects/chamblin/2018_brain_age_predict/data/imaging/mriqc/reports/PNC_ALL_Group/bold.csv')
pdb.set_trace()
for i,sub in IQM.iterrows():
	if sub['subject_id'][:-4] in TL_dict:
		TL_dict[sub['subject_id'][:-4]] = sub
		
TL_df = pd.DataFrame.from_dict(TL_dict)
TL_df = TL_df.transpose()
TL_df = TL_df.drop(columns = 'subject_id')

# Classifier
clf = RandomForestClassifier(max_depth=10, random_state=0)

# Fit Classifier with True labels
clf.fit(TL_df, exclude_bin)
