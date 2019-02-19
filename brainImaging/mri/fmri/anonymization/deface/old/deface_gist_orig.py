import os, subprocess, shutil, tempfile
import os.path as op
import nibabel as nib
import numpy as np

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
    subprocess.call(['fslchfiletype', 'ANALYZE', anat_fullfile, temp_img])
    cwd = os.getcwd()
    os.chdir(temp_dir)
    with open(os.devnull, 'wb') as DEVNULL:
        subprocess.call(['mask_face', anat_name, '-a', '-s', '0.75', '-v', '0', '-m', 'normfilter'],
                        stdout = DEVNULL,
                        stderr = DEVNULL
                       )
    mask_face_img = op.join(temp_dir, 'maskface', '%s_full_normfilter.img' % anat_name)
    mask_face_nii = op.join(op.dirname(anat_fullfile), anat_name + '_defaced.nii.gz')
    subprocess.call(['fslchfiletype', 'NIFTI_GZ', mask_face_img, mask_face_nii])
    os.chdir(cwd)
    shutil.rmtree(temp_dir)
    reorient_like(mask_face_nii, anat_fullfile)
    return mask_face_nii

def unmask_brain(raw, defaced):
    anat_name = op.basename(raw).split('.')[0]
    anat_dir = op.dirname(raw)
    raw_nii = nib.load(raw)
    raw_data = raw_nii.get_data().astype(np.float32)
    deface_nii = nib.load(defaced)
    deface_data = deface_nii.get_data().astype(np.float32)
    face_mask = deface_data != raw_data
    #  run watershed, get the brain mask, unmask any brain voxels
    stripped = op.join(anat_dir, '%s_watershed.nii.gz' % anat_name)
    subprocess.call(['mri_watershed', raw, stripped])
    strip_nii = nib.load(stripped)
    brain_mask = strip_nii.get_data() > 0
    deface_data[brain_mask] = raw_data[brain_mask]
    nib.save(nib.Nifti1Image(deface_data, deface_nii.get_affine()), defaced)
    os.remove(stripped)

raw_anat_file = '/hd1/scsnl/data/face_blur_worked/spgr.nii.gz'
defaced_anat_file = mask_face(raw_anat_file) # deface
unmask_brain(raw_anat_file, defaced_anat_file) # unblur any voxels mri_watershed thinks are brain
