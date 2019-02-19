'''print directory trees from subject list'''

import os
from subprocess import call

rawdata = '/oak/stanford/groups/menon/rawdata/scsnl/'

sublists_folder = '/oak/stanford/groups/menon/scsnlscripts/utilities/dataOrganization/study_sublists/'
study_sublists = os.listdir(sublists_folder)

for sublist in study_sublists:

	study = sublist.split('_subjects.txt')[0]
	infile = open(os.path.join(sublists_folder,sublist),'r')
	scans= infile.readlines()
	scans = [x.strip() for x in scans]

	outfile = open('%s_tree.txt'%study,'w+')

	for scan in scans:
		outfile.write('\n'+scan+'\n\n')
		outfile.flush()
		scan_list = scan.split('_')
		pid = scan_list[0].zfill(4)
		visit = 'visit'+scan_list[1]
		session = 'session'+scan_list[2].split('.')[0]
		path = os.path.join(rawdata,pid,visit,session)
		if not os.path.exists(path):
			outfile.write('%s does not exist\n'%path)
			outfile.flush()
			continue
		call('tree --filelimit 50 %s'%path,shell=True,stdout = outfile)
		outfile.flush()
