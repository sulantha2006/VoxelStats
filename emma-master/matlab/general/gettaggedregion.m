function values = gettaggedregion (volume, tags, progress)
% GETTAGGEDREGION  read in all voxel values for a labelled region
%
%   values = gettaggedregion (volume, tags [, progress])
% 
% reads the voxel values of every point specified by tags, and returns them
% as a column vector.  If there are N tag points, then the returned vector
% will have at most N values.  (It is possible to have multiple tag points
% map to a single voxel, for example when a region is drawn on
% high-resolution MRI data, and then applied to low-resolution PET data.
% In this case, gettaggedregion removes duplicate points.)
% 
% Tag points may be specified either as a filename (which will be loaded
% with loadtagfile), or as a matrix of points.  If the tags are specified
% as a matrix, it must have N columns (for N points) and three rows (for
% the three spatial dimensions).  (Alternately, a four-row form is
% acceptable: three rows for the three spatial dimensions, plus a row of
% all ones.  This is the format of data returned by loadtagfile.)
% 
% If the image volume is dynamic, then values will be returned as a
% matrix with one column of values per frame.
% 
% The volume argument must be an image handle as returned by openimage
% or newimage.
% 
% If the optional argument progress is one, then gettaggedregion will
% print out progress information as it goes.

% $Id: gettaggedregion.m,v 1.3 1997-10-20 18:23:24 greg Rel $
% $Name:  $

% by Greg Ward 95/11/9

err = nargchk (2, 3, nargin);
if (err)
   help gettaggedregion
   error (err);
end

if (nargin < 3)
   progress = 0;
end

if (isstr (tags))
   tags = loadtagfile (tags);
end

[n,num_tags] = size (tags);
if (n < 3 | n > 4)
   error ('tags argument must have either 3 or 4 rows, and one column per point');
end

% 
% Get the voxel coordinates of the tagged points, and then remove
% duplicate points.
% 

num_slices = getimageinfo (volume, 'NumSlices');
vtags = round (worldtovoxel (volume, tags));
diffs = vtags(1:3,1:num_tags-1) - vtags(1:3,2:num_tags);
keep = find ([1 any(diffs)]);
vtags = vtags(:,keep);
num_tags = length (keep);


% 
% Pull out the slice coordinates, sort them, and remove duplicate slice
% numbers.  Then, make sure they're reasonable (ie. not outside the
% range of slices in the volume).
% 

slices = vtags(1,:);
unique_slices = sort (slices);
unique_slices = unique_slices (find ([1 diff(unique_slices)]));

% 
% Extract the pixel coordinates (ie. coords for the two image
% dimensions) and convert them to indeces into the image vector.
% 

coords = vtags(2:3,:);
index = pixelindex (volume, coords(2,:), coords(1,:));

if (slices(1) < 1 | slices(num_tags) > num_slices)
  error('illegal tag points: slice coordinates out of range');
end

% 
% Check if the volume has a time dimension; if so, we'll read all
% frames and output one vector of values per frame.
% 

num_frames = getimageinfo (volume, 'NumFrames');
if (num_frames > 0)
   frames = 1:num_frames;
else
   frames = [];
   num_frames = 1;         % just for allocating values
end

if (progress), fprintf ('reading slices: '), end;

values = zeros (num_tags, num_frames);

for sl = unique_slices
   if (progress), fprintf ('%d..', sl), end;

   % Read the current slice from disk

   img = getimages (volume, sl, frames);
   
   % Find which tag points are in that slice
   
   select = find (slices == sl);
   
   % Pull out the values for those pixels and stuff them into
   % the appropriate place in the return variable.

   values(select,:) = img(index(select),:);
   
   clear img select
end

if (progress), fprintf ('done\n'), end;
