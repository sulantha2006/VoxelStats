function mask = makeroimask (wantedROIs, fig, dim)

% MAKEROIMASK  Create a mask from a set of ROI's
%
%
%        mask = makeroimask (ROIs [,fig[,dim]])
%
%
%  Create a mask from a set of ROI's associated with an image.  The ROI's
%  are either specified by number (referenced to the current figure), or by
%  handle.  For example, to create a mask from ROI's 1 to 3 in the current
%  figure, specify:
%
%           mask = makeroimask (1:3);
%
%  The figure to use as the current figure may also be specified.  For
%  example, to create a mask from ROI's 2:5 in figure 2, specify:
%
%           mask = makeroimask (2:5,2);
%
%  In both of the above cases, the mask produced will be the same dimensions
%  as the figure used.  However, this is not always desirable, as in the
%  case where the ROI's are drawn on a 256x256 MRI, but are applied to a
%  128x128 PET.  To solve this, it is possible to specify the desired
%  dimensions of the resulting mask.  In the following example, we request
%  ROI's 2:4 from figure 1, but with a specified dimension of the mask of
%  128x128:
%
%           mask = makeroimask (2:4,1,[128 128]);
%
%  Finally, it is possible to specify that a mask for ALL ROI's is desired.
%  This is done by passing an empty array for the desired ROIs:
%
%           mask = makeroimask ([]);
%

% $Id: makeroimask.m,v 1.3 1997-10-20 18:23:27 greg Rel $
% $Name:  $

% @COPYRIGHT  :
%             Copyright 1993,1994 Mark Wolforth and Greg Ward, McConnell
%             Brain Imaging Centre, Montreal Neurological Institute, McGill
%             University.
%             Permission to use, copy, modify, and distribute this software
%             and its documentation for any purpose and without fee is
%             hereby granted, provided that the above copyright notice
%             appear in all copies.  The authors and McGill University make
%             no representations about the suitability of this software for
%             any purpose.  It is provided "as is" without express or
%             implied warranty.


if (nargin<1)
  help makeroimask
  error('Too few input arguments.');
elseif (nargin<2)
  fig = gcf;
  
  Xlimits = get (gca,'XLim');
  Ylimits = get (gca,'YLim');
  
  Xrange = max(Xlimits) - min(Xlimits);
  Yrange = max(Ylimits) - min(Ylimits);
  xmin = min(Xlimits);
  xmax = max(Xlimits);
  ymin = min(Ylimits);
  ymax = max(Ylimits);
elseif (nargin<3)
  figure(fig);
  
  Xlimits = get (gca,'XLim');
  Ylimits = get (gca,'YLim');
  
  Xrange = max(Xlimits) - min(Xlimits);
  Yrange = max(Ylimits) - min(Ylimits);
  xmin = min(Xlimits);
  xmax = max(Xlimits);
  ymin = min(Ylimits);
  ymax = max(Ylimits);
else
  Xrange = dim(1);
  Yrange = dim(2);
  xmin = 1;
  xmax = Xrange+1;
  ymin = 1;
  ymax = Yrange+1;
end

mask = zeros(Xrange,Yrange);

%
% See if the ROIs are specified by handle
%

if (min(wantedROIs>100))
  fig = floor(wantedROIs/100);
  fig = fig(1);
  wantedROIs = wantedROIs - (fig*100);
  
  %
  % Make sure that all ROIs specified by handle are
  % related to the same figure.
  %
  
  if (max(wantedROIs) > 100)
    error ('All ROIs specified by handle must be from the same figure!');
  end
end


eval (['global ROIs',int2str(fig)]);
eval (['ROIs = ROIs',int2str(fig),';']);
index = find(ROIs==-1);
numROIs = length(index)-1;

%
% Did the user want ALL ROI's?
%

if (length(wantedROIs) == 0)
  wantedROIs = 1:numROIs;
end

for i=wantedROIs

  Vertices = ROIs((index(i)+1):(index(i+1)-1));
  numVertices = length(Vertices)/2;
  xi = ((Vertices(1:numVertices)).*Xrange)';
  yi = ((Vertices((numVertices+1):(length(Vertices)))).*Yrange)';

  %
  % Make sure xi and yi don't form a closed polygon
  % (closedness is implied).
  %

  n = length(xi); 
  if xi(n)==xi(1) & yi(n)==yi(1)
    xi = xi(1:n-1);
    yi = yi(1:n-1);
  end

  %
  % Transform xi,yi into pixel coordinates.  Fix-up coordinates
  % to deal with coordinates extending from pixel boundaries rather
  % than pixel centers.
  % 
  
  dx = max( (xmax-xmin)/Xrange, eps );
  dy = max( (ymax-ymin)/Yrange, eps );
  kx = (Xrange-1+dx);
  ky = (Yrange-1+dy);
  xx = max(min((xi-xmin)/(xmax-xmin)*kx+(1-dx/2),Xrange),1);
  yy = max(min((yi-ymin)/(ymax-ymin)*ky+(1-dy/2),Yrange),1);

  %
  % Coordinates of pixels
  %
  
  [u,v] = meshgrid(1:Xrange,1:Yrange);

  m = length(xx);

  %
  % Make sure polygon is traversed counter clockwise
  %
  
  [dum,i] = min(xx);
  h = rem(i+m-2,m)+1;
  j = rem(i,m)+1;
  if det([xx([h i j]) yy([h i j]) ones(3,1)]) > eps
    xx = flipud(xx(:)); 
    yy = flipud(yy(:)); 
  end

  %
  % For each triangular piece of the general polygon, find the interior
  %
  
  while m>=3,
    imin = 1; jmin = 2; hmin = 3;       % Defaults
  
    %
    % Find triangle with minimum diagonal
    %
    
    mindiag = inf;
    for i=1:m,
      h = rem(i+m-2,m)+1;
      j = rem(i,m)+1;
      if det([xx([h i j]) yy([h i j]) ones(3,1)])<eps,
        thisdiag = norm([xx(h)-xx(j) yy(h)-yy(j)]);
        if thisdiag<mindiag
          mindiag = thisdiag;
          imin = i;
          hmin = h;
          jmin = j;
        end
      end
    end
    m = m-1;
    dd = ones(Xrange,Yrange);

    for k=1:3,
      dx = xx(imin)-xx(jmin);
      dy = yy(imin)-yy(jmin);
      dd = dd & (((u-xx(imin))*dy - (v-yy(imin))*dx) <= 1);
      sav = imin;
      imin = jmin;
      jmin = hmin;
      hmin = sav;
    end
    mask = dd | mask;

    %
    % Remove vertex at imin
    %
    
    xx(imin) = []; yy(imin) = [];

  end
end

mask = reshape (mask',Xrange*Yrange,1);
