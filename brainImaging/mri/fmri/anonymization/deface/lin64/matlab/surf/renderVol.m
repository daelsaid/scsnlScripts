%avw=avw_img_read('/data/cninds01/data2/WORK/misha/src/RAW');
%avw=avw_img_read('/data/cninds01/data2/WORK/misha/src/BRAIN001');
avw=avw_img_read('/data/cninds01/data2/WORK/misha/src/clinicmr_msk');
A=avw.img;
%A=blur3(A,2);
[m,n,p]=size(A);
%fv=isosurface(A,X,Y,Z,200.0);
fv=isosurface(A,40.0);
p=patch(fv);
%p=patch(isosurface(A,200.0));
[faces vertex]=reducepatch(p,10000);
isonormals(A,p);
set(p,'FaceColor',[1 0.78 0.60],'EdgeColor','none');
daspect([1 1 1])
view([-1 0.7 0.5]); axis tight
camlight
lighting gouraud