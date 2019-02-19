clear all; close all; clc;
%warning('off');

addpath(genpath('/oak/stanford/groups/menon/projects/changh/2018_miscellaneous/toolboxes/libsvm-3.1'));
addpath(genpath('/oak/stanford/groups/menon/projects/changh/2018_miscellaneous/toolboxes/CommonlyUsedScripts')); 
addpath(genpath('/oak/stanford/groups/menon/deprecatedGems/scsnlscripts_2018_02_20/spm_scripts')); 
addpath(genpath('/oak/stanford/groups/menon/toolboxes/spm8_R3028')); 

SubjectList = '/oak/stanford/groups/menon/projects/mcsnyder/2018_Short_Intervention/data/subjectlist/pilot_test.csv';  

SessionList = '/oak/stanford/groups/menon/projects/mcsnyder/2018_Short_Intervention/data/subjectlist/sessions.txt';

%--------------------------------------------------------------------------

%mother_img = 'spmT_0001.img'; % This is all 3 mother's voice stim
cont1_img = 'spmT_0001.img'; % trained - rest
cont2_img = 'spmT_0003.img'; % untrained - rest

Subjects = csvread(SubjectList,1);
NumSubj = length(Subjects);
Sessions = ReadList(SessionList);
% Can also be specified as RUNS. These "sessions" are not the subject-specific session name, they are like addition1, addition2 etc

DataLabel = [];
FullImgFile = [];
FusedLabel = [];

Stim1Label = 1;
Stim2Label = 2;

Stim1FusedLabel = -1;
Stim2FusedLabel = 1;

for iSubj = 1:length(Subjects)	
  PID = num2str(Subjects(iSubj,1));
  VISIT = num2str(Subjects(iSubj,2));
  SESSION = num2str(Subjects(iSubj,3));
  for i = 1:length(Sessions)
    StatsDir = fullfile('/oak/stanford/groups/menon/projects/mcsnyder/2018_Short_Intervention/results/taskfmri/participants/', PID, ['visit',VISIT], ['session',SESSION],'glm', 'stats_spm8', Sessions{i});
    Stimulus_ImgFile = cell(2, 1);
    Stimulus_ImgFile{1} = fullfile(StatsDir, cont1_img);
    Stimulus_ImgFile{2} = fullfile(StatsDir, cont2_img);
    FullImgFile = [FullImgFile; Stimulus_ImgFile];
    DataLabel = [DataLabel; Stim1Label; Stim2Label];
    FusedLabel = [FusedLabel;Stim1FusedLabel; Stim2FusedLabel];
  end
end

ClassificationInput.DataLabel = DataLabel;

ClassificationInput.MaskFile = '/oak/stanford/groups/menon/projects/mcsnyder/2018_Short_Intervention/activity_classification/fsl41_greymatter_bin.img';
%ClassificationInput.MaskFile = '/mnt/mabloo1/apricot1_share1/intervention/shortIntervention/0_new/activity_classification/mask_23ROIs.nii';

%ClassificationInput.MaskFile = '/mnt/apricot1_share2/speech-asymmetry/ROIs/Merged_ACx_ROI.nii';
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

dirname = '/oak/stanford/groups/menon/projects/mcsnyder/2018_Short_Intervention/results/taskfmri/activity_classification';

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







