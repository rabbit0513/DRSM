clc
clear
path_data = 'data22';
tic

%% 参数集
th = 0.7;       % 分割阈值
radius = 5;     % 搜索半径
period = 15;    % 镜头抖动周期
clu = [3,2];    % 聚类参数
ex = 8;         % 绘制矩形框扩展尺寸
tg_sz = 4;      % 绘制目标框尺寸(横纵半径)

%% 建立图片索引
filedir  = dir(fullfile(path_data,'*.bmp'));
filename = sort_nat({filedir.name})';
[num_img,~] = size(filedir);
idx_img = cell(num_img,2); 
ori_cube_gray = zeros(256,256);
proposed_cube = zeros(256,256,num_img);  % 双区搜索抑制后的最终滤波特征图序列
for i = 1 : num_img
    idx_img{i,1} = i;
    idx_img{i,2} = filename{i};
end

%% 多方向滤波
for i = 1 : num_img
    path_img = fullfile( path_data, idx_img{i,2});
    img = imread(path_img);
    [imgR, imgC, dimension]=size(img);

    % 将图片转换为灰度图
    if(dimension>2) 
        img = rgb2gray(img);
    end
    ori_cube_gray(:,:,i) = img;  % 原始图像序列IRn
    img = im2double(img);   % 转换为双精度（0～1）

    % 用改进的sobel算子进行8方向滤波
    img_temp = sobel8(img, imgR, imgC);
    img_cube(:,:,i) = img_temp; % 滤波特征图序列IFn
end

img_temp = img_cube;
img_temp(img_cube < th) = 0;
pfs_res = sum(img_temp(:,:,1:period),3); %  叠加聚类
pfs_res = imbinarize(pfs_res,0.01);

%% DBscan聚类，获得数据点坐标及其类别
classify_res = cluster_dbscan(pfs_res, clu);

%% 寻找最长类别，并返回两端点坐标作为目标范围Target Range
[target_range,TR] = find_longest(classify_res);
if TR(2,2) > TR(1,2)
    temTR = TR(2,2);
    TR(2,2) = TR(1,2);
    TR(1,2) = temTR;
end
% figure
% imshow(pfs_res)
% hold on
% rectangle('Position',[TR(2,2)-ex,TR(2,1)-ex,TR(1,2)-TR(2,2)+2*ex+1,TR(1,1)-TR(2,1)+2*ex+1],'EdgeColor','r',"LineWidth",1.5);
% hold off

%% 双区搜索，以TR外扩ex1个像素为搜索范围，对图像层逐层搜索，取最大值的坐标为目标位置，存入图片索引
ex1 = 4;
s_t = TR(2,1) - ex1;
s_b = TR(1,1) + ex1;
s_l = TR(2,2) - ex1;
s_r = TR(1,2) + ex1;
sort_cube = img_cube(s_t:s_b,s_l:s_r,:);
for k = 1:period
    temp = img_cube(s_t:s_b,s_l:s_r,k);
    [r,c] = find(temp == max(temp,[],"all"));
    r = r + s_t -1;
    c = c + s_l -1;
    idx_img{k,3} = [r,c];
    idx_img{k,5} = [r,c];
    idx_img{k,4} = ori_cube_gray(r,c,k);
end
% 取前1个周期内的众数
for k = 1:period
    A(k) = idx_img{k,4};
end
z = mode(A);

th_gray = 20;   % 灰度判别阈值
th_dist = 5;    % 距离判别阈值
for k = period + 1 : num_img
    tem_loc = idx_img{k - 1,3};
    temp = img_cube(tem_loc(1,1)-radius:tem_loc(1,1)+radius,tem_loc(1,2)-radius:tem_loc(1,2)+radius,k);
    [r,c] = find(temp == max(temp,[],"all"));
    r = r + tem_loc(1,1)-radius -1;
    c = c + tem_loc(1,2)-radius -1;
    if abs(ori_cube_gray(r,c,k) - z) < th_gray && dist([r,c],(idx_img{k-1,3})') < th_dist
        idx_img{k,3} = [r,c];
        idx_img{k,4} = ori_cube_gray(r,c,k);
    else
        temp = img_cube(s_t:s_b,s_l:s_r,k);
        [r,c] = find(temp == max(temp,[],"all"));
        r = r + s_t -1;
        c = c + s_l -1;
        idx_img{k,3} = [r,c];
        idx_img{k,4} = ori_cube_gray(r,c,k);
    end
end

%% 二次校正
for k = period + 1 : num_img
    if abs(idx_img{k,4} - z) < th_gray || dist(idx_img{k,3},(idx_img{k-1,3})') < th_dist
        idx_img{k,5} = idx_img{k,3};
        continue
    else
        tem_loc = idx_img{k - 1,5};
        idx_img{k,5} = tem_loc;
        for i = 6:10
            temp = img_cube(tem_loc(1,1)-i:tem_loc(1,1)+i,tem_loc(1,2)-i:tem_loc(1,2)+i,k);
            [r,c] = find(temp == max(temp,[],"all"));
            r = r + tem_loc(1,1)-i -1;
            c = c + tem_loc(1,2)-i -1;
            if abs(ori_cube_gray(r,c,k) - z) < th_gray
                idx_img{k,5} = [r,c];
                idx_img{k,6} = ori_cube_gray(r,c,k);
                break
            end
        end
    end
end

for i = 1 : num_img
    loc = idx_img{i,5};
    proposed_cube(loc(1,1)-ex:loc(1,1)+ex,loc(1,2)-ex:loc(1,2)+ex,i) = img_cube(loc(1,1)-ex:loc(1,1)+ex,loc(1,2)-ex:loc(1,2)+ex,i);
end
toc

result = proposed_cube;
% save("proposed_05.mat","result");

%% 画图
for i = 1 : 10
    path_img = fullfile( path_data, idx_img{i,2});
    img_single_frame = imread(path_img);
    lrs = idx_img{i,5};
    figure
    imshow(img_single_frame,[])
    hold on
    rectangle('Position',[lrs(1,2)-tg_sz,lrs(1,1)-tg_sz,2*tg_sz+1,2*tg_sz+1],'EdgeColor','r',LineWidth=1);
    rectangle('Position',[TR(2,2)-ex,TR(2,1)-ex,TR(1,2)-TR(2,2)+2*ex+1,TR(1,1)-TR(2,1)+2*ex+1],'EdgeColor','g',LineWidth=1);
    hold off
%     close all
end