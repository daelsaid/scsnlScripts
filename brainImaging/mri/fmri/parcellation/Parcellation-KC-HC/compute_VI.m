function [mean_VI, std_VI,mean_NMI,std_NMI] = compute_VI(result_dir,roiname,Kvals)

mean_VI = zeros(1,length(Kvals));
std_VI = zeros(1,length(Kvals));
mean_NMI = zeros(1,length(Kvals));
std_NMI = zeros(1,length(Kvals));
for k = 1:length(Kvals)
    fname = [result_dir 'Labels-' roiname{1} '-' num2str(Kvals(k)) '.mat'];
    load(fname)
    VI_vals = [];
    NMI_vals = [];
    for m = 1:size(data_labels,1)-1
        for n = m+1:size(data_labels,1)
            [vi,nmi] = compare_clusterings(data_labels(m,:), data_labels(n,:));
            VI_vals = [VI_vals vi];
            NMI_vals = [NMI_vals,nmi];
        end
    end
    mean_VI(k) = mean(VI_vals);
    std_VI(k) = std(VI_vals);
    mean_NMI(k) = mean(NMI_vals);
    std_NMI(k) = std(NMI_vals);
end