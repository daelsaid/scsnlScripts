#setenv LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:/home/kochalka/lib64/

import os
import os.path
import sys
from run_AROMA_config import *

def source_fsl5():
  try:
    os.system('ml load biology')
    os.system('ml load fsl')
    os.system('ml load py-numpy')
    os.system('ml load py-scipy')

  except Exception, e:
    print str(e)

def ReadSubjectList(filename):
  try:
    f = open(filename, 'rU')
    subjectIDs = f.read()
    f.close()
    subjectList = [ subj.split(',') for subj in subjectIDs.split()[1:] ]
  except Exception, e:
    print str(e)
  return subjectList

def Run_ICA_AROMA_nonaggr(input_file, output_folder, mc_file, brain_mask_fname):
  try:
    cmd = 'sbatch -p menon -t 24:00:00 -o ' + jobs_dir + 'run-aroma-ica-%A.out -e ' + jobs_dir + 'run-aroma-ica-%A.err -J aroma-ica --wrap="ml load biology; ml load fsl; ml load py-numpy; ml load py-scipy; python /oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/aromaICA/functions/ICA_AROMA.py -in ' + input_file + ' -out ' + output_folder + ' -mc ' + mc_file + ' -tr ' + tr +' -m ' + brain_mask_fname + '"'
    print cmd
    os.system(cmd)
  except Exception, e:
    print str(e)

def Run_ICA_AROMA_aggr(input_file, output_folder, mc_file, brain_mask_fname):
  try:
    cmd = 'sbatch -p menon -t 24:00:00 -o ' + jobs_dir + 'run-aroma-ica-%A.out -e ' + jobs_dir + 'run-aroma-ica-%A.err -J aroma-ica --wrap="ml load biology; ml load fsl; ml load py-numpy; ml load py-scipy; python /oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/aromaICA/functions/ICA_AROMA.py -in ' + input_file + ' -out ' + output_folder + ' -mc ' + mc_file + ' -tr ' + tr +' -m ' + brain_mask_fname + ' -den aggr"'

#cmd = 'python /oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/aromaICA/ICA_AROMA.py -in ' + input_file + ' -out ' + output_folder + ' -mc ' + mc_file + ' -tr 2 ' + ' -m ' + brain_mask_fname + ' -den aggr'
    print cmd
    os.system(cmd)
  except Exception, e:
    print str(e)

def main():
    source_fsl5 # aggr needs fsl5

    subjectList = ReadSubjectList(subjectlist_file)

    for aggr_sign in aggr_signs:
      for isubj in subjectList:
          print isubj, aggr_sign

          for task_folder in task_dirs:

#                try:
                  interim_path_src = '/fmri/' + task_folder + '/' + pipeline + '_spm12/'
                  interim_path_des = '/fmri/' + task_folder + '/AROMA'
                  tmp1_input_file = raw_dir + 'imaging/' + 'participants/' + isubj[0] +'/'+'visit'+isubj[1] +'/session'+isubj[2] + interim_path_src + pipeline + 'I.nii.gz'
                  tmp2_input_file =raw_dir + 'imaging/' + 'participants/' + isubj[0] +'/'+'visit'+isubj[1] +'/session'+isubj[2] + interim_path_src + pipeline + 'I.nii'
		  print tmp1_input_file
		  print tmp2_input_file
                  if os.path.isfile(tmp2_input_file):
                    input_file = tmp2_input_file
                  elif os.path.isfile(tmp1_input_file):
                     input_file = tmp1_input_file
                  else:
                     print 'error: file path does not exist'
                     continue
                  output_folder = raw_dir + 'imaging/' + 'participants/' + isubj[0] +'/'+'visit'+isubj[1] +'/session'+isubj[2] + interim_path_des + '_' + aggr_sign
                  mc_file = raw_dir + 'imaging/' + 'participants/' + isubj[0] +'/'+'visit'+isubj[1] +'/session'+isubj[2] + interim_path_src + 'rp_I.txt'

                  if aggr_sign == 'nonaggr':
                    Run_ICA_AROMA_nonaggr(input_file, output_folder, mc_file, brain_mask_fname)
                  elif aggr_sign == 'aggr':
                    Run_ICA_AROMA_aggr(input_file, output_folder, mc_file, brain_mask_fname)
                  else:
                    print 'error: aggr sign does not match'
                    sys.exit(1)
 #               except:
  #                  pass


if __name__ == '__main__':
  main()
