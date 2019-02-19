function main_kmeans_BASC(data_dir, result_dir, roiname,subject_list)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Kvals = 2:10;
B = 100;            %# of Replications/Initializations
blk_size = 10;      % for bootsrapping
%%%%%%%%%% Data Input %%%%%%%%%%%%%%%%%%%%
for subj = 1:length(subject_list)
    subj
    subject = subject_list(subj);
    datafile = strcat(data_dir, 'ROITimeseries/',subject{1}, '-', roiname{1}, '_ts', '.mat');
    xx = load(datafile); Xo = xx.Y';Coods = xx.vXYZ';
    xx = [];
    X = zeros(size(Xo,1),size(Xo,2)-0);
    %Regressor for Global Mean
    global_mean = mean(Xo);
    global_mean = global_mean(1:end);
    global_mean = global_mean - mean(global_mean);
    global_mean = global_mean./norm(global_mean);
    % Regressor for detrend
    xd = 1:length(global_mean);
    xd = xd'./norm(xd);
    %Regressor for tempral mean
    xm = ones(length(global_mean),1);
    xm = xm./norm(xm);
   % D = [xm xd global_mean'];
   D = [xm];
    %Normalization
    for r = 1:size(X,1)
        x = Xo(r,1:end);
        beta_hat = D\x';
        x = x - (D*beta_hat)';
        %x  = x./norm(x);
        X(r,:) = x;
    end
    estLabels = stability_selection_clusters_kmeans(X,Kvals,B,blk_size,subj);
    outputfile = [result_dir 'kmeans-' subject{1} '-' roiname{1} '-SS'  '.mat'];
    isave(outputfile, estLabels,Coods',Kvals)
end


function isave(outputfile, estLabels,Coods,Kvals)

save(outputfile, 'estLabels','Coods','Kvals')

