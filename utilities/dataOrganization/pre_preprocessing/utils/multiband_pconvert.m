function MuxEpiRecon20160929(pfile)
% reconstruction code for CNI's mux epi sequence, export the 'nii' files 
% -- input 'PXXXX.7' make sure that the 'PXXXX.7.ref' and 'PXXXX.7.vrgf' files are
% under the same directory as 'PXXXX.7'
% -- output the reconstructed nifti file and 'pinfo.mat' containing the key
% header infromation of the file  

% using Kangrong @CNI's code to reconstruct the .mat file and Sam @RSL's
% code to convert to nifi files  
% jingyuan 04/21/16  


% first add path ... 
%addpath(genpath('/usr/local/bin/SMS/matlabcode'));
addpath(genpath('/home/wdcai/tempdata/scripts/multiband_recon_jyc/mux_epi_recon-master')); 
addpath(genpath('/home/wdcai/tempdata/scripts/multiband_recon_jyc/others')); 

% print out current cpu/memory usage  
% [ppath,pname,pext] = fileparts(pfile);  
% system(['free -m >>',pname,'_CpuMemUse.txt &']);

% wait till there is enough memory for reconstruction   
% FreeMemThres = 5*1024*1024;  % 5G memory  
% FreeBufferMemThres = 10*1024;
% recon_flag = 0;  
% while (recon_flag < 2)
%     MemFree = CheckMem(pname);    
%     while ((MemFree(1) < FreeMemThres) | (MemFree(2) < FreeBufferMemThres))
%         MemFree = CheckMem(pname);  
%         recon_flag = 0;  
%         pause(30);  
%     end  
%     recon_flag = recon_flag + 1;  
% end  

%--------------------------------------------------------------------------
% Do multiband reconstruction using CNI's reconstruction code   

% perform offline recon or RT recon based on file size 
fileinfo = dir(pfile); 
filesize = fileinfo.bytes/(1024^3); 
if (filesize < 0)
    sprintf('file size %.2g G, using offline reconstruction ... ', filesize)
%     V = mux_epi_main(pfile,'tempfile',pfile,[],[],[],0,0,0,0);   
    V = mux_epi_main_offline(pfile, 'tempfile', pfile, [], [], [], 0, 0, 0, 0, 0);
else
    sprintf('file size %.2g G, using real-time reconstruction ... ', filesize) 
    % may take longer time, but can be handled by the cute computer ... 
    V = mux_epi_main_RT(pfile,'tempfile',pfile,[],[],[],0,0,0,0,0,0,0); 
%     system(['./mux_epi_main_RT ',pfile,' ',pname,'_tempfile ',pfile])
%      V = mux_epi_main_RT(pfile);
%     load tempfile
%     V = d;
end

%--------------------------------------------------------------------------
% Write mat file to niftis (from Sam)

h = read_gehdr(pfile);   
h.image.psd_iname = 'epi';  
h = gehdr_tweak(h);
rcnparm.h = h;
rcnparm.dcmhdr = lx2dcm(h); % Even if we don't write DICOM files, this is useful
rcnparm.hinfo = useful_gereconinfo(h); 
rcnparm.output = 'spm';
rcnparm.orient = orient_geimg(h);     % this isn't doing anything  
rcnparm.bypassgrappa = 1;
rcnparm.forcedRfactor = 0; 
rcnparm.sliceorder = 1:size(V,3);
rcnparm.orient.rotate = 1;
rcnparm.orient.flipx = 1;
V = flipdim(V,1);      % should flip x instead of y ... 

% V = V4drot90(V);  % rotate the direction  
% V = permute(V,[2 1 3 4]);  
V = V4drot90(V4dfliplr(V));  % flip left/right dimension  
p = mux_epi_params(pfile); 
V = V(:,:,:,p.num_mux_cycle+1:end);  % remove the calibration scans  

% Write spm for nifti
write_vol_qsm(V(:,:,:,1), rcnparm, 1, 1, 1);

[I hdr] = cbiReadNifti(sprintf('e%05ds%03d-v001.img',rcnparm.hinfo.examno,rcnparm.hinfo.seriesno));
%I.img = V; 
sz = hdr.dim';
hdr.dim = [ 4 sz(2:4) size(V,4) 1 1 1 ]';          
hdr.pixdim(7) = rcnparm.hinfo.te; 
hdr.pixdim(6) = rcnparm.hinfo.tr; 

% cbiWriteNifti(sprintf('e%05ds%03d.nii',rcnparm.hinfo.examno,rcnparm.hinfo.seriesno),V,hdr);
[pathstr, name, ext] = fileparts(pfile);
cbiWriteNifti([name,'_nonr.nii'],V,hdr);  

% Save header infomation to pinfo.mat  
pinfo.examno = rcnparm.hinfo.examno;  
pinfo.seriesno = rcnparm.hinfo.seriesno;  
pinfo.protocol = h.series.prtcl;  
pinfo.sedescrip = h.series.se_desc; 
pinfo.te = h.image.te/1000; % ms  
pinfo.tr = h.image.tr/1000000; % 
pinfo.num_frame_specified = p.nt_to_recon_total;  
pinfo.dimension = [p.nx_pres p.ny_pres p.num_unmuxed_slices p.nt_to_recon];
pinfo.voxres = [p.fov/p.nx_pres p.fov/p.ny_pres p.slthick];  
pinfo.slicegap = p.slspacing;  
pinfo.etl = h.image.effechospace/1000;  
pinfo.rawpfile = h;
save([name,'_info.mat'],'pinfo');

% rotate the file directions  
system(['/home/fmri/fmrihome/fsl5.0.10/bin/fslswapdim ',name,'_nonr.nii y -x z ',name,'.nii']);
system(['gunzip ',name,'.nii.gz'])

% Delete unused spm files
%delete([pname,'_tempfile'])
delete(['tempfile.mat']);
delete(sprintf('e%05ds%03d-v001.img',rcnparm.hinfo.examno,rcnparm.hinfo.seriesno));
delete(sprintf('e%05ds%03d-v001.hdr',rcnparm.hinfo.examno,rcnparm.hinfo.seriesno));
delete(sprintf('e%05ds%03d-v001.mat',rcnparm.hinfo.examno,rcnparm.hinfo.seriesno));  
% delete([pname,'_CpuMemUse.txt'])  
%delete([name,'_nonr.nii'])
% 
% remove the path  
%rmpath(genpath('/usr/local/bin/SMS/matlabcode'));  
rmpath(genpath('/home/wdcai/tempdata/scripts/multiband_recon_jyc/mux_epi_recon-master')); 
rmpath(genpath('/home/wdcai/tempdata/scripts/multiband_recon_jyc/others'));  
  

end

