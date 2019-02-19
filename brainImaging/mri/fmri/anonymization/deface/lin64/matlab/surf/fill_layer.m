function [Mask] = fill_layer (dims, step, lower_surf,upper_surf,orig_surf)

Mask=zeros(dims);
dx=floor((dims(1)-1)/step);
dy=floor((dims(2)-1)/step);
edge1=ones(1,3);
edge2=dims;

for x=1:dx
    for y=1:dy
        face_b=makeFace(x,y,step,lower_surf);
        face_orig=makeFace(x,y,step,orig_surf);
        face_t=makeFace(x,y,step,upper_surf);        
        prisms=getPrismoids(face_b,face_t,face_orig);
        for i=1:max(size(prisms))
            tetra=prism_partition(prisms(i));            
            for j=1:max(size(tetra))
                t=tetra(j);
                x0=t.origin;
                x1=x0+t.v1;
                x2=x0+t.v2;
                x3=x0+t.v3;
                vert1=max(edge1,min(x0,min(min(x1,x2),x3)));
                vert2=min(edge2,max(x0,max(max(x1,x2),x3)));
                for mx=round(vert1(1)):round(vert2(1))
                    for my=round(vert1(2)):round(vert2(2))
                        for mz=round(vert1(3)):round(vert2(3))                            
                            if(is_inside_tetrahedron([mx my mz],t))
                                Mask(mx,my,mz)=i*10+j*2+0.01;
                            end;
                        end;
                    end;
                end;
            end;
        end;            
        %break;
    end;
    %break;
end;    
return;

function [pr] = makePrismoid(face_b,face_t,ind)
for i=1:3
    bt(i,:)=face_b.vert(ind(i),:);
    tp(i,:)=face_t.vert(ind(i),:);
end;
pr.bt=bt;
pr.tp=tp;
pr.ind=ind;

function [face] = makeFace(x,y,step,surf)
lx=(x-1)*step+1;
rx=lx+step;
ty=(y-1)*step+1;
by=ty+step;

vert(1,:)=surf(1:3,x,y)';
vert(2,:)=surf(1:3,x+1,y)';
vert(3,:)=surf(1:3,x+1,y+1)';
vert(4,:)=surf(1:3,x,y+1)';

face.vert=vert;
deg=ones(4,1);
for(i=1:4) 
   if(vert(i,3)~=1) deg(i)=0;end;
end;
face.deg=deg;
face.ndeg=sum(deg);

function [prisms] = getPrismoids(face_b,face_t,face_orig)
if(face_orig.ndeg>1) prisms=[]; return; end;
deg=face_orig.deg;
if(face_orig.ndeg==1) %one vertex is degenerate, exclude containing prismoid
    if(deg(1)==1) ind=[2,3,4];
    elseif(deg(2)==1) ind=[3,4,1];
    elseif(deg(3)==1) ind=[4,1,2];
    else ind=[1,2,3];
    end;
    prisms(1)=makePrismoid(face_b,face_t,ind);
else %regular case.
    prisms(1)=makePrismoid(face_b,face_t,[1,2,3]);
    prisms(2)=makePrismoid(face_b,face_t,[1,4,3]);
end;

function[tetra]=tetrahedron_partition(ptl_l,pbl_l,ptr_l,pbr_l,ptl_u,pbl_u,ptr_u,pbr_u)
%partition begins
%front prismoid partition begins
%front tetrahedron
tetra(1)=tetrahedron(pbl_l,ptl_l,ptr_l,ptl_u);
%left tetrahedron
tetra(2)=tetrahedron(ptr_u,ptl_u,pbl_u,pbl_l);
%right tetrahedron
tetra(3)=tetrahedron(ptl_u,ptr_u,ptr_l,pbl_l);
%front prismoid partition ends
%rear prisomoid partition begins
%left tetrahedron
tetra(4)=tetrahedron(pbr_l,pbl_l,ptr_l,pbl_u);
%right tetrahedron
tetra(5)=tetrahedron(pbr_l,ptr_l,ptr_u,pbl_u);
%front(back) tetrahedron
tetra(6)=tetrahedron(pbl_u,pbr_u,ptr_u,pbr_l);
%rear prisomid partition ends
%partition ends

function[tetra]=prism_partition(prism)
tetra(1)=tetrahedron(prism.bt(3,:),prism.bt(1,:),prism.bt(2,:),prism.tp(1,:));
tetra(2)=tetrahedron(prism.tp(2,:),prism.tp(1,:),prism.tp(3,:),prism.bt(3,:));
tetra(3)=tetrahedron(prism.tp(1,:),prism.tp(2,:),prism.bt(2,:),prism.bt(3,:));

function[res]=tetrahedron(x1,x2,x3,x4)
coefs=zeros(4,4);
base=plane_eq(x1,x2,x3);
left=plane_eq(x2,x4,x3);
right=plane_eq(x4,x2,x1);
rear=plane_eq(x1,x3,x4);
coefs(:,1)=base;
coefs(:,2)=left;
coefs(:,3)=right;
coefs(:,4)=rear;

