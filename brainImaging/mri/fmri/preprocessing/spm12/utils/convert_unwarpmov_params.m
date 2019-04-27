function convert_unwarpmov_params(temp_dir,unwarp_motion_file)
rp_outfile='rp_I.txt';
unwarped_motion_params=load(unwarp_motion_file,"-ascii")

rotation_x=degtorad(unwarped_motion_params(:,6));
rotation_y=degtorad(unwarped_motion_params(:,5));
rotation_z=degtorad(unwarped_motion_params(:,4));

orderedparams=[unwarped_motion_params(:,1:3),rotation_x,rotation_y,rotation_z];

dlmwrite(rp_outfile,orderedparams,'delimiter','\t','precision','% .6e')

end
