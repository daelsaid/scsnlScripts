%-classification master script
%-Input is a structure with fields:
%  .ImageFile : .nii files (a cell array)
%  .DataLabel: label for each observation
%  .MaskFile: .nii file (ROI file, Gray, White or Whole brain)
%  .ClassifType: 'naive_bayes', 'linear_svm' (tunable)
%  .SearchLight_On: 1 if searchlight within mask, 0 if using all features in mask

%-Note:
%-If use spatiotemporal featurs, each image file should have a 4th temporal
% dimension
%-******The number of data points in each class should be the same!******
%-******Multi-class classification is only done for hard margin linear SVM

%-Tianwen Chen, SCSNL

function OutputResult = Main_Classification_multiCore_demean_weighted_class(Options)

addpath(genpath('$OAK/projects/changh/toolboxes/libsvm-3.1'));
addpath(genpath('$OAK/projects/changh/toolboxes/CommonlyUsedScripts')); 

VY = Options.ImageFile;
DL = Options.DataLabel;
VM = Options.MaskFile;
FusedLabel = Options.FusedLabel;
LabelWeight = Options.LabelWeight;

DL = DL(:);
ClassifType = Options.ClassifType;
SearchOn = Options.SearchLight_On;
SearchOpt.def = 'sphere';
SearchOpt.spec = Options.SearchRadius;

if SearchOn
  OutputResult = searchlight_classif(VY, VM, DL, SearchOpt, ClassifType, FusedLabel, LabelWeight);
else
  NumDataPT = length(VY);
  VY = char(VY);
  VY = spm_vol(VY);
  NumTimePT = round(length(VY)./NumDataPT);
  
  VM = char(VM);
  VM = spm_vol(VM);
  VM = spm_read_vols(VM);
  VMIdx = VM == 1;
  
  DIM = VY(1).dim;
  YY = spm_read_vols(VY);
  YY = reshape(YY, prod(DIM), length(VY));
  Y = YY(VMIdx, :);
  YDim = size(Y);
  Y = reshape(Y(:), YDim(1)*NumTimePT, NumDataPT);
  Y = Y';
  Y(:, isnan(sum(Y, 1))) = [];
  Y = NormalizeData(Y);
  OutputResult = SubClassif(Y, DL, ClassifType, FusedLabel);
end

end

function MV = searchlight_classif(VY, VM, DataLabel, SearchOpt, ClassifType, FusedLabel, LabelWeight)
NumDataPT = length(VY);
VY = char(VY);
VY = spm_vol(VY);
NumTimePT = round(length(VY)./NumDataPT);

VM = char(VM);
VM = spm_vol(VM);

