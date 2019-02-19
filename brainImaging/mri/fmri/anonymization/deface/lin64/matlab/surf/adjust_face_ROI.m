%x0 =  [2.9115   11.5680 -174.6295];
%x1 = [-4.8215   34.4920   44.6995];

function [nx] = adjust_face_ROI(x0,x1)
N=19;
d=[x1-x0]/N;
len=norm(x1-x0,'fro');
%len1=len*1.2;
%x00=x0-8*d;
%x11=x1;
%d1=[x11-x00]/N;
for i=0:N
    %nx(i+1,:)=x00+d1*i;
    nx(i+1,:)=x0+d*i;
end
%len1=norm(x11-x00,'fro');