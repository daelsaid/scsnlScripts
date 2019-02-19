function [B]=reflect(A,p)
sz=size(A);
B=zeros(sz);
start=[1 1 1];
step=[1 1 1];
endval=[sz(1) sz(2) sz(3)];
start(p)=endval(p);
endval(p)=1;
step(p)=-1;
x0=1;y0=1;z0=1;

for x=start(1):step(1):endval(1)    
    for y=start(2):step(2):endval(2)
        for z=start(3):step(3):endval(3)
            B(x,y,z,:)=A(x0,y0,z0,:);
            z0=z0+1;
        end;
        z0=1;
        y0=y0+1;
    end;
    y0=1;
    x0=x0+1;
end;