function get_labels_I(result_dir,roiname, subject_list,Kvals)

%matlabpool local 8

for k = 1:length(Kvals)
 %for k = 1:length(Kvals)
    k
    data_labels = [];
    for subj = 1:length(subject_list)
        subject = subject_list(subj);
        kval = Kvals(k);
        fname = [result_dir 'IndStabilityMatrix-' subject{1} '-' roiname{1} '-' num2str(Kvals(k)) '.mat'];
        xx = load(fname); I = xx.I; xx = [];
        Idx = ones(size(I));
        Idx = tril(Idx,-1);
        ix = find(Idx > 0);
        Y = 1-I(ix);
        Z = linkage(Y','average');
        data_labels(subj,:) = cluster(Z,'maxclust',kval);
    end
    fname = [result_dir 'Labels-' roiname{1} '-' num2str(kval) '.mat'];
    isaveLabels(fname,data_labels)
end
%matlabpool close

function isaveLabels(fname,data_labels)
save(fname,'data_labels')