%equation sign checks.
%if (ev_plane_eq(x4,base)<0)
if(x4(1)*base(1)+x4(2)*base(2)+x4(3)*base(3)+base(4)<0)    
    coefs(:,1)=-base;
end;
%if (ev_plane_eq(x1,left)<0)
if(x1(1)*left(1)+x1(2)*left(2)+x1(3)*left(3)+left(4)<0)
    coefs(:,2)=-left;
end;
%if (ev_plane_eq(x3,right)<0)
if(x3(1)*right(1)+x3(2)*right(2)+x3(3)*right(3)+right(4)<0)    
    coefs(:,3)=-right;
end;
%if(ev_plane_eq(x2,rear)<0)
if(x2(1)*rear(1)+x2(2)*rear(2)+x2(3)*rear(3)+rear(4)<0)
    coefs(:,4)=-rear;
end;

res.faces=coefs;
res.origin=x2;
v1=x1-x2;v2=x3-x2;v3=x4-x2;
n1=norm(v1);n2=norm(v2);n3=norm(v3);

%if(n1>0)v1=v1/n1;end;
%if(n2>0)v2=v2/n2;end;
% if(n3>0)v3-v3/n3;end;
res.v1=v1;res.v2=v2;res.v3=v3;
res.n1=n1;res.n2=n2;res.n3=n3;

if(n1>0 && n2>0 && n3>0)
    res.deg=0;
else res.deg=1;
end;
%useful, dot parallel products.
dp1=left(1)*v1(1)+left(2)*v1(2)+left(3)*v1(3);
dp2=right(1)*v2(1)+right(2)*v2(2)+right(3)*v2(3);
dp3=base(1)*v3(1)+base(2)*v3(2)+base(3)*v3(3);
res.dp=[dp1,dp2,dp3];
n=zeros(3,3);
n(:,1)=n1;
n(:,2)=n2;
n(:,3)=n3;
res.n=n;
vx=[v1(1),v2(1),v3(1)];
vy=[v1(2),v2(2),v3(2)];
vz=[v1(3),v2(3),v3(3)];
cx=[coefs(1,2),coefs(1,3),coefs(1,1)];
cy=[coefs(2,2),coefs(2,3),coefs(2,1)];
cz=[coefs(3,2),coefs(3,3),coefs(3,1)];
res.vx=vx;res.vy=vy;res.vz=vz;
res.cx=cx;res.cy=cy;res.cz=cz;

A=zeros(3,4,3);
if(dp1==0) dp1=1;end;
if(dp2==0) dp2=1;end;
if(dp3==0) dp3=1;end;
dp=[dp1,dp2,dp3];

A(1,1,:)=((vx.*cx)./dp)';
A(1,2,:)=((vx.*cy)./dp)';
A(1,3,:)=((vx.*cz)./dp)';
A(1,4,:)=((vy.*x2(1).*cy+x2(1).*cz.*vz-vx.*cz.*x2(3)-vx.*x2(2).*cy)./dp)';
A(2,1,:)=((vy.*cx)./dp)';
A(2,2,:)=((vy.*cy)./dp)';
A(2,3,:)=((vy.*cz)./dp)';
A(2,4,:)=((-cx.*vy.*x2(1)+cx.*vx.*x2(2)+cz.*vz.*x2(2)-cz.*vy.*x2(3))./dp)';
A(3,1,:)=((vz.*cx)./dp)';
A(3,2,:)=((vz.*cy)./dp)';
A(3,3,:)=((vz.*cz)./dp)';
A(3,4,:)=((-vz.*cx.*x2(1)-vz.*x2(1).*cy+x2(3).*cx.*vx+vy.*x2(3).*cy)./dp)';
res.A=A;

function[coefs]=plane_eq(x1,x2,x3)
cx=(x1(2)-x2(2))*(x3(3)-x2(3))-(x1(3)-x2(3))*(x3(2)-x2(2));
cy=(x1(3)-x2(3))*(x3(1)-x2(1))-(x1(1)-x2(1))*(x3(3)-x2(3));
cz=(x1(1)-x2(1))*(x3(2)-x2(2))-(x1(2)-x2(2))*(x3(1)-x2(1));
c0=(-x2(2)*x3(1)+x2(1)*x3(2))*x1(3)+(x2(3)*x3(1)-x2(1)*x3(3))*x1(2)+...
    (-x2(3)*x3(2)+x2(2)*x3(3))*x1(1);
coefs=-[cx,cy,cz,c0];
%mx=max(coefs);
%if(mx>0) coefs=coefs/mx; end;

function[res]=is_inside_tetrahedron(x,tetr)
dscr=-1e-10;
if(tetr.deg~=0) res=0; return; end;
res=1;
for i=1:4
%   if(ev_plane_eq(x,tetr.faces(:,i))<dscr)
    if(x(1)*tetr.faces(1,i)+x(2)*tetr.faces(2,i)+x(3)*tetr.faces(3,i)+tetr.faces(4,i)<0)    
        res=0; return;
    end;
end;

function[res]=ev_plane_eq(x,eq)
res=eq(1)*x(1)+eq(2)*x(2)+eq(3)*x(3)+eq(4);
