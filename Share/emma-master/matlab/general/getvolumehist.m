function [no,xo] = getvolumehist (handle,bins)

%
%
%        [no,xo] = getvolumehist (handle [,bins])
%
%

% $Id: getvolumehist.m,v 1.4 2000-04-10 16:00:51 neelin Exp $
% $Name:  $

% @COPYRIGHT  :
%             Copyright 1994 Mark Wolforth, McConnell Brain Imaging Centre,
%             Montreal Neurological Institute, McGill University.
%             Permission to use, copy, modify, and distribute this software
%             and its documentation for any purpose and without fee is
%             hereby granted, provided that the above copyright notice
%             appear in all copies.  The author and McGill University make
%             no representations about the suitability of this software for
%             any purpose.  It is provided "as is" without express or
%             implied warranty.

%
% Check the input arguments
%

if (nargin < 1)
  help getvolumehist
  error ('Too few input arguments.');
elseif (nargin == 1)
  bins = 10;
end

%
% Get the image information
%

slices = getimageinfo(handle,'NumSlices');

if (length(bins) == 1)
  filename = handlefield(handle,'Filename');
  mins=mireadvar(filename,'image-min');
  min_val = min(mins);
  maxs=mireadvar(filename,'image-max');
  max_val = max(maxs);
  
  %
  % Calculate the bin limits
  %
  
  binwidth = (max_val - min_val) ./ bins;
  xx = min_val + binwidth*[0:bins];
  xx(length(xx)) = max_val;
  xo = xx(1:length(xx)-1) + binwidth/2;
else
  xo = bins;
end
  
%
% Initialize no
%

no = zeros (1,length(xo));

%
% Get the histograms
% 

fprintf ('Procesing %d slices', slices);

for i=1:slices
  MRI = getimages(handle,i);
  [n,x] = hist(MRI,xo);
  no = no+n;
  fprintf ('.');
end
fprintf ('done\n');

%
% If there are no output arguments, then plot
% the bar graph.
%

if (nargout == 0)
  bar (xo,no);
end
  
