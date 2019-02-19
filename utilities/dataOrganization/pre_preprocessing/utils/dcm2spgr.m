% This script converts DICOM file to spgr.nii
% It is meant to run as call from the move_data.py script which processes data that has come from the lucas center 
%_________________________________________________________________________
% 2018 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id: dicomtospgr.m 2012-03-07 $
% -------------------------------------------------------------------------

function dicomtospgr(anatomical_path)

warning('off', 'MATLAB:FINITE:obsoleteFunction')
c     = fix(clock);
%fname = sprintf('transfer_logs/dicomtospgr-%d_%02d_%02d-%02d_%02d_%02.0f.log',c);
%diary(fname);
disp('==================================================================');
fprintf('DICOM conversion starts at %d/%02d/%02d %02d:%02d:%02d\n',c);
disp('==================================================================');
disp(['Current directory is: ',pwd]);
disp('------------------------------------------------------------------');


% Remember the current directory
currentdir = pwd;

global opts numdicom;
% Read in parameters
%%server_path   = strtrim(paralist.server_path);
%%subjectlist   = strtrim(paralist.subjectlist);
numdicom = [124, 128, 132, 166, 248, 280, 292, 332];

opts = 'all';
%%parent_folder = '';

spm('defaults', 'fmri');


cd(anatomical_path)

dirlist = dir;
numitem = length(dirlist);
numfolder = 0;
foldername = {};
for j = 1:numitem
  if (~dirlist(j).isdir)||strcmp(dirlist(j).name, '.')|| ...
      strcmp(dirlist(j).name, '..')
    continue;
  else
    numfolder = numfolder + 1;
    foldername{numfolder} = dirlist(j).name;
  end
end
file_match = zeros(numfolder,1);
for j = 1:numfolder
  cd(foldername{j});
  files = spm_select('List', pwd, 'dcm$');
  numfiles = size(files,1);
  cd ..;
  if ismember(numfiles,numdicom)
    file_match(j) = 1;
  end
end

if sum(file_match) == 0
  fprintf(['Warning: %s does not appear to have the specified number' ...
    ' of DICOM files \n'], anatomical_path);
  warning_subj(subcnt) = 1;
  return;
end


dcm_folder = foldername(logical(file_match));
NumDCMFolder = length(dcm_folder);

for i_dcm = 1:NumDCMFolder
cd(dcm_folder{i_dcm});

%--------------------------------------------------------------------------
%-Delete any *.nii files in the correct dicom folder
%NiiFile = dir('*.nii*');
%if ~isempty(NiiFile)
%  NumFile = length(NiiFile);
%  for iFile = 1:NumFile
%    unix(sprintf('/bin/rm -rf %s', NiiFile(iFile).name));
%  end
%end
%--------------------------------------------------------------------------

files = spm_select('List', pwd, '.dcm$');
NumDicom = size(files, 1);
DicomInfo = dicominfo(deblank(files(1,:)));
NumImages = DicomInfo.ImagesInAcquisition;

DicomImgRatio = NumDicom/NumImages;

if DicomImgRatio > 2
  error('incorrect number of acquisitions');
end

stdcm = 1;
TotalDcmImg = 0;
if DicomImgRatio == 2
  for iAcq = 1:2
    DicomInfo = dicominfo(deblank(files(stdcm,:)));
    NumImages = DicomInfo.ImagesInAcquisition;
    
    TotalDcmImg = TotalDcmImg + NumImages;
    
    DicomFiles = files(stdcm:stdcm+NumImages-1, :);
    hdr = spm_dicom_headers(DicomFiles);
    fileout = spm_dicom_convert(hdr, opts,'flat', 'nii');
    if ~isempty(fileout.files)
      disp('DICOM to SPGR conversion is successful!');
      fname = fileout.files{1};
      unix(sprintf('gunzip -fq %s', fname));
      unix(sprintf('/bin/mv %s %s', fname, ['spgr_', num2str(iAcq), '.nii']));
      unix(sprintf('gzip -fq %s', ['spgr_', num2str(iAcq), '.nii']));
      unix(sprintf('/bin/mv %s ..', ['spgr_', num2str(iAcq), '.nii.gz']));
    else
      disp('DICOM fails, no DICOM files selected.')
    end
    stdcm = stdcm + NumImages;
  end
  if TotalDcmImg ~= NumDicom
    error('Unequal dicom files');
  end
end

if DicomImgRatio == 1
  
  hdr = spm_dicom_headers(files);
  fileout = spm_dicom_convert(hdr, opts,'flat', 'nii');
  % If output files list is not empty, it indicates sucessful conversion
  if ~isempty(fileout.files)
    disp('DICOM to SPGR conversion is successful!');
    % Change name of converted (and swapped) T1 image to spgr.nii
    fname = fileout.files{1};
    if NumDCMFolder == 1
      unix(sprintf('gunzip -fq %s', fname));
      unix(sprintf('/bin/mv %s %s', fname, 'spgr.nii'));
      unix(sprintf('gzip -fq %s', 'spgr.nii'));
      unix(sprintf('/bin/mv %s ..', 'spgr.nii.gz'));
      cd ..;
      %unix(sprintf('/usr/local/fsl/bin/fslswapdim %s x -z y spgr', fname));
    else
      %unix(sprintf('/usr/local/fsl/bin/fslswapdim %s x -z y %s', fname, ['spgr_', num2str(i_dcm)]));
      unix(sprintf('gunzip -fq %s', fname));
      unix(sprintf('/bin/mv %s %s', fname, ['spgr_', num2str(i_dcm), '.nii']));
      unix(sprintf('gzip -fq %s', ['spgr_', num2str(i_dcm), '.nii']));
      unix(sprintf('/bin/mv %s ..', ['spgr_', num2str(i_dcm), '.nii.gz']));
      cd ..;
    end
  else
    disp('DICOM fails, no DICOM files selected.')
  end
  
end
end

end
