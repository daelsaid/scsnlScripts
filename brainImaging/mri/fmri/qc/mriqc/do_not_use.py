'''
This script takes as input the path to a bold_group.html report output from the group-level mriqc analysis. It pulls all the outliers (above the rectangle body) in order 
Each statistic's outliers are put into an ordered csv "compiled_group_[stat]_outliers.csv"

To Run:
source activate
python compile_group_mriqc_outputs.py /full/path/to/folder/containing/htmlfiles
'''

import os
import pandas as pd
from subprocess import call
import sys
import re 
import pdb
from bs4 import BeautifulSoup

def check_file_name(file_name):
	if file_name[5:9] == 'group' and file_name[-4:] == 'html':
		return True
	return False

def run(reports_path):
	html = open(sys.argv[1], "r")		
	soup = BeautifulSoup(html, 'html.parser')
	divlist = list(soup.body.find_all('div'))	
	pdb.set_trace()


if __name__ == '__main__':
	html = open(sys.argv[1], "r")
        soup = BeautifulSoup(html, 'html.parser')
        divlist = list(soup.body.find_all('div'))
        pdb.set_trace()

