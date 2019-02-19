% Preprocess MRI data - skullstrip using spm
%__________________________________________________________________________

function preprocessmri_skullstrip_spm(SegmentationDirectory, SpgrFile, SpgrSPMSkullstripFile)

SegDir = SegmentationDirectory;
fprintf('SegDir is : \n %s \n\n',SegDir);
fprintf('Spgrfile is : %s \n',SpgrFile);
% unix(sprintf('gunzip -fq %s', fullfile(SegDir, '*.gz')));
 [filepath SpgrFileName SpgrFileExt] = fileparts(SpgrFile);
 if strcmp(SpgrFileExt,'.gz')
     SpgrFile = SpgrFileName;
   elseif isempty(SpgrFileExt)
     SpgrFile = [SpgrFileName '.nii'];
   else
     SpgrFile = [SpgrFileName SpgrFileExt];
 end
 

fprintf('SpgrFile is : %s \n', SpgrFile);
C1_D = spm_read_vols(spm_vol(fullfile(SegDir, ['c1' SpgrFile])));
C2_D = spm_read_vols(spm_vol(fullfile(SegDir, ['c2' SpgrFile])));
C3_D = spm_read_vols(spm_vol(fullfile(SegDir, ['c3' SpgrFile])));

C = (C1_D + C2_D + C3_D) ~= 0;
%  C_orig =  C1_D + C3_D + C3_D;
%  C = zeros(size(C1_D,1),size(C1_D,2),size(C1_D,3));
%  C(find(C_orig>0.05))=1;
%  C = reshape(C,[size(C1_D,1),size(C1_D,2),size(C1_D,3)]);
 
M_V = spm_vol(fullfile(SegDir,SpgrFile));
M_D = spm_read_vols(M_V);

M_D = M_D.*C;

M_V.fname = SpgrSPMSkullstripFile;
M_V.descrip = 'SPM12_Skull_Stripped';
M_V.private.dat.fname = SpgrSPMSkullstripFile;
M_V.private.descrip = 'SPM12_Skull_Stripped';
spm_write_vol(M_V, M_D);
%unix(sprintf('gzip -fq %s', SpgrSPMSkullstripFile));
end
