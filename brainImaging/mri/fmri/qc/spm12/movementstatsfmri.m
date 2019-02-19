function movementstatsfmri(ConfigFile)


CurrentDir = pwd;

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
disp('==================================================================');
fprintf('fMRI MovementStats start at %d/%02d/%02d %02d:%02d:%02d \n',c);
disp('==================================================================');
disp(['Current directory is: ',CurrentDir]);
fprintf('Script: %s\n', which('movementstatsfmri.m'));
fprintf('Configfile: %s\n', ConfigFile);
fprintf('\n')
disp('------------------------------------------------------------------');

% -------------------------------------------------------------------------
% Check existence of the configuration file
% -------------------------------------------------------------------------
ConfigFile = strtrim(ConfigFile);
if ~exist(ConfigFile, 'file')
    error('cannot find the configuration file')
end
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
eval(ConfigFile);
clear ConfigFile;


spm_version             = strtrim(paralist.spmversion);
software_path           = '/oak/stanford/groups/menon/toolboxes/';
spm_path                = fullfile(software_path, spm_version);
spmqcscript_path   = ['/oak/stanford/groups/menon/scsnlscripts/brainImaging/mri/fmri/qc/' spm_version];

sprintf('adding SPM path: %s\n', spm_path);
addpath(genpath(spm_path));
sprintf('adding SPM based qc scripts path: %s\n', spmqcscript_path);
addpath(genpath(spmqcscript_path));

%-Configurations
spmversion   = strtrim(paralist.spmversion);
subjectlist  = strtrim(paralist.subjectlist);
exp_runlist  = strtrim(paralist.runlist);
raw_dir      = strtrim(paralist.rawdatadir);
project_dir  = strtrim(paralist.projectdir);
prep_folder  = strtrim(paralist.preprocessed_folder);
ScanToScanCrit = paralist.scantoscancrit;

disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

%-Check for spm version mismatch
%--------------------------------------------------------------------------
if ~strcmp(spmversion, spm_version)
    error('spm version mismatch');
end

subjectlist = csvread(subjectlist,1);
NumSubjs = size(subjectlist, 1);
Conditions = ReadList(exp_runlist);
NumConds = length(Conditions);
NumRuns = NumSubjs*NumConds;

RunIndex = zeros(NumRuns, 4);
[C1, C2] = meshgrid(1:NumSubjs, 1:NumConds);
RunIndex(:,1) = C1(:);
RunIndex(:,2) = C2(:);
RunIndex(:,3) = 1:NumRuns;
RunIndex(:,4) = 1;

MvmntDir = cell(NumRuns, 1);
%-overall max range | sum of max range | overall max scan to scan movement |
%-max of sum of scan to scan movement | # scans > 0.5 voxel w.r.t. max overall scan
%-to scan movement
MvmntStats = zeros(NumRuns, 12);

