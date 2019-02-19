import os, subprocess, shutil, tempfile
import os.path as op
import nibabel as nib
import numpy as np
import pdb
import sys

#pdb.set_trace()
#subprocess.call('source /hd1/scsnl/scripts/face_blur/lin64/bin/maskface_setup.sh',shell=True, executable="/bin/bash")

def reorient_like(reo_img, ref_img):
    # There is probably a better way, but fslswapdim/reorient2std will not do it
    ref = nib.load(ref_img)
    ref_aff = ref.get_affine()
    ref_ori = nib.orientations.io_orientation(ref_aff)
    reo = nib.load(reo_img)
    reo_ori = nib.orientations.io_orientation(reo.get_affine())
    reo2ref_ori_xfm = nib.orientations.ornt_transform(reo_ori, ref_ori)
    reo_data = nib.orientations.apply_orientation(reo.get_data(), reo2ref_ori_xfm)
    nib.save(nib.Nifti1Image(reo_data, ref_aff), reo_img)

def mask_face(anat_fullfile):
    temp_dir = tempfile.mkdtemp()
    anat_name = op.basename(anat_fullfile).split('.')[0]
    temp_img = op.join(temp_dir, anat_name + '.img')
    #pdb.set_trace()
    subprocess.call(['fslchfiletype ANALYZE '+ anat_fullfile + ' '+ temp_img],shell=True)
    cwd = os.getcwd()
    os.chdir(temp_dir)
    #pdb.set_trace()
    with open(os.devnull, 'wb') as DEVNULL:
         subprocess.call(['mask_face', anat_name, '-a', '-s', '0.75', '-v', '0', '-m', 'normfilter'],
                         stdout = DEVNULL,
                         stderr = DEVNULL,
                         shell=True
                        )
    #pdb.set_trace()
    mask_face_img = op.join(temp_dir, 'maskface', '%s_full_normfilter.img' % anat_name)
    mask_face_nii = op.join(op.dirname(anat_fullfile), anat_name + '_defaced.nii.gz')
    #pdb.set_trace()
    subprocess.call(['fslchfiletype NIFTI_GZ ' + anat_name + ' '+ mask_face_nii],shell=True)
    os.chdir(cwd)
    #shutil.rmtree(temp_dir)
    #reorient_like(mask_face_nii, anat_fullfile)
    return mask_face_nii

def unmask_brain(raw, defaced):
    anat_name = op.basename(raw).split('.')[0]
    anat_dir = op.dirname(raw)
    raw_nii = nib.load(raw)
    raw_data = raw_nii.get_data().astype(np.float32)
    #pdb.set_trace()
    deface_nii = nib.load(defaced)
    deface_data = deface_nii.get_data().astype(np.float32)
    face_mask = deface_data != raw_data
    #  run watershed, get the brain mask, unmask any brain voxels
    stripped = op.join(anat_dir, '%s_watershed.nii.gz' % anat_name)
   # pdb.set_trace()
    #subprocess.call(['/usr/local/freesurfer/bin/mri_watershed ' + raw + ' ' + stripped],shell=True)
    #strip_nii = nib.load(stripped)
    #brain_mask = strip_nii.get_data() > 0
    #mask = op.join(anat_dir, '%s_facemask.nii.gz' % anat_name)
    #eface_data[brain_mask] = raw_data[brain_mask]
    #nib.save(nib.Nifti1Image(face_mask.astype(np.int16), deface_nii.get_affine()), mask)
    #nib.save(nib.Nifti1Image(deface_data, deface_nii.get_affine()), defaced)
    #os.remove(stripped)

pathsfile = open(sys.argv[1],'r')
paths = pathsfile.readlines()
paths = [x.strip() for x in paths]

for raw_anat_file in paths:
	print('defacing image %s'%raw_anat_file)
	#raw_anat_file = '/oak/stanford/groups/menon/rawdata/scsnl/100509/visit1/session1/mri/dti/100509_1_1.3T2/dwi_006.nii.gz'
	defaced_anat_file = mask_face(raw_anat_file) # deface
	#pdb.set_trace()
	#unmask_brain(raw_anat_file, defaced_anat_file) # unblur any voxels mri_watershed thinks are brain

# source freesurfer 6
# FREESURFER_HOME=...
# source /hd1/scsnl/scripts/face_blur/lin64/bin/maskface_setup.sh
