# This script computes framewise displacement (FD)
# FD is computed using procedure described by Jenkinson et.al.:
# https://www.ncbi.nlm.nih.gov/pubmed/12377157
# Rationale for using this procedure:
# https://www.biorxiv.org/content/biorxiv/early/2017/06/27/156380.full.pdf
#
# To run fd_jenk_gist.py:
# /oak/stanford/groups/menon/software/miniconda3/bin/python fd_jenk_gist.py
# _________________________________________________________________________
# 2018 Stanford Cognitive and Systems Neuroscience Laboratory
#
# $Id: fd_jenk_gist.py 2018-05-01 $
#
# Created by: kochalka 2017-07-24
# Edited  by: ksupekar 2018-05-01 (made compatible w. sherlock)
# -------------------------------------------------------------------------

# Project dir
projectdir = '/oak/stanford/groups/menon/projects/shelbyka/2017_TD_MD_mathfun/'

# Path to subjectlist file
subjectlist = 'fmrisubjectlist.csv'

# List of sessions you are running for. Do not need to be present for all subjects
sessions = ['comparison_dot']

# Path/name of output csv for list of subjects/session to exclude
output_file = 'fd_jenk_output.csv'

import os, csv
import numpy as np
import nibabel as nib
import os.path as op
import pandas as pd

def load_subjects(filename):
    data = pd.read_csv(filename)
    #data = np.loadtxt(filename, dtype=str)
    #subjects = data
    subjects = data.values
    return subjects


def rigid_mtx(xyz, theta):
    cx, cy, cz = np.cos(theta)
    sx, sy, sz = np.sin(theta)
    Rx = np.array([[1, 0, 0, 0],
                   [0, cx, sx, 0],
                   [0, -sx, cx, 0],
                   [0, 0, 0, 1]])

    Ry = np.array([[cy, 0, sy, 0],
                   [0, 1, 0, 0],
                   [-sy, 0, cy, 0],
                   [0, 0, 0, 1]])

    Rz = np.array([[cz, sz, 0, 0],
                   [-sz, cz, 0, 0],
                   [0, 0, 1, 0],
                   [0, 0, 0, 1]])

    T = np.eye(4)
    T[:3, -1] = xyz
    return T.dot(Rx).dot(Ry).dot(Rz)


def FDjenk(motdata, c, radius=80):
    Tt = np.array([rigid_mtx(x[:3], np.pi * x[3:] / 180.) for x in motdata])
    fd_jenk = np.zeros(motdata.shape[0], )
    for i in range(1, motdata.shape[0]):
        M = Tt[i].dot(np.linalg.inv(Tt[i - 1])) - np.eye(4)
        A = M[0:3, 0:3]
        b = M[0:3, 3]
        bAc = b + A.dot(c)
        fd_jenk[i] = np.sqrt((radius ** 2 / 5.) * np.trace(A.T.dot(A)) + bAc.T.dot(bAc))
    return fd_jenk


def get_com(img_file):
    raw_img = nib.load(img_file)
    affine = raw_img.get_affine()
    center_vox = [(x - 1) // 2 for x in raw_img.shape[:3]]
    center_mm = affine.dot(center_vox + [1])[:3]
    return center_mm

subjects = load_subjects(subjectlist)
tasks = sessions
to_include = {'subject': [], 'visit': [], 'session': [],'task': [], 'fd_jenk': []}
for s in range(len(subjects)):
    for t in range(len(tasks)):
        subject = str(subjects[s,0])
        visit   = str(subjects[s,1])
        session = str(subjects[s,2])
        strvisit = 'visit' + visit
        strsession = 'session' + session
        run_dir = op.join(projectdir, 'data/imaging/participants', subject, strvisit, strsession, 'fmri', tasks[t])
        motdata = np.loadtxt(op.join(run_dir, 'smoothed_spm8', 'rp_I.txt'))
        raw_dir = op.join('/oak/stanford/groups/menon/rawdata/scsnl', subject, strvisit, strsession, 'fmri', tasks[t])
        com = get_com(op.join(raw_dir, 'unnormalized', 'I.nii.gz'))
        fd_jenk = FDjenk(motdata, com)

        to_include['subject'].append(subject)
        to_include['visit'].append(visit)
        to_include['session'].append(session)
        to_include['task'].append(tasks[t])
        to_include['fd_jenk'].append(np.mean(fd_jenk))

print('Done')

with open(output_file, 'w') as outfile:
    writer = csv.writer(outfile)
    writer.writerow(to_include.keys())
    writer.writerows(zip(*to_include.values()))


