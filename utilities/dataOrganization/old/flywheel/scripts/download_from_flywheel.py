import os
from os.path import join as pjoin
from subprocess import call,Popen,PIPE
from flywheel import Flywheel
import time
import sys
import pdb
sys.path.insert(0, '/oak/stanford/groups/menon/projects/chamblin')
from helper_funcs import print_out, split_path
from studies_template import studies_template, studies_rules

#log = open('../logs/fw_download_%s.log' % time.strftime('%m-%d-%Y'), 'w+')

#Get flywheel credentials
fw = Flywheel('lucascenter.flywheel.io:oglHDMF0DnDeKPmDnl')
me = fw.get_current_user()


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

def print_out(statement, file): # function for printing to a log as well as the terminal
	print(statement)
	file.write(str(statement))
	file.write('\n')
	file.flush()

def split_path(path):
	folderlist = path.split('/')
	root = '/'.join(folderlist[:-1])
	file = folderlist[-1]
	return [root,file]

def replace_right(source, target, replacement, replacements=None):
	return replacement.join(source.rsplit(target, replacements))

# Function to check whether a session has run all its gears or not
def has_pending_jobs(fw, session_id): 
	jobs = fw.get_session_jobs(session_id)
	for job in jobs.jobs:
		if job.state in [ 'pending', 'running' ]:
			return True
	return False

def checkpath(path):
	level = 1
	pathroot = split_path(path)[0]
	filename = split_path(path)[1]
	if not os.path.exists(path):
		return path
	newpath = pjoin(pathroot,str(level)+'_'+filename)
	while os.path.exists(newpath):
		level += 1
		newpath = pjoin(pathroot,str(level)+'_'+filename)
	return newpath

def modify_file_class_by_template(acq_id,file_name,download_path,fw = fw):
	if 'dwi' in download_path:
		label = 'dwi'
	elif 'fmri' in download_path:
		label = 'functional'
	elif 'anatomical' in download_path and 't2' not in file_name and 'T2' not in file_name:
		label = 'anatomy_t1w'
	elif 'anatomical' in download_path:
		label = 'anatomy_t2w'
	else:
		label = 'unknown'
	fw.modify_acquisition_file(acq_id, file_name,body={'measurements':[label]})	


#rsync behavioral data folder on scsnlpc with sherlock .fromlucas folder
print('rsyncing behavioral data')
call('rsync -av scsnl@171.65.52.100:/hd1/scsnl/datafromlucas/ /oak/stanford/groups/menon/rawdata/.fromlucas',shell=True)

#run some checks
# Check that data can flow back & forth across the bridge
#bridge_response = flywheel.test_bridge('world')
#assert bridge_response == 'Hello world'
# Check SDK version
#assert len(flywheel.Flywheel.get_sdk_version()) > 0

#generate dictionary of project ids to study names
projects_full = fw.get_all_projects()
#print(fw_projects_full)
projects_thin = {}
for project in projects_full:
	projects_thin[project['_id']] = project['label']

#generate list of thin exam dictionaries with  flywheel id, scanid, and study name
exams_full = fw.get_all_sessions()
#print(type(sessions))
#print(sessions)
exams_thin = []
for exam in exams_full:
	try:
		label_root = exam['subject']['code'].split('.')[0]
		scanidlist = label_root.split('_')
		scanid = scanidlist[0].zfill(4)+'_'+scanidlist[1]+'_'+scanidlist[2]
		thin_exam = {'fw_id':exam['_id'],'scanid':scanid,'study':projects_thin[exam['project']]}
		exams_thin.append(thin_exam)
	except:
		print(exam['subject']['code']+' poorly formatted')

#print('exams in flywheel:')
#print(exams_thin)

#iterate through every exam on flywheel, if its scanid is not on Sherlock, and all gears are processed for all exams with that scanid,
#download acquisition files according to the study template
downloaded_scanids = []

