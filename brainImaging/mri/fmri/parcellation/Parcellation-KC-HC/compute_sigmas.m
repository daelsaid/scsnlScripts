function avg_silhouette = compute_sigmas(result_dir,roiname,Kvals,subject_list)

fname = [result_dir 'IndStabilityMatrix-' subject_list{1} '-' roiname{1} '-' num2str(Kvals(1)) '.mat'];
load(fname);
G = zeros(size(I,1));
avg_silhouette = zeros(1,length(Kvals));
for k = 1:length(Kvals)
    kval = Kvals(k);
    for subj = 1:length(subject_list)
        subject = subject_list(subj);
        fname = [result_dir 'IndStabilityMatrix-' subject{1} '-' roiname{1} '-' num2str(kval) '.mat'];
        load(fname);
        G = G + I;
    end
    G = G./length(subject_list);
    Idx = ones(size(G));
    Idx = tril(Idx,-1);
    ix = find(Idx > 0);
    Y = 1-G(ix);
    Z = linkage(Y','average');
    
    data_labels = cluster(Z,'maxclust',kval);
    silhoute_vals = compute_silhoutes(data_labels,G,kval);
    avg_silhouette(k) = mean(silhoute_vals);
end


function silhoute_vals = compute_silhoutes(data_labels,G,mval)

unique_labels = unique(data_labels);
%Compute Intra Cluster similarity for each voxel
silhoute_vals = zeros(1,length(data_labels));
for C = 1:mval
    Ix = find(data_labels == C);
    for i = 1:length(Ix);
        ix1 = setdiff(Ix,Ix(i));
        %intra-cluster cluster similarity
        asi = mean(G(Ix(i),ix1));
        other_labels = unique_labels(unique_labels ~= C);
        bs_vals = zeros(1,length(other_labels)); %inter-cluster separability
        for ol = 1:length(other_labels)
            Iy = find(data_labels == other_labels(ol));
            bs_vals(ol) = mean(G(Ix(i),Iy));
        end
        bsi = max(bs_vals);
        silhoute_vals(Ix(i)) = (asi-bsi);%/max(asi,bsi);
    end
end
