function index = pixelindex (img,col,row)
% PIXELINDEX  generates the vector index of a point
%
%       index = pixelindex (img,col,row)
% 
% generates the vector index of the col and row coordinates of a pixel
% in an image.  col and row are, respectively coordinates along the
% fastest- and second-fastest varying dimensions of an image volume
% (the "image dimensions", which are what vary over a single image).
% 
% img is either an image handle or a 2x1 vector describing the size of
% each image of the form returned by getimageinfo's `imagesize'
% option.  That is, the first number is the number of pixels in the
% image "height" dimension, and the second number is the number of
% pixels in the "width" dimension.  ("Height" and "width" are
% respectively the second-fastest and fastest-varying dimensions in
% the volume.)
% 
% EXAMPLES
% 
% If the image is 128x128 pixels, then the vector index will be from
% 1..16384; pixel (col,row) = (37,24) will translate as follows:
%
%     index = width*(row-1) + col = 128*23 + 37 = 2981
% 
% where width = img(2).
% 
% Note that the first pixel in an image has coordinates (1,1), which
% works out to index 1; the last pixel (in the above example) has
% coordinates (128,128), which works out to index 128*127+128 = 16384.

% $Id: pixelindex.m,v 1.4 1997-10-20 18:23:19 greg Rel $
% $Name:  $

% by Greg Ward 95/3/16 (from the obsolete calpix.m)

error (nargchk (3, 3, nargin));

if (size(img) == [1 1])
   imgsize = getimageinfo (img, 'imagesize');
elseif (size(img) == [1 2] | size(img) == [2 1])
   imgsize = img;
else
   error ('img must be either an image handle or a 2x1 vector');
end

index = imgsize(2) * round(row-1) + round(col);
