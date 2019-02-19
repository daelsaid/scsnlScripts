function Vo = write_thresholded_img (Z, XYZ, DIM, M, descrip, F)

%-Get filename
%-----------------------------------------------------------------------
[pathstr, filestr] = fileparts(deblank(F));
Q = fullfile(pathstr, [filestr, '.nii']);

%-Set up header information
%-----------------------------------------------------------------------
Vo      = struct(...
        'fname',    Q,...
        'dim',      DIM',...
        'dt',       [spm_type('uint8') spm_platform('bigend')],...
        'mat',      M,...
        'descrip',  descrip);

%-Reconstruct (filtered) image from XYZ & Z pointlist
%-----------------------------------------------------------------------
Y      = zeros(DIM(1:3)');
OFF    = XYZ(1,:) + DIM(1)*(XYZ(2,:)-1 + DIM(2)*(XYZ(3,:)-1));
Y(OFF) = Z.*(Z > 0);

%-Write the reconstructed volume
%-----------------------------------------------------------------------
Vo = spm_write_vol(Vo,Y);
spm('alert"',{'Written:',['    ',spm_select('CPath',Q)]}, mfilename,1);

end