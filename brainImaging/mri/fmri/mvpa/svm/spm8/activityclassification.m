% This script performs individual activityclassification
% It first loads configuration file containing individual stats parameters
%
% This scripts are compatible with both Analyze and NIFTI formats
% To use either format, change the data type in activityclassification_config.m
%
% To run individual fMRI analysis, type at Matlab command line:
% >> activityclassfication('activityclassification_config.m')
%
% _________________________________________________________________________
% 2009-2012 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id:mcsnyder activityclassification.m 2018-06-04
% Hyesang Chang 2017-10-10
% -------------------------------------------------------------------------

function activityclassification(ConfigFile)
	
global currentdir idata_type run_img;
currentdir = pwd;

    warning('off', 'MATLAB:FINITE:obsoleteFunction')
    c     = fix(clock);
    disp('==================================================================');
    fprintf('fMRI ActivityClassification start at %d/%02d/%02d %02d:%02d:%02d \n',c);
    disp('==================================================================');
    disp(['Current directory is: ',currentdir]);
    fprintf('Script: %s\n', which('activityclassification.m'));
    fprintf('Configfile: %s\n', ConfigFile);
    fprintf('\n')
    disp('------------------------------------------------------------------');


% -------------------------------------------------------------------------
% Check existence of the configuration file
% -------------------------------------------------------------------------
    ConfigFile = strtrim(ConfigFile);

      if ~exist(ConfigFile,'file')
          fprintf('Cannot find the configuration file %s ..\n',ConfigFile);
          error('Cannot find the configuration file');
      end
  [ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
    eval(ConfigFile);
    clear ConfigFile;


spm_version             = strtrim(paralist.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
spmindvstatsscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/glmActivation/individualStats/' spm_version];
dirname 		= strtrim(paralist.output_dir);

contrast_1             = strtrim(paralist.contrast_1);
contrast_2             = strtrim(paralist.contrast_2);

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding generic libsvm and commonly used scripts paths');
addpath(genpath('/oak/stanford/groups/menon/projects/changh/2018_miscellaneous/toolboxes/libsvm-3.1'));
addpath(genpath('/oak/stanford/groups/menon/projects/changh/2018_miscellaneous/toolboxes/CommonlyUsedScripts'));
addpath(genpath('/oak/stanford/groups/menon/deprecatedGems/scsnlscripts_2018_02_20/spm_scripts'));

% contrasts (1 and 2)

cont1_img = contrast_1;
cont2_img = contrast_2;

%cont1_img = 'spmT_0001.img'; % trained - rest
%cont2_img = 'spmT_0003.img'; % untrained - rest

DataLabel = [];
FullImgFile = [];
FusedLabel = [];

Stim1Label = 1;
Stim2Label = 2;

Stim1FusedLabel = -1;
Stim2FusedLabel = 1;

% -------------------------------------------------------------------------
% Read activityclassification parameters
% -------------------------------------------------------------------------
% Ignore white space if there is any
    subjectlist        = strtrim(paralist.subjectlist);
    runlist            = strtrim(paralist.runlist);
    project_dir        = strtrim(paralist.projectdir);
    maskfile           = strtrim(paralist.maskfile);

    [v,r] = spm('Ver','',1);
    fprintf('>>>-------- This SPM is %s V%s ---------------------\n',v,r);

    disp('-------------- Contents of the Parameter List --------------------');
    disp(paralist);
    disp('------------------------------------------------------------------');
    clear paralist;


% -------------------------------------------------------------------------
% Read in subjects and sessions
% Get the subjects, sesses in cell array format
        Subjects          = csvread(subjectlist,1);
        Numsubj           = length(Subjects);
        Sessions          = ReadList(runlist);


for iSubj = 1:length(Subjects)	
  PID = num2str(Subjects(iSubj,1));
  VISIT = num2str(Subjects(iSubj,2));
  SESSION = num2str(Subjects(iSubj,3));
  for i = 1:length(Sessions)
    StatsDir = fullfile(project_dir,'results/taskfmri/participants/', PID, ['visit',VISIT], ['session',SESSION],'glm', 'stats_spm8', Sessions{i});
    Stimulus_ImgFile = cell(2, 1);
    Stimulus_ImgFile{1} = fullfile(StatsDir, cont1_img);
    Stimulus_ImgFile{2} = fullfile(StatsDir, cont2_img);
    FullImgFile = [FullImgFile; Stimulus_ImgFile];
    DataLabel = [DataLabel; Stim1Label; Stim2Label];
    FusedLabel = [FusedLabel;Stim1FusedLabel; Stim2FusedLabel];
  end
end

ClassificationInput.DataLabel = DataLabel;
ClassificationInput.MaskFile = maskfile;
%ClassificationInput.MaskFile = '/oak/stanford/groups/menon/projects/mcsnyder/2018_Short_Intervention/activity_classification/fsl41_greymatter_bin.img';
%ClassificationInput.ClassifType = 'svm_gaussian_rbf'; % No longer used for anything
ClassificationInput.ClassifType = 'svm_linear_hardmargin'; % Use for ROI and WB Searchlight

ClassificationInput.SearchLight_On = 1;
ClassificationInput.SearchRadius = 6;

ClassificationInput.ImageFile = FullImgFile;
ClassificationInput.FusedLabel = FusedLabel;
ClassificationInput.LabelWeight = [2 1];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     % Use this for ROI-Based Analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     OutputResult(iComp) = Main_Classification_multiCore(ClassificationInput);
%     StimCompar{iComp} = ['spmT_000', num2str(Stim1), '.img_vs_spmT_000', num2str(Stim2),'.img'];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Use these lines for Whole Brain Analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OutputResult = Main_Classification_multiCore_demean_weighted_class(ClassificationInput);

mkdir(dirname);
newfname = [dirname '/ClassificationInput.mat'];
save(newfname ,'ClassificationInput');

num_class = length(OutputResult);

%for iclass = 1:num_class
  for iclass = 1:num_class-1
  file_name = ['stim', num2str(iclass), '_selective.nii'];
  newfname_ClassOutput = fullfile(dirname, file_name);
  %     writing data
  V = spm_vol(ClassificationInput.MaskFile);
  V.fname = newfname_ClassOutput;					%name of your file (example.nii)
  V.dt = [16 0];
  V.private.dat.dtype = 'FLOAT32-LE';
  spm_write_vol(V,OutputResult{iclass});		%X is your 3D matlab variable of dimensions 91*109*91
  
end

file_name = 'average_classification_accuracy.nii';
newfname_ClassOutput = fullfile(dirname, file_name);
%     writing data

V = spm_vol(ClassificationInput.MaskFile);
V.fname = newfname_ClassOutput;					%name of your file (example.nii)
V.dt = [16 0];
V.private.dat.dtype = 'FLOAT32-LE';
%spm_write_vol(V,OutputResult{num_class+1});		%X is your 3D matlab variable of dimensions 91*109*91

spm_write_vol(V,OutputResult{num_class});
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use This line for ROI Based Analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% dirname = ['/mnt/mabloo1/apricot1_share2/asd_auditory/fMRI_Analysis/Results/Classification/ROI_Based/Left_NAc'];
% newfname_ClassOutput = [dirname '/Left_NAc_ClassificationOutput.mat'];
% save(newfname_ClassOutput ,'OutputResult','StimCompar');







