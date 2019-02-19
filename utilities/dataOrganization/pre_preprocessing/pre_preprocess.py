import os
from os.path import join as pjoin
from subprocess import call
import sys
import glob


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

def dwiconvert(insubdir,outsubdir, shelllog):
	#DWI convert	
	print_out('Converting DWI DICOMS . . .', shelllog)
	dwifound = False
	dwiout = pjoin(outsubdir,'dwi')
	if not os.path.exists(dwiout):
		os.makedirs(dwiout,exist_ok=True)
	nums_dicoms = [7800, 6048]
	for root, folders, files in os.walk(insubdir):
		for folder in folders:
			dcm = glob.glob(os.path.join(root,folder,'*.dcm'))
			if len(dcm) in nums_dicoms:
				dwifound = True
				print_out('found dwi in %s'%pjoin(root,folder),shelllog)
				if not os.path.exists(pjoin(dwiout,'dwi_raw.nii.gz')):
					call('dcm2niix -b y -f dwi_raw -o %s -z y %s'%(dwiout,pjoin(root,folder)),shell=True, stdout=shelllog, stderr=shelllog)
				else:
					print_out('dwi already converted',shelllog)
				break
	if not dwifound:
		print('no dwi dicoms found') 

def fmriconvert(insubdir,outsubdir, shelllog):
	print_out('processing fmri . . . ',shelllog)
	infmri = pjoin(insubdir,'fmri')
	outfmri = pjoin(outsubdir,'fmri')
	if not os.path.exists(outfmri):
		os.makedirs(outfmri,exist_ok=True)	
	rundirs = os.listdir(infmri)
	for run in rundirs:
		if run == 'physio':
			print_out('found physio',shelllog)
			if not os.path.exists(pjoin(outfmri,'physio')):
				call('cp -r %s %s'%(pjoin(infmri,'physio'),outfmri),shell=True, stdout=shelllog, stderr=shelllog)
			continue
		print_out('processing run %s'%run,shelllog)
		if not os.path.exists(pjoin(outfmri,run, 'unnormalized','I.nii.gz')):
			dicoms = False
			for root,folders,files in os.walk(pjoin(infmri,run)):
				for file in files:
					if 'dcm' in file:
						dicoms = True
						dicomfolder = root
						break
			if dicoms:
				print_out('found dicom folder %s'%dicomfolder,shelllog)
				if not os.path.exists(pjoin(outfmri,run, 'unnormalized')):
					os.makedirs(pjoin(outfmri,run, 'unnormalized'),exist_ok=True)	
				call('dcm2niix -b y -f I -o %s -z y %s'%(pjoin(outfmri,run,'unnormalized'),dicomfolder),shell=True, stdout=shelllog, stderr=shelllog)
			else:
				pfile = False
				for root, folders, files in os.walk(pjoin(infmri,run)):
					for file in files:
						if file[0] == 'P' and '.7' in file:
							pfile = file
							pfilepath = pjoin(root,file)
							pfilefolder = root
							break
				if not pfile:
					print_out('no dicoms or pfiles found',shelllog)
				else:
					print_out('Converting Pfiles', shelllog)
					pwd = os.getcwd()
					multiband = False
					for file in os.listdir(pfilefolder):
						if file[0] == 'P' and file[-4:] == '.dat':
							multiband = True
					if multiband:
						os.chdir('utils')
						print_out('found multiband',shelllog)
						pfile_nii = pfile.replace('.7','.nii')
						pfile_info_mat = pfile.replace('.7', '_info.mat')
						pfile_niigz = pfile.replace('.7','.nii.gz')
						pfile_nonr = pfile.replace('.7','_nonr.nii')
						call('unlimit; limit coredumpsize 0; setenv MATLABPATH /home/fmri/fmrihome//matlab/paths; /usr/local/matlab2013b/bin/matlab -nodesktop -nojit -nosplash -r "try;multiband_pconvert(\'%s\');catch;end;quit"'%pfilepath,shell=True, stdout=shelllog, stderr=shelllog)
						call('/bin/rm %s'%pfile_nonr,shell=True, stdout=shelllog, stderr=shelllog)
						if not os.path.exists(pfile_nii):
							print_out('conversion failed, file %s not created'%pfile_nii,shelllog)
							continue
						if not os.path.exists(pjoin(outfmri,run,'unnormalized')):
							os.makedirs(pjoin(outfmri,run,'unnormalized'),exist_ok=True)
						print_out('successfully created %s'%pfile_nii,shelllog)
						call('gzip %s'%pfile_nii,shell=True, stdout=shelllog, stderr=shelllog)
						call('mv %s %s'%(pfile_niigz,pjoin(outfmri,run,'unnormalized','I.nii.gz')),shell=True, stdout=shelllog, stderr=shelllog)
						call('mv %s %s'%(pfile_info_mat,pjoin(outfmri,run,'unnormalized')),shell=True, stdout=shelllog, stderr=shelllog)
						os.chdir(pwd)
					else:
						print_out('found normal Pfiles',shelllog)
						os.chdir(pfilefolder)
						call('/oak/stanford/groups/menon/toolboxes/pconvert/makenifti E*P*.7 I',shell=True,stdout=shelllog, stderr=shelllog)

						call('/oak/stanford/groups/menon/scsnlscripts/data/data_move/pconvert/makenifti E*P*.7 I',shell=True,stdout=shelllog, stderr=shelllog)
						if not os.path.exists(pjoin(outfmri,run,'unnormalized','unused')):
							os.makedirs(pjoin(outfmri,run,'unnormalized','unused'),exist_ok=True)
						call('mv I* %s'%pjoin(outfmri,run,'unnormalized'),shell=True,stdout=shelllog, stderr=shelllog)
						if os.path.exists(pjoin(outfmri,run,'unnormalized', 'I.nii')):
							call('gzip %s'%pjoin(outfmri,run,'unnormalized','I.nii'),shell=True,stdout=shelllog, stderr=shelllog)
						# splitting 4-D to 3-Ds
						os.chdir(pjoin(outfmri,run,'unnormalized'))
						call('fslsplit I.nii I_',shell=True,stdout=shelllog, stderr=shelllog)
						call('rm -rf I.nii*',shell=True,stdout=shelllog, stderr=shelllog)
  
						# move first 1/2 frames to unused folder
						call('mv -f I_0000* unused',shell=True,stdout=shelllog, stderr=shelllog)
						call('mv -f I_0001* unused',shell=True,stdout=shelllog, stderr=shelllog)
						# merge rest 3-Ds to a 4-D
						call('fslmerge -t I *.nii.gz', shell = True, stdout=shelllog, stderr=shelllog)
						call('rm -rf I_*', shell=True, stdout=shelllog,stderr=shelllog)
						if os.path.isfile(pjoin(outfmri,run,'unnormalized','I.nii.gz')):
							print_out('P Conversion successful.', shelllog)
						else:
							print_out('P Conversion unsuccessful.', shelllog)
					os.chdir(pwd)
		else:
			print_out('already converted',shelllog)

