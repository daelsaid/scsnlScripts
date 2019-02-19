# to run this script:
#ml biology fsl
#python mv_dummy_scans.py


from subprocess import call
import os


### EDIT THESE TWO LINES ###

path = '/oak/stanford/groups/menon/rawdata/scsnl/9302/visit2/session1/fmri/sym1_redo/unnormalized'# Full path to unnormalized folder containing I.nii.gz file
num_unused = 16

###   STOP EDITING    ####

os.chdir(path)
if not os.path.exists('unused/'):
	os.mkdir('unused/',exist_ok=True)
if os.path.isfile('I.nii'):
	call('gzip I.nii',shell=True)
# splitting 4-D to 3-D
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

