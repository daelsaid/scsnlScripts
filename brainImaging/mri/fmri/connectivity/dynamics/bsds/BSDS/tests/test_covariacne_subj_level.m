% this script evaluate the estimated covarince in subject level
% taghia@stanford.edu

clc
close all
clear all
addpath(genpath('/home/taghia/BayesianHiddenFactorAnalysis/VB-HMMFA-NBD'))

nsamps = 300; % model will be trained only on nsmaps
dim= 5;
nStates = 4; % # of states
nSubjs = 2;
% hmm model
ldim =round(dim/2);
pio = rand(nStates,1); pio = pio./sum(pio);
transProb = random('uni',0.5,0.82,nStates,nStates) + (diag(random('uni',1,2,nStates,1)).*eye(nStates));
transProb = (transProb./repmat(sum(transProb ,2),1,nStates))';
for subj= 1:nSubjs
      mus{subj} = randn(nStates,ldim);
      Covs{subj} = zeros(ldim,ldim,nStates);
      for state=1:nStates
            Covs{subj}(:,:,state) = diag(rand(1,ldim));
      end
end
U = zeros(dim,ldim,nStates);
for state=1:nStates
      tempU = randn(dim,ldim);
      U(:,:,state) = tempU - repmat(mean(tempU,2), 1,ldim);
end
[dataS, hiddenSources,trueStates, cov_data] = simdata_hmm2_subj(U,transProb,pio,nSubjs,mus,Covs,nsamps, .01);

for ns = 1:nSubjs
      data{ns} = preprocess(dataS{ns}(:,1:nsamps));
end
rmpath(genpath('/home/taghia/BayesianHiddenFactorAnalysis/VB-HMMFA-NBD'))
addpath(genpath('/home/taghia/BayesianHiddenFactorAnalysis/BSDSS'))
% noninformative initialization
maxIter = 100;
maxStates = 8;
pca_flag = 1;
maxLocalDim =  dim-1;%decideOnLocalComplexityBasedOnEnergy(data);
opt.n_iter = 12;
opt.noise = 0;
opt.n_init_learning = 2;
group_model = BayesianSwitchingDynamicStateSpace(data, maxStates, maxLocalDim, opt);
group_net = group_model.net;
model = compute_subject_level_stats(data, group_net, 30, 0);
estCov = model.estimated_covarinace;
for subj = 1:nSubjs
      figure(subj);
      sid = unique(group_model.estimated_states{subj});
      rc = zeros(1, nStates);
      rid = zeros(1, nStates);
      cid = zeros(1, nStates);
      rcor = zeros(nStates, numel(sid));
      pvals =  zeros(nStates, numel(sid));
      for ref_s = 1:nStates
            for ss = 1:numel(sid)
                  tempcov = cov_data{subj}(:,:,ref_s );
                  tempcov = tempcov - diag(diag(tempcov));
                  tempcov2 = estCov{subj}{ sid(ss)} ;
                  tempcov2 = tempcov2 - diag(diag(tempcov2));
                  [rcor(ref_s,ss),pvals(ref_s,ss)] = corr( tempcov(:), tempcov2(:));
            end
            [num] = max(rcor(ref_s,:));
            [rid(ref_s), cid(ref_s)] = ind2sub(size(rcor),min(find(rcor==num)));
            rc(ref_s ) = rcor(rid(ref_s), cid(ref_s));
            subplot(nStates,2,2*(ref_s-1)+1)
            imagesc(tempcov)
            title(['state', num2str(rid(ref_s))])
            subplot(nStates,2,2*(ref_s))
            tempcov_est = estCov{subj}{ sid(cid(ref_s))};
            tempcov_est = tempcov_est - diag(diag(tempcov_est));
            imagesc(tempcov_est)
            title(['estimated state', num2str(cid(ref_s)), '   correlation: ', num2str(rc(ref_s ))])
      end
      display(['average correlation across all states between estiamted and true covariance for subject', num2str(subj), ': ',num2str(mean(rc))]);

end