#pdb.set_trace()
for exam in exams_thin:
	#print('checking for exam:')
	#print(exam)
	#check if scanid already in rawdata
	if exam['scanid'] in rawdata_scanids:
		continue
	print('new %s scan found: %s'%(exam['study'],exam['scanid']))
	# Check to see if any exams with that scan id still need to finish running gears
	pending_jobs = False
	for other_exam in exams_thin:
		if other_exam['scanid'] == exam['scanid']:
			if has_pending_jobs(fw, other_exam['fw_id']):
				pending_jobs=True
				break
	if pending_jobs:
		print('Gears have not finished on this scanid. Skipping . . .')
		continue
	#Download data according to template
	#path information for data to be downloaded

	pid = exam['scanid'].split('_')[0]
	visit = 'visit'+exam['scanid'].split('_')[1]
	session = 'session'+exam['scanid'].split('_')[2]
	downloaded_scanids.append([pid,visit,session,exam['study']])
	scanidpath = pjoin(rawdata_root,pid,visit,session)
	#gen list of acquisitions associated with this exam
	fw_acqs = fw.get_session_acquisitions(exam['fw_id'])
	study_template = studies_template[exam['study']]
	for acquisition in study_template:
		for fw_acq in fw_acqs:
			#download acquisition files from study template
			if fw_acq['label'] == acquisition:
				for download_pair in study_template[acquisition]:
					for file in fw_acq['files']:
						#modify file types
						if '.7' in file['name'] and (file['name'][0] =='E' or file['name'][0]=='P'):
							fw.modify_acquisition_file(fw_acq['_id'], file['name'],body={'type':'pfile'})	
						#download files
						if download_pair[0] in file['name']:
							modify_file_class_by_template(fw_acq['_id'],file['name'],download_pair[1])
							os.makedirs(split_path(pjoin(scanidpath,download_pair[1].replace('*',file['name'])))[0],exist_ok=True)
							pathname = checkpath(pjoin(scanidpath,download_pair[1].replace('*',file['name'])))
							print('downloading %s'%pathname)
							fw.download_file_from_acquisition(fw_acq['_id'], file['name'], pathname)
			# download redo files
			if acquisition in fw_acq['label'] and 'redo' in fw_acq['label']:
				for download_pair in study_template[acquisition]:
					for file in fw_acq['files']:
						# recassify files and modify files types
						if '.7' in file['name'] and (file['name'][0] =='E' or file['name'][0]=='P'):
							fw.modify_acquisition_file(fw_acq['_id'], file['name'],body={'type':'pfile'})	
						#download files
						if download_pair[0] in file['name']:
							modify_file_class_by_template(fw_acq['_id'],file['name'],download_pair[1])
							os.makedirs(split_path(pjoin(scanidpath,download_pair[1].replace('*',file['name'])).replace(acquisition,fw_acq['label']))[0],exist_ok=True)
							pathname = checkpath(pjoin(scanidpath,download_pair[1].replace('*',file['name'])).replace(acquisition,fw_acq['label']))
							print('downloading %s'%pathname)
							fw.download_file_from_acquisition(fw_acq['_id'], file['name'], pathname)

failed_downloads = []
for scanid_list in downloaded_scanids:
	if not os.path.exists(pjoin('/oak/stanford/groups/menon/rawdata/scsnl',scanid_list[0],scanid_list[1],scanid_list[2])):
		failed_downloads.append(scanid_list)
		downloaded_scanids.remove(scanid_list)		

print('downloaded scanids:')
print(downloaded_scanids)
print('failed downloads:')
print(failed_downloads)

