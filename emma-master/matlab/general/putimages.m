function putimages (handle, images, slices, frames)
%PUTIMAGES  Writes whole images to an open MINC file.
%
%      putimages (handle, images [, slices [, frames]])
%
%  writes images (a matrix with each column containing a whole image)
%  to the MINC file specified by handle, at the slices/frames specfied
%  by the slices/frames vectors.
%
%  Note that only one of the vectors slices or frames may have multiple
%  elements; ie., you may not write multiple slices and multiple frames
%  simultaneously.  (This should not be a problem, since you cannot *read*
%  multiple frames and slices simultaneously either.)  If both slices
%  and frames are present in the MINC file, then both slices and frames
%  vectors must be supplied and be non-empty.  If either of those 
%  dimensions are not present, though, then the associated vector must
%  be either omitted or empty.  
%
%  EXAMPLES
%    
%    To write zeros to an entire slice (say, 21 frames of slice 7) of
%    a full dynamic MINC file with 128x128 images [already opened with
%    handle = newimage (...)]:
%
%      images = zeros (16384,21);
%      putimages (handle, images, 7, 1:21);
%
%    To write random data to a single slice (7) of a non-dynamic file 
%    (again 128x128 images):
%
%      image = rand (16384, 1);
%      putimages (handle, image, 7);
%
%  SEE ALSO  newimage, openimage, getimages

% ------------------------------ MNI Header ----------------------------------
%@NAME       : putimages
%@INPUT      : handle - to an already-created image in MATLAB
%              images - matrix of images, where the columns of the matrix
%              contain whole images laid out linearly
%              slices, frames - vectors describing which slices/frames
%              the columns of images correspond to.  Only one of these
%              vectors may have multiple elements, i.e. all the columns
%              of images must correspond to either a certain slice and
%              various frames (listed in the frames vector) or a certain
%              frame and various slices (listed in the slices vector).
%@OUTPUT     : 
%@RETURNS    : (none)
%@DESCRIPTION: Write images to the MINC file associated with handle.  If
%              there is no such MINC file, no action is taken.
%@METHOD     : 
%@GLOBALS    : 
%@CALLS      : miwriteimages (if there is a MINC file)
%@CREATED    : June 1993, Greg Ward & Mark Wolforth
%@MODIFIED   : 93-7-5, Greg Ward: foisted most of the work onto miwriteimages
%              (the .m file, not the CMEX routine).
%@VERSION    : $Id: putimages.m,v 1.9 2000-04-10 16:00:53 neelin Exp $
%              $Name:  $
%-----------------------------------------------------------------------------


if ((nargin < 2) | (nargin >4))
    help putimages
    error ('Incorrect number of arguments.');
end
 
Flags = handlefield(handle, 'Flags');
if (~ Flags(1))
   error ('Cannot write to a read-only file');
end

% if frames not supplied, make it empty

if (nargin < 3)
   slices = [];
end

if (nargin < 4)
   frames = [];
end

% figure out number of images we expect to see in matrix images

if (isempty (slices) & isempty (frames))
   num_required = 1;
else
   num_required = max (length(slices), length(frames));
end

% check that slices and frames are valid

error (check_sf (handle, slices, frames));

% N.B. number of rows in images is the image length (eg., 16384 for 
% 128 x 128 images); number of columns is the number of images specified.
% This must be the same as the number of elements in whichever of slices
% or frames has multiple elements.

[im_len, num_im] = size (images);

if (num_required ~= num_im)
   errmsg = sprintf ('%d slices and %d frames were specified, which means I need to write %d images into the file -- but the image matrix has %d columns',...
            length(slices), length(frames), num_required, num_im);
   error (errmsg);
end

% Get the file name

filename = handlefield(handle, 'Filename');

if ~isempty (filename)        % write images to MINC file if there is one
   miwriteimages (filename, images, slices, frames);
else
   disp ('Warning: cannot put images without a filename');
end
