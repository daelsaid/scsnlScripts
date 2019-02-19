import os
from os.path import join as pjoin
from subprocess import call

folder_name = 'level1_run1'

permissions = {'wdcai':'rwx'}

pids2change = []

raw_data_folder = '/oak/stanford/groups/menon/rawdata/scsnl'

pids = os.listdir(raw_data_folder)

for pid in pids:
	for root, folders, files in os.walk(pjoin(raw_data_folder,pid)):
		if folder_name in folders:
			print(pid)
			pids2change.append(pid)


for pid in pids2change:
	for sunet in permissions:
		call('setfacl -R -m u:%s:%s %s'%(sunet,permissions[sunet],pjoin(raw_data_folder,pid)),shell=True)