# syncing behavioral data
from_lucas_path = '/oak/stanford/groups/menon/rawdata/.fromlucas'
behav_targets = ['behavioral','behavior','Behavioral','Behavior']
fromlucas_folders = os.listdir(from_lucas_path)
for scanid_list in downloaded_scanids:
	#find downloaded scanids in .fromlucas folder
	scanid = scanid_list[0]+'_'+scanid_list[1][-1]+'_'+scanid_list[2][-1]
	#compile flywheel exams associated with scanid
	flywheel_exams = []
	for exam in exams_thin:
		if scanid in exam['scanid']:
			flywheel_exams.append(exam)
	rawdatapath = pjoin('/oak/stanford/groups/menon/rawdata/scsnl',scanid_list[0],scanid_list[1],scanid_list[2])
	print('processing %s behavioral'%scanid)
	lucas_found = False
	for lucas_scanid in fromlucas_folders:
		if scanid in lucas_scanid:
			lucas_found = True
			lucas_scanid_path = pjoin(from_lucas_path,lucas_scanid)
			#download extra folders
			for folder in os.listdir(lucas_scanid_path):
				if folder not in behav_targets and folder not in ['anatomical','anatomy','mri','dwi','dti','fmri']:
					extra_folder_path = pjoin(lucas_scanid_path,folder)
					print('found extra folder %s'%extra_folder_path)
					call('cp -r %s %s'%(extra_folder_path,rawdatapath),shell=True)
					if os.path.isdir(pjoin(lucas_scanid_path,folder)):
						acqId = fw.add_acquisition({'label': folder,'session': flywheel_exams[0]['fw_id']})
						for root, folders, files in os.walk(pjoin(lucas_scanid_path,folder)):
							for file in files:
								print('uploading %s to acq %s %s'%(pjoin(root,file),folder,acqId))
								fw.upload_file_to_acquisition(acqId, pjoin(root,file))
			# download behavioral folders
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
							sess_acqs = fw.get_session_acquisitions(flywheel_exams[0]['fw_id'])
							fw_behavioral_found = False
							for sess_acq in sess_acqs:
								if sess_acq['label'] == 'behavioral':
									acqId = sess_acq['_id']
									fw_behavioral_found = True
									break
							if not fw_behavioral_found:
								acqId = fw.add_acquisition({'label': 'behavioral','session': flywheel_exams[0]['fw_id']})
							for behav_path in files_under_behavioral:
								print('uploading %s'%behav_path)
								fw.upload_file_to_acquisition(acqId, behav_path)				
	if not lucas_found:
		print('scanid not found in .fromlucas folder!')
	#Functional data processing
	print('pconverting %s'%scanid)
	cwd = os.getcwd()
	for root, folders, files in os.walk(pjoin(rawdatapath,'fmri')):
		#splitting niftis non p conversion
		for file in files:
			if file == 'I.nii.gz':
				# splitting 4-D to 3-Ds
				if not os.path.exists(pjoin(root,'unused')):
					os.makedirs(pjoin(root,'unused'),exist_ok=True)
				print('splitting nifti %s'%pjoin(root,file))
				os.chdir(root)
				call('fslsplit I.nii.gz I_',shell=True)
				call('/bin/rm -rf I.nii*',shell=True)
				#move unused according to study rules
				num_unused = int(studies_rules[scanid_list[3]]['unused_num'])
				print('moving first %s images to unused'%num_unused)
				for i in range(num_unused):
					image_slice = str(i).zfill(4)
					call('mv -f I_%s* unused'%image_slice,shell=True)
				# merge rest 3-Ds to a 4-D
				call('fslmerge -t I *.nii.gz', shell = True)
				call('/bin/rm -rf I_*', shell=True)
		# P Conversion
		for folder in folders:
			if folder == 'Pfiles':
				pfilespath = pjoin(root,folder)
				print('pconverting %s'%pfilespath)
				os.chdir(pfilespath)
				call('/oak/stanford/groups/menon/toolboxes/pconvert/makenifti E*P*.7 I',shell=True)
				if not os.path.exists('../unnormalized/unused'):
					os.makedirs('../unnormalized/unused',exist_ok=True)
				call('mv I* ../unnormalized',shell=True)
				if os.path.exists('../unnormalized/I.nii'):
					call('gzip ../unnormalized/I.nii',shell=True)
				# splitting 4-D to 3-Ds
				os.chdir('../unnormalized')
				call('fslsplit I.nii I_',shell=True)
				call('/bin/rm -rf I.nii*',shell=True)
				#move unused according to study rules
				num_unused = int(studies_rules[scanid_list[3]]['unused_num'])
				print('moving first %s images to unused'%num_unused)
				for i in range(num_unused):
					image_slice = str(i).zfill(4)
					call('mv -f I_%s* unused'%image_slice,shell=True)
				# merge rest 3-Ds to a 4-D
				call('fslmerge -t I *.nii.gz', shell = True)
				call('/bin/rm -rf I_*', shell=True)
				if os.path.isfile('I.nii.gz'):
					print('P Conversion successful.')
					print('deleting pfiles . . .')
					call('/bin/rm -r ../Pfiles', shell=True)
					this_dir = os.getcwd()
					# replace bad nifti file on flywheel with this file
					sess_acqs = []
					for exam in flywheel_exams:
						for acq in fw.get_session_acquisitions(exam['fw_id']):
							sess_acqs.append(acq)
					for sess_acq in sess_acqs:
						if '/'+sess_acq['label']+'/' in this_dir:
							print('found matching acq %s %s'%(sess_acq['label'],sess_acq['_id']))
							#check for pfiles
							pfiles_found = False
							for file in sess_acq['files']:
								if file['name'][-2:] == '.7':
									pfiles_found = True
									break
							if not pfiles_found:
								print('no pfiles in fw acq')
								continue
							#upload pconverted nifti file
							print('uploading pconverted, dummy-stripped %s to acq %s %s'%(pjoin(this_dir,'I.nii.gz'),sess_acq['label'],sess_acq['_id']))
							fw.upload_file_to_acquisition(sess_acq['_id'], pjoin(this_dir,'I.nii.gz'))
							fw.modify_acquisition_file(sess_acq['_id'], 'I.nii.gz',body={'measurements':['functional']})
							current_dicom = False
							current_nifti = False
							current_nifti_name = 'none'
							for file in sess_acq['files']:
								if '.7.' not in file['name'] and '.nii.gz' in file['name'] and len(file['name'])>20:
									current_nifti = True
									current_nifti_name = file['name']
								if '.dicom.zip' in file['name']:
									current_dicom = True
							if current_dicom and current_nifti:
								print('deleting bad dicom converted nifti file %s from acq %s %s'%(current_nifti_name,sess_acq['label'],sess_acq['_id']))
								fw.delete_acquisition_file(sess_acq['_id'],current_nifti_name)
							else:
								print('bad nifti file not found to replace')
				else:
					print('P Conversion unsuccessful :(')
				os.chdir(cwd)
	#anatomical conversion
	cwd = os.getcwd()
	print('anatomical dicom convert %s'%scanid)
	anatomicalpath = pjoin(rawdatapath,'anatomical')
	if os.path.exists(anatomicalpath):
		os.chdir(anatomicalpath)
	else:
		print('no anatomical folder :(')
		continue
	anat_folders_created = 0
	anatroots = []
	for anatroot, folders, files in os.walk(anatomicalpath):
		for file in files:
			if '.dicom.zip' in file:
				anat_folders_created += 1
				anat_folder_name = str(anat_folders_created).zfill(3)
				anatroots.append(anatroot)
				os.chdir(anatroot)
				call('unzip %s'%pjoin(anatroot,file),shell=True)
				print('moving %s to %s'%(file.replace('.zip',''),anat_folder_name))
				call('mv %s %s'%(pjoin(anatroot,file).replace('.zip',''),pjoin(anatroot,anat_folder_name)),shell=True)
				call('/bin/rm %s'%pjoin(anatroot,file),shell=True)
	#for subdir in os.listdir('.'):
	#	if '.dicom.zip' in subdir:
	#		anat_folders_created += 1
	#		anat_folder_name = str(anat_folders_created).zfill(3)
	#		call('unzip %s'%subdir,shell=True)
	#		print('moving %s to %s'%(subdir.replace('.zip',''),anat_folder_name))
	#		call('mv %s %s'%(subdir.replace('.zip',''),anat_folder_name),shell=True)
	#		call('/bin/rm %s'%subdir,shell=True)
	os.chdir('/oak/stanford/groups/menon/scsnlscripts/utilities/dataOrganization/pre_preprocessing/utils')
	for anatroot in anatroots:
		call('matlab -nodisplay -nosplash -nodesktop -r "try;dcm2spgr(\'%s\');catch;end;quit"'%anatroot,shell=True)
	os.chdir(anatomicalpath)
	spgr_made = False
	spgr_num = 0
	for anatroot, folders, files in os.walk(anatomicalpath):
		for file in files:
			if 'spgr' in file:
				spgr_made = True
				spgr_num+=1
	if spgr_made:
		for anatroot, folders, files in os.walk(anatomicalpath):
			for folder in folders:
				if folder.isdigit():
					call('/bin/rm -r %s'%pjoin(anatroot,folder),shell=True)
		print('%s spgr files made!'%spgr_num)
	else:
		print('no spgr files made :(')
	os.chdir(cwd)	


#Permissions 
print('editing permissions for successful download folders:')

for scanid_list in downloaded_scanids:
	print(scanid_list)
	path = pjoin('/oak/stanford/groups/menon/rawdata/scsnl',scanid_list[0],scanid_list[1],scanid_list[2])
	if not os.path.exists(path):
		print('%s not found!'%path)
		continue
	study = scanid_list[3]
	people = studies_rules[study]['permissions']
	print(people)
	for person in people:
		call('setfacl -R -m u:%s:rwx %s'%(person,path),shell=True)		


