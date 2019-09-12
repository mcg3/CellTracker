function [out_masks, colonies] = statsArrayToSplitMasksIbidi(nmasks,nuc_imgs,cyt_imgs,cellmasks,toshift,matchdist,shiftframe)


imsize = size(nuc_imgs(:,:,1));

%a few parameters

minArea = 1000;

maxeroderad = 12;
discardsmall = 300;


if iscell(nmasks) || isstruct(nmasks)
    stats = nmasks;
    ntimes = length(stats);
else
    ntimes = size(nmasks,3);
    for ii = 1:ntimes
        stats{ii} = regionprops(nmasks(:,:,ii),'Area','Centroid','PixelIdxList');
    end
end

    % shift the centroids, not the xyt
if toshift == 1
shifted = shiftcoordinates(stats,shiftframe,imsize);
stats = shifted;
end

ncellsperframe = cellfun(@(x)size(x,1),stats);
ncells = sum(cellfun(@length,stats));

%get all xyt data
xyt = zeros(ncells,3);
q = 1;

for ii = 1:ntimes
    xyt(q:(q+ncellsperframe(ii)-1),1:2) = cat(1,stats{ii}.Centroid);
    xyt(q:(q+ncellsperframe(ii)-1),3) = ii; %time number
    xyt(q:(q+ncellsperframe(ii)-1),4) =1:ncellsperframe(ii); %cell number within that frame
    xyt(q:(q+ncellsperframe(ii)-1),5) =cat(1,stats{ii}.Area); %areas
    q = q + ncellsperframe(ii);
end

%group into colonies
global userParam;
userParam.colonygrouping = 100;
allinds=NewColoniesAW(xyt(:,1:2));
xyti = [xyt,allinds];

ncolonies = max(allinds);

%diagnostic plotting to label colonies
figure; plot(xyt(:,1),xyt(:,2),'r.'); hold on;
for ii = 1:ncolonies
    coldata = xyti(allinds == ii,:);
    mm  = mean(coldata,1);
    text(mm(1),mm(2),int2str(ii),'Color','c');
end

out_masks = false(imsize(1),imsize(2),ntimes);

for ii = 1:ncolonies %loop over colonies, find the ones that need to be split
    coldata = xyti(allinds == ii,:);
    nc_time =zeros(ntimes,1);
    nc_area = nc_time;
    for jj = 1:ntimes
        curr_inds = coldata(:,3) == jj;
        nc_time(jj) = sum(curr_inds); %number of cells in colony
        nc_area(jj) = sum(coldata(curr_inds,5)); %colony area
        if jj > 1 %store mask from last frame
            oldmask = maskToUse;
        end
        
        %make the mask of the current colony
        cellnums = coldata(curr_inds,4);
        tmpmask = false(imsize);
        tmpmask(cat(1,stats{jj}(cellnums).PixelIdxList))=true;
        
        if jj > 1
            if nc_time(jj) < max(nc_time(1:jj-1)) && nc_time(jj) > 0 %&& nc_area(jj) > 0.9*nc_area(jj-1) %lost a cell, didn't lose area
                done = false;
                %first try erosion based splitting
                numneeded = max(nc_time(1:jj-1));
                ncell = nc_time(jj);
                erode_rad = 1;
                %increase erosion radius until object is separated
                while ncell < numneeded && erode_rad < maxeroderad
                    newmask = imerode(tmpmask,strel('disk',erode_rad));
                    newmask = bwareaopen(newmask,discardsmall,4);
                    cc = bwconncomp(newmask);
                    ncell = cc.NumObjects;
                    erode_rad = erode_rad + 1;
                end
                if erode_rad < maxeroderad %possible success
                    outside = ~imdilate(tmpmask,strel('disk',2));
                    basin =  sobelEdge(nuc_imgs(:,:,jj));
                    basin = imimposemin(basin, newmask | outside);
                    L = watershed(basin);
                    testmask = L > 1;
                    
                    testmask = bwareaopen(testmask,discardsmall,4); %remove small stuff from mask
                    cc = bwconncomp(testmask);
                    a = regionprops(cc,'Area');
                    a = sort([a.Area],'descend');
                    a = a(1:min(numneeded,length(a)));
                    
                    if min(a) < minArea %didn't work
                        disp(['Warning: Colony ' int2str(ii) ' time ' int2str(jj) '. Discarding erode-based split. Resulting cells too small.'...
                            ' Trying overlap based splitting.']);
                    else %it's good
                        disp(['Split: Colony ' int2str(ii) ' time ' int2str(jj) '. Erode radius: ' int2str(erode_rad)]);
                        maskToUse = testmask;
                        done = true;
                    end
                end
                if ~done
                    disp(['Warning: erosion based splitting failed. Colony ' int2str(ii) ' time ' int2str(jj)...
                        '. Trying overlap based spliting.']);
                    maskToUse = tmpmask;
                    intmask = tmpmask & oldmask;
                    cc = bwconncomp(intmask);
                    ncell = cc.NumObjects;
                    numneeded = max(nc_time(1:jj-1));
                    if ncell >= numneeded %try spliting based on overlap with last frame
                        outside = ~imdilate(tmpmask | intmask ,strel('disk',2));
                        intmask(outside) = false; %make sure new mask doesn't overlap background
                        intmask = imerode(intmask,strel('disk',1));
                        intmask = bwareaopen(intmask,discardsmall,4); %remove small stuff from mask
                        basin = sobelEdge(nuc_imgs(:,:,jj));
                        basin = imimposemin(basin, intmask | outside);
                        L = watershed(basin);
                        maskToUse = L > 1;
                        maskToUse = bwareaopen(maskToUse,discardsmall,4);
                        cc = bwconncomp(maskToUse);
                        a = regionprops(cc,'Area');
                        a = sort([a.Area],'descend');
                        if min(a) > minArea
                            disp(['Split: Colony ' int2str(ii) ' time ' int2str(jj) '. Used overlap with previous']);
                        else
                            maskToUse = tmpmask;
                        end
                    end
                end
                
            else %doesn't need splitting
                maskToUse = tmpmask;
                numneeded = nc_time(jj);
            end
        else %first frame
            
            colonies(ii) = dynColony();
            maskToUse = tmpmask; 
            numneeded = nc_time(jj); 
           
        end

        colonies(end).ncells_predicted = [colonies(end).ncells_predicted, numneeded];
        colonies = addFrameToDynamicUcolony(maskToUse,cellmasks(:,:,jj),nuc_imgs(:,:,jj),cyt_imgs(:,:,jj),jj,colonies,matchdist);
                   
        out_masks(:,:,jj) = out_masks(:,:,jj) | maskToUse;
    end
    
end
