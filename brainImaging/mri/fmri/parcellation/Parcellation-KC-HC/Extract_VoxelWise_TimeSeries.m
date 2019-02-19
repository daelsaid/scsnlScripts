function Extract_VoxelWise_TimeSeries(resultsloc,roidir,roi,subjects,TR)

warning off MATLAB:FINITE:obsoleteFunction



rmpath(genpath('/home/fmri/fmrihome/SPM/spm5/toolbox/robust_toolbox'));
addpath /home/fmri/fmrihome/SPM/spm5/toolbox/marsbar;
addpath('/mnt/musk2/home/sryali/Work/misc/BandPass');

present_dir = pwd;
projectloc = '/fs/musk1/';

%TR = 2;                 %TR
%nframes = 240;
Fs = 1/TR;              %Sampling Frequency
fl = 0.008;             %Lower cutoff
fh = 0.1;                %Upper cutoff
Fc = 0.5*(fh + fl);     %Center Frequency
No = floor(Fs * 2/Fc); %Filter Order
A = 1;
%B = getFiltCoeffs(zeros(1,nframes),Fs,fl,fh,0,No); %FIR filter Coefficients
for ithsubject = 1:length(subjects)
    ithsubject
    flag = 0;
    year = subjects{ithsubject}(1:2);
    smootheddir = strcat(projectloc,'20', num2str(year), '/', subjects{ithsubject}, '/fmri/resting_state_1/smoothed_spm8/');
    %smootheddir = strcat(projectloc,'20', num2str(year), '/', subjects{ithsubject}, '/fmri/resting_state_1/smoothed_spm8_0mm/');
    
    if exist(strcat(smootheddir,'swarI.nii.gz'),'file')
        %display('swarI.nii.gz')
         unix(sprintf('gunzip -fq %s', strcat(smootheddir,'swarI.nii.gz')));
         smoothedimages = spm_get('Files', smootheddir, 'swarI.nii');
         flag = 1;
    elseif exist(strcat(smootheddir,'swfarI.nii.gz'),'file')
       % display('swfarI.nii.gz')
         unix(sprintf('gunzip -fq %s', strcat(smootheddir,'swfarI.nii.gz')));
         smoothedimages = spm_get('Files', smootheddir, 'swfarI.nii');
         flag = 1;
    elseif exist(strcat(smootheddir,'swarI.nii'),'file')
        %display('swarI.nii.gz')
         smoothedimages = spm_get('Files', smootheddir, 'swarI.nii');
         flag = 1;
    elseif exist(strcat(smootheddir,'swfarI.nii'),'file')
       % display('swfarI.nii')
         smoothedimages = spm_get('Files', smootheddir, 'swfarI.nii');
         flag = 1;
    end
    cd(roidir);
    for jthroi = 1:size(roi,2)
        vol = spm_vol([roi{jthroi} '.nii']);
        roi_obj = maroi_image(struct('vol', vol, 'binarize',1));
        [Y multv vXYZ mat] = getdata(roi_obj, smoothedimages);
        roi_size(jthroi) = size(Y,2);
        Y = detrend(Y);
        Y = Y - repmat(mean(Y),size(Y,1),1);
        nframes = size(Y,1);
        B = getFiltCoeffs(zeros(1,nframes),Fs,fl,fh,0,No); %FIR filter Coefficients
        Y = filtfilt(B,A,Y);              %Filter the data
        outputfile = strcat(resultsloc,'/ROITimeseries/', subjects{ithsubject},'-',roi{jthroi},'_ts.mat');
        save(outputfile,'Y','vXYZ');
        
    end
    if flag
    unix(sprintf('gzip -fq %s', strcat(smootheddir,'swarI.nii')));
    else
        unix(sprintf('gzip -fq %s', strcat(smootheddir,'swfarI.nii')));
    end 
end
cd(present_dir)



