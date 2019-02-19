function [out_vol] = read_vol(subfolder,session_root,session_name,suffix)
target=strcat(session_root,'/',subfolder);
if(isdir(target)==0)
    out_vol=0;
    return;
end;
cur_dir=pwd;
cd ([target]);
out_vol=analyze75read(strcat(session_name,suffix));
cd ([cur_dir]);