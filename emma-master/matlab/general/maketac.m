function tac = maketac (x,y,pet)
% MAKETAC   Generate time activity curves from dynamic PET data
%
%    tac = maketac (x, y, pet)
% or
%    tac = maketac (offsets, pet)
% 
% 
% Generates a set of time-activity curves (TACs) from dynamic PET data.
% In the first example, a list of x and y voxel coordinates are
% specified by the x and y arguments.  These must be row vectors of the
% same length; if they are 1 x n, then maketac produces n
% TACs.  
% 
% In the second form, you specify a list of offsets into each slice.
% These are just the 1-D analogues of an (x,y) pair, which can be
% computed with the help of pixelindex.  offsets must be a row vector;
% if it is 1 x n, then n TACs will be computed.
% 
% The TACs themselves are computed from a 5x5 square of data around each
% specified point.  In particular, each voxel within that square
% contributes equally to a mean, which is extracted across all frames
% (columns) of the image data.  The size, shape, and weighting (or lack
% thereof) of this kernel are quite hard-coded and unlikely to change.
% 
% EXAMPLES
% 
%    tacs = maketac (1:128, 1:128, pet) 
% 
% gives you 128 TACs, pulled from data along the diagonal of your image
% (points (1,1), (2,2), ..., (128,128)).  If what you really wanted was
% to extract a TAC for every single voxel, you should use the
% offset-based form of calling maketac:
% 
%    tacs = maketac (1:16384, pet)
% 
% which is actually a bit of overkill; you can most likely get away with
% using a mask, as in
% 
%    summed_pet = ntrapz (getimageinfo (h, 'midframetimes'), pet')';
%    mask = summed_pet > mean (summed_pet);
%    tacs = maketac (find (mask)', pet);
%

% $Id: maketac.m,v 1.5 1997-10-20 18:23:20 greg Rel $
% $Name:  $

if (nargin < 2 | nargin > 3)
  help maketac
  error ('Incorrect number of input arguments');
end

if (nargin == 3)                        % supplied lists of x and y coordinates
   [nx,mx] = size (x);
   [ny,my] = size (y);
   if (nx ~= 1 | ny ~= 1 | mx ~= my)
      error ('x and y must be row vectors of the same length');
   end
else                                    % supplied just a list of offsets
   cp = x;
   pet = y;
   
   [n,m] = size (cp);
   if (n ~= 1)
      error ('offsets must be a row vector');
   end
end

% cp stands for centre_pixel; ll for line_length
% (yes, this *does* make the code clearer!)
ll = length(pet) ^ .5;
if (ll ~= floor(ll))
   error ('Image must be square.');
end

if (nargin == 3)
   cp = pixelindex ([ll ll], floor(x), floor(y));
end

% this is done in an explicit loop (rather than with the : operator)
% in order to allow for vector values of x and y (and thus of cp)
loc = zeros (25, length (cp));
for i = -2 : +2
   base = cp + (i*ll);
   loc ( (i+2)*5 + 1, : ) = base - 2;
   loc ( (i+2)*5 + 2, : ) = base - 1;
   loc ( (i+2)*5 + 3, : ) = base;
   loc ( (i+2)*5 + 4, : ) = base + 1;
   loc ( (i+2)*5 + 5, : ) = base + 2;
end

% Hmmm, would love a way to vectorize this loop.  Even so, it's not too
% horribly bad -- takes about 15 sec to compute all the TACs for one
% masked slice (~5500 voxels)

[n,num_points] = size (cp);
[n,num_frames] = size (pet);
tac = zeros (num_frames, num_points);
for i = 1 : num_points
   tac(:,i) = mean (pet (loc (:,i), :))';
end
