import os
from subprocess import call
from os.path import join as pjoin
import pandas as pd


def print_out(statement, file): # function for printing to a log as well as the terminal
	print(statement)
	file.write(str(statement))
	file.write('\n')
	file.flush()

def clean_punctuation(thing):
	return thing.replace(' ','\ ').replace('(','\(').replace(')','\)').replace(',','\,')

def path_insert(path,target,insert,side='before'):
	pathsplit = path.split('/')
	newpath = 'targetnotfound'
	for i in range(len(pathsplit)):
		if pathsplit[i] == target:
			if side == 'before':
				j = i
			else:
				j = i+1
			newpathsplit = pathsplit[:j]
			newpathsplit.append(insert)
			newpath = ('/').join(newpathsplit)
			break
	if newpath != 'targetnotfound':
		print('adding path %s'%newpath)
		#os.mkdir(newpath)
		return newpath
	else:
		print('target folder not found for making new path in func path_insert')
		return newpath




tree1 = '/oak/stanford/groups/menon/rawdata/.box_behavioral_data_empty'
tree2 = '/oak/stanford/groups/menon/rawdata/scsnl'


pids = os.listdir(tree1)
for folder in pids:
	if not folder.isdigit():
		pids.remove(folder)
pids.remove('AWMA Scores Backup')
pids.remove('visit_template_ASD_Speech')

pids.sort()

for pid in pids:
	visits = os.listdir(pjoin(tree1,pid))
	for visit in visits:
		for root, folder, files in os.walk(pjoin(tree1,pid,visit)):
			for file in files:
				if not os.path.exists(pjoin(root,file).replace(pjoin(tree1,pid,visit),pjoin(tree2,pid,visit,'assessments'))):
					print(root.replace(pjoin(tree1,pid,visit),pjoin(tree2,pid,visit,'assessments')))
					os.makedirs(root.replace(pjoin(tree1,pid,visit),pjoin(tree2,pid,visit,'assessments')),exist_ok=True)
					call('cp -p %s %s'%(pjoin(clean_punctuation(root),clean_punctuation(file)),root.replace(pjoin(tree1,pid,visit),pjoin(tree2,pid,visit,'assessments'))),shell=True)