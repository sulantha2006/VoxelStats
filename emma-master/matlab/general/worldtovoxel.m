function out = worldtovoxel (volume, in, options)
% WORLDTOVOXEL  convert points from world to voxel coordinates
%
%     v_points = worldtovoxel (volume, w_points [, options])
% or
%     wv_xfm = worldtovoxel (volume)
% 
% If the first form is used, then w_points must be a matrix with N
% columns (for N points) and three rows (for the three spatial
% dimensions).  (Alternately, a four-row form is acceptable: three rows
% for the three spatial dimensions, plus a row of all ones.)
%
% Normally, worldtovoxel assumes that the the voxel coordinates are to
% be used as slice/pixel numbers within EMMA, i.e. that the coordinates
% should be one-based and in the order (slice, row, col).  However, if
% the points are to be used externally (eg., with a C program such as
% mincextract), then they should be zero-based.  Using the 'external'
% option will cause this to be done.  Also, some applications may expect
% voxel coordinates in (x,y,z) order; use the 'xyzorder' option when this
% is needed.
% 
% If the second form is used then the just the world-to-voxel transform
% (a 4x4 matrix) is returned.  This is simply the inverse of the matrix
% returned by getvoxeltoworld, modified to convert zero-based to
% one-based and to reorder world-order to voxel-order (unless overridden
% by the 'external' or 'xyzorder' options).
% 
% Options are specified as single words, all in the same string, and
% separated by spaces.  The currently-available options are:
% 
%    xyzorder    put output voxel coordinates in (x,y,z) order,
%                i.e. do not permute them to (slice,row,col) order
%    noflip      make output voxel coordinates refer to unflipped
%                dimensions (any dimensions with negative step sizes
%                are flipped when read in by EMMA to ensure
%                anatomical consistency)
%    zerobase    make output voxel coordinates zero-based
%                (coordinates for use within MATLAB are one-based, and
%                thus must be shifted down before converting to world
%                coordinates)
%    external    combines 'noflip' and 'zerobase'
%
% The volume argument must be an image handle as returned by openimage
% or newimage.
% 
% EXAMPLES
% 
% To use the points in a tag file with EMMA:
%
%    h = openimage ('foo.mnc');
%    tags = loadtagfile ('foo.tag');       % get tags in world coordinates
%    vtags = worldtovoxel (h, tags');      % transform to voxel coordinates
%
% vtags will be a matrix with one column per point; the first three rows
% will be slice, row, and column numbers for use with EMMA.  (Slice numbers
% for getimages/putimages, row and column numbers for pixelindex.)
%
% Note that this does NOT give the same vtags as:
% 
%    wv = inv (getworldtovoxel (h));
%    vtags = wv * tags;
% 
% because in this case, none of the conversions from "external"-style voxel
% coordinates to EMMA-style voxel coordinates are done.  It is almost
% always preferable to use worldtovoxel for this type of conversion, as it
% takes care of all the gory details for you.
%
% SEE ALSO
%   getvoxeltoworld, voxeltoworld, gettaggedregion

% $Id: worldtovoxel.m,v 1.7 2000-04-04 14:09:39 neelin Exp $
% $Name:  $

% by Mark Wolforth; rewritten 95/3/10-12 by Greg Ward, and then
% again 95/11/3-9 by GW (sigh)


% @COPYRIGHT  :
%             Copyright 1994 Mark Wolforth and Greg Ward, McConnell
%             Brain Imaging Centre, Montreal Neurological Institute,
%             McGill University.  Permission to use, copy, modify, and
%             distribute this software and its documentation for any
%             purpose and without fee is hereby granted, provided that
%             the above copyright notice appear in all copies.  The
%             authors and McGill University make no representations about
%             the suitability of this software for any purpose.  It is
%             provided "as is" without express or implied warranty.


%
% Check input arguments
%

nargs = nargin;

if (nargs < 1 | nargs > 3)
  help worldtovoxel
  error ('Incorrect number of arguments');
end

if (nargs == 3)
   nargs = 2;
else
   options = '';
end

if (size(volume) ~= [1,1])
   error ('volume parameter must be an image handle');
end

wv = inv (voxeltoworld (volume, [], options));

% If an empty set of points was supplied, pretend that none were
% supplied (so the user can supply options when they wish to fetch just
% the transform)

if (nargs == 2)
   if (size (in) == [0 0])
      nargs = 1;
   end
end

% If only one argument was supplied, just return the transform

if (nargs == 1)
   out = wv;

% If exactly two arguments were supplied, the second is a matrix
% of points.  First check to see if caller supplied a three-row
% or four-row matrix; if three, we have to tack on ones to make
% the points homogeneous

elseif (nargs == 2)
   points = in;
   [m,n] = size (points);     % make sure we have points in homogeneous
   if (m == 3)                % coordinates (i.e. [x y z 1]')
      points = [points; ones(1,n)];
   elseif (m ~= 4)
      error ('If a matrix of points is supplied, it must have either three or four rows');
   end

   points = wv * points;      % perform the transformation
   
   if (m == 3)                % if caller only supplied 3 rows, lose the 4th
      points = points (1:3,:);
   end
   out = points;
end
