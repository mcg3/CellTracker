% plots the fractions of gene-positive cells, gene-positive colonies and number of cells as a function of colony size 
% 
% colonies is a cell array of colony data, separate for each of 
% quadrants/matfiles
% M is the maximum colony size from the given colony structure


function [totalcells,ratios,ratios2,totcol]=PlotColAnalysisQuadrAN(colonies,M,thresh,nms2,param1,index1,flag,dapimax,chanmax,dapiscalefactor)
clear tmp
colormap = colorcube;
disp(dapiscalefactor);
for k=1:size(nms2,2) %  loop over the number of experimental conditions    
    totalcolonies = zeros(M,1);
    genepositive = zeros(M,1);
    geneposcolonies = zeros(M,1);
    totalcells=zeros(M,1);   
    
    for ii=1:size(colonies{k},2)
        a = any(colonies{k}(ii).data(:,3)>dapimax(1));%%any(colonies{k}(ii).data(:,index1(1))>dapimax(1))
        in = colonies{k}(ii).imagenumbers;
        b = any(colonies{k}(ii).data(:,index1(1))./colonies{k}(ii).data(:,5)<chanmax);
        if ~isempty(colonies{k}(ii).data)   && (a ==0) ;  %use b only for the fgfhigh dataset fractions
            nc = colonies{k}(ii).ncells;
            
            totalcolonies(nc)=totalcolonies(nc)+1;
            if size(index1,2)==1
            tmp = colonies{k}(ii).data(:,index1(1))> thresh(k);
            end
            if size(index1,2)>1
            tmp = (colonies{k}(ii).data(:,index1(1))./(colonies{k}(ii).data(:,5)/dapiscalefactor(k)) > thresh(k)) ;
            end            
            genepositive(nc)= genepositive(nc)+sum(tmp);
            geneposcolonies(nc)=geneposcolonies(nc)+any(tmp);            
        end
    end
    %
    for l=1:length(totalcolonies)        
        totalcells(l)=totalcolonies(l)*l;
        %totalcolonies(l) = totalcells(l)/l;
    end
   
    allcells = sum(totalcells);
    ratios{k} = genepositive./totalcells;
    ratios2{k} = geneposcolonies./totalcolonies;
     totcol{k} = totalcolonies;
    if flag == 1
    figure(3), plot(ratios{k},'-*','color',colormap(k+2,:),'markersize',18,'linewidth',2); legend(nms2,'location','southeast');figure(3),hold on
    xlabel('Number of cells in the colony');
    ylabel(['FractionOf',(param1),'PositiveCells']);
    title ([thresh]);
    xlim([0 8]);
    ylim([0 1]);
    
    figure(4), plot(ratios2{k},'-*','color',colormap(k+2,:),'markersize',18,'linewidth',2); legend(nms2,'location','southeast');figure(4),hold on
    xlabel('Number of cells in the colony');
    ylabel(['FractionOf',(param1),'PositiveColonies']);
    title ([thresh]);
    xlim([0 8]);
    ylim([0 1]);
    
    figure(5),  plot(totalcolonies,'-*','color',colormap(k+2,:),'markersize',18,'linewidth',2); legend(nms2);figure(5),hold on % plot toalcolonies instead
    xlabel('Number of cells in the colony');
    ylabel('Total COlonies');
    title ([thresh]);
    xlim([0 8]);
    end
    
end

end