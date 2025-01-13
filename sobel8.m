function imde = sobel8(img,imgR ,imgC)
%% sobel 滤波因子 角度分别为：0°，22.5°，45°，67.5°，90°，112.50°，135°，157.50°
filter_kernel(:,:,1) = [0 0 0 0 0; -1 -2 -4 -2 -1;-2 -2 8 -2 -2;1 2 4 2 1;0 0 0 0 0];
filter_kernel(:,:,2) = [0 0 0 0 0; 0 -2 -4 -2 -4; -1 -4 8 4 1; -4 2 4 2 0;0 0 0 0 0];
filter_kernel(:,:,3) = [0 0 0 -1 -2; 0 -2 -4 -2 1 ;0 -4 8 4 0;  -1 -2 4 2 0;-2 1 0 0 0];
filter_kernel(:,:,4) = [0 0 -1 -4 0;0 -2 -4 2 0; 0 -4 8 4 0;0 -2 4 2 0;0 -4 1 0 0];
filter_kernel(:,:,5) = rot90(filter_kernel(:,:,1));
filter_kernel(:,:,6) = rot90(filter_kernel(:,:,2));
filter_kernel(:,:,7) = rot90(filter_kernel(:,:,3));
filter_kernel(:,:,8) = rot90(filter_kernel(:,:,4));

direction_cube = zeros(imgR, imgC, 8);
for i = 1:8
    direction_cube(:,:,i) = conv2(img,filter_kernel(:,:,i), 'same');
end

dc_min = min(direction_cube,[],3);
dc_sum = sum(direction_cube,3);

% normalization
dc_min(dc_min<0) = 0;
dc_min = normalize(dc_min);
dc_sum(dc_sum<0) = 0;
dc_sum = normalize(dc_sum);
dc_min([1,2,imgR-1,imgR],:) = 0;
dc_min(:,[1,2,imgC-1,imgC]) = 0;
dc_sum([1,2,imgR-1,imgR],:) = 0;
dc_sum(:,[1,2,imgC-1,imgC]) = 0;

im = dc_min.* dc_sum;
im([1,2,imgR-1,imgR],:) = 0;
im(:,[1,2,imgC-1,imgC]) = 0;
imde = normalize(im);
