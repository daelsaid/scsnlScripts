clear all
close all
clc

addpath(genpath('/home/fmri/fmrihome/SPM/spm8'))
addpath('/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/common_scripts')
addpath('/mnt/musk2/home/sryali/Work/parcellation/BASC-kmeans')
warning('off')

% Rois = {'R-Hippocampus'};
% DataDirs{1} = '/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/Kmeans-HC/Results/'; %Insula
% DataDirs{2} = '/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/Kmeans-HC/Results/'; %AG
% DataDirs{3} = '/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/Kmeans-HC/Results/'; %SMA-pSMA
% DataDirs{4} = '/mnt/musk2/home/sryali/Work/parcellation/Validation_performance_measures/Kmeans-HC/Results/'; %SMA-pSMA-Paracentral
% RoiNames = {'ROI_R_Insula_MNI','ROI_R_PGa_PGp_MNI','R_preSMA_SMA','ROI_R_SMA_preSMA_paracntrl'};

RoiNames = {'AG-SPP'};
DataDirs{1} = '/mnt/mandarin1/TempUsers/sryali/Parcellation/Combined-ROIs/Data/';
result_dir = '/mnt/mandarin1/TempUsers/sryali/Parcellation/Combined-ROIs/Results/';
Kvals = 2:10;
subject_list = {'06-11-12.1', '06-11-17.1', '06-11-17.2', '06-11-20.1', '06-11-28.1',...
    '06-11-29.1', '06-12-12.1', '06-12-14.1', '06-12-18.2', '07-01-08.1', ...
    '07-01-17.1', '07-01-18.1', '07-01-23.1', '07-01-31.2', '07-02-12.1',...
    '07-02-15.2', '07-02-24.1', '07-03-09.1', '07-03-12.1', '07-03-14.1', '07-04-09.2'};

%%%%%%%%%%%%%%%%% Extract Time Series  %%%%%%%%%%%%%%%%%%%%%%%%%
roidir = strcat(DataDirs{1},'ROIs');
TR = 2;
%Extract_VoxelWise_TimeSeries(DataDirs{1},roidir,RoiNames(1),subject_list,TR);
%matlabpool local 8
for roi = 1:length(RoiNames)
    %fprintf('Kmeans Consensus Clustering........\n')
    main_kmeans_BASC(DataDirs{1}, result_dir, RoiNames(1),subject_list);
    fprintf('Computing I for ROI = %s \n',RoiNames{roi})
    compute_indvidual_stability_matrix_I(result_dir, result_dir, RoiNames{roi}, subject_list)
    fprintf('Computing Cluster Labels from I for ROI = %s \n', RoiNames{roi})
    get_labels_I(result_dir,RoiNames(roi),subject_list,Kvals);
end
%matlabpool close

