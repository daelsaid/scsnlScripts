function[R] = SaveRegion(A,B,x1,x2,wid)
[w h]=size(A);
dx=x2(1)-x1(1);
dy=x2(2)-x1(2);
r=sqrt(dx^2+dy^2);
dx=dx/r;
dy=dy/r;
[tl, br, bl0, tl0, tr0, br0]=bounds(x1,x2,wid);
%tl=NormalizePt(tl,[0 0],[wid ht]);
%br=NormalizePt(br,[0 0],[wid ht]);

eq1=line_equation(bl0,tl0);
eq2=line_equation(tl0,tr0);
eq3=line_equation(tr0,br0);
eq4=line_equation(br0,bl0);
R=A;
for x=round(tl(1)):round(br(1))
    for y=round(tl(2)):round(br(2))
        if(is_inside(eq1,eq2,eq3,eq4,[x y])==0)
            continue;
        end;
        xn =round(x_new([x y],x1,dx,dy));
        xn(2)=xn(2)+wid+1;
        xn=NormalizePt(xn,[1 1],[r+1 2*wid+1]);
        R(y,x)=B(xn(2),xn(1));
    end;
end;


%bounding rectangle:


function[res]=is_inside(eq1,eq2,eq3,eq4,x)
if(eval_line_equation(eq1,x)>0) 
    res=0; return;
end;
if(eval_line_equation(eq2,x)>0) 
    res=0; return;
end;
if(eval_line_equation(eq3,x)>0) 
    res=0; return;
end;
if(eval_line_equation(eq4,x)>0) 
    res=0; return;   
end;
res=1;


function [res]=eval_line_equation(eq,x)
res=eq(1)*x(1)+eq(2)*x(2)+eq(3);

function[coefs]=line_equation(x0,x1)
u_x=x1(1)-x0(1);
u_y=x1(2)-x0(2);
coefs=[u_y -u_x -(x0(1)*u_y-x0(2)*u_x)];
coefs=coefs/max(abs(coefs));

function[x]=x_new(x_old,x1,dx,dy)
x=[((x_old(1)-x1(1))*dx+(x_old(2)-x1(2))*dy) (-(x_old(1)-x1(1))*dy+(x_old(2)-x1(2))*dx)];

function [x]=NormalizePt(x_old,tl,br)
x=x_old;
if(x_old(1)<tl(1)) x(1)=tl(1); end;
if(x_old(1)>br(1)) x(1)=br(1); end;
if(x_old(2)<tl(2)) x(2)=tl(2); end;
if(x_old(2)>br(2)) x(2)=br(2); end;
    
function[tl, br, bl0, tl0, tr0, br0]=bounds(x1,x2,wid)
nrm=unit_normal(x2-x1);
bl0=x1+wid*nrm;
tl0=x1-wid*nrm;
tr0=x2-wid*nrm;
br0=x2+wid*nrm;
tl=tl0;
tl(1)=min([bl0(1) tl0(1) tr0(1) br0(1)]);
tl(2)=min([bl0(2) tl0(2) tr0(2) br0(2)]);
br=br0;
br(1)=max([bl0(1) tl0(1) tr0(1) br0(1)]);
br(2)=max([bl0(2) tl0(2) tr0(2) br0(2)]);

function[n]=unit_normal(x)
n=[-x(2) x(1)];
n=n/sqrt(x(1)*x(1)+x(2)*x(2));