def behavioralconvert(insubdir,outsubdir,shelllog):
	behav_targets = ['behavioral','behavior','Behavioral','Behavior']
	for root, folders, files in os.walk(insubdir):
		for folder in folders:
			if folder in behav_targets:
				print_out('found behavioral folder %s'%pjoin(root,folder),shelllog)
				if not os.path.exists(pjoin(root.replace(insubdir,outsubdir),folder)):
					os.makedirs(pjoin(root.replace(insubdir,outsubdir),folder),exist_ok=True)
				subfiles = os.listdir(pjoin(root,folder))
				for subfile in subfiles:
					if not os.path.exists(pjoin(root.replace(insubdir,outsubdir),folder,subfile)):
						print_out('copying %s'%subfile,shelllog)
						call('cp -r %s %s'%(pjoin(root,folder,subfile),pjoin(root.replace(insubdir,outsubdir),folder)),shell=True, stdout=shelllog, stderr=shelllog)
					else:
						print_out('%s already copied'%subfile,shelllog)

def anatomicalconvert(insubdir,outsubdir,shelllog):
	print_out("Converting Anatomical DICOMS . . .", shelllog)
	outanat = pjoin(outsubdir,'anatomical')
	outanat_subdirs = os.listdir(outanat)
	for subdir in outanat_subdirs:
		if subdir in ['spgr.nii.gz','spgr_1.nii.gz','spgr_2.nii.gz']:
			print_out('anatomical conversion already run',shelllog)
			return
	os.makedirs(outanat,exist_ok=True)
	pwd = os.getcwd()
	os.chdir('utils')
	anat_folders = []
	for root, folders, files in os.walk(insubdir):
		for folder in folders:
			if folder.isdigit():
				if 'dwi' not in root and 'dti' not in root and 'fmri' not in root and root not in anat_folders:
					print_out('found anatomical folder %s'%root, shelllog)
					anat_folders.append(root)
	for folder in anat_folders:
		subfolders = os.listdir(folder)
		already_converted = False
		for subfolder in subfolders:
			if 'spgr' in subfolder and os.path.isfile(pjoin(folder,subfolder)):
				already_converted = True
				print_out('already converted: %s'%pjoin(folder,subfolder),shelllog)
		if not already_converted:
			#call matlab
			call('matlab -nodisplay -nosplash -nodesktop -r "try;dcm2spgr(\'%s\');catch;end;quit"' % folder,shell=True, stdout=shelllog, stderr=shelllog)
	
	spgr = False
	for anat_folder in anat_folders:
		subfiles = os.listdir(anat_folder)
		for subfile in subfiles:
			if 'spgr' in subfile:
				spgr = True
				call('cp %s %s'%(pjoin(anat_folder,subfile),outanat),shell=True, stdout=shelllog, stderr=shelllog)
				print_out('found spgr %s'%pjoin(anat_folder,subfile),shelllog)
	if not spgr:
		print_out('no spgr made! :(', shelllog)
		 

def processsubject(subject):
	shelllog = open('logs/%s_anatconvert_shell.log'%subject,'w+')
	print_out('processing subject %s'%subject, shelllog)
	scanidlist = subject.split('.')[0].split('_')
	pid = scanidlist[0].zfill(4)
	visit = 'visit'+scanidlist[1]
	session = 'session'+scanidlist[2]
	insubdir = pjoin('/oak/stanford/groups/menon/rawdata/.fromlucas',subject)
	outsubdir = pjoin('/oak/stanford/groups/menon/rawdata/scsnl',pid,visit,session)
	#fmriconvert(insubdir,outsubdir,shelllog)
	#behavioralconvert(insubdir,outsubdir,shelllog)
	#dwiconvert(insubdir,outsubdir,shelllog)
	anatomicalconvert(insubdir,outsubdir,shelllog)


subject = sys.argv[1]

processsubject(subject)
