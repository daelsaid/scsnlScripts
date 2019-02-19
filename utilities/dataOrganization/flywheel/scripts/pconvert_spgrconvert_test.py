'''temp file to test move unused and spgr convert functionality'''

import os
from os.path import join as pjoin
from subprocess import call
from flywheel import Flywheel
import time
import sys
import pdb
sys.path.insert(0, '/oak/stanford/groups/menon/projects/chamblin')
from helper_funcs import print_out, split_path
from studies_template import studies_template, studies_rules

'''
downloaded_scanids = [['0059', 'visit2', 'session1','smpmathfun'], 
['7483', 'visit7', 'session1','asdmemory'], ['7943', 'visit3', 'session1','hwc'], 
['0224', 'visit2', 'session1','smpmathfun'], ['0224', 'visit2', 'session2','smpsmp'], 
['0281', 'visit2', 'session1','smpmathfun'], ['0098', 'visit2', 'session1','smpmathfun']]
'''
downloaded_scanids = [['8082', 'visit2', 'session1','mathwhiz'], 
['7863', 'visit2', 'session1','hwc'], ['0098', 'visit2', 'session2','smpsmp']]


for scanid_list in downloaded_scanids:
	scanid = scanid_list[0]+'_'+scanid_list[1][-1]+'_'+scanid_list[2][-1]
	rawdatapath = pjoin('/oak/stanford/groups/menon/rawdata/scsnl',scanid_list[0],scanid_list[1],scanid_list[2])
	#pconversion
	print('pconverting %s'%scanid)
	for root, folders, files in os.walk(pjoin(rawdatapath,'fmri')):
		for folder in folders:
			if folder == 'Pfiles':
				pfilespath = pjoin(root,folder)
				cwd = os.getcwd()
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
				call('rm -rf I.nii*',shell=True)
				#move unused according to study rules
				num_unused = int(studies_rules[scanid_list[3]]['unused_num'])
				print('moving first %s images to unused'%num_unused)
				for i in range(num_unused):
					image_slice = str(i).zfill(4)
					call('mv -f I_%s* unused'%image_slice,shell=True)
				# merge rest 3-Ds to a 4-D
				call('fslmerge -t I *.nii.gz', shell = True)
				call('rm -rf I_*', shell=True)
				if os.path.isfile('I.nii.gz'):
					print('P Conversion successful.')
					print('deleting pfiles . . .')
					call('/bin/rm -r ../Pfiles', shell=True)
				else:
					print_out('P Conversion unsuccessful :(')
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
	for subdir in os.listdir('.'):
		if '.dicom.zip' in subdir:
			anat_folders_created += 1
			anat_folder_name = str(anat_folders_created).zfill(3)
			call('unzip %s'%subdir,shell=True)
			call('mv %s %s'%(subdir.replace('.zip',''),anat_folder_name),shell=True)
			call('rm %s'%subdir,shell=True)
	os.chdir('/oak/stanford/groups/menon/scsnlscripts/utilities/dataOrganization/pre_preprocessing/utils')
	call('matlab -nodisplay -nosplash -nodesktop -r "try;dcm2spgr(\'%s\');catch;end;quit"'%anatomicalpath,shell=True)
	os.chdir(anatomicalpath)
	spgr_made = False
	spgr_num = 0
	for file in os.listdir('.'):
		if 'spgr' in file:
			spgr_made = True
			spgr_num+=1
	if spgr_made:
		for file in os.listdir('.'):
			if file.isdigit():
				call('/bin/rm -r %s'%file,shell=True)
		print('%s spgr files made!'%spgr_num)
	else:
		print('no spgr files made :(')
	os.chdir(cwd)		