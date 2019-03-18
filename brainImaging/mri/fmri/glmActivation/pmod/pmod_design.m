% This script adds parametric modulation for an existing task design
% _________________________________________________________________________
% 2019 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id:  $ 03-18-19 Carlo de los Angeles

% -------------------------------------------------------------------------

function pmod_design(SubjectI,ConfigFile)

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('Parametric Modulation starts at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');

currentdir = pwd;

% -------------------------------------------------------------------------
% Check existence of the configuration file
% -------------------------------------------------------------------------

ConfigFile = strtrim(ConfigFile);
if ~exist(ConfigFile,'file')
    fprintf('Cannot find the configuration file ... \n');
    diary off;
    return;
end

 [ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
    eval(ConfigFile);
    clear ConfigFile;

spm_version             = strtrim(paralist.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
spmindvstatsscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/glmActivation/individualStats/' spm_version];

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding SPM based individual stats scripts path: %s\n', spmindvstatsscript_path);
addpath(genpath(spmindvstatsscript_path)); 
spmpreprocscript_path   = fullfile('/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/preprocessing/',spm_version);    
sprintf('adding SPM based preprocessing scripts path: %s\n', spmpreprocscript_path);
addpath(genpath(spmpreprocscript_path));    
% -------------------------------------------------------------------------
% Read individual stats parameters
% -------------------------------------------------------------------------
% Ignore white space if there is any
    subject_i          = SubjectI;
    subjectlist        = strtrim(paralist.subjectlist);
    runlist            = strtrim(paralist.runlist);
    project_dir        = strtrim(paralist.projectdir);
    task_dsgn          = strtrim(paralist.task_design);
    pmod_script		   = strtrim(paralist.pmod_script)


    [v,r] = spm('Ver','',1);
    fprintf('>>>-------- This SPM is %s V%s ---------------------\n',v,r);

    disp('-------------- Contents of the Parameter List --------------------');
    disp(paralist);
    disp('------------------------------------------------------------------');
    clear paralist;

% -------------------------------------------------------------------------
% Read in subjects and sessions
% Get the subjects, sesses in cell array format
        subjectlist       = csvread(subjectlist,1);
        subject           = subjectlist(subject_i);
        subject           = char(string(subject));
        subject           = char(pad(string(subject),4,'left','0'));%<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        visit             = num2str(subjectlist(subject_i,2));
        session           = num2str(subjectlist(subject_i,3));

        numsub           = 1;
        runs              = ReadList(runlist);
        numrun            = length(runs);



% -------------------------------------------------------------------------
% Start pmod task design processing
% -------------------------------------------------------------------------
for subcnt = 1:numsub
    
	fprintf('Processing Subject: %s \n',subject);
	disp('--------------------------------------------------------------');

	run_raw_dir = cell(numrun,1);

	for irun = 1:numrun
      
	    %--------  run folder (preprocessed)
	     run_raw_dir{irun} = fullfile(project_dir, '/data/imaging/participants/', subject, ...
	                        ['visit',visit], ['session',session], 'fmri', runs{irun});

	    %-------- Check task_design file 
	    addpath(fullfile(run_raw_dir{irun}, 'task_design'));
	    str = which(task_dsgn);
	    fprintf('>>>> str is %s \n',str);
	    if isempty(str)
	       error('Cannot find task design file in task_design folder.');
	       cd(currentdir);
	       return;
	    end
	                    
		%%%-------------load task design file ---------------

		[filepath,name,ext] = fileparts(task_dsgn);
		fprintf('>>> pwd is %s \n',pwd);
		fprintf('>>>> task_design file is %s %s %s \n',filepath, name, ext);
		if(strcmp(ext,'.mat'))
		    load(str,'-mat');
		    fprintf('<><> \n');
		else
		    error('task design file type should be *.mat');
		end
		    rmpath(fullfile(run_raw_dir{irun}, 'task_design'));

	    %%%-------------add pmods to task design file --------

	    [pmod_filepath,name,ext] = fileparts(pmod_script);
	    addpath(genpath(pmod_filepath));

	    [sess_name names onsets durations pmod rest_exists] = feval(name,sess_name,names,onsets,durations,rest_exists);

	    %%% ------------resave task_design with pmods file --------------------

	    cd(fullfile(run_raw_dir{irun}, 'task_design'))
	    save task_design_pmod.mat sess_name names onsets durations pmod rest_exists;
	end
end
c     = fix(clock);
disp('==================================================================');
fprintf('Parametric Modulation ends at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');