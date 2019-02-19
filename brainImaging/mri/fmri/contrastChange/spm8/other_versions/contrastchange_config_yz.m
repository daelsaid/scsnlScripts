% This is the configuration file for individual contrast change 
% More information can be found in the HELP section below
% _________________________________________________________________________
% 2009-2010 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: contrastchange_config.m.template 2010-09-24 $
% -------------------------------------------------------------------------

% /Users/yuanzh/Desktop/Sherlock/ /oak/stanford/groups/menon/

% Please specify participant folder name in full path
paralist.stats_server = '/Users/yuanzh/Desktop/Sherlock/projects/mcsnyder/2018_Short_Intervention/results/taskfmri/participants';

% Please specify project directoyr
paralist.projectdir = '/Users/yuanzh/Desktop/Sherlock/projects/mcsnyder/2018_Short_Intervention/'

% Please specify the subject list file
%paralist.subject_list = '11-05-29.1_3T2';
paralist.subject_list = '/Users/yuanzh/Desktop/Sherlock/projects/mcsnyder/2018_Short_Intervention/data/subjectlist/pilot_test.csv';
%paralist.subject_list = {'11-05-29.1_3T2', '11-06-18.1_3T2','11-07-22.1_3T2','12-03-11.1_3T2','12-04-08.1_3T2','11-07-24.2_3T2','11-07-31.1_3T2','11-08-13.1_3T2','11-08-21.1_3T2','11-10-22.1_3T2','11-11-13.1_3T2','11-12-04.2_3T2','11-07-16.1_3T2','11-07-16.2_3T2','11-07-24.1_3T2','11-10-02.1_3T2','12-03-18.1_3T2','12-03-24.1_3T2','11-10-23.1_3T2','11-11-20.1_3T2','11-12-04.3_3T2','12-02-25.1_3T2'};

% Please specify the contrast definition file
paralist.contrastmat = 'New_contrasts.mat';

% Please specify the stats folder to look for SPM.mat
%paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_R_aHipp';
%paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_L_aHipp';
%paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_R_mHipp';
% paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_L_mHipp';
% paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_R_PHC';
%paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_L_PHC';
% paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_R_FG';
% paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_L_FG';
%paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_R_pITC';
% paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_L_pITC';
% paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_R_LOC';
%paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_L_LOC';
% paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_R_LPC';
% paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_L_LPC';
%paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_R_IFG';
% paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_L_IFG';
% paralist.stats_folder = 'standard_encoding_swaor_112614_gPPI_mask/PPI_ROI_R_IFS';

% paralist.stats_folder = 'test_4cond/PPI_ROI_L_AG';

paralist.spmversion = 'spm8'

paralist.stats_folder = {'volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_L_AG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_AG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_L_mOFG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_L_Lingual_PHG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_Precuneus_PCing','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_L_mHipp','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_mHipp','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_L_aHipp','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_aHipp','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_PHG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_L_IFG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_L_IPS','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_MiddleFrontalG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_SupramarginalG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_L_Cerebellum','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_L_MiddleFrontalG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_Cerebellum','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_MidOccipitalG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_Caudate','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_SuppMotorArea','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_SFG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_IFG','volume_repair_4cond_swgcavr_whiz_4run_6dur_Aug9_gPPI_mask/PPI_ROI_R_IPS'};

% Specify if you want this done in paralell
paralist.parallel = '0'

% Please specify the folder holding batch templates
paralist.template_path    = '/Users/yuanzh/Desktop/Sherlock/deprecatedGems/scsnlscripts_2018_02_20/spm/BatchTemplates';
