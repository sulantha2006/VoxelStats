function msg = check_sf (handle, slices, frames)
%  CHECK_SF  determine the validity of slice and frame lists (internal use)
%
%      msg = check_sf (handle, slices, frames)
%
%  examines the lists of slices and frames, compares them to the 
%  properties of the MINC file specified by handle, and generates
%  a reasonably useful error message if there's any inconsistency.
%  check_sf is meant to be called by other EMMA functions, particularly
%  getimages and putimages.
%
%  The specific conditions that cause an error message are:
%
%     - both slices and frames have multiple values
%     - the file has no time dimension, but a frame list was given
%     - the file has a time dimension, but no frame list was given
%     - the file has no slice dimension, but a slice list was given
%     - the file has a slice dimension, but no slice list was given
%     - there were out-of-range frames: frame number either greater than
%       the number of frames or less than one
%     - there were out-of-range slices
%
%  If there are no problems, then the empty matrix is returned.

% $Id: check_sf.m,v 1.8 2000-04-10 16:00:50 neelin Exp $
% $Name:  $

msg = [];

% First retrieve the number of frames and slices

dim_sizes = handlefield(handle, 'DimSizes');
num_frames = dim_sizes(1);
num_slices = dim_sizes(2);

if (length(slices) > 1) & (length(frames) > 1)
   msg = 'Cannot specify both multiple slices and multiple frames';
end

if (num_frames == 0)
   if ~isempty (frames)
%     disp ('Warning: image has no frames, frame list will be ignored');
      msg = 'Image has no time dimension: list of frames not allowed';
   end
end

if (isempty (frames)) & (num_frames > 0)
   msg = 'Image has a time dimension; you must specify frames';
end

if (num_slices == 0)
   if ~isempty (slices)
%     disp ('Warning: image has no slices, slice list will be ignored');
      msg = 'Image has no slice dimension: list of slices not allowed';
   end
end

if (isempty (slices)) & (num_slices > 0)
   msg = 'Image has a slice dimension; you must specify slices';
end

if (find (slices > num_slices | slices <= 0))
   msg = 'Out-of-range slice number given';
end

if (find (frames > num_frames | frames <= 0))
   msg = 'Out-of-range frame number given';
end