RunCnt = 1;
for isubj = 1:NumSubjs
    subject = subjectlist(isubj, 1);
    subject = char(pad(string(subject),4,'left','0'));
    visit   = num2str(subjectlist(isubj, 2));
    session = num2str(subjectlist(isubj, 3));
    RunCnt
    for iCond = 1:NumConds
        UnnormDir = fullfile(raw_dir, subject, ['visit',visit],['session',session], 'fmri', ...
            Conditions{iCond}, 'unnormalized');
        if ~exist(UnnormDir, 'dir')
            fprintf('Cannot find the unnormalized folder: %s\n', UnnormDir);
            RunIndex(RunCnt, 4) = 0;
            RunCnt = RunCnt + 1;
            continue;
        end
        unix(sprintf('gunzip -fq %s', fullfile(UnnormDir, 'I.nii.gz')));
        ImgFile = fullfile(UnnormDir, 'I.nii');
        if ~exist(ImgFile, 'file')
            fprintf('Cannot find the image file: %s\n', ImgFile);
            RunIndex(RunCnt, 4) = 0;
            RunCnt = RunCnt + 1;
            continue;
        end
        V = spm_vol(ImgFile);
        VoxSize = abs(V(1).mat(1,1));
        fprintf('---> Subject: %s | Visit: %s | Session: %s | Task: %s | VoxelSize: %f\n', ...
            subject, visit, session, Conditions{iCond}, VoxSize);
        unix(sprintf('gzip -fq %s', fullfile(UnnormDir, 'I.nii')));
        
        MvmntDir{RunCnt} = fullfile(project_dir,'/data/imaging/participants', ...
            subject,['visit',visit],['session',session], 'fmri', ...
            Conditions{iCond}, prep_folder);
        
        MvmntFile = fullfile(MvmntDir{RunCnt}, 'rp_I.txt');
        GSFile = fullfile(MvmntDir{RunCnt}, 'VolumRepair_GlobalSignal.txt');
        
        if ~exist(MvmntFile, 'file') || ~exist(GSFile, 'file')
            fprintf('Cannot find movement file or global signal file: %s\n', subject);
            RunIndex(RunCnt, 4) = 0;
            RunCnt = RunCnt + 1;
            continue;
        else
            %-Load rp_I.txt
            rp_I = load(MvmntFile);
            
            %-translation and rotation movement
            TransMvmnt = rp_I(:, 1:3);
            RotMvmnt = 65.*rp_I(:, 4:6);
            TotalMvmnt = [TransMvmnt, RotMvmnt];
            TotalDisp = sqrt(sum(TotalMvmnt.^2, 2));
            
            ScanToScanTrans = abs(diff(TransMvmnt));
            ScanToScanRot = 65.*abs(diff(rp_I(:, 4:6)));
            ScanToScanMvmnt = [ScanToScanTrans, ScanToScanRot];
            
            ScanToScanTotalDisp = sqrt(sum(ScanToScanMvmnt.^2, 2));
            
            
            TransRange = range(rp_I(:, 1:3));
            RotRange = 180/pi*range(rp_I(:, 4:6));
            
            MvmntStats(RunCnt, 1) = TransRange(1);
            MvmntStats(RunCnt, 2) = TransRange(2);
            MvmntStats(RunCnt, 3) = TransRange(3);
            MvmntStats(RunCnt, 4) = RotRange(1);
            MvmntStats(RunCnt, 5) = RotRange(2);
            MvmntStats(RunCnt, 6) = RotRange(3);
            
            MvmntStats(RunCnt, 7) = max(TotalDisp);
            
            MvmntStats(RunCnt, 8) = max(ScanToScanTotalDisp);
            
            MvmntStats(RunCnt, 9) = mean(ScanToScanTotalDisp);
            
            MvmntStats(RunCnt, 10) = sum(ScanToScanTotalDisp > (ScanToScanCrit*VoxSize));
            
            mvnout_idx = (find(ScanToScanTotalDisp > (ScanToScanCrit*VoxSize)))'+1;
            
            g = load(GSFile);
            gsigma = std(g);
            gmean = mean(g);
            mincount = 5*gmean/100;
            %z_thresh = max( z_thresh, mincount/gsigma );
            z_thresh = mincount/gsigma;        % Default value is PercentThresh.
            z_thresh = 0.1*round(z_thresh*10); % Round to nearest 0.1 Z-score value
            zscoreA = (g - mean(g))./std(g);  % in case Matlab zscore is not available
            glout_idx = (find(abs(zscoreA) > z_thresh))';
            
            MvmntStats(RunCnt, 11) = length(glout_idx);
            
            union_idx = unique([1; mvnout_idx(:); glout_idx(:)]);
            MvmntStats(RunCnt, 12) = length(union_idx)/length(g)*100;
            
            CondStatsFile = fullfile(project_dir,'/data/imaging/participants', ...
                subject,['visit',visit],['session',session], 'fmri', ...
                Conditions{iCond}, prep_folder, 'MovementStats.txt');
            
            fid = fopen(CondStatsFile, 'w+');
            fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'TASK', 'PID', 'Session', 'Visit', ...
                'Range x', 'Range y', 'Range z', 'Range pitch', 'Range roll', 'Range yaw', 'Max Displacement', ...
                'Max Scan-to-Scan Displacement', 'Mean Scan-to-Scan Displacement', 'Num Scans > 0.5 Voxel Displacement', ...
                'Num Scans > 5% Global Signal', '% of Volumes Repaired');
            fprintf(fid, '%s\t%s\t%s\t%s\t', Conditions{iCond}, subject, session, visit);
            fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', MvmntStats(RunCnt, 1), ...
                MvmntStats(RunCnt, 2), MvmntStats(RunCnt, 3), ...
                MvmntStats(RunCnt, 4), MvmntStats(RunCnt, 5), ...
                MvmntStats(RunCnt, 6), MvmntStats(RunCnt, 7), ...
                MvmntStats(RunCnt, 8), MvmntStats(RunCnt, 9), ...
                MvmntStats(RunCnt, 10), MvmntStats(RunCnt, 11), ...
                MvmntStats(RunCnt, 12));
            fclose(fid);
            
            RunCnt = RunCnt + 1;
        end
    end
end
    
FullRunIndex = find(RunIndex(:,4) ~= 0);

if ~isempty(FullRunIndex)
    fid = fopen('MovementSummaryStats.txt', 'w+');
    fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'TASK', 'PID', 'Vist', 'Session', ...
        'Range x', 'Range y', 'Range z', 'Range pitch', 'Range roll', 'Range yaw', 'Max Displacement', ...
        'Max Scan-to-Scan Displacement', 'Mean Scan-to-Scan Displacement', 'Num Scans > 0.5 Voxel Displacement', ...
        'Num Scans > 5% Global Signal', '% of Volumes Repaired');
    for i = 1:length(FullRunIndex)
        isubj = RunIndex(FullRunIndex(i),1);
        subject = subjectlist(isubj, 1);
        subject = char(pad(string(subject),4,'left','0'));
        visit   = num2str(subjectlist(isubj, 2));
        session = num2str(subjectlist(isubj, 3));
        fprintf(fid, '%s\t%s\t%s\t%s\t', Conditions{RunIndex(FullRunIndex(i), 2)}, ...
            subject, visit, session);
        fprintf(fid, '%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\n', MvmntStats(RunIndex(FullRunIndex(i), 3), 1), ...
            MvmntStats(RunIndex(FullRunIndex(i), 3), 2), MvmntStats(RunIndex(FullRunIndex(i), 3), 3), ...
            MvmntStats(RunIndex(FullRunIndex(i), 3), 4), MvmntStats(RunIndex(FullRunIndex(i), 3), 5), ...
            MvmntStats(RunIndex(FullRunIndex(i), 3), 6), MvmntStats(RunIndex(FullRunIndex(i), 3), 7), ...
            MvmntStats(RunIndex(FullRunIndex(i), 3), 8), MvmntStats(RunIndex(FullRunIndex(i), 3), 9), ...
            MvmntStats(RunIndex(FullRunIndex(i), 3), 10), MvmntStats(RunIndex(FullRunIndex(i), 3), 11), ...
            MvmntStats(RunIndex(FullRunIndex(i), 3), 12));
    end
    fclose(fid);

    if length(FullRunIndex) < NumRuns
        fid = fopen('MovementMissingInfo.txt', 'w+');
        fprintf(fid, '%s\t%s\t%s\t%s\t%s\n', 'TASK', 'PID', 'Visit', 'Session');
        MissSet = setdiff(1:NumRuns, FullRunIndex);
        for i = 1:length(MissSet)
            isubj = RunIndex(MissSet(i),1);
            subject = subjectlist(isubj, 1);
            subject = char(pad(string(subject),4,'left','0'));
            visit   = num2str(subjectlist(isubj, 2));
            session = num2str(subjectlist(isubj, 3));
            fprintf(fid, '%s\t%s\t%s\t%s\n', Conditions{RunIndex(MissSet(i), 2)}, ...
                subject, visit, session);
        end
        fclose(fid);
    end
else
    disp('None of the runs has rp_I.txt or global signal file');
end

cd(CurrentDir);
disp('------------------------------------------------------------------');
fprintf('Analysis is done!\n');
fprintf('Please check: MovementMissingInfo.txt (if any) for subjects that do not have movement files\n');
fprintf('Please check: MovementSummaryStats.txt for summary stats\n');
disp('------------------------------------------------------------------');


