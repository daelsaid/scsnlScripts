%-Whole brain similarity analysis
%-Tianwen Chen, 2012-03-29
%__________________________________________________________________________
%-2009-2012 Stanford Cognitive and Systems Neuroscience Laboratory

function rsa_wholebrain (ConfigFile)

disp('==================================================================');
disp('rsa_wholebrain.m is running');
fprintf('Current directory is: %s\n', pwd);
fprintf('Config file is: %s\n', ConfigFile);
disp('------------------------------------------------------------------');
disp('Send error messages to tianwenc@stanford.edu');
disp('==================================================================');
fprintf('\n');

ConfigFile = strtrim(ConfigFile);
CurrentDir = pwd;
if ~exist(ConfigFile,'file')
  fprintf('Cannot find the configuration file %s ..\n',ConfigFile);
  error('Cannot find the configuration file');
end
[ConfigFilePath, ConfigFile, ConfigFileExt] = fileparts(ConfigFile);
  eval(ConfigFile);
  clear ConfigFile;

ServerPath   = strtrim(paralist.ServerPath);
SubjectList  = strtrim(paralist.SubjectList);
MapType      = strtrim(paralist.MapType);
MapIndex     = paralist.MapIndex;
MaskFile     = strtrim(paralist.MaskFile);
StatsFolder  = strtrim(paralist.StatsFolder);
OutputDir    = strtrim(paralist.OutputDir);
SearchShape  = strtrim(paralist.SearchShape);
SearchRadius = paralist.SearchRadius;
SPM_Version  = paralist.spmversion;

addpath(genpath(['/oak/stanford/groups/menon/toolboxes/',SPM_Version]));

disp('-------------- Contents of the Parameter List --------------------');
disp(paralist);
disp('------------------------------------------------------------------');
clear paralist;

Subjects = csvread(SubjectList,1);
NumSubj = size(Subjects,1); %length(Subjects); % Yuan edit

NumMap = length(MapIndex);

if NumMap ~= 2
  error('Only 2 MapIndex are allowed');
end

for iSubj = 1:NumSubj
  PID = num2str(Subjects(iSubj,1));
  VISIT = num2str(Subjects(iSubj,2));
  SESSION = num2str(Subjects(iSubj,3));
  DataDir = fullfile(ServerPath,PID,['visit',VISIT], ['session',SESSION], ...
    'glm', 'stats_spm12', StatsFolder);
  
  load(fullfile(DataDir, 'SPM.mat'));
  
  VY = cell(NumMap, 1);
  
  MapName = cell(NumMap, 1);
  
  switch lower(MapType)
    case 'tmap'
      for i = 1:NumMap
        VY{i} = fullfile(DataDir, SPM.xCon(MapIndex(i)).Vspm.fname);
        MapName{i} = SPM.xCon(MapIndex(i)).name;
      end
    case 'conmap'
      for i = 1:NumMap
        VY{i} = fullfile(DataDir, SPM.xCon(MapIndex(i)).Vcon.fname);
        MapName{i} = SPM.xCon(MapIndex(i)).name;
      end
  end
  
  if isempty(MaskFile)
    VM = fullfile(DataDir, SPM.VM.fname);
  else
    VM = MaskFile;
  end
  
  OutputFolder = fullfile(OutputDir, PID,['visit',VISIT], ['session',SESSION],['rsa'],['within_task'],['comp_dot'],[MapName{1}, '_VS_', MapName{2}]);
  if ~exist(OutputFolder, 'dir')
    mkdir(OutputFolder);
  end
  
  OutputFile = fullfile(OutputFolder, 'rsa');
  
  SearchOpt.def = SearchShape;
  SearchOpt.spec = SearchRadius;
  
  scsnl_searchlight(VY, VM, SearchOpt, 'pearson_correlation', OutputFile);
end

disp('-----------------------------------------------------------------');
fprintf('Changing back to the directory: %s \n', CurrentDir);
cd(CurrentDir);
disp('Wholebrain RSA is done.');
clear all;
close all;

end
