function convert_unwarpmov_params(temp_dir,unwarp_motion_file)
%      daelsaid 04/29/2019: this script takes an afni motion file and converts
%      the rotation parameters from degrees to radians and orders the columns
%      to match spm's order (from z,x,y to x,y,z).
%
%     input
%         temp_dir= working directory of current task being run through the preprocessfmri_distortioncorr.m pipeline
%         unwarp_motion_file =  afni motion file generated via unwarpEPIpipeline.
%              - requires that the first two rows are removed
%     output
%          rp_I.txt file - for easy re-integration to
%          preprocessfmri pipeline (unwarp_motion_file_convert.sh can
%          generate the appropriate output file)
%

rp_outfile='rp_I.txt'; %output filename

unwarped_motion_params=load(unwarp_motion_file,"-ascii") %load the motion file

%convert units from angle to radians
rotation_x=deg2rad(unwarped_motion_params(:,6)); % x-angle
rotation_y=deg2rad(unwarped_motion_params(:,5)); % y-angle
rotation_z=deg2rad(unwarped_motion_params(:,4)); % z-angle

% combine translation param columns with re-ordered rotation columns
orderedparams=[unwarped_motion_params(:,1:3),rotation_x,rotation_y,rotation_z];

%write new params to file, using tabs as the delimiter, and in scientific
%notation with 6 decimal places
dlmwrite(rp_outfile,orderedparams,'delimiter','\t','precision','% .6e')

end
