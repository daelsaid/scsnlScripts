'''
############################################################
############################################################
############################################################

Initialize a new project directory and github repo on StanfordCosyne page
 
    - Usage:
	1. Go to your projects (oak/stanford/groups/menon/projects/SUNETid)
	2. python ../../startproject.py 
	3. Follow prompts 


############################################################
############################################################
############################################################
'''

import os
import sys
import pdb
import subprocess
from subprocess import call

# Initialize a git repo ONLINE under StanfordCosyne github organization
call(['bash /oak/stanford/groups/menon/projects/mcsnyder/scsnlscripts/spm/Utility/auto_git.sh'],shell=True)

project_name = raw_input("Re-enter project name: ")
if project_name[len(project_name)-1:len(project_name)] != '/':
    project_name = project_name+'/'

dirs = [project_name+'scripts',
	    project_name+'scripts/mriqc',
            project_name+'scripts/restfmri',
            project_name+'scripts/restfmri/seedfc',
            project_name+'scripts/restfmri/networkfc',
            project_name+'scripts/restfmri/dynamicfc',
            project_name+'scripts/restfmri/preprocess',
            project_name+'scripts/restfmri/ica',
            project_name+'scripts/taskfmri',
            project_name+'scripts/taskfmri/preprocess',
            project_name+'scripts/taskfmri/MVPA',
            project_name+'scripts/taskfmri/groupstats',
            project_name+'scripts/taskfmri/individualstats',
	    project_name+'scripts/taskfmri/task_design',
            project_name+'scripts/dmri',
            project_name+'scripts/dmri/hardi',
            project_name+'scripts/dmri/dti',
            project_name+'scripts/smri',
            project_name+'scripts/smri/vbm',
            project_name+'scripts/smri/freesurfer',
            project_name+'results',
            project_name+'results/taskfmri',
            project_name+'results/taskfmri/participants',
            project_name+'results/taskfmri/groupstats',
            project_name+'results/restfmri',
            project_name+'results/restfmri/groupstats',
            project_name+'results/restfmri/participants',
            project_name+'results/dmri',
            project_name+'results/dmri/dti',
            project_name+'results/dmri/hardi',
            project_name+'results/smri',
            project_name+'results/smri/freesurfer',
            project_name+'results/smri/vbm',
            project_name+'data',
            project_name+'data/imaging',
            project_name+'data/imaging/roi',
            project_name+'data/imaging/participants',
            project_name+'data/behavior',
            project_name+'data/subjectlist',
            project_name+'publications',
            project_name+'publications/checklist',
            project_name+'publications/docs',
	    project_name+'Jobs']

for d in dirs:
    os.mkdir(d)

print('Success! Created project directory %s'%(project_name))

os.popen('bash /oak/stanford/groups/menon/projects/mcsnyder/scsnlscripts/spm/Utility/gitpush.sh '+project_name).read()



