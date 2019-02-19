'''
############################################################
############################################################
############################################################

Initialize a new project directory
 
    - Usage:

        python startproject.py path_to_newproject

        i.e. python startproject.py ~/newproject
        where newproject is the project being created

############################################################
############################################################
############################################################
'''

import os
import sys

def main(**kwargs):
    project_name=kwargs['dir']

    if project_name[len(project_name)-1:len(project_name)] != '/':
        project_name = project_name+'/'

    dirs = [project_name,
            project_name+'scripts',
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
	    project_name+'Jobs'
           ]

    for d in dirs:
        os.mkdir(d)

    os.system('git init %s'%(project_name))

    print('Success! Created project directory %s'%(project_name))

if __name__ == '__main__':
    if len(sys.argv) == 2:
        project_dir = sys.argv[1]
        if not os.path.exists(project_dir):
            main(dir=project_dir)
        else:
            print('Error: project directory %s already exists!'%(project_dir))
    elif len(sys.argv) == 1:
        print('Error: no project directory defined!')
    elif len(sys.argv) > 2:
        print('Error: too many arguments!')


