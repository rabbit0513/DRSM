function [res] = normalize(image)
    gmin = min(image,[],'all');
    gmax = max(image,[],'all');
    gdel = gmax - gmin + eps;
    res = (image - gmin)./gdel;
end

