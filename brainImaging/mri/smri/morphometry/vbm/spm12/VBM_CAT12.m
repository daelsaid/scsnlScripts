% Preprocess MRI data - segment
%__________________________________________________________________________

function VBM_CAT12(CurrentDir, SpgrFile, OutputDir,spm_path)

       tpm_path = strcat(spm_path,'/tpm');
       cat12_path = '/oak/stanford/groups/menon/toolboxes/spm12/toolbox/cat12';
       addpath(genpath(cat12_path));       
       
       % fprintf('++++ here is the fist line\n'); 
         fprintf('input is %s \n\n',SpgrFile);
        matlabbatch{1}.spm.tools.cat.estwrite.data = {SpgrFile};
	matlabbatch{1}.spm.tools.cat.estwrite.nproc = 4;
	matlabbatch{1}.spm.tools.cat.estwrite.opts.tpm = {[tpm_path,'/TPM.nii']};
	matlabbatch{1}.spm.tools.cat.estwrite.opts.affreg = 'mni';
	matlabbatch{1}.spm.tools.cat.estwrite.opts.biasstr = 0.5;
	matlabbatch{1}.spm.tools.cat.estwrite.extopts.APP = 1070;
	matlabbatch{1}.spm.tools.cat.estwrite.extopts.LASstr = 0.5;
	matlabbatch{1}.spm.tools.cat.estwrite.extopts.gcutstr = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.extopts.registration.darteltpm = {[cat12_path,'/templates_1.50mm/Template_1_IXI555_MNI152.nii']};
	matlabbatch{1}.spm.tools.cat.estwrite.extopts.registration.shootingtpm = {[cat12_path,'/templates_1.50mm/Template_0_IXI555_MNI152_GS.nii']};
	matlabbatch{1}.spm.tools.cat.estwrite.extopts.registration.regstr = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.extopts.vox = 1.5;
	matlabbatch{1}.spm.tools.cat.estwrite.extopts.restypes.fixed = [1 0.1];
	matlabbatch{1}.spm.tools.cat.estwrite.output.surface = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.neuromorphometrics = 1;
	matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.lpba40 = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.cobra = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.output.ROImenu.atlases.hammers = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.output.GM.native = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.output.GM.mod = 1;
	matlabbatch{1}.spm.tools.cat.estwrite.output.GM.dartel = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.output.WM.native = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.output.WM.mod = 1;
	matlabbatch{1}.spm.tools.cat.estwrite.output.WM.dartel = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.output.bias.warped = 1;
	matlabbatch{1}.spm.tools.cat.estwrite.output.jacobian.warped = 0;
	matlabbatch{1}.spm.tools.cat.estwrite.output.warps = [0 0];
 
        fprintf('matlab batch is running  \n');

% Update and save batch
[SPGRFileDir SPGRFileName SPGRExt] = fileparts(SpgrFile);
BatchFile = fullfile(OutputDir, [SPGRFileName '_batch_VBM.mat']);
save(BatchFile, 'matlabbatch');

% Run batch of segmentation
cd(OutputDir);
spm_jobman('run', BatchFile);
clear matlabbatch;
cd(CurrentDir);


end
