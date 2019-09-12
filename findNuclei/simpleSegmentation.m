function [finalMask, img_proc] = simpleSegmentation(img,cellArea,cellIntensity,separateFused)

global userParam;

cellSize = sqrt(cellArea/pi);
userParam.gaussRadius = max(floor(cellSize/6),3);
userParam.gaussSigma = max(floor(cellSize/18),1);
userParam.presubNucBackground = 1;
userParam.backdiskrad = round(cellSize*2);
erodeSize = 1.2;%1.2

%img_proc = preprocessImages(img);% do not preprocess
img_proc = (img);
mask = (img_proc > cellIntensity); %& ~e_img;

mask = imfill(mask,'holes');
mask = bwareaopen(mask,2*floor(cellArea/3));

if separateFused
    CC = bwconncomp(mask);
    stats = regionprops(CC, 'Area');
    area = [stats.Area];
    fusedCandidates = area > 1.3*cellArea;%1.7
    
    sublist = CC.PixelIdxList(fusedCandidates);
    sublist = cat(1,sublist{:});
    
    fusedMask = false(size(mask));
    fusedMask(sublist) = 1;
    
    s = round(erodeSize*cellSize/3);
    nucmin = imerode(fusedMask,strel('disk',s));
    
    % dilation by 1 pixel because otherwise the distance on the edge is
    % zero so the mask is shrunk by 1 pixel
    outside = ~imdilate(fusedMask,strel('disk',1));
    basin = imcomplement(bwdist(outside));
    basin = imimposemin(basin, nucmin | outside);
    
    L = watershed(basin);
    finalMask = L > 1 | mask - fusedMask;
else
    finalMask = mask;
end

%finalMask = imclose(finalMask,strel('disk',floor(cellSize/6)));

