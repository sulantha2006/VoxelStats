function xfm = getvoxeltoworld (volume)
% GETVOXELTOWORLD  Build the voxel-to-world coordinate transform for a volume
%
%   xfm = getvoxeltoworld (volume)
% 
% returns the 4x4 transformation matrix to convert voxel coordinates
% to world coordinates.  This matrix assumes that 1) the voxel
% coordinates are zero-based (C conventions, not MATLAB), 2) the voxel
% coordinates are in (x,y,z) order, and 3) the coordinates are
% relative to unflipped dimensions.  If this is not the case, you
% should be using voxeltoworld and worldtovoxel, as they take care of
% these issues for you.
% 
% The voxel-to-world transformation matrix is derived from the volume's
% step sizes, start coordinates, and direction cosines.  See the source
% for how this is done.
% 
% The volume argument must be an image handle as returned by openimage
% or newimage.
% 
% getvoxeltoworld is a fairly low-level function; usually, you should
% use voxeltoworld or worldtovoxel.  These functions both use
% getvoxeltoworld for their first step, but they also correctly handle
% issues of array indexing, coordinate ordering, and dimension
% conversion.  These issues are kind of hairy, but quite important
% when you wish to do coordinate conversions in MATLAB.  Usually, you
% can let the two higher-level functions take care of them, but if you
% really want to know the gory details, read on.
% 
% First, you must consider the base index of arrays.  In C (and thus in
% most MINC utilities and applications), the first element of an array
% is element 0.  Thus, voxel coordinates start at (0,0,0); in a volume
% with all positive step sizes, this will be the inferior, posterior,
% left-most corner of the volume.  However, the convention in MATLAB is
% to number arrays starting at 1.  EMMA uses this convention, so (for
% instance) slice numbers passed to getimages or putimages start at 1,
% row/column coordinates within an image start at 1, etc.  Thus, one of
% the steps in translating world coordinates to voxel coordinates *for
% use within MATLAB* must be to add/subtract 1 to/from voxel
% coordinates.  If you use the transform matrix returned by
% getvoxeltoworld, this will *not* be done -- you should use
% voxeltoworld and/or worldtovoxel.  However, if you're performing the
% coordinate transformation for use by utilities *outside* of MATLAB,
% you should stick to the zero-based convention.  This can be done by
% using the 'external' option with voxeltoworld and worldtovoxel.
%
% Next, you must consider dimension ordering.  The canonical order, and
% the way in which world coordinates are *always* specified, is (x,y,z).
% However, MINC volumes can be stored in a variety of orders; the most
% common are transverse (z,y,x), coronal (y,z,x), or sagittal (x,z,y).
% When coordinates are specified in this order, it's easy to pick out
% the slice number -- it's just the first coordinate.  Likewise, the
% "row" coordinate is the second, and the "column" coordinate is the
% last.  (These are called row and column coordinates because it makes
% anatomical sense to display volumes with one of the three standard
% orientations such that the fastest-varying dimension is horizontal on
% the screen, and the second-fastest-varying dimension is vertical.
% Volumes with non-standard orientations, such as "xyz", will *not* look
% right when displayed this way... but viewimage does it anyways.)
%
% Since you always specify coordinates in MATLAB by slice, row, and
% column (ie. in voxel order), then we obviously need something to take
% us from world order (x,y,z) to voxel order.  This is the "permutation
% matrix" P, which is simply a 4x4 identity matrix with the rows
% reordered according to the volume's dimension ordering.  The
% `permutation' option to getimageinfo will give you the permutation
% matrix to go from voxel order to world order.  (To go the opposite
% direction, simply invert the permutation matrix.  Actually, since it's
% an orthogonal matrix, you really only need to transpose it, if you're
% really worried about shaving off every possible clock cycle.)
%
% Finally, there is dimension conversion to worry about.  The only form
% of dimension conversion performed when EMMA reads a MINC file is
% dimension flipping, so that data always has a positive orientation.
% Thus, for any flipped dimensions, voxel coordinates have to be
% subtracted from the maximum voxel index for use with EMMA.  For
% instance, if a volume's x dimension has 128 elements and a negative
% step size, then external voxel coordinate 10 corresponds to EMMA voxel
% coordinate 118 (128 - 10).
%
% EXAMPLES
%
% To convert a point from voxel coordinates in voxel order to world
% coordinates in world order, neglecting array indexing and dimension
% flipping:
%
%      T = getvoxeltoworld (volume);
%      P = getimageinfo (volume, 'permutation');
%      v = [50 30 10 1]';
%      w = T * P * v;
%
% Here T is the basic voxel-to-world transform, and P reorders points
% from voxel to world order.  Note the order of application of the two
% matrices: we first reorder v, and *then* apply T.  This is because T
% is meant to be applied to points in x,y,z (world) order, so
% voxel-ordered points *must* be reordered before applying T to them.
%
% Ignoring the issue of array indexing (here everything must be
% zero-based, as getvoxeltoworld makes no adjustment for the one-based
% MATLAB world), this is more or less what the voxeltoworld function
% does.
%
% Note that P is applied first (to reorder the point to world order),
% and then T is applied -- the transform matrix returned by
% getvoxeltoworld assumes that the voxel points will be in (x,y,z)
% order.  You could, of course, post-multiply T by P to get a
% voxel-to-world matrix that expects voxel coordinates in voxel order.
%
% SEE ALSO
%   voxeltoworld, worldtovoxel

% $Id: getvoxeltoworld.m,v 1.5 2000-04-10 16:00:52 neelin Exp $
% $Name:  $

% by Greg Ward 95/3/10

%
% Get image information - steps, starts, and direction cosines
%

if (size(volume) == [1,1])
   filename = handlefield(volume, 'Filename');
else
   error ('volume argument must be an image handle');
end

% Get the volume parameters needed for the voxel-to-world transform

step = diag (getimageinfo (volume, 'Steps'));
dircos = getimageinfo (volume, 'DirCosines');
start = getimageinfo (volume, 'Starts');

% And construct the transform (no explanation offered because
% I don't really understand this).

xfm = [dircos * step, dircos * start];
xfm = [xfm; 0 0 0 1];
