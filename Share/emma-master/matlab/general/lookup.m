% LOOKUP   Fast linear interpolation
%
%   newy = lookup (oldx, oldy, newx)
%
% performs a linear interpolation on the data set [oldx, oldy].  oldx 
% and oldy must be vectors of the same size and shape; newx must be a
% vector, but can be of any length.  The resulting newy will be the 
% same size and shape as newx.  Also, oldx must be monotonic.
% 
% The value that y would have at each x value in newx is linearly
% interpolated using the two bracketing values of oldx and oldy.  In
% particular, if oldx[j] < newx[i] < oldx[j+1], then
%
%      slope = (oldy[j+1] - oldy[j]) / (oldx[j+1] - oldx[j])
%    newy[i] = oldy[j] + slope * (newx[i] - oldx[j])
%
% If newx[i] does not fall within the lower and upper bounds of oldx,
% then NaN will be returned in newy[i].  Also, if newx[i] == oldx[j+1]
% then newy[i] will still be interpolated from oldx[j+1] and oldx[j];
% note that this means any NaN's in oldy will be propagated to newy.

% $Id: lookup.m,v 1.2 1997-10-20 18:23:23 greg Rel $
% $Name:  $

% lookup.c - CMEX by Greg Ward & Mark Wolforth
