'''move Pfiles to Pfiles dir'''

import os
from subprocess import call


fmridir = '/oak/stanford/groups/menon/rawdata/scsnl/0306/visit4/session2/fmri'


rundirs = os.listdir(fmridir)

for run in rundirs:
	runsubdirs = os.listdir(os.path.join(fmridir,run))
	if 'Pfiles' not in runsubdirs:
		os.mkdir(os.path.join(fmridir,run,'Pfiles'))
		call('mv %s/E* %s/Pfiles'%(os.path.join(fmridir,run),os.path.join(fmridir,run)),shell=True)
		call('mv %s/P* %s/Pfiles'%(os.path.join(fmridir,run),os.path.join(fmridir,run)),shell=True)
