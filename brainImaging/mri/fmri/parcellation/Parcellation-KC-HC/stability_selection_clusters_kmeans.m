function estLabels = stability_selection_clusters_kmeans(X,Kvals,B,blk_size,subj)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N = size(X,2);  % # of features
for k = 1:length(Kvals)
    K = Kvals(k);
    Labels_rep = zeros(B, size(X,1));
    no_blks = floor(N/blk_size);
    for b = 1:B
        ix_blks = randsample(no_blks,floor(0.75*no_blks));
        start_pts = (ix_blks - 1) * blk_size + 1;
        end_pts = start_pts + blk_size - 1;
        Ix = [];
        for m = 1:size(start_pts,1)
            Ix = [Ix;(start_pts(m):end_pts(m))'];
        end
        Ix = Ix(Ix <= N);
        Y = X(:,Ix);
        for r = 1:size(Y,1)
            y = Y(r,:);
            y  = y./norm(y);
            Y(r,:) = y;
        end
        Labels_rep(b,:) = kmeans(Y,K,'Replicates',5,'Distance','cosine','emptyaction','drop')';
    end
    estLabels(k).Labels_rep = Labels_rep;
end
