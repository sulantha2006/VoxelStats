function [no,xo] = gettaggedhist (handle,tags,bins,progress)
% GETTAGGEDHIST  creates a histogram of voxel values from a labelled volume
%
%     [no,xo] = gettaggedhist (handle, tags [, bins [, progress]])
%
% returns vectors no and xo such that bar(xo,no) will plot a histogram
% of the voxel values in the labelled region given by tags.
% 
%     gettaggedhist (handle, tags [, bins [, progress]])
%     
% will plot the histogram.
% 
% See the help for gettaggedregion for more information on tagged
% regions.

% $Id: gettaggedhist.m,v 1.3 1997-10-20 18:23:21 greg Rel $
% $Name:  $

% @COPYRIGHT :Copyright 1994-95 Mark Wolforth and Greg Ward, McConnell
%             Brain Imaging Centre, Montreal Neurological Institute,
%             McGill University.  Permission to use, copy, modify, and
%             distribute this software and its documentation for any
%             purpose and without fee is hereby granted, provided that
%             the above copyright notice appear in all copies.  The
%             author and McGill University make no representations about
%             the suitability of this software for any purpose.  It is
%             provided "as is" without express or implied warranty.

%
% Check the input arguments
%

err = nargchk (2, 4, nargin);
if (err)
   help gettaggedhist
   error (err);
end

if (nargin < 3)
  bins = 50;
end

if (nargin < 4)
  progress = 0;
end

%
% If caller only supplied number of bins, calculate the bin limits 
% from the volume min and max.  Otherwise, just use the user-supplied
% bin list (which is a list of bin midpoints).
%
  
if (length(bins) == 1)
  minmax = getimageinfo (handle, 'MinMax');
  min_val = minmax(1); max_val = minmax(2);
  
  binwidth = (max_val - min_val) ./ bins;
  xx = min_val + binwidth*[0:bins];
  xx(length(xx)) = max_val;
  xo = xx(1:length(xx)-1) + binwidth/2;
else
  xo = bins;
end

%
% Get the voxel values for the labelled volume, and make a histogram of them
%

values = gettaggedregion (handle, tags, progress);
no = hist(values,xo);

%
% If there are no output arguments, then plot
% the bar graph.
%

if (nargout == 0)
  bar (xo,no);
end
