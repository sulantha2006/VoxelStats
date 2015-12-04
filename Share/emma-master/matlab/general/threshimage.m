function threshimage (upper, lower, map, overcolour, undercolour)
% THRESHIMAGE   threshold an image
% 
%      threshimage (upper, lower, map [,overcolour [,undercolour]]
%
%  upper is the upper threshold percentage (0-1)
%  lower is the lower threshold percentage (0-1)
%  map may either be the name of a colormap (eg. spectral, hotmetal, etc)
%      or an nx3 table of RGB values

% $Id: threshimage.m,v 1.3 2000-04-04 14:57:58 neelin Exp $
% $Name:  $

%
% Check the input arguments
%

if (nargin < 3)
  help threshimage
  error ('Insufficient number of input arguments.');
end

if (nargin == 3)
  overcolour = [1 1 1];
  undercolour = [0 0 0];
else
  if (nargin == 4)
    undercolour = [0 0 0];
  end
end

if (upper > 1)
  upper = 1;
end
if (lower < 0)
  lower = 0;
end

mapsize = length(colormap);

undersize = round(lower*mapsize);
oversize = round((1-upper)*mapsize);
newmapsize = mapsize - (undersize + oversize);

if (newmapsize>0)
  if (isstr(map))
    evalstr = ['newmap = ' map '(' int2str(newmapsize) ');'];
    eval (evalstr);
  else
    n = length(map);
    X0 = linspace (1, n, newmapsize);
    newmap = emma_table([(1:n)' map],X0)';
  end
else
  newmap = [];
end

if (undersize > 0)
  under = ones(undersize,3);
  under(:,1) = under(:,1) * undercolour(1);
  under(:,2) = under(:,2) * undercolour(2);
  under(:,3) = under(:,3) * undercolour(3);
end
if (oversize > 0)
  over = ones(oversize,3);
  over(:,1) = over(:,1) * overcolour(1);
  over(:,2) = over(:,2) * overcolour(2);
  over(:,3) = over(:,3) * overcolour(3);
end

colormap ([under; newmap; over]);

