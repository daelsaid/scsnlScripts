function [ri, pri] = get_pri(P1,P2)

m1 = length(unique(P1)); % # of clusters in Partition 1
m2 = length(unique(P2)); % # of clusters in Partition 2
p11 = (1/m1)*(1/m2); w11 = -log2(p11);
p00 = ((m1-1) * (m2-1))/(m1*m2); w00 = -log2(p00);
p10 = (m2-1)/(m1*m2); w10 = -log2(p10);
p01 = (m1-1)/(m1*m2); w01 = -log2(p01);

n11 = 0; n00 = 0; n10 = 0; n01 = 0;

unique_labels = unique(P1);
connectivity_mtx1 = zeros(length(P1));
for p = 1:length(unique_labels)
    ix = find(P1 == unique_labels(p));
    connectivity_mtx1(ix,ix) = 1;
end
connectivity_mtx1 = connectivity_mtx1 + diag(ones(1,length(P1)).*NaN);
unique_labels = unique(P2);
connectivity_mtx2 = zeros(length(P2));
for p = 1:length(unique_labels)
    ix = find(P2 == unique_labels(p));
    connectivity_mtx2(ix,ix) = 1;
end
connectivity_mtx2 = connectivity_mtx2 + diag(ones(1,length(P1)).*NaN);
%Counts
% for r = 1:size(connectivity_mtx1,1)
%     % count pair of objects placed in the same cluster in both P1 & P2
%     ix1 = connectivity_mtx1(r,:) == 1;
%     ix2 = connectivity_mtx2(r,:) == 1;
%     ix = sum(ix1.*ix2);
%     n11 = n11 + ix;
%     % count pair of objects that are in different clusters in both P1 & P2
%     ix1 = connectivity_mtx1(r,:) == 0;
%     ix2 = connectivity_mtx2(r,:) == 0;
%     ix = ix1.*ix2;
%     n00 = n00 + sum(ix);
%     % count pair of objects that are in the same cluster in P1 but in different clusters in P2
%     ix1 = connectivity_mtx1(r,:) == 1;
%     ix2 = connectivity_mtx2(r,:) == 0;
%     ix = ix1.*ix2;
%     n10 = n10 + sum(ix);
%     % count pair of objects that are in different cluster in P1 but in the same cluster in P2
%     ix1 = connectivity_mtx1(r,:) == 0;
%     ix2 = connectivity_mtx2(r,:) == 1;
%     ix = ix1.*ix2;
%     n01 = n01 + sum(ix);
% end

% count pair of objects placed in the same cluster in both P1 & P2
ix1 = connectivity_mtx1 == 1;
ix2 = connectivity_mtx2 == 1;
ix = sum(ix1.*ix2);
n11 = n11 + sum(ix);
% count pair of objects that are in different clusters in both P1 & P2
ix1 = connectivity_mtx1 == 0;
ix2 = connectivity_mtx2 == 0;
ix = ix1.*ix2;
n00 = n00 + sum(sum(ix));
% count pair of objects that are in the same cluster in P1 but in different clusters in P2
ix1 = connectivity_mtx1 == 1;
ix2 = connectivity_mtx2 == 0;
ix = ix1.*ix2;
n10 = n10 + sum(sum(ix));
% count pair of objects that are in different cluster in P1 but in the same cluster in P2
ix1 = connectivity_mtx1 == 0;
ix2 = connectivity_mtx2 == 1;
ix = ix1.*ix2;
n01 = n01 + sum(sum(ix));


n11 = n11/2; n00 = n00/2; n10 = n10/2; n01 = n01/2;
ri = (n11 + n00)/(n11 + n00 + n10 + n01);
pri = (w11*n11 + w00*n00)/(w11*n11 + w00*n00 + w10*n10 + w01*n01);