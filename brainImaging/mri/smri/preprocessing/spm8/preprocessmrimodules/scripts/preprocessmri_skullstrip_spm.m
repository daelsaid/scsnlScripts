% Preprocess MRI data - skullstrip using spm
%__________________________________________________________________________

function preprocessmri_skullstrip_spm(SegmentationDirectory, SpgrFile, SpgrSPMSkullstripFile)

SegDir = SegmentationDirectory;
unix(sprintf('gunzip -fq %s', fullfile(SegDir, '*.gz')));
[SpgrFilePath SpgrFileName SpgrFileExt] = fileparts(SpgrFile);
if(SpgrFileExt == '.gz')
    SpgrFile = SpgrFileName;
end
C1_V = spm_vol(fullfile(SegDir, ['c1' SpgrFile]));
C1_D = spm_read_vols(C1_V);
C2_V = spm_vol(fullfile(SegDir, ['c2' SpgrFile]));
C2_D = spm_read_vols(C2_V);
C3_V = spm_vol(fullfile(SegDir, ['c3' SpgrFile]));
C3_D = spm_read_vols(C3_V);
C = (C1_D + C2_D + C3_D) ~= 0;

M_V = spm_vol(fullfile(SegDir, ['m' SpgrFile]));
M_D = spm_read_vols(M_V);
M_D = M_D.*C;
M_V.fname = SpgrSPMSkullstripFile;
M_V.descrip = 'SPM8 Skull Stripped';
M_V.private.dat.fname = SpgrSPMSkullstripFile;
M_V.private.descrip = 'SPM8 Skull Stripped';
spm_write_vol(M_V, M_D);

end
