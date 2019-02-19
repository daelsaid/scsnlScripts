'''This script is for backfilling flywheel with data from OAK,
 it will upload based on a specific subject list in 
 oak/stanford/groups/menon/scsnlscripts/utilities/dataOrganization/study_sublists'''

import os
from os.path import join as pjoin
from subprocess import call,Popen,PIPE
from flywheel import Flywheel
import flywheel
import time
import sys
#import pdb
#sys.path.insert(0, '/oak/stanford/groups/menon/projects/chamblin')
#from helper_funcs import print_out, split_path
#from studies_template import studies_template, studies_rules

#PARAMETERS
SUBLIST = 'mathwhiz_subjects.txt'

#Get flywheel credentials
fw = Flywheel('lucascenter.flywheel.io:oglHDMF0DnDeKPmDnl')
me = fw.get_current_user()

#listify file of scanids
study = SUBLIST.split('_subjects.txt')[0]
file = open(pjoin('/oak/stanford/groups/menon/scsnlscripts/utilities/dataOrganization/study_sublists',SUBLIST),'r')
scans= file.readlines()
scans = [x.strip() for x in scans]	

#generate dictionary of project ids to study names
projects_full = fw.get_all_projects()
#print(fw_projects_full)
projects_thin = {}
for project in projects_full:
	projects_thin[project['label']] = project['_id']

projects_thin_inverted = dict([[v,k] for k,v in projects_thin.items()])
study_id = projects_thin[study]


#generate list of thin exam dictionaries with  flywheel id, scanid, and study name
exams_full = fw.get_all_sessions()
#print(type(sessions))
#print(sessions)
exams_thin = []
fw_scanids = []
for exam in exams_full:
	#print(exam['label'])
	try:
		label_root = exam['subject']['code'].split('.')[0]
		scanidlist = label_root.split('_')
		scanid = scanidlist[0].zfill(4)+'_'+scanidlist[1]+'_'+scanidlist[2]
		fw_scanids.append(scanid)
		thin_exam = {'fw_id':exam['_id'],'scanid':scanid,'study':projects_thin_inverted[exam['project']]}
		exams_thin.append(thin_exam)
	except:
		print(exam['subject']['code']+' poorly formatted')

def upload_fmri(session_id,scanid):
	print('processing fmri')
	scanidlist = scanid.split('_')
	pid = scanidlist[0]
	visit = scanidlist[1]
	session = scanidlist[2].split('.')[0]
	fmri_path = pjoin('/oak/stanford/groups/menon/rawdata/scsnl/',pid,'visit'+str(visit),'session'+str(session),'fmri')
	if not os.path.exists(fmri_path):
		print('fmri path does not exist')
		return False
	fmri_image_paths = []
	for root, folders, files in os.walk(fmri_path):
		for file in files:
			if file == 'I.nii.gz' or file == 'I.nii':
				fmri_image_paths.append(pjoin(root,file))
	runs = {}
	for path in fmri_image_paths:
		path_split = path.split('/')
		unnormalized_found = False
		for i in range(len(path_split)):
			if 'unnormalized' in path_split[i]:
				run = path_split[i-1]
				unnormalized_found=True
				if run not in runs:
					print('creating acquisition '+run)
					acquisition_id = fw.add_acquisition(flywheel.Acquisition(session=session_id, label=run))
					runs[run] = acquisition_id
		if not unnormalized_found:
			print('no unnormalized folder found for %s'%path)
			continue
		print('uploading %s to acquisition %s'%(path,runs[run]))
		fw.upload_file_to_acquisition(runs[run], path)
		fw.modify_acquisition_file(runs[run], path.split('/')[-1],body={'measurements':['functional']})
	return runs

def upload_behavioral(session_id,scanid,runs):
	print('processing behavioral')
	behav_targets = ['behavioral','behavior','Behavioral','Behavior']
	behav_acq = False
	scanidlist = scanid.split('_')
	pid = scanidlist[0]
	visit = scanidlist[1]
	session = scanidlist[2].split('.')[0]
	top_path = pjoin('/oak/stanford/groups/menon/rawdata/scsnl/',pid,'visit'+str(visit),'session'+str(session))
	for root, folders, files in os.walk(top_path):
		for folder in folders:
			if folder in behav_targets:
				behav_path = pjoin(root,folder)
				run_found = False
				for run in runs:
					if '/'+run+'/' in behav_path:
						run_found = True
						run_id = runs[run]
						upload_acq = run_id
						break
				if not run_found:
					if behav_acq == False:
						behav_acq=fw.add_acquisition(flywheel.Acquisition(session=session_id, label='behavioral'))
					upload_acq = behav_acq
				behav_files = os.listdir(behav_path)
				for behav_file in behav_files:
					if not os.path.isfile(pjoin(behav_path,behav_file)):
						print('creating acquisition for behavioral subfolder %s'%pjoin(behav_path,behav_file))
						upload_acq2 = fw.add_acquisition(flywheel.Acquisition(session=session_id, label='behavioral_'+behav_file))
						for root2, folders, files2 in os.walk(pjoin(behav_path,behav_file)):
							for file2 in files2:
								fw.upload_file_to_acquisition(upload_acq2, pjoin(root2,file2))
								fw.modify_acquisition_file(upload_acq2, file2,body={'measurements':['behavioral']})	
						continue
					print('uploading %s to acq %s'%(pjoin(behav_path,behav_file),upload_acq))
					fw.upload_file_to_acquisition(upload_acq, pjoin(behav_path,behav_file))
					fw.modify_acquisition_file(upload_acq, behav_file,body={'measurements':['behavioral']})					



