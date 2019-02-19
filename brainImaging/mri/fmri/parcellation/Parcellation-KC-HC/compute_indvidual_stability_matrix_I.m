function compute_indvidual_stability_matrix_I(data_dir,result_dir, roiname, subject_list)


%matlabpool local 8
for subj = 1:length(subject_list)
    subj
    subject = subject_list(subj);
    outputfile = [data_dir 'kmeans-' subject{1} '-' roiname{1} '-SS'  '.mat'];
    xx = load(outputfile); estLabels = xx.estLabels; Coods = xx.Coods; Kvals = xx.Kvals;
    xx = [];
    %clear xx
    %Find Individual Stability Matrices
    no_sites = size(estLabels(2).Labels_rep(1,:),2);
    for k = 1:length(estLabels)
        B = size(estLabels(k).Labels_rep,1);
        connectivity_mtx = zeros(no_sites,no_sites);
        if B~= 0
            for b = 1:B
                %[subj k b]
                labels = estLabels(k).Labels_rep(b,:);
                unique_labels = unique(labels);
                temp = zeros(no_sites,no_sites);
                for p = 1:length(unique_labels)
                    ix = find(labels == unique_labels(p));
                    temp(ix,ix) = 1;
                end
                connectivity_mtx = connectivity_mtx + temp;
            end
            I = connectivity_mtx./B;
        else
            I = [];
        end
        fname = [result_dir 'IndStabilityMatrix-' subject{1} '-' roiname{1} '-' num2str(Kvals(k)) '.mat'];
        isaveI(fname,I)
    end
end

function isaveI(fname,I)

save(fname,'I')

