'''
This script takes as input the path to a folder full of html reports outputed from mriqc. It pulls all the quantitative data 
from those reports and compiles them into a csv "compiled_mriqc_data.csv" which it places in the same fodler as the report.
To Run:
source activate
python compile_mriqc_outputs.py /full/path/to/folder/containing/htmlfiles
'''

import os
import pandas as pd
from subprocess import call
import sys
import re 
import pdb

def check_file_name(file_name):
	if file_name[0:3] == 'sub' and file_name[-4:] == 'html':
		return True
	return False

def run(reports_path):
	rows_list = []

	fields = ['aor','aqi','dummy_trs','dvars  nstd','dvars  std','dvars  vstd','efc','fber','fd  mean',
	'fd  num','fd  perc','fwhm  avg','fwhm  x','fwhm  y','fwhm  z','gcor','gsr  x','gsr  y','size  t',
	'size  x','size  y','size  z','snr','spacing  tr','spacing  x','spacing  y','spacing  z','summary  bg  k',
	'summary  bg  mad','summary  bg  mean','summary  bg  median','summary  bg  n','summary  bg  p05','summary  bg  p95',
	'summary  bg  stdv','summary  fg  k','summary  fg  mad','summary  fg  mean','summary  fg  median','summary  fg  n',
	'summary  fg  p05','summary  fg  p95','summary  fg  stdv','tsnr']  

	#make dict of html names corresponing to field names
	html_dict = {}
	for field in fields:
		field_split = field.strip().split('  ')
		if len(field_split) == 1:
			html_string = '<tr><td colspan=3>' + field_split[0] + '</td><td>' 
		elif len(field_split) == 2:
			html_string = '<tr><td>'+ field_split[0] + '</td><td colspan=2>' + field_split[1] + '</td><td>'
		else:
			html_string = '<tr><td>' + field_split[0] + '</td><td>' + field_split[1] + '</td><td>' + field_split[2] + '</td><td>'
		html_dict[field] = html_string

	print(html_dict)
	'''
	fields_split = []
	for field in fields:
		field_split = field.strip().split('  ')
		fields_split.append(field_split)
	#print(fields_split)
	'''
	regex1 = re.compile('[0-9]+\.[0-9]+')
	regex2 = re.compile('[0-9]+</td></tr>')

	files = os.listdir(reports_path)
	files = [x for x in files if check_file_name(x)] 

	for file_name in files:
		print('processing '+file_name)
		file = open(os.path.join(reports_path,file_name),'r')
		file_as_list = file.readlines(8500)
		file_as_list = [x.strip() for x in file_as_list]
		output_dict = {'subject':file_name.replace('.html','')}
		for field in fields:
			output_dict[field] = 'NA'
		for line in file_as_list:
			if line[0:4] == '<tr>':
				for field in fields:
					if html_dict[field] in line:
						matches = regex1.findall(line)
						if len(matches) == 1:
							output_dict[field] = matches[0]
							break
						else:
							matches = regex2.findall(line)
							if len(matches) == 1:
								output_dict[field] = matches[0].replace('</td></tr>','')
								break
		for field in output_dict:
			if output_dict[field] == 'NA':
				print(field+' not found')
		rows_list.append(output_dict)
	df = pd.DataFrame(rows_list)
	df = df[['subject']+fields]
	print('writing output csv to %s'%os.path.join(reports_path,'compiled_mriqc_data.csv'))
	df.to_csv(os.path.join(reports_path,'compiled_mriqc_data.csv'))

if __name__ == '__main__':
	reports_path = sys.argv[1]
	run(reports_path)