def upload_anatomical(session_id,scanid):
	print('processing anatomical')
	scanidlist = scanid.split('_')
	pid = scanidlist[0]
	visit = scanidlist[1]
	session = scanidlist[2].split('.')[0]
	anatomical_acq = fw.add_acquisition(flywheel.Acquisition(session=session_id, label='anatomical'))
	anatomical_path = pjoin('/oak/stanford/groups/menon/rawdata/scsnl/',pid,'visit'+str(visit),'session'+str(session),'anatomical')
	if not os.path.exists(anatomical_path):
		print('no anatomcal folder!')
		return False
	for root, folders, files in os.walk(anatomical_path):
		for file in files:
			if 'spgr' in file and 'old' not in root:
				print('uploading %s to acq %s'%(pjoin(root,file),str(anatomical_acq)))
				fw.upload_file_to_acquisition(anatomical_acq, pjoin(root,file))
				fw.modify_acquisition_file(anatomical_acq, file,body={'measurements':['anatomy_t1w']})


def upload_dwi(session_id,scanid):
	print('processing dwi')
	scanidlist = scanid.split('_')
	pid = scanidlist[0]
	visit = scanidlist[1]
	session = scanidlist[2].split('.')[0]
	dwi_acq = fw.add_acquisition(flywheel.Acquisition(session=session_id, label='dwi'))
	dwi_path = pjoin('/oak/stanford/groups/menon/rawdata/scsnl/',pid,'visit'+str(visit),'session'+str(session),'dwi')
	if not os.path.exists(dwi_path):
		print('no dwi folder!')
		return False
	for root, folders, files in os.walk(dwi_path):
		for file in files:
			if 'dwi' in file and ('.nii' in file or '.json' in file):
				print('uploading %s to acq %s'%(pjoin(root,file),str(dwi_acq)))
				fw.upload_file_to_acquisition(dwi_acq, pjoin(root,file))
				fw.modify_acquisition_file(dwi_acq, file,body={'measurements':['diffusion']})
	return True


def upload_extra(session_id,scanid):
	print('processing extra')
	scanidlist = scanid.split('_')
	pid = scanidlist[0]
	visit = scanidlist[1]
	session = scanidlist[2].split('.')[0]
	top_level = pjoin('/oak/stanford/groups/menon/rawdata/scsnl/',pid,'visit'+str(visit),'session'+str(session))
	if not os.path.exists(top_level):
		print('no top level folder!')
		return False
	top_level_folders = os.listdir(top_level)
	extra_folders = []
	for folder in top_level_folders:
		if folder not in ['fmri','anatomical','dwi']:
			print('extra folder found: %s'%folder)
			extra_folders.append(folder)
	if extra_folders == []:
		print('no extra folders found')
		return
	for folder in extra_folders:
		acqs = fw.get_session_acquisitions(session_id)
		upload_id = False
		for acq in acqs:
			if acq['label'] == folder:
				upload_id = acq['_id']
				break
		if upload_id == False:
			upload_id=fw.add_acquisition(flywheel.Acquisition(session=session_id, label=folder))
		extra_files = os.listdir(pjoin(top_level,folder))
		for extra_file in extra_files:
			if not os.path.isfile(pjoin(top_level,extra_file)):
				print('taring folder %s and uploading to %s'%(pjoin(top_level,extra_file),folder))
				call('tar zcvf %s.tar.gz %s'%(pjoin(top_level,extra_file),pjoin(top_level,extra_file)),shell=True)
				tarball = '%s.tar.gz'%pjoin(top_level,extra_file)
				fw.upload_file_to_acquisition(upload_id, tarball)
				call('/bin/rm %s'%tarball,shell=True)
			else:
				print('taring folder %s and uploading to %s'%(pjoin(top_level,extra_file),folder))
				fw.upload_file_to_acquisition(upload_id, pjoin(top_level,extra_file))
	return True

#iterate through sublist scanids and identity and upload those that aren't present
for scanid in scans:
	print('uploading %s'%scanid)
	if scanid in fw_scanids or scanid.split('.')[0] in fw_scanids:
		print('already uploaded')
		continue
	print('adding session %s to project %s'%(scanid,study))
	session_id = fw.add_session(flywheel.Session(project=study_id, label=scanid))
	fw.modify_session(session_id,{'subject':{'code':scanid}})
	runs=upload_fmri(session_id,scanid)
	if runs != False:
		upload_behavioral(session_id,scanid, runs)
	success = upload_anatomical(session_id,scanid)
	success = upload_dwi(session_id,scanid)
	success = upload_extra(session_id,scanid)
