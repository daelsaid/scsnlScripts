function [TabData xSPM] = get_xspm_hc (spm_file, contrast_index, ...
  threshold_info, mask_file, NumMax, DisMax)

%- modified from spm_getSPM.m in spm8 folder

%-Load SPM.mat
load(spm_file);

%-Check whether SPM.mat has been estimated
try
  XYZ  = SPM.xVol.XYZ;
catch
  error('The model has not been estimated');
end

swd = SPM.swd;
%-Design definition structure
xX = SPM.xX;
%-XYZ coordinates
XYZ = SPM.xVol.XYZ;
%-Search Volume {voxels}
S = SPM.xVol.S;
%-Search Volume {resels}
R = SPM.xVol.R;
%-Voxels to mm matrix
M = SPM.xVol.M(1:3,1:3);
%-Voxel dimensions
VOX = sqrt(diag(M'*M))';
if isempty(mask_file)
  %mask_file = fullfile(swd, 'mask.img');
  mask_file = fullfile(swd, 'mask.nii'); %HC modified for SPM12 mask image format
end
%-XYZ coordinates in mm
Msk   = mask_file;
svc_str = mask_file;
D     = spm_vol(Msk);
str   = strrep(spm_str_manip(Msk,'a30'),'\','\\');
str   = strrep(str,'^','\^'); str   = strrep(str,'_','\_');
str   = strrep(str,'{','\{'); str   = strrep(str,'}','\}');
str   = sprintf('image mask: %s',str);
VOXsv = sqrt(sum(D.mat(1:3,1:3).^2));
FWHM  = SPM.xVol.FWHM.*(VOX./VOXsv);
sv    = spm_sample_vol(D, XYZ(1,:), XYZ(2,:), XYZ(3,:),0);
j     = find(sv > 0);
S     = length(j);
R     = spm_resels(FWHM, D, 'I');
XYZ   = XYZ(:, j);


%-Load contrast definitions (if available)
try
  xCon = SPM.xCon;
catch
  error('Contrasts are not defined in SPM.mat');
end

%-Select the contrast of interest
Ic = contrast_index;
xCon = SPM.xCon;
nc = length(Ic);
n = 1;
SPM.xCon = xCon;
IcAdd = [];
titlestr = xCon(Ic).name;

%-No masking with other contrasts
Im = [];
pm = [];
Ex = [];

%-Compute contrast
SPM = spm_contrasts(SPM, unique([Ic, Im, IcAdd]));
xCon = SPM.xCon;
STAT = xCon(Ic(1)).STAT;
VspmSv = cat(1,xCon(Ic).Vspm);

%-Degree of freedom
df = [xCon(Ic(1)).eidf xX.erdf];
str = '';
switch STAT
  case 'T'
    STATstr = sprintf('%c%s_{%.0f}','T',str,df(2));
  case 'F'
    STATstr = sprintf('%c%s_{%.0f,%.0f}','F',str,df(1),df(2));
  case 'P'
    STATstr = sprintf('%s^{%0.2f}','PPM',df(1));
end
fprintf('\t%-32s: %30s','SPM computation','...initialising \n');

%-Compute conjunction as minimum of SPMs
Z = Inf;
for i = Ic
  Z = min(Z,spm_get_data(xCon(i).Vspm,XYZ));
end

%-Copy of Z and XYZ before masking, for later use with FDR
XYZum = XYZ;
Zum   = Z;

%-Begin thresholding
%--------------------------------------------------------------------------
%-Height threshold
u = -Inf;
%-Extent threshold {voxels}
k = 0;

%-Get FDR mode
defaults = spm('GetGlobal','defaults');
% try
%   topoFDR = defaults.stats.topoFDR;
% catch
%   topoFDR = true;
% end
topoFDR = false;

%-Height threshold - classical inference
%--------------------------------------------------------------------------
if STAT ~= 'P'
  
  fprintf('%s%30s',repmat(sprintf('\b'),1,30),'...height threshold')  %-#
  
  %-Get height threshold
  %----------------------------------------------------------------------
  try
    thresDesc = xSPM.thresDesc;
  catch
    if topoFDR
      str = 'FWE|none';
    else
      str = 'FWE|FDR|none';
    end
    thresDesc = threshold_info.method;
  end
  
  u = threshold_info.u;
  
  switch thresDesc
    
    case 'FWE' % Family-wise false positive rate
      thresDesc = ['p<' num2str(u) ' (' thresDesc ')'];
      u = spm_uc(u,df,STAT,R,n,S);
      
      
    case 'FDR' % False discovery rate
      %------------------------------------------------------------------
      if topoFDR,
        fprintf('\n');                                              %-#
        error('Change defaults.stats.topoFDR to use voxel FDR.');
      end
      thresDesc = ['p<' num2str(u) ' (' thresDesc ')'];
      u = spm_uc_FDR(u,df,STAT,n,VspmSv,0);
      
    case 'none'  % No adjustment
      % p for conjunctions is p of the conjunction SPM
      %------------------------------------------------------------------
      if u <= 1
        thresDesc = ['p<' num2str(u) ' (unc.)'];
        u = spm_u(u^(1/n),df,STAT);
      else
        thresDesc = [STAT '=' num2str(u) ];
      end
      
    otherwise
      %------------------------------------------------------------------
      fprintf('\n');                                                  %-#
      error(sprintf('Unknown control method "%s".',thresDesc));
      
  end % switch thresDesc
  
  %-Compute p-values for topological and voxel-wise FDR (all search voxels)
  %----------------------------------------------------------------------
  if ~topoFDR
    %-Voxel-wise FDR
    fprintf('%s%30s',repmat(sprintf('\b'),1,30),'...for voxelFDR')  %-#
    switch STAT
      case 'Z'
        Ps   = (1-spm_Ncdf(Zum)).^n;
      case 'T'
        Ps   = (1 - spm_Tcdf(Zum,df(2))).^n;
      case 'X'
        Ps   = (1-spm_Xcdf(Zum,df(2))).^n;
      case 'F'
        Ps   = (1 - spm_Fcdf(Zum,df)).^n;
    end
    Ps = sort(Ps);
    %uv = spm_uc_FDR(0.05,df,STAT,n,VspmSv,0);
  end
  
  %-Peak FDR
  [up, Pp]     = spm_uc_peakFDR(0.05,df,STAT,R,n,Zum,XYZum,u);
  
  %-Cluster FDR
  if STAT == 'T' && n == 1
    V2R      = 1/prod(SPM.xVol.FWHM(SPM.xVol.DIM>1));
    [uc, Pc, ue] = spm_uc_clusterFDR(0.05,df,STAT,R,n,Zum,XYZum,V2R,u);
  else
    uc       = NaN;
    ue       = NaN;
    Pc       = [];
  end
  
  %-Peak FWE
  uu           = spm_uc(0.05,df,STAT,R,n,S);
  
end

%-Calculate height threshold filtering
%--------------------------------------------------------------------------
Q      = find(Z > u);

%-Apply height threshold
%--------------------------------------------------------------------------
Z      = Z(:,Q);
XYZ    = XYZ(:,Q);
if isempty(Q)
  fprintf('\n');                                                      %-#
  warning(sprintf('No voxels survive height threshold u=%0.2g',u))
end

%-Extent threshold (disallowed for conjunctions)
%--------------------------------------------------------------------------
if ~isempty(XYZ) && nc == 1
  
  fprintf('%s%30s',repmat(sprintf('\b'),1,30),'...extent threshold')  %-#
  
  %-Get extent threshold [default = 0]
  %----------------------------------------------------------------------
  k = threshold_info.k;
  
  %-Calculate extent threshold filtering
  %----------------------------------------------------------------------
  A     = spm_clusters(XYZ);
  Q     = [];
  for i = 1:max(A)
    j = find(A == i);
    if length(j) >= k; Q = [Q j]; end
  end
  
  % ...eliminate voxels
  %----------------------------------------------------------------------
  Z     = Z(:,Q);
  XYZ   = XYZ(:,Q);
  if isempty(Q)
    fprintf('\n');                                                  %-#
    warning(sprintf('No voxels survive extent threshold k=%0.2g',k))
  end
  
else
  
  k = 0;
  
end

%-Done
%--------------------------------------------------------------------------
fprintf('%s%30s\n',repmat(sprintf('\b'),1,30),'...done')
xSPM   = struct( ...
  'swd',      swd,...
  'title',    titlestr,...
  'Z',        Z,...
  'n',        n,...
  'STAT',     STAT,...
  'df',       df,...
  'STATstr',  STATstr,...
  'Ic',       Ic,...
  'Im',       Im,...
  'pm',       pm,...
  'Ex',       Ex,...
  'u',        u,...
  'k',        k,...
  'XYZ',      XYZ,...
  'XYZmm',    SPM.xVol.M(1:3,:)*[XYZ; ones(1,size(XYZ,2))],...
  'S',        S,...
  'R',        R,...
  'FWHM',     SPM.xVol.FWHM,...
  'M',        SPM.xVol.M,...
  'iM',       SPM.xVol.iM,...
  'DIM',      SPM.xVol.DIM,...
  'VOX',      VOX,...
  'Vspm',     VspmSv,...
  'thresDesc',thresDesc);

% RESELS per voxel (density) if it exists
%--------------------------------------------------------------------------
try, xSPM.VRpv = SPM.VRpv; end
try
  xSPM.units = SPM.xVol.units;
catch
  try, xSPM.units = varargin{1}.units; end;
end

% p-values for topological and voxel-wise FDR
%--------------------------------------------------------------------------
try, xSPM.Ps    = Ps;             end  % voxel FDR
try, xSPM.Pp    = Pp;             end  % peak FDR
try, xSPM.Pc    = Pc;             end  % cluster FDR

% 0.05 critical thresholds for FWEp, FDRp, FWEc, FDRc
%--------------------------------------------------------------------------
try, xSPM.uc    = [uu up ue uc];  end

%-List local maximas
hReg = [];
%-Maxima per cluster
Num = NumMax;
%-Distance among maxima (mm)
Dis = DisMax;

str = sprintf('search volume: %s',svc_str);
TabData = get_datalist('List', xSPM, hReg, Num, Dis, str);

end
