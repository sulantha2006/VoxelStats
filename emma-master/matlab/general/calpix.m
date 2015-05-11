function cp = calpix(x,y)
% CALPIX  Obsolete function - please use PIXELINDEX instead

% $Id: calpix.m,v 1.5 1997-10-20 18:23:19 greg Rel $
% $Name:  $

disp ('calpix is obsolete.  Please use pixelindex instead');
cp = pixelindex ([128 128], x, y);
