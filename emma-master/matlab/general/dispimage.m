function dispimage (img, colourmap, ncolours);

% VIEWIMAGE  displays an image from a vector or square matrix.
%
%    [fig_handle, image_handle, bar_handle] = ...
%        viewimage (img [, update [, colourbar_flag [, uiflag]]])
% 
%
% Displays an image using the MATLAB image function.  The only required
% argument, img, must be either a column vector representing an image
% (in the standard EMMA way), or a matrix containing the image in 2D.
% If the image is passed as a vector, it must be square; that is, the
% vector must have N^2 elements where the image is NxN pixels.  If the
% image is passed as an MxN matrix, then it will be displayed as MxN
% pixels.
%
% Before displaying, the image is scaled to fill the default
% colour map, and any NaN's or infinities in the image are set to the
% image minimum, so that they will display as black (with most
% colour maps, at least).  The default colour map is spectral on colour
% displays, or gray on monochrome displays.  (This is determined by
% the display depth; viewimage doesn't know about gray-scale displays,
% and will treat them as colour.)  The colour map can be changed,
% either with the MATLAB colormap function, or through viewimage's
% user interface features.
%
% Also by default, viewimage sets up a number of buttons and sliders
% to facilitate image viewing.  You can change the colourmap, brighten
% or darken the image, zoom in, or threshold the image.  Most of
% these are self-explanatory, but the image zoom option needs some
% explanation: basically, when zooming is activated (by pushing the
% "Zoom" button), you can select an area of the image by dragging
% with the left mouse button.  When you let go of the button, the
% selected rectangle will fill the display window.  This can be
% repeated as often as you wish, and you can zoom back out again
% (undoing one zoom step at a time) by clicking the middle mouse 
% button on the image.  (Note that there currently appears to be
% some sort of conflict between the MATLAB `zoom' function (which
% is used by viewimage to do the zooming) and viewimage's own
% user interface features; however, you can ignore the resulting 
% error messages.)
%
% Currently, viewimage forces all images to a square aspect ratio,
% regardless of their true size (either in voxel or world
% coordinates).  This will probably be fixed soon.  Also, it knows
% nothing about world coordinates anyway, so even if it did display
% non-square images properly, it still wouldn't get the aspect ratio
% right for images with anisotropic pixels.
%
% The optional arguments should all be either 0 or 1, and are:
% update    - if 1, viewimage will not redraw the user interface
%             buttons and sliders, nor will it redraw the colour bar.
%             Setting update to 1 when drawing new images can cause
%             errors.  [default: 0]
% colourbar - if 0, the colour bar will not be drawn [default: 1].
% uiflag    - if 0, the buttons and sliders will not be drawn [default: 1]

% $Id: dispimage.m,v 2.1 2000-04-10 16:02:11 neelin Exp $
% $Name:  $

%  Copyright 1993,1994 Mark Wolforth and Greg Ward, McConnell Brain
%  Imaging Centre, Montreal Neurological Institute, McGill
%  University.
%  Permission to use, copy, modify, and distribute this
%  software and its documentation for any purpose and without
%  fee is hereby granted, provided that the above copyright
%  notice appear in all copies.  The authors and McGill University
%  make no representations about the suitability of this
%  software for any purpose.  It is provided "as is" without
%  express or implied warranty.

% IDEAS...
%  - need a way to know both the image size (so we can properly reshape      
%    a vector) and the physical size of each pixel
%  - easily fetched from the MINC file, but what if image isn't 
%    associated with any MINC file?
%  - also need whole new calling convention for viewimage, e.g.
%    viewimage (img, 'handle', h, 'uiflag', 0, 'update', 1);  or
%    viewimage (img, 'imgsize', [128 15], 'pixelsize', [2 6.5]);
%    This is nicely extensible and elegant, but is it too cumbersome
%    for the user?  Would having a long list of required parameters
%    really be any easier, though?

if (nargin < 1)
  help viewimage
  error ('Too few input arguments.');
end
if (nargin < 3)
  ncolours = 64;
end
if (nargin < 2)
  colourmap = 'spectral';
end

% Reshape the image appropriately
[x,y] = size (img);

if ((x > 1) & (y > 1))             % image passed as a matrix, so accept size
    xsize = x;
else                               % image passed as a vector - must be square
    xsize= x^.5;
    if (xsize ~= floor (xsize))
        error('If image is passed as a vector, it must have N^2 elements for some integer N');
    end
    if (y ~= 1)
        error('Image cannot be a row vector (must be either a matrix or column vector)');
    end
    img = reshape (img, xsize, xsize);
end

% Flip the image
img=fliplr(img);

% If any NaN's or infinities are present in the image, find the min/max
% of the image *without* them, and assign them all to the minimum -- that 
% way they will display as black.

nuke = (isnan (img) | isinf (img));
if any (any (nuke))
  lo = min(img(~nuke));
  hi = max(img(~nuke));
  disp ('viewimage warning: image contains NaN''s and/or infinities');
  nuke = find(nuke);
  img(nuke) = zeros (size (nuke));
else
  lo = min(min(img));
  hi = max(max(img));
end

eval(['colormap(' colourmap '(' num2str(ncolours) '));']);

% Shift/scale img so that it maps onto 1..length(colourmap).

num_colors = length (colormap);
img = ((img - lo) * ((num_colors-1) / (hi-lo))) + 1;

% Now display it

image (img');

if (~exist('OCTAVE_VERSION'))
  axis('square');
end

