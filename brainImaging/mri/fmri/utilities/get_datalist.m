function varargout = get_datalist (varargin)

%-Ouput local maximum information
%-Modified from spm_list.m


% Choose between voxel-wise and topological FDR
%--------------------------------------------------------------------------
defaults = spm('GetGlobal','defaults');
try
  topoFDR = defaults.stats.topoFDR;
catch
  topoFDR = true;
end

%==========================================================================
switch lower(varargin{1}), case 'list'                            %-List
  %==========================================================================
  % FORMAT TabDat = spm_list('list',SPM,hReg)
  
  %-Tolerance for p-value underflow, when computing equivalent Z's
  %----------------------------------------------------------------------
  tol = eps*10;
  
  %-Parse arguments and set maxima number and separation
  %----------------------------------------------------------------------
  if nargin < 2,  error('insufficient arguments'),     end
  if nargin < 3,  hReg = []; else  hReg = varargin{3}; end
  
  %-Extract data from xSPM
  %----------------------------------------------------------------------
  S     = varargin{2}.S;
  VOX   = varargin{2}.VOX;
  DIM   = varargin{2}.DIM;
  n     = varargin{2}.n;
  STAT  = varargin{2}.STAT;
  df    = varargin{2}.df;
  u     = varargin{2}.u;
  M     = varargin{2}.M;
  k     = varargin{2}.k;
  try, QPs = varargin{2}.Ps; end
  try, QPp = varargin{2}.Pp; end
  try, QPc = varargin{2}.Pc; end
  try
    thresDesc = sprintf('{%s}', varargin{2}.thresDesc);
  catch
    thresDesc = '';
  end
  
  if STAT~='P'
    R     = varargin{2}.R;
    FWHM  = varargin{2}.FWHM;
  end
  try
    units = varargin{2}.units;
  catch
    units = {'mm' 'mm' 'mm'};
  end
  units{1}  = [units{1} ' '];
  units{2}  = [units{2} ' '];
  
  DIM       = DIM > 1;              % dimensions
  VOX       = VOX(DIM);             % scaling
  
  if STAT~='P'
    FWHM  = FWHM(DIM);            % Full width at max/2
    FWmm  = FWHM.*VOX;            % FWHM {units}
    v2r   = 1/prod(FWHM);         % voxels to resels
    k     = k*v2r;                % extent threshold in resels
    R(find(~DIM) + 1) = [];       % eliminate null resel counts
    try, QPs = sort(QPs(:)); end  % Needed for voxel FDR
    try, QPp = sort(QPp(:)); end  % Needed for peak FDR
    try, QPc = sort(QPc(:)); end  % Needed for cluster FDR
  end
  
  %-get number and separation for maxima to be reported
  %----------------------------------------------------------------------
  if length(varargin) > 3
    Num    = varargin{4};         % number of maxima per cluster
    Dis    = varargin{5};         % distance among clusters (mm)
  else
    Num    = 3;
    Dis    = 8;
  end
  if length(varargin) > 5
    Title  = varargin{6};
  else
    Title  = 'p-values adjusted for search volume';
  end
  
  %-Table header & footer
  %======================================================================
  
  %-Table axes & Title
  %----------------------------------------------------------------------
  %if SatWindow, ht = 0.85; bot = 0.14; else ht = 0.4; bot = 0.1; end
  
  if STAT == 'P'
    Title = 'Posterior Probabilities';
  end
  
  
  
  %-Headers for text table...
  %-----------------------------------------------------------------------
  TabDat.tit = Title;
  TabDat.hdr = {  'set',      'c';...
    'set',      'p';...
    'cluster',  'p(FWE-cor)';...
    'cluster',  'p(FDR-cor)';...
    'cluster',  'equivk';...
    'cluster',  'p(unc)';...
    'peak',     'p(FWE-cor)';...
    'peak',     'p(FDR-cor)';...
    'peak',      STAT;...
    'peak',     'equivZ';...
    'peak',     'p(unc)';...
    '',         'x,y,z {mm}'}';...
    
  TabDat.fmt = {  '%-0.3f','%g',...                          %-Set
    '%0.3f', '%0.3f','%0.0f', '%0.3f',...                  %-Cluster
    '%0.3f', '%0.3f', '%6.2f', '%5.2f', '%0.3f',...        %-Peak
    '%3.0f %3.0f %3.0f'};                                  %-XYZ
  
  
  %-Table filtering note
  %----------------------------------------------------------------------
  if isinf(Num)
    TabDat.str = sprintf('table shows all local maxima > %.1fmm apart',Dis);
  else
    TabDat.str = sprintf(['table shows %d local maxima ',...
      'more than %.1fmm apart'],Num,Dis);
  end
  
  
  %-Volume, resels and smoothness (if classical inference)
  %----------------------------------------------------------------------
  if STAT ~= 'P'
    %------------------------------------------------------------------
    Pz              = spm_P(1,0,u,df,STAT,1,n,S);
    Pu              = spm_P(1,0,u,df,STAT,R,n,S);
    %Qu              = spm_P_FDR(u,df,STAT,n,QPs);
    [P Pn Em En] = spm_P(1,k,u,df,STAT,R,n,S);
    
    %-Footnote with SPM parameters
    %------------------------------------------------------------------
    TabDat.ftr    = cell(5,2);
    TabDat.ftr{1} = ...
      sprintf('Height threshold: %c = %0.2f, p = %0.3f (%0.3f)',...
      STAT,u,Pz,Pu);
    TabDat.ftr{2} = ...
      sprintf('Extent threshold: k = %0.0f voxels, p = %0.3f (%0.3f)',...
      k/v2r,Pn,P);
    TabDat.ftr{3} = ...
      sprintf('Expected voxels per cluster, <k> = %0.3f',En/v2r);
    TabDat.ftr{4} = ...
      sprintf('Expected number of clusters, <c> = %0.2f',Em*Pn);
    if any(isnan(varargin{2}.uc))
      TabDat.ftr{5} = ...
        sprintf('FWEp: %0.3f, FDRp: %0.3f',varargin{2}.uc(1:2));
    else
      TabDat.ftr{5} = ...
        sprintf('FWEp: %0.3f, FDRp: %0.3f, FWEc: %0.0f, FDRc: %0.0f',...
        varargin{2}.uc);
    end
    TabDat.ftr{6} = ...
      sprintf('Degrees of freedom = [%0.1f, %0.1f]',df);
    TabDat.ftr{7} = ...
      ['FWHM = ' sprintf('%0.1f ', FWmm) units{:} '; ' ...
      sprintf('%0.1f ', FWHM) '{voxels}'];
    TabDat.ftr{8} = ...
      sprintf('Volume: %0.0f = %0.0f voxels = %0.1f resels', ...
      S*prod(VOX),S,R(end));
    TabDat.ftr{9} = ...
      ['Voxel size: ' sprintf('%0.1f ',VOX) units{:} '; ' ...
      sprintf('(resel = %0.2f voxels)',prod(FWHM))];
    
  else
    TabDat.ftr = {};
  end
  
  
  %-Characterize excursion set in terms of maxima
  % (sorted on Z values and grouped by regions)
  %======================================================================
  if isempty(varargin{2}.Z)
    TabDat.dat = cell(0,12);
    varargout  = {TabDat};
    return
  end
  
  % Includes Darren Gitelman's code for working around
  % spm_max for conjunctions with negative thresholds
  %----------------------------------------------------------------------
  minz        = abs(min(min(varargin{2}.Z)));
  zscores     = 1 + minz + varargin{2}.Z;
  [N Z XYZ A] = spm_max(zscores,varargin{2}.XYZ);
  Z           = Z - minz - 1;
  
  %-Convert cluster sizes from voxels to resels
  %----------------------------------------------------------------------
  if STAT~='P'
    if isfield(varargin{2},'VRvp')
      V2R = spm_get_data(varargin{2}.VRvp,XYZ);
    else
      V2R = v2r;
    end
    N       = N.*V2R;
  end
  
  %-Convert maxima locations from voxels to mm
  %----------------------------------------------------------------------
  XYZmm = M(1:3,:)*[XYZ; ones(1,size(XYZ,2))];
  
  
  
  %-Set-level p values {c} - do not display if reporting a single cluster
  %----------------------------------------------------------------------
  c     = max(A);                                    %-Number of clusters
  if STAT ~= 'P'
    Pc    = spm_P(c,k,u,df,STAT,R,n,S);            %-Set-level p-value
  else
    Pc    = [];
  end
  
  TabDat.dat = {Pc,c};            %-Table data
  TabLin     = 1;                 %-Table data line
  
  
  %-Local maxima p-values & statistics
  %----------------------------------------------------------------------
  while numel(find(isfinite(Z)))
    
    %-Find largest remaining local maximum
    %------------------------------------------------------------------
    [U,i]   = max(Z);           % largest maxima
    j       = find(A == A(i));  % maxima in cluster
    
    
    %-Compute cluster {k} and peak-level {u} p values for this cluster
    %------------------------------------------------------------------
    if STAT ~= 'P'
      Nv      = N(i)/v2r;                       % extent {voxels}
      
      Pz      = spm_P(1,0,   U,df,STAT,1,n,S);  % uncorrected p value
      Pu      = spm_P(1,0,   U,df,STAT,R,n,S);  % FWE-corrected {based on Z}
      [Pk Pn] = spm_P(1,N(i),u,df,STAT,R,n,S);  % [un]corrected {based on k}
      if topoFDR
        Qc  = spm_P_clusterFDR(N(i),df,STAT,R,n,u,QPc); % cluster FDR-corrected {based on k}
        Qp  = spm_P_peakFDR(U,df,STAT,R,n,u,QPp); % peak FDR-corrected {based on Z}
        Qu  = [];
      else
        Qu  = spm_P_FDR(   U,df,STAT,n,QPs);  % voxel FDR-corrected {based on Z}
        Qc  = [];
        Qp  = [];
      end
      
      if Pz < tol                               % Equivalent Z-variate
        Ze  = Inf;                            % (underflow => can't compute)
      else
        Ze  = spm_invNcdf(1 - Pz);
      end
    else
      Nv      = N(i);
      
      Pz      = [];
      Pu      = [];
      Qu      = [];
      Pk      = [];
      Pn      = [];
      Qc      = [];
      Qp      = [];
      ws      = warning('off','SPM:outOfRangeNormal');
      Ze      = spm_invNcdf(U);
      warning(ws);
    end
    
    % Specifically changed so it properly finds hMIPax
    %------------------------------------------------------------------
    
    if topoFDR
      [TabDat.dat{TabLin,3:12}] = deal(Pk,Qc,Nv,Pn,Pu,Qp,U,Ze,Pz,XYZmm(:,i));
    else
      [TabDat.dat{TabLin,3:12}] = deal(Pk,Qc,Nv,Pn,Pu,Qu,U,Ze,Pz,XYZmm(:,i));
      
    end
        
    TabLin = TabLin + 1;
    
    %-Print Num secondary maxima (> Dis mm apart)
    %------------------------------------------------------------------
    [l q] = sort(-Z(j));                % sort on Z value
    D     = i;
    for i = 1:length(q)
      d = j(q(i));
      if min(sqrt(sum((XYZmm(:,D)-XYZmm(:,d)*ones(1,size(D,2))).^2)))>Dis;
        
        if length(D) < Num
          % voxel-level p values {Z}
          %------------------------------------------------------
          if STAT ~= 'P'
            Pz    = spm_P(1,0,Z(d),df,STAT,1,n,S);
            Pu    = spm_P(1,0,Z(d),df,STAT,R,n,S);
            if topoFDR
              Qp = spm_P_peakFDR(Z(d),df,STAT,R,n,u,QPp);
              Qu = [];
            else
              Qu = spm_P_FDR(Z(d),df,STAT,n,QPs);
              Qp = [];
            end
            if Pz < tol
              Ze = Inf;
            else
              Ze = spm_invNcdf(1 - Pz);
            end
          else
            Pz    = [];
            Pu    = [];
            Qu    = [];
            Qp    = [];
            ws      = warning('off','SPM:outOfRangeNormal');
            Ze    = spm_invNcdf(Z(d));
            warning(ws);
          end
          D = [D d];
          
          if topoFDR
            [TabDat.dat{TabLin,7:12}] = ...
              deal(Pu,Qp,Z(d),Ze,Pz,XYZmm(:,d));
          else
            [TabDat.dat{TabLin,7:12}] = ...
              deal(Pu,Qu,Z(d),Ze,Pz,XYZmm(:,d));
          end
          TabLin = TabLin+1;
        end
      end
    end
    Z(j) = NaN;     % Set local maxima to NaN
  end             % end region
  
  %-Return TabDat structure & reset pointer
  %----------------------------------------------------------------------
  varargout = {TabDat};
  %==================================================================
  otherwise                                      %-Unknown action string
    %==================================================================
    error('Unknown action string')
  end

end
