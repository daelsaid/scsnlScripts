'''
pconvert fmri folder iterate through find pfiles pconvert
to run:
source activate py36
ml biology fsl
'''
import os
from os.path import join as pjoin
from subprocess import call

rawdata = '/oak/stanford/groups/menon/rawdata/scsnl/'
fmri_path = rawdata+'/7884/visit2/session1/fmri/' #just fmri path not run path it will do each run on its own!!!!

delete_Pfiles = False
# If H&W, set num_unused to 2
num_unused = 2

for root, folders, files in os.walk(pjoin(fmri_path)):
	for folder in folders:
		print(folder)
		if folder == 'Pfiles':
			pfilespath = pjoin(root,folder)
			cwd = os.getcwd()
			print('found pfiles %s'%pfilespath)
			if os.path.isfile(pjoin(root,'unnormalized','I.nii.gz')):
				print('I.nii.gz already exists!')
				continue
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
			print('moving first %s images to unused'%num_unused)
			for i in range(num_unused):
				image_slice = str(i).zfill(4)
				call('mv -f I_%s* unused'%image_slice,shell=True)
			# merge rest 3-Ds to a 4-D
			call('fslmerge -t I *.nii.gz', shell = True)
			call('/bin/rm -rf I_*', shell=True)
			if os.path.isfile('I.nii.gz'):
				print('P Conversion successful.')
				if delete_Pfiles:
					print('deleting pfiles . . .')
					call('/bin/rm -r ../Pfiles', shell=True)
				# replace bad nifti file on flywheel with this file
				'''
				sess_acqs = []
				for exam in flywheel_exams:
					sess_acqs.append(fw.get_session_acquisitions(exam['fw_id']))
				for sess_acq in sess_acqs:
					if '/'+sess_acq['label']+'/' in root:
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
						print('uploading pconverted, dummy-stripped %s to acq %s %s'%(pjoin(root,'unnormalized','I.nii.gz'),sess_acq['label'],sess_acq['_id']))
						fw.upload_file_to_acquisition(sess_acq['_id'], pjoin(root,'unnormalized','I.nii.gz'))
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
				'''

			else:
				print('P Conversion unsuccessful :(')
			os.chdir(cwd)
