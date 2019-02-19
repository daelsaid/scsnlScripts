import os
import sys
import dicom, glob, subprocess
from subprocess import call
import numpy as np
import pandas as pd
import os.path as op
import re
import nibabel as nib

'''
    This script creates new subject directories (if not created already)
    and anonymizes behavioral + functional data
'''

import os
import sys
import glob
import re
from subprocess import call
import numpy as np
import pandas as pd
import nibabel as nib

def main(logfile):
    #functional anonymization
    working_dir = '/mnt/apricot1_share6/data_for_oak'
    data_dir = 'final'

    scanIDs = generate_sids()
    for scanID in scanIDs:
	if int(scanID[:2]) > 20:
		year = '19'+scanID[:2]
	else:
        year = '20'+scanID[:2]
        datadir = '/mnt/musk1/'+year+'/'+scanID+'/'+'fmri/'


        if os.path.isdir(datadir):

            # create new directories for the scan ID
            sub_dirs, path_msg, session, newID, visit = mk_new_subdir(working_dir+'/'+data_dir+'/',scanID)
            fmridir = sub_dirs[1]

            logargs = {}
            logargs['scanID'] = scanID
            logargs['newID'] = str(newID)
            logargs['visit'] = str(visit)
            logargs['session'] = session
            logargs['path'] = path_msg

            runs = os.listdir(datadir)
            runs = [run for run in runs if os.path.isdir(datadir+run)]
            for run in runs:

                # will only work for eprime now, so older files will have to be parsed differently
                logargs['behavioral'] = anonymize_eprime(run,scanID,fmridir)

                #anonymize functional data
                anonymize_functional(run,scanID,fmridir,logfile,logargs)
        else:
            pass


def anonymize_eprime(run,scanID,fmridir):
    '''
        Removes identifying information from an eprime text file

    '''
    year = '20'+scanID[:2]
    datadir = '/mnt/musk1/'+year+'/'+scanID+'/'+'fmri/'
    subdirs = os.listdir(datadir+run)
    if 'behavioral' in subdirs and 'resting' not in run:
        print(datadir+run)
        behavdir = datadir+run+'/'+'behavioral/'
        behavfiles = os.listdir(behavdir)
        if len(behavfiles) == 0:
            return 'Behavioral directory is empty'
        txtfile = ''
        for file in behavfiles:
            if 'edat2' in file:
                txtfile = file.replace('edat2','txt')
            elif 'edat' in file:
                txtfile = file.replace('edat','txt')
        if txtfile != '':
            fulltxtfile = behavdir + txtfile
            if os.path.isfile(fulltxtfile):
                removeFields = ['SessionDate:',
                                'SessionTime:',
                                'SessionStartDateTimeUtc:',
                                'Subject:',
                                'Clock.Information:',
                                'Clock.StartTimeOfDay:',
                                'SessionTimeUtc:']

                with open(fulltxtfile, 'rb') as f:
                    content = f.readlines()

                outLines = []
                for con in content:
                    remove = False
                    tc = repr(con)
                    tc = tc.replace("\\x00","")
                    tc = tc.replace("\\xff","")
                    tc = tc.replace("\\xfe","")
                    tc = tc.replace("\\r","")
                    tc = tc.replace("b'","")
                    tc = tc.replace("'","")
                    tc = tc.replace("\\n","\n")
                    tc = tc.replace("\\t","\t")
                    for rmvF in removeFields:
                        if rmvF in tc:
                            remove = True

                    if not remove:
                        outLines.append(tc)

                anonFile = txtfile.replace(".txt","_anon.txt")
                outBehavDir = fmridir+run+'/'+'behavioral/'
                print(outBehavDir)
                if not os.path.isdir(outBehavDir):
                    os.makedirs(outBehavDir)

                with open(outBehavDir+anonFile,"w") as outf:
                    outf.writelines(outLines)
            
                return 'yes'

            else:
                return 'Error: Unable to find eprime txt file'
        else:
            return 'Error: No eprime file found'
    else:
        if 'resting' in run:
            return 'NA'        
        else:
            return 'Error: Unable to find behavioral directory'



def pconvert(pdir,datadir,run):
    '''
        Converts pfiles to nifti
            This is a port of the lab's matlab function

    '''
    currdir = os.getcwd()
    if os.path.isdir(pdir):
        try:
            os.chdir(pdir)

            call('makenifti E*P*.7 I',shell=True)
            call('mkdir ../unnormalized',shell=True)
            call('mv I* ../unnormalized',shell=True)
            call('mkdir -p ../unnormalized/unused',shell=True)

            # splitting 4-D to 3-Ds
            os.chdir(datadir+run+'/unnormalized')
            call('fslsplit I.nii I_',shell=True)
            call('rm -rf I.nii',shell=True)
		          
            # move first 1/2 frames to unused folder
            call('mv -f I_0000.nii.gz unused',shell=True)
            call('mv -f I_0001.nii.gz unused',shell=True)

		    # merge rest 3-Ds to a 4-D
            call('fslmerge -t I.nii.gz I_*.nii.gz',shell=True)
            call('rm -rf I_*.nii.gz',shell=True)

            os.chdir(currdir)
            print('Conversion successful.')
            return True
        except:
            print('Conversion failed.')
            os.chdir(currdir)
            return False
    else:
        print('Conversion failed.')
        return False


def generate_sids():
    '''
        Generate subject IDs from the pid2scanid list that we can iterate through
    '''
    df = pd.read_csv('/mnt/apricot1_share6/data_for_oak/anonymize/6-30-17/scanid2pid/pid2scanid.csv')
    sessions = ['Session_1','Session_2','Session_3']
    sid_list = []
    for session in sessions:
        nas = pd.isnull(df[session])
        sesslist = list(df[session][nas == False])
        sid_list.append(sesslist)
    sid_list = [i for j in sid_list for i in j]    
    return sid_list


