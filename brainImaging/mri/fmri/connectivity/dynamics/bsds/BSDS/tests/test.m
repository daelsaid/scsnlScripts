clear all

addpath(genpath('/home/users/taghia/BSDS/'))
% generate a random data
nsubjs = 3;
dim = 4;
nsamps = 60;
for subj =1 : nsubjs
    data{subj} = randn(dim, nsamps);
end

%c = parcluster('local');
%c.NumWorkers = 12;
%parpool('local', 12);

max_states = 20; %
max_ldim = size(data{1}, 1) - 1;
opt.n_iter = 10;
opt.n_init_iter =2;
opt.tol = 1e-10;
opt.noise = 0;
opt.n_init_learning = 2;
data = data;

group_model = BayesianSwitchingDynamicalSystems(data, max_states, max_ldim, opt);

%save('/home/taghia/BSDS/models/group_model.mat', 'group_model')

subj_model = compute_subject_level_stats(data, group_model, opt.n_iter);
[stats_group, stats_subj] = vector_autoregressive_model(data, group_model, subj_model);


