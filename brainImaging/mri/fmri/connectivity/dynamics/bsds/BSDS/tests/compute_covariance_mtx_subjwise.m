% post-analysis scripts
% compute covariance matrix from each state and run community detection

clear all
clc

addpath(genpath('/Volumes/mnt/mapricot/musk2/home/taghia/BayesianHiddenFactorAnalysis/BSDSS'))

%% Loading data and models
% Data parameters
num_subj = 122;
num_ROI = 11;
phase = 'LR';
session = sprintf('tfMRI_WM_%s', phase);
value = 'eigen1';
detrend_option = 1;
ROI_subgroup = 'B2v0';
subj_subgroup = 'ss1to122';

% Algorithm parameters
coreScriptVersion = 6; %including model initiation selection
maxldim_def = num_ROI-1;
nIter = 100;
tol = 1e-3;
maxStates = 10;
nSubj = num_subj;
approach = 1;

variance_ratio = 1; % variance ratio
dim_option = 3; %{1:'minldim', 2:'maxldim', 3:'fullldim'}

maxldim = maxldim_def;

dataloc = '/Volumes/mnt/mandarin2/Public_Data/HCP2014/Stats/HMM/data/';
data_fname = sprintf('%s%s_regMov_%s_dt%d_%dss_%s_%dROIs_%s.mat',dataloc, session,value,detrend_option,num_subj,ROI_subgroup,num_ROI,subj_subgroup);

load(data_fname);

% FA-VAR
modelloc = '/Volumes/mnt/mandarin2/Public_Data/HCP2014/Stats/HMM/results/VB-FA-VAR/';
model_fname = sprintf('%sFA-VAR-v%d_%s_regMov_%s_dt%d_%dss_%s_%dROIs_maxStats%d_maxldim%d_vr%d_%s_method%d.mat',modelloc,coreScriptVersion,session,value,detrend_option,num_subj,ROI_subgroup,num_ROI,maxStates,maxldim,variance_ratio*10,subj_subgroup,approach);

load(model_fname);
net = net_opt;

%% compute covariance matrix subject-wise

maxIter = 50;
pca_flag = 1;
model_subjwise = compute_subject_level_stats(data, net, maxIter, pca_flag);

output_fname = sprintf('%ssubj_cov_FA-VAR-v%d_%s_regMov_%s_dt%d_%dss_%s_%dROIs_maxStats%d_maxldim%d_vr%d_%s_method%d.mat',modelloc,coreScriptVersion,session,value,detrend_option,num_subj,ROI_subgroup,num_ROI,maxStates,maxldim,variance_ratio*10,subj_subgroup,approach);
save(output_fname, 'model_subjwise');