def mk_new_subdir(rawdir,scanid):
	'''
	    Makes a directory with the new data mapping
	'''
	df = pd.read_csv('/mnt/apricot1_share6/data_for_oak/anonymize/6-30-17/scanid2pid/weidong_rawdata.csv')
	for index, row in df.iterrows():
		row['PID'] = str(row['PID'])
		if len(row['PID']) == 1:
			row['PID'] = '000'+row['PID']
		elif len(row['PID']) == 2:
			row['PID'] = '00'+row['PID']
		elif len(row['PID']) == 3:
			row['PID'] = '0'+row['PID']
		if scanid == row['Session_1']:
		    dirs = [rawdir,
					rawdir+str(row['PID']),
					rawdir+str(row['PID'])+'/visit'+str(row['Visit']),
					rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session1/',
                                        rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session1/'+'anatomical/',
                                        rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session1/'+'fmri/',
					                    rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session1/'+'dwi/']
		    for d in dirs:
		        d = os.path.dirname(d)
		        if not os.path.exists(d):
		            os.makedirs(d)
		    return dirs[-3:], 'yes', 'session1', row['PID'], row['Visit']
		elif scanid == row['Session_2']:
		    dirs = [rawdir,
					rawdir+str(row['PID']),
					rawdir+str(row['PID'])+'/visit'+str(row['Visit']),
					rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session2/',
				                        rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session2/'+'anatomical/',
                                        rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session2/'+'fmri/',
                                        rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session2/'+'dwi/']
		    for d in dirs:
		        if not os.path.exists(d):
		            os.makedirs(d)
		    return dirs[-3:], 'yes', 'session2', row['PID'], row['Visit']
		elif scanid == row['Session_3']:
		    dirs = [rawdir,
					rawdir+str(row['PID']),
					rawdir+str(row['PID'])+'/visit'+str(row['Visit']),
					rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session3/',
                                        rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session3/'+'anatomical/',
                                        rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session3/'+'fmri/',
                                        rawdir+str(row['PID'])+'/visit'+str(row['Visit'])+'/session3/'+'dwi/']
		    for d in dirs:
		        d = os.path.dirname(d)
					
		        if not os.path.exists(d):
		            os.makedirs(d)
		    return dirs[-3:], 'yes', 'session3', row['PID'], row['Visit']
		else:
		    if index == 2183:
		        msg = 'Error: '+scanid+' not found!'
		        print(msg)
		        return [], msg, 'none', row['PID'], row['Visit']



def anonymize_functional(run,scanID,fmridir,logfile,logargs):
    '''
        This removes identifying information from functional data

    '''
    logargs['run'] = run
    if int(scanID[:2]) > 20:
        year = '19'+scanID[:2]
    else:
        year = '20'+scanID[:2]
    datadir = '/mnt/musk1/'+year+'/'+scanID+'/'+'fmri/'
    subdirs = os.listdir(datadir+run)
    if 'Pfiles' in subdirs:
        pdir = datadir+run+'/'+'Pfiles'
        niifile = datadir+run+'/'+'unnormalized/I.nii.gz'
        if os.path.isfile(niifile):
            niiexists = True         
        else:
            niiexists = pconvert(pdir,datadir,run)

        if niiexists:
            anonNiiName = fmridir+run+'/'+'unnormalized/I_anon.nii.gz'
            newNiiName = datadir+run+'/'+'unnormalized/I_new.nii.gz'
            try:
                call("source NiftiAnonymizer.sh %s 'no'"%(niifile),shell=True)
            except:
                logargs['func_msg'] = 'Error: Functional anonymization failed'
                writeLog(logfile,logargs)
                return

            if not os.path.isfile(newNiiName):
                logargs['func_msg'] = 'Error: Functional anonymization failed'
                writeLog(logfile,logargs)
                return
                
            if not os.path.isdir(fmridir+run+'/unnormalized'):
                os.makedirs(fmridir+run+'/unnormalized')

            call("mv %s %s"%(newNiiName,anonNiiName),shell=True)

            try:
                # insert TR in header (may fail if >1 E file)
                TR = getTR(pdir)
                funcImg = nib.load(anonNiiName)
                pixdim = funcImg.header['pixdim']
                pixdim[4] = TR
                funcImg.header['pixdim'] = pixdim
                nib.save(funcImg,anonNiiName)
                logargs['func_msg'] = 'yes'
            except:
                logargs['func_msg'] = 'yes, but unable to insert TR in header'
        else:
            logargs['func_msg'] = 'Error: No unnormalized nifti found'
    else:
        logargs['func_msg'] = 'Error: No Pfiles directory found'
    writeLog(logfile,logargs)


def writeLog(logfile,logargs):
    '''
        Write the log on each iteration
    '''
    logfile.write(','.join((logargs['scanID'],
                            logargs['newID'],
                            logargs['visit'],
                            logargs['session'],
                            logargs['run'],
                            logargs['path'],
                            logargs['behavioral'],
                            logargs['func_msg'],'\n')))
    logfile.flush()


def getTR(pfile_dir):
    '''
        Load TR from the efile
    '''
    efile = glob.glob(pfile_dir + '/E*.7')
    assert len(efile)==1, 'multiple E files'
    with open(efile[0],'r') as f:
        line = f.readline()
        while line[:2] != 'TR':
            line = f.readline()
        TR = float(re.findall('[0-9]+', line)[0])
    return TR


if __name__ == '__main__':
    funclogfile = open('func_logs/weidong_func_log.txt','w')
    funclogfile.write(','.join(('old_ID','new_ID','visit','session','run','path_complete','behav_complete','func_complete','\n')))
    main(funclogfile)