function Cluster_G(data_dir,result_dir,roiname, subject_list,Kopt,roidir,prefix_fname,coods_dir)

fname = [data_dir 'IndStabilityMatrix-' subject_list{1} '-' roiname{1} '-' num2str(Kopt) '.mat'];
load(fname);
G = zeros(size(I,1));
for subj = 1:length(subject_list)
    subject = subject_list(subj);
    fname = [data_dir 'IndStabilityMatrix-' subject{1} '-' roiname{1} '-' num2str(Kopt) '.mat'];
    load(fname);
    G = G + I;
end
G = G./length(subject_list);
Idx = ones(size(G));
Idx = tril(Idx,-1);
ix = find(Idx > 0);
Y = 1-G(ix);
Z = linkage(Y','average');
data_labels= cluster(Z,'maxclust',Kopt);

V = spm_vol([roidir roiname{1}, '.nii']);
parcellation_ms = zeros(V.dim(1),V.dim(2),V.dim(3));
outputfile = [coods_dir 'kmeans-' subject_list{1} '-' roiname{1} '-SS'  '.mat'];
load(outputfile)
if size(Coods,1) < size(Coods,2)
    Coods = Coods';
end
for k = 1:size(Coods,1)
    x = Coods(k,1); y = Coods(k,2); z = Coods(k,3);
    parcellation_ms(x,y,z) = data_labels(k);
end
fname = [result_dir prefix_fname '-' num2str(Kopt) '.nii'];
V.fname = fname;
V1 =spm_write_vol(V,parcellation_ms);

%Compute Stability Matrix
wc = zeros(Kopt,length(data_labels));
no_sites = size(Coods,1);
for C = 1:Kopt
    %for every voxel (region i)
    for i = 1:no_sites
        %for every column j in G belongigng to Cluster C
        ix = find(data_labels == C);
        ix1 = setdiff(ix,i);
        wc(C,i) = mean(G(i,ix1));
    end
end

for C = 1:Kopt
    Stability_Map = zeros(V.dim(1),V.dim(2),V.dim(3));
    for k = 1:size(Coods,1)
        x = Coods(k,1); y = Coods(k,2); z = Coods(k,3);
        Stability_Map(x,y,z) = wc(C,k);
    end
    fname = [result_dir, 'StabilityIndex-', prefix_fname,'-SS-', num2str(C),'-', num2str(Kopt) '.nii'];
    V.fname = fname;
    V1 =spm_write_vol(V,Stability_Map.*100);
end




