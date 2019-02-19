function [mean_RI, mean_PRI] = compute_PRI(result_dir,roiname,Kvals)

matlabpool local 8

mean_RI = zeros(1,length(Kvals));
mean_PRI = zeros(1,length(Kvals));
parfor k = 1:length(Kvals)
    k
    fname = [result_dir 'Labels-' roiname{1} '-' num2str(Kvals(k)) '.mat'];
    xx = load(fname); data_labels = xx.data_labels; xx = [];
    RI_vals = [];
    PRI_vals = [];
    for m = 1:size(data_labels,1)-1
        for n = m+1:size(data_labels,1)
            [ri,pri] = get_pri(data_labels(m,:), data_labels(n,:));
            RI_vals = [RI_vals ri];
            PRI_vals = [PRI_vals,pri];
        end
    end
    mean_RI(k) = mean(RI_vals);
    mean_PRI(k) = mean(PRI_vals);
end
matlabpool close

