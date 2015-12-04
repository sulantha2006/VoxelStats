function new_data = smooth (old_data)

% SMOOTH  do spatial smoothing on an image
%
%        new_data = smooth (old_data)
% 
% Smooths a two-dimensional image by averaging over a circle with a
% diameter of 5 pixels.  Note that a far better way to perform spatial
% smoothing is to generate a Gaussian kernel and perform a
% convolution; this function is only provided for backwards
% compatibility.  Two functions are available for more sophisticated
% smoothing: kernel (part of EMMA), to generate a Gaussian kernel; and
% conv2 (part of the MATLAB Image Processing Toolbox), to perform a
% fast 2-D convolution.

% $Id: smooth.m,v 1.7 1997-10-20 18:23:22 greg Rel $
% $Name:  $

if (nargin ~= 1)
   help smooth
   error ('Incorrect number of input arguments.');
end

kernel = [0 0 1 0 0; ...
          0 1 1 1 0; ...
          1 1 1 1 1; ...
          0 1 1 1 0; ...
          0 0 1 0 0  ];

kernel = kernel / sum(sum(kernel));

new_data = conv2 (old_data, kernel, 'same');
