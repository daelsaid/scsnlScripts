
parfor k = 1:length(Kvals)
    for subj = 1:length(subject_list)
        subject = subject_list(subj);
        kval = Kvals(k);
        fname = [data_dir 'IndStabilityMatrix-' subject{1} '-' num2str(kval) '.mat'];
        xx = load(fname); I = xx.I; xx = [];
        Idx = ones(size(I));
        Idx = tril(Idx,-1);
        ix = find(Idx > 0);
        Y = 1-G(ix);
        Z = linkage(Y','average');
        data_labels = cluster(Z,'maxclust',kval);
    end
end