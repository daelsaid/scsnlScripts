#This script can be used to compile a csv from flywheel of all scanids within a certain date range
import os
from os.path import join as pjoin
from subprocess import call,Popen,PIPE
from flywheel import Flywheel
import flywheel
import time
import sys
import datetime
from dateutil.tz import tzutc

#####   PARAMETERS (edit this section)   ########
start_date = [2018,2,1]      #year,month,day  to start search
end_date = [2018,10,31]      #year,month,day  to end search


###### DO NOT EDIT below this line ######

start_date_dt = datetime.datetime(start_date[0], start_date[1], start_date[2], 0, 0, 0, 0, tzinfo=tzutc())
end_date_dt = datetime.datetime(end_date[0], end_date[1], end_date[2], 23, 0, 0, 0, tzinfo=tzutc())

start_date_unix = time.mktime(start_date_dt.timetuple())
end_date_unix = time.mktime(end_date_dt.timetuple())


fw = Flywheel('lucascenter.flywheel.io:oglHDMF0DnDeKPmDnl')
me = fw.get_current_user()


#generate dictionary of project ids to study names
projects_full = fw.get_all_projects()
#print(fw_projects_full)
projects_thin = {}
for project in projects_full:
	projects_thin[project['label']] = project['_id']
projects_thin_inverted = dict([[v,k] for k,v in projects_thin.items()])


exams_full = fw.get_all_sessions()

print('scanid,timestamp,project')

for exam in exams_full:
	if exam['timestamp'] != None:
		if start_date_unix < time.mktime(exam['timestamp'].timetuple()) < end_date_unix:
			if exam['subject']['code'][:2] != 'ex':
				print(str(exam['subject']['code'])+','+str(exam['timestamp'].day)+'-'+str(exam['timestamp'].month)+'-'+str(exam['timestamp'].year)+','+str(projects_thin_inverted[exam['project']]))


