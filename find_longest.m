function [img_res,label_res] = find_longest(img)
    [m1,~] = size(img);
    b = topkrows(img,m1);
    c = tabulate(b(:,1));
    [m2,~] = size(c);
    d = topkrows(c,m2);
    img_res = 0;
    label_res = zeros(2);
    dis = 0;
    for i = b(1,1):-1:1
        img_temp = b(1:d(1,2),2:3);
        max_label = max(img_temp,[],1);
        min_label = min(img_temp,[],1);
        if dist(max_label,min_label')>dis
            dis = dist(max_label,min_label');
            label_res(1,:) = max_label;
            label_res(2,:) = min_label;
            img_res = img_temp;
        end
        b(1:d(1,2),:) = [];
        d(1,:) = [];
    end


        

