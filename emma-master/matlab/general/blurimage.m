function img = blurimage (InputImage, FWHM)

% blurimage - Perform a 2D Gaussian blurring on an image
%
%
%     img = blurimage (InputImage, FWHM)
%
%
%  This function performs a 2D Gaussian blurring of an input image.  The
%  full-width half maximum (FWHM) of the blurring kernel is specified in
%  voxel coordinates (not spatial coordinates).
%
%  The input image may be either an EMMA standard vector image, or else a 2D
%  matrix containing an image.
%

% $Id: blurimage.m,v 1.2 1997-10-20 18:23:20 greg Rel $
% $Name:  $

%  Copyright 1994 Mark Wolforth, McConnell Brain Imaging Centre, Montreal
%  Neurological Institute, McGill University.
%  Permission to use, copy, modify, and distribute this software and its
%  documentation for any purpose and without fee is hereby granted, provided
%  that the above copyright notice appear in all copies.  The author and
%  McGill University make no representations about the suitability of this
%  software for any purpose.  It is provided "as is" without express or
%  implied warranty.


if (nargin~=2)
  help blurimage
  error ('Insufficient number of input arguments.');
end

kern = kernel (FWHM);

%
% Reshape the image appropriately
%

[x,y] = size (InputImage);

if ((x > 1) & (y > 1))
    xsize = x;
else
    xsize= x^.5;
    if (xsize ~= floor (xsize))
        error('Image must be square.');
    end
    if (y ~= 1)
        error('Image must be a vector if not square.');
    end
    InputImage = reshape (InputImage, xsize, xsize);
end

%
% Now perform the 2D convolution
%

img = conv2 (InputImage, kern, 'same');

%
% If the result is square, convert it back to a vector image.
%

[x,y] = size(img);

if (x==y)
  img = reshape(img,x*y,1);
end
