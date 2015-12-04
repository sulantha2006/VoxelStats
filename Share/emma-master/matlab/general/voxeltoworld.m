function [out] = voxeltoworld (volume, in, options)
% VOXELTOWORLD  convert points from world to voxel coordinates
%
%     w_points = voxeltoworld (volume, v_points [, options])
% or
%     vw_xfm = voxeltoworld (volume)
% 
% If the first form is used, then v_points must be a matrix with N
% columns (for N points) and three rows (for the three spatial
% dimensions).  (Alternately, a four-row form is acceptable: three rows
% for the three spatial dimensions, plus a row of all ones.)
% 
% If the second form is used, then just the voxel-to-world transform
% (a 4x4 matrix) is returned.  This is just the transform returned by
% getvoxeltoworld, modified to adjust voxel coordinates from EMMA
% style to some external form, possibly modified by the options
% parameter.
% 
% Normally, voxeltoworld assumes that the the input voxel coordinates
% originate from slice/pixel numbers within EMMA.  (Such coordinates are
% 1-based, in the order (slice,row,column), and possibly "inverted" for
% dimensions with negative step sizes.  See "help getvoxeltoworld" for
% the whole story.)  In this case, part of the voxel-to-world conversion
% involves adjusting the coordinates to a more standard form.  However,
% you can suppress any of these adjustments using the options
% argument.  This argument is just a list of space-separated keywords,
% of which four are possible:
% 
%    xyzorder    assume input voxel coordinates are in (x,y,z) order,
%                i.e. do not permute them from (slice,row,col) order
%    noflip      assume input voxel coordinates refer to unflipped
%                dimensions (any dimensions with negative step sizes
%                will be flipped when read in by EMMA to ensure
%                anatomical consistency)
%    zerobase    assume input voxel coordinates are zero-based
%                (coordinates for use within MATLAB are one-based, and
%                thus must be shifted down before converting to world
%                coordinates
%    external    combines 'noflip' and 'zerobase'
% 
% The `external' option should be used when converting voxel
% coordinates in the standard MINC style used by mincreshape,
% mincextract, etc.  When using voxel coordinates from Display or
% Register (which always use (x,y,z) order), use 'external xyzorder'.
%
% The volume parameter must be an image volume handle as returned by
% openimage or newimage.
%
% EXAMPLES
% 
% To convert an EMMA (slice, row, column)-style coordinate to world
% coordinates (where h is the handle for an open image volume): 
% 
%    w = voxeltoworld (h, [s, r, c]');
%    
% The same, but where [s, r, c] comes from (for example) a C program,
% and are therefore zero-based, non-dimension-flipped coordinates:
% 
%    w = voxeltoworld (h, [s, r, c]', 'external');
% 
% Convert a point (vx,vy,vz) -- voxel coordinates, but in world order --
% to world coordinates (assuming vx,vy,vz are zero-based):
%
%    w = voxeltoworld (h, [vx,vy,vz]', xyzorder external');
%
% SEE ALSO
%   worldtovoxel, getvoxeltoworld

% $Id: voxeltoworld.m,v 1.5 2000-04-04 14:09:39 neelin Exp $
% $Name:  $

% by Greg Ward 95/3/12

% Copyright 1995 Greg Ward, McConnell Brain Imaging Centre,
% Montreal Neurological Institute, McGill University.  Permission to
% use, copy, modify, and distribute this software and its
% documentation for any purpose and without fee is hereby granted,
% provided that the above copyright notice appear in all copies.  The
% authors and McGill University make no representations about the
% suitability of this software for any purpose.  It is provided "as
% is" without express or implied warranty.


%
% Check input arguments
%
nargs=nargin;

if (nargs < 1 | nargs > 3)
  help voxeltoworld
  error ('Incorrect number of arguments');
end


% Default options

reorder = 1;					  % use voxel order
flip = 1;					  % do flip dimensions
onebase = 1;					  % do shift array base

if (nargs == 3)
   if (~isstr (options))
      error ('options argument must be a string');
   end
   
   % Parse the options string as a list of space-separated words.
   % 'xyzorder' means don't reorder to (slice,row,col); 'noflip' means
   % don't take (x = length(x) - x - 1) for dimensions with step<0;
   % 'zerobase' means don't add one to coordinates for MATLAB-style
   % array indexing.  'external' is the combination of 'noflip' and
   % 'zerobase'.  'external' should be used for voxel coordinates in the
   % style of mincextract, mincreshape, etc.  'external xyzorder'
   % should be used for voxel coordinates displayed by Display and
   % Register (Dave likes xyz order).
   
   delim = [];
   if (length(options) == 0)
     delim = [];
     num_options = 0;
   else
     delim = find (options == ' ');
     num_options = length (delim) + 1;
   end
   if (length(delim) > 0)
     delim = [0 delim length(options)+1];
   else
     delim = [0 length(options)+1];
   end
   for i = 1:num_options
      opt = options((delim(i)+1):(delim(i+1)-1));
      if (strcmp (opt, 'xyzorder'))
	 reorder = 0;
      elseif (strcmp (opt, 'noflip'))
	 flip = 0;
      elseif (strcmp (opt, 'zerobase'))
	 onebase = 0;
      elseif (strcmp (opt, 'external'))
	 flip = 0;
	 onebase = 0;
      elseif (length (opt) > 0)
	 error (['unknown option: ' opt]);
      end
   end
   
   nargs = 2;
end

if (size(volume) ~= [1,1])
   error ('volume parameter must be an image handle');
end

% Get the raw voxel-to-world transform.  This one assumes it's
% converting voxel coordinates that are zero-based, unflipped, and
% in x,y,z order.

vw = getvoxeltoworld (volume);

% Get the matrix that reorders points from voxel to world order.

perm = getimageinfo (volume, 'permutation');
   
% Construct a matrix that converts from one-based to zero-based by
% subtracting one from each coordinate.

if (~onebase)
   shift = eye (4);
else
   shift = [1  0  0 -1 ; 
            0  1  0 -1 ; 
	    0  0  1 -1 ; 
	    0  0  0  1];
end

% Construct a matrix to compensate for the dimension conversion
% (flipping) done by mireadimages.  Note: this matrix assumes it
% operates on voxel-ordered points, hence the reordering of `steps'
% (which are output by getimageinfo in x,y,z order).

if (~flip)
   flip = eye (4);
else
   steps = getimageinfo (volume, 'steps');
   steps = inv(perm) * [steps; 1];
   lengths = getimageinfo (volume, 'dimsizes');
   lengths = lengths(2:4);			  % strip off frame count
   flip = diag (sign (steps));
   firstvoxel = (lengths-1) .* (steps(1:3) < 0);
   flip(1:3,4) = firstvoxel;
end

% Possibly override the permuation matrix found earlier (we don't
% do this up above because we might need `perm' to build `flip').

if (~reorder)
   perm = eye (4);
end

% Now put them all together to build the real voxel-to-world transform

vw = vw * perm * flip * shift;

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
   out = vw;

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

   points = vw * points;      % perform the transformation (may include
                              % reordering, shifting, and flipping)
   
   if (m == 3)                % if caller only supplied 3 rows, lose the 4th
      points = points (1:3,:);
   end
   out = points;

end