%-Get space details
%--------------------------------------------------------------------------
N            = length(VY);                     %-number of images
M            = VY(1).mat;                          %-voxels to mm matrix
iM           = inv(M);                             %-mm to voxels matrix
DIM          = VY(1).dim;                          %-image dimensions
NDIM         = prod([DIM N]);                      %-overall dimension
[x,y,z]      = ndgrid(1:DIM(1), 1:DIM(2), 1:DIM(3));
XYZ          = [x(:)';y(:)';z(:)']; clear x y z    %-voxel coordinates {vx}
XYZmm        = M(1:3, :)*[XYZ; ones(1, size(XYZ,2))];%-voxel coordinates {mm}
XYZmm_cpy    = XYZmm;                              %-copy without masking

YY = spm_read_vols(VY);

%-Search volume (from mask)
%--------------------------------------------------------------------------
if ~isempty(VM)
  %   if any(DIM-VM.dim) || any(any(abs(VM.mat-M)>1e-4))
  %     MM   = spm_get_data(VM,VM.mat\[XYZmm;ones(1,size(XYZmm,2))],false);
  %   else
  %     MM   = spm_read_vols(VM);
  %   end
  MM   = spm_read_vols(VM);
  MM       = logical(MM);
  %XYZmm    = XYZmm(:,MM(:));
  XYZ      = XYZ(:, MM(:));
else
  error('MaskFile not found');
end

%-Searchlight options (clique definition)
%--------------------------------------------------------------------------
xY     = SearchOpt;
xY.xyz = [NaN NaN NaN];
xY.rej = {'cluster','mask'};
xY     = spm_ROI(xY);

%-Get local clique and perform searchlight over voxels
%==========================================================================

%-Build local clique
%--------------------------------------------------------------------------
c            = round(DIM(:)/2);
xY.xyz       = M(1:3,:) * [c;1];
[~, clique] = spm_ROI(xY, XYZmm_cpy);
clique       = round(iM(1:3,:) * [clique;ones(1,size(clique,2))]);
clique       = bsxfun(@minus, clique, c);

%SLR  = zeros(size(XYZ, 2), 1);

UniqueLabel = unique(DataLabel);
NumClass = length(UniqueLabel);
    
unique_fused_label = unique(FusedLabel);
num_fused_class = length(unique_fused_label);

%-Searchlight
%--------------------------------------------------------------------------
NumVox = size(XYZ, 2);
NumCPU = 12;

NumVox_CPU = [repmat(1:NumCPU, 1, floor(NumVox/NumCPU)) 1:mod(NumVox, NumCPU)];

SLR = cell(NumCPU, 1);
SLRIndex = cell(NumCPU, 1);
%parpool("local", 12); % Matlab-Sherlock command for multi-threading in matlabbatch jobs
parfor iCPU = 1:NumCPU
  CPUIndex = find(NumVox_CPU == iCPU);
  CPU_SLR = zeros(num_fused_class+1, length(CPUIndex));
  for ii = 1:length(CPUIndex)
    i = CPUIndex(ii);
    %-Local clique (handle image boundaries and mask)
    %----------------------------------------------------------------------
    xyz          = bsxfun(@plus,XYZ(:,i),clique);
    xyz(:,any(bsxfun(@lt,xyz,[1 1 1]') | bsxfun(@gt,xyz,DIM'))) = [];
    idx          = sub2ind(DIM,xyz(1,:),xyz(2,:),xyz(3,:));
    j            = MM(idx);
    idx          = idx(j);
    %xyz          = xyz(:,j);
    idx      = bsxfun(@plus, idx(:), 0:prod(DIM):NDIM-1);
    Y        = YY(idx);
    YDim = size(Y);
    Y = reshape(Y(:), YDim(1)*NumTimePT, NumDataPT);
    Y = Y';
    Y(:, isnan(sum(Y, 1))) = [];   
    %%%%%%%%%%%%%%
    % Demeaned (grand mean) by TC 09/12/14
    for iClass = 1:NumClass
      class_idx = DataLabel == UniqueLabel(iClass);
      Y_class = Y(class_idx, :);
      Y_class = Y_class - mean(Y_class(:));
      Y(class_idx, :) = Y_class;
    end    
    %%%%%%%%%%%%%%
    Y = NormalizeData(Y);
    CPU_SLR(:, ii) = SubClassif(Y, DataLabel, ClassifType, FusedLabel, LabelWeight);
  end
  SLR{iCPU} = CPU_SLR;
  SLRIndex{iCPU} = CPUIndex;
end

TSLR = zeros(num_fused_class+1, NumVox);
for iClass = 1:num_fused_class+1
  for iCPU = 1:NumCPU
    TSLR(iClass, SLRIndex{iCPU}) = SLR{iCPU}(iClass, :);
  end
end
clear SLRIndex SLR;

%-cross validation accuracy
MV = cell(num_fused_class+1, 1);
for iClass = 1:num_fused_class+1
  MV_class = NaN(DIM);
  MV_class(sub2ind(DIM, XYZ(1,:), XYZ(2,:), XYZ(3,:))) = TSLR(iClass, :);
  MV{iClass} = MV_class;
end

end

function CVA = SubClassif(Y, DataLabel, ClassifType, FusedLabel, LabelWeight)

switch lower(ClassifType)
  case 'naive_bayes'
    CVO = cvpartition(DataLabel, 'k', 5);
    CVAcc = zeros(length(DataLabel), 1);
    for iCV = 1:CVO.NumTestSets
      trIdx = CVO.training(iCV);
      teIdx = CVO.test(iCV);
      ytest = classify(Y(teIdx, :), Y(trIdx, :), DataLabel(trIdx), 'diaglinear', 'empirical');
      CVAcc(teIdx) = ytest == DataLabel(teIdx);
    end
    CVA = sum(CVAcc)./length(CVAcc);
    
  case 'linear_svm'
    UniqueLabel = unique(DataLabel);
    NumClass = length(UniqueLabel);
    ClassIndex = cell(NumClass, 1);
    NumObsv = zeros(NumClass, 1);
    for iClass = 1:NumClass
      ClassIndex{iClass} = find(DataLabel == UniqueLabel(iClass));
      NumObsv(iClass) = length(ClassIndex{iClass});
      RPVec = randperm(NumObsv(iClass));
      ClassIndex{iClass} = ClassIndex{iClass}(RPVec);
    end
    
    CVAcc = zeros(length(DataLabel), 1);
    
    NumFold = 5;
    NumDP = NumObsv(1);
    FoldIndex = randsample([repmat(1:NumFold, 1, floor(NumDP/NumFold)) 1:mod(NumDP, NumFold)], NumDP);
    for iCV = 1:NumFold
      iCVIndex = find(FoldIndex == iCV);
      trClassIndex1 = ClassIndex{1};
      trClassIndex1(iCVIndex) = [];
      trClassIndex2 = ClassIndex{2};
      trClassIndex2(iCVIndex) = [];
      trIdx = [trClassIndex1(:); trClassIndex2(:)];
      teIdx = [ClassIndex{1}(iCVIndex); ClassIndex{2}(iCVIndex)];
      SVMModel = parEstLinear(Y(trIdx, :), DataLabel(trIdx), -5, 10, 5);
      ytest = svmpredict(DataLabel(teIdx), Y(teIdx, :), SVMModel);
      CVAcc(teIdx) = ytest == DataLabel(teIdx);
    end
    CVA = sum(CVAcc)./length(CVAcc);
    
  case 'svm_linear_hardmargin'
    UniqueLabel = unique(DataLabel);
    NumClass = length(UniqueLabel);
    ClassIndex = cell(NumClass, 1);
    NumObsv = zeros(NumClass, 1);
    for iClass = 1:NumClass
      ClassIndex{iClass} = find(DataLabel == UniqueLabel(iClass));
      NumObsv(iClass) = length(ClassIndex{iClass});
    end
    
    NumDP = min(NumObsv);
       
    predict_label = zeros(length(DataLabel), 1);
    %-get the overall CVA as well as CVA for each class
    unique_fused_label = unique(FusedLabel);
    num_fused_class = length(unique_fused_label);
    CVA = zeros(num_fused_class+1, 1);
    
    for iCV = 1:NumDP
      iCVIndex = iCV;
      trIdx = [];
      teIdx = [];
      for iClass = 1:NumClass
        trClassIndex = ClassIndex{iClass};
        trClassIndex(iCVIndex) = [];
        trIdx = [trIdx; trClassIndex(:)];
        teIdx = [teIdx; ClassIndex{iClass}(iCVIndex)];
      end
      data_label = FusedLabel(trIdx);
      data = Y(trIdx, :);
      svm_cmd = sprintf('-s 0 -t 0 -c 10^10 -w-1 %d -w1 %d', LabelWeight(1), LabelWeight(2));
      svm_model = svmtrain(data_label, data, svm_cmd);
      ytest = svmpredict(FusedLabel(teIdx), Y(teIdx, :), svm_model);
      predict_label(teIdx) = ytest;
    end
    
    
    %-overall CVA in the last value
    CVA(num_fused_class+1) = mean(predict_label == FusedLabel, 1);
    
    %-CVA for each class
    for iClass = 1:num_fused_class
      class_idx = FusedLabel == unique_fused_label(iClass);
      CVA(iClass) = mean(predict_label(class_idx) == FusedLabel(class_idx));
    end
end

end

function SVMModel = parEstLinear(data, data_label, clo, chi, m)

data_label = data_label(:);
bestcv = 0;
if isempty(m)
  m = length(data_label)-1;
end

for log2c = clo:chi,
  cmd = [' -v ' num2str(m) ' -c ', num2str(2^log2c), ' -q'];
  cv = svmtrain(data_label, data, cmd);
  if (cv >= bestcv),
    bestcv = cv; bestc = 2^log2c;
  end
  
end

SVMModel = svmtrain(data_label, data, ['-c ', num2str(bestc), ' -q']);

end


