function[x0,x1,x2,x3,d]=face_coord(root)
iman=strcat(root,'.img');
im4dfp=strcat(root,'.4dfp.img');
impts=strcat(root,'_pts.4dfp.img');

avw=avw_img_read(iman);
I0=avw.img;
avw=avw_img_read(im4dfp);
I1=avw.img;
avw=avw_img_read(impts);
I2=avw.img;
if(size(I0)~=size(I1)) 
    display 'sizes do not match';
end;
Ip0=(I2==1);
Ip1=(I2==2);
Ip2=(I2==3);
Ip3=(I2==4);
x0=getROICenter(Ip0);
x1=getROICenter(Ip1);
x2=getROICenter(Ip2);
x3=getROICenter(Ip3);
%v1=x1-x0; %v1=v1/norm(v1,'fro');
v2=x2-x0; v2=v2/norm(v2,'fro');
%v3=x3-x0; %v3=v3/norm(v3,'fro');
e1=[1 0 0];
e2=[0 1 0];
e3=[0 0 1];
d=[dot(v2,e1) dot(v2,e2) dot(v2,e3)];
[val j]=max(abs(d));
val=d(j);
d=[val j];

function[x]=getROICenter(V)
sz=size(V);
xmin=sz(1);
ymin=sz(2);
zmin=sz(3);
xmax=0;
ymax=0;
zmax=0;
for z=1:sz(3)
    [row,col]=find(V(:,:,z));
    if (any(row))
        xmin=min(xmin,min(row));
        ymin=min(ymin,min(col));
        zmin=min(zmin,z);
        xmax=max(xmax,max(row));
        ymax=max(ymax,max(col));
        zmax=max(zmax,z);
    end;
end;
x=[(xmax+xmin)*.5 (ymax+ymin)*.5 (zmax+zmin)*.5];
