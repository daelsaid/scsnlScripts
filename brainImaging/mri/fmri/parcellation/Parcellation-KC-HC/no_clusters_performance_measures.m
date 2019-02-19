clear all
close all
clc

addpath(genpath('/mnt/musk2/home/sryali/Work/parcellation/SpectralClusteringLib'))
addpath('/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/common_scripts')
addpath(genpath('/home/fmri/fmrihome/SPM/spm8'))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Insula %%%%%%%%%%%%%%
%    data_dir= '/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/Kmeans-HC/Results/';
%    roiname = {'ROI_R_Insula_MNI'};
%    prefix_fname = 'Insula';
%    roidir = '/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/Data/ROIs/';
%    coods_dir = data_dir;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SMA-pSMA %%%%%%%%%%%%%%%%%
%   data_dir = '/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/Kmeans-HC/Results/';
%   roiname = {'R_preSMA_SMA'};
%   prefix_fname = 'SMA-pSMA';
%   roidir = strcat('/mnt/musk2/home/sryali/Work/parcellation/Test_BASC_simFMRI/Data/','ROIs/');
%   coods_dir = '/mnt/musk2/home/sryali/Work/parcellation/Test_BASC_simFMRI/Results/';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Paracentral-SMA-pSMA %%%%%%%%%%%%%%%%%
%    data_dir = '/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/Kmeans-HC/Results/';
%    prefix_fname = 'Paracentrl-SMA-pSMA';
%    roiname  =  {'ROI_R_SMA_preSMA_paracntrl'};
%    roidir = strcat('/mnt/musk2/home/sryali/Work/parcellation/Test_BASC_simFMRI/Data/','ROIs/');
%    coods_dir = '/mnt/musk2/home/sryali/Work/parcellation/Test_BASC_simFMRI/Results/';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% VMA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% data_dir = '/mnt/musk2/home/sryali/Work/parcellation/Test_BASC_simFMRI/Results/';
% roiname = {'L-V1-M1-A1'};
% prefix_fname = 'VMA';
% roidir = strcat('/mnt/musk2/home/sryali/Work/parcellation/Test_BASC_simFMRI/Data/','ROIs/');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% AG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  data_dir =  '/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/Kmeans-HC/Results/';
%  roiname  =  {'ROI_R_PGa_PGp_MNI'};
%  prefix_fname = 'AG';
%  roidir = '/mnt/musk2/home/sryali/Work/parcellation/Parietal/AG/Data/Adults/ROIs/';
%  coods_dir = '/mnt/musk2/home/sryali/Work/parcellation/Parietal/AG/Results/Adults/';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SMA-pSMA-Paracentral-AG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data_dir = '/mnt/mandarin1/TempUsers/sryali/Parcellation/Combined-ROIs/Results/';
roiname = {'AG-SPP'};
prefix_fname = 'AG-SPP';
roidir = data_dir;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
result_dir = '/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/Kmeans-HC/Results/';


Kvals = 2:10;
subject_list = {'06-11-12.1', '06-11-17.1', '06-11-17.2', '06-11-20.1', '06-11-28.1',...
    '06-11-29.1', '06-12-12.1', '06-12-14.1', '06-12-18.2', '07-01-08.1', ...
    '07-01-17.1', '07-01-18.1', '07-01-23.1', '07-01-31.2', '07-02-12.1',...
    '07-02-15.2', '07-02-24.1', '07-03-09.1', '07-03-12.1', '07-03-14.1', '07-04-09.2'};
%%%%%%%%%% VI & NMI  %%%%%%%%%%%
[mean_VI, std_VI, mean_NMI,std_NMI] =  compute_VI(data_dir,roiname,Kvals);
 %%%%%%%% RI & PRI %%%%%%%%%%%%
[mean_RI, mean_PRI] = compute_PRI(data_dir,roiname,Kvals);
% %%%%%%%%% Silhouette %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mean_Silhouette = compute_sigmas(result_dir,roiname,Kvals,subject_list);

fname = strcat(result_dir, 'Performance-Measures-',roiname{1},'.mat');
save(fname, 'mean_VI', 'mean_NMI', 'std_NMI','mean_RI', 'mean_PRI','mean_Silhouette')
%load(fname)

subplot(321)
plot(Kvals,mean_VI,'o-')
ylabel('Mean VI')
subplot(323)
plot(Kvals,mean_NMI,'o-')
ylabel('Mean NMI')
xlabel('Cluster Number')
subplot(324)
plot(Kvals,std_NMI,'o-')
ylabel('Standard Deviation NMI')
xlabel('Cluster Number')
subplot(325)
plot(Kvals,mean_RI,'o-')
ylabel('Mean RI')
xlabel('Cluster Number')
subplot(326)
plot(Kvals,mean_PRI,'o-')
ylabel('Mean PRI')
 subplot(322)
 plot(Kvals,mean_Silhouette,'o-')
 ylabel('Mean Silhouette')

Kopt = input('Kopt = ')
Cluster_G(data_dir,result_dir,roiname, subject_list,Kopt,roidir,prefix_fname,coods_dir);