function runTileMM_usemultipleChansforSeg(files,outfile,posRange,bIms,nIms,paramfile,chanmerge,areamin,areamax)

global userParam;

try
    eval(paramfile);
catch
    error('Error evaluating paramfile.');
end

%nImages=length(files.chan)-1;
nImages=length(files.chan);% AN
xmax = max(files.pos_x)+1;
ymax = max(files.pos_y)+1;

for ii=posRange(1):posRange(2)
    disp(['Running image ' int2str(ii)]);
    %read the files
    try   
        %Initialize error string
        userParam.errorStr=sprintf('Position %d\n',ii);
        [nuc1,maskC,statsN]= makeMaskswith2chans_nooverlap(files,ii,bIms,nIms,paramfile,0,chanmerge,areamin,areamax); % AN makeMaskswithmultiplechanelsMM
        
        % nuc is a cell array with all images
        nuc = nuc1{1};
       
        % [maskC, statsN]=segmentCells2(nuc,fimg);% this function is
       % standard, for the case when all cells have nuclear label
        % make maskC the mask compliled from two chanels
        
      % [~, statsN]=addCellAvr2Stats(maskC,fimg,statsN);% 
      
       % probably will not need, or make separately for each chanel and then
       % put together into the outdat
       outdat_tmp = struct;
       for k=1:nImages
           if ~isempty(statsN)
           [~, statsN1]=addCellAvr2Stats(maskC,nuc1{k},statsN);% AN
           outdat_tmp(k).stats = statsN1;
           end
       end
        outdat_tmp2 = struct;
       
        for k=1:nImages            
            if ~isempty(outdat_tmp(k).stats)                
                %outdat=outputData4AWTracker(statsN,nuc,nImages);
                outdat_tmp2(k).data = Data4AWTracker_AN(outdat_tmp(k).stats,nuc1{k},1);
            end            
        end             
           colnum = (5+(nImages-1)*2);
           finoutdat = zeros(size(outdat_tmp2(nimgvect(1)).data,1),colnum);
            % next for loop to compile the outdat in the usual form for
            % saving in peaks      
            nimgvect = (1:nImages);
            % the chanel order will be the same as the order returned by the readMMdirectory , e.g. ('CFP','CY5','GFP','RFP')
           finoutdat(:,1:5) = outdat_tmp2(nimgvect(1)).data(:,1:5);
           q = 0;
           for jj=(2:(nImages))
           finoutdat(:,(5+jj-1+q):(5+jj+q)) = outdat_tmp2(nimgvect(jj).data(:,end-1:end)); % 
            q = q+1;
           end          
            peaks{ii}=finoutdat;
            imgfiles(ii).errorStr=userParam.errorStr;
            % compress and save the binary mask for nuclei
            imgfiles(ii).compressNucMask = compressBinaryImg([statsN.PixelIdxList], size(nuc) );
            
            save(outfile,'peaks','userParam','imgfiles'); 
        
    catch err       
        disp(['Error with image ' int2str(ii)]);
        disp(err.identifier);
        %rethrow(err);
    end
end
end