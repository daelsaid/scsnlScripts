''' specify  pids, sunets and permissions for those sunets and this script will set an acl for each user on all those pid folders'''
import os
from os.path import join as pjoin
from subprocess import call

permissions = {'jkboram':'rwx',
	       'shelbyk':'rwx',
	       'changh':'rwx'}

'''
pids = ['9347','9302','9033','9072','100515','100514','100513','100512','100511','100510','100509','100508','100507','100506',
'100505','100504','100503','100502','100501','100500','9177','9235']
'''

pids = ['9440','9337']

raw_data_folder = '/oak/stanford/groups/menon/rawdata/scsnl'

for pid in pids:
	print(pid)
	if not os.path.exists(pjoin(raw_data_folder,pid)):
		print('does not exist')
		continue
	for sunet in permissions:
		call('setfacl -R -m u:%s:%s %s'%(sunet,permissions[sunet],pjoin(raw_data_folder,pid)),shell=True)


