% e.g. new axes (in atlas space coords) are:
% X: (175:155, 80, 23)
% Y: (155, 80, -26:72)
% Z: (155, 55:105, 23)
% then X0=175, X1=155, Y0=-26, Y1=72, Z0=55, Z1=105.
% perm = (1 3 2) (i.e. which axes in old coord. system are changing for x,y,z
function [R] = calcROIpts(X0,X1,Y0,Y1,Z0,Z1,perm)
N=20;
O=[X1 (Y0+Y1)/2 (Z0+Z1)/2];
M=zeros(3,3,2);
M(:,:,1)=[X1 O(2) O(3); O(1) Y0 O(3); O(1) O(2) Z0];
M(:,:,2)=[X0 O(2) O(3); O(1) Y1 O(3); O(1) O(2) Z1];

%compute the inverse of perm.
I=eye(3,3);
P=I(perm,:);
ip(perm)=1:3;
MT=M(:,ip,:);
OT=O(ip);
R=zeros(N*3+1,3);
R(1,:)=OT;
x0=MT(1,:,1);x1=MT(1,:,2);
R(2:N+1,:)=printKnots(x1,x0,N);
y0=MT(2,:,1);y1=MT(2,:,2);
R(N+2:2*N+1,:)=printKnots(y0,y1,N);
z0=MT(3,:,1);z1=MT(3,:,2);
R(2*(N+1):3*N+1,:)=printKnots(z0,z1,N);


function [res] = printKnots(x0, x1, N)
d=[x1-x0]/(N-1);
for i=0:N-1
    res(i+1,:)=x0+d*i;
end

%len1=norm(x11-x00,'fro');
