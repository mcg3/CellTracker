function colonyColorPointPlot(col,dcols,ps,climits,rescale_fac,centerpos)
%function colonyColorPointPlot(col,dcols)
%---------------------------------------
%Colony scatter plot with points colored by data
%col -- colony object
%dcols -- columns for data, if length==1, use this col
%           if length==2, use 2nd one for norm
%ps = pointsize (default 12);

xdat=col.data(:,1);
ydat=col.data(:,2);
center = col.center; 
rad = col.radius;

if length(dcols)==1
    coldat=col.data(:,dcols);
elseif length(dcols)==2
    coldat=col.data(:,dcols(1))./col.data(:,dcols(2));
end


if ~exist('ps','var')
    ps=12;
end

if ~exist('climits','var')
    climits=[min(coldat) max(coldat)];
end

if ~exist('newfig','var')
    newfig=0;
end

if ~exist('rescale_fac','var')
    rescale_fac=0.66; %conversion from pixels to microns
end

if ~exist('centerpos','var')
    centerpos=1;
end

if newfig
figure; 
end

if centerpos
    xdat=bsxfun(@minus,xdat,mean(xdat));
    ydat=bsxfun(@minus,ydat,mean(ydat));
end

includeinds=sqrt(xdat.*xdat+ydat.*ydat) < 30*50+5;
xdat=xdat(includeinds); ydat=ydat(includeinds);
coldat=coldat(includeinds);

colormap('jet');
scatter(rescale_fac*xdat,rescale_fac*ydat,ps,coldat);
minx=min(xdat); maxx=max(xdat);
miny=min(ydat); maxy=max(ydat);

maxdiff=max(maxx-minx,maxy-miny);

axis equal; axis(rescale_fac*[minx-50 minx+maxdiff+50 miny-50 miny+maxdiff+50]);
set(gca,'CLim',climits);
