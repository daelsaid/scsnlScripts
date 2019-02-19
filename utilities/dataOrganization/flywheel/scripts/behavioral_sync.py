import os
from os.path import join as pjoin
from subprocess import call
from flywheel import Flywheel
import time
import sys
sys.path.insert(0, '/oak/stanford/groups/menon/projects/chamblin')
from helper_funcs import print_out, split_path
from studies_template import studies_template


#Downloaded scanids (Set this!!!!)
downloaded_scanids =[['8088', 'visit1', 'session1'], ['0059', 'visit2', 'session1'], ['7483', 'visit7', 'session1'], ['7943', 'visit3', 'session1'], ['0224', 'visit2', 'session1'], ['0224', 'visit2', 'session2'], ['0281', 'visit2', 'session1'], ['0098', 'visit2', 'session1'], ['8082', 'visit2', 'session1'], ['7863', 'visit2', 'session1'], ['0098', 'visit2', 'session2']]

#Get flywheel credentials
fw = Flywheel('lucascenter.flywheel.io:oglHDMF0DnDeKPmDnl')
me = fw.get_current_user()

projects_full = fw.get_all_projects()
#print(fw_projects_full)
projects_thin = {}
for project in projects_full:
	projects_thin[project['_id']] = project['label']


#Generate a list of all scanids currently in rawdata_scsnl
rawdata_scanids = []
rawdata_root = '/oak/stanford/groups/menon/rawdata/scsnl'
pids = os.listdir(rawdata_root)
for pid in pids:
	visits = os.listdir(pjoin(rawdata_root,pid))
	for visit in visits:
		sessions = os.listdir(pjoin(rawdata_root,pid,visit))
		for session in sessions:
			sessnum = session[-1]
			visitnum = visit[-1]
			scanid = pid+'_'+visitnum+'_'+sessnum
			rawdata_scanids.append(scanid)


#generate list of thin exam dictionaries with  flywheel id, scanid, and study name
exams_full = fw.get_all_sessions()
#print(type(sessions))
#print(sessions)
exams_thin = []
for exam in exams_full:
	#print(exam['label'])
	label_root = exam['subject']['code'].split('.')[0]
	scanidlist = label_root.split('_')
	scanid = scanidlist[0].zfill(4)+'_'+scanidlist[1]+'_'+scanidlist[2]
	thin_exam = {'fw_id':exam['_id'],'scanid':scanid,'study':projects_thin[exam['project']]}
	exams_thin.append(thin_exam)


#syncing behavioral data
from_lucas_path = '/oak/stanford/groups/menon/rawdata/.fromlucas'
behav_targets = ['behavioral','behavior','Behavioral','Behavior']
fromlucas_folders = os.listdir(from_lucas_path)
for scanid_list in downloaded_scanids:
	scanid = scanid_list[0]+'_'+scanid_list[1][-1]+'_'+scanid_list[2][-1]
	rawdatapath = pjoin('/oak/stanford/groups/menon/rawdata/scsnl',scanid_list[0],scanid_list[1],scanid_list[2])
	print('processing %s behavioral'%scanid)
	lucas_found = False
	for lucas_scanid in fromlucas_folders:
		if scanid in lucas_scanid:
			lucas_found = True
			lucas_scanid_path = pjoin(from_lucas_path,lucas_scanid)
			flywheel_exams = []
			for exam in exams_thin:
				if scanid in exam['scanid']:
					flywheel_exams.append(exam)
			for root, folders, files in os.walk(lucas_scanid_path):
				for folder in folders:
					if folder in behav_targets:
						behav_folder_path = pjoin(root,folder)
						print('found behav folder %s'%behav_folder_path)
						files_under_behavioral = []
						for root2, folders2, files2 in os.walk(behav_folder_path):
							for behav_file in files2:
								files_under_behavioral.append(pjoin(root2,behav_file))
						# add behavioral to rawdata
						call('cp -r %s %s'%(pjoin(root,folder),root.replace(lucas_scanid_path,rawdatapath)),shell=True)
						#add behavioral to flywheel
						found_run_on_fw=False
						run =False
						if '/fmri/' in root:
							folder_list = pjoin(root,folder).split('/')
							for i in range(len(folder_list)):
								if folder_list[i] == 'fmri':
									run = folder_list[i+1]
									break
							for exam in flywheel_exams:
								fw_acqs = fw.get_session_acquisitions(exam['fw_id'])
								for fw_acq in fw_acqs:
									if fw_acq['label'] == run:
										found_run_on_fw = True
										for behav_path in files_under_behavioral:
											print('uploading %s'%behav_path)
											fw.upload_file_to_acquisition(fw_acq['_id'], behav_path)
						if not found_run_on_fw:
							if run:
								print('run %s not found, creating acquisition behavioral under flywheel exam id %s'%(run,flywheel_exams[0]['fw_id']))
							else:
								print('creating acquisition behavioral under flywheel exam id %s'%run,flywheel_exams[0]['fw_id'])
							acqId = fw.add_acquisition({'label': 'behavioral','session': flywheel_exams[0]['fw_id']})
							for behav_path in files_under_behavioral:
								print('uploading %s'%behav_path)
								fw.upload_file_to_acquisition(fw_acq['_id'], behav_path)
							
	if not lucas_found:
		print('scanid not found in .fromlucas folder!')

