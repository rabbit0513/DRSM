function idx = cluster_dbscan(img, clu)
    r = clu(1);     % 聚类半径
    minpts = clu(2);   % 最少点数
    [row,col] = find(img);
    x = cat(2,row,col);
    idx = cat(2,dbscan(x,r,minpts),x);
end
