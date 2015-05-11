function krn = kernel (fwhm, style)
% KERNEL   Create a 2D kernel with the specified full-width half-maximum
%
%  kern = kernel (fwhm [, style])
% 
% generates a square matrix containing a 2-D function with the 
% full-width half-maximum FWHM.  Currently the only available
% kernel style is 'gaussian'.  Note that the FWHM is specified
% with respect to matrix coordinates, rather than any physical
% system.  Thus, if you wish to generate a blurring kernel with
% FWHM of (say) 20 mm, you must first find out what physical size
% each pixel in your image corresponds to, and divide the desired
% FWHM by the pixel size to get the FWHM in pixel coordinates.
% 
% For a gaussian kernel, the size of the matrix is such that three
% standard deviations will fit in the kernel on either side of the
% origin (the centre of the matrix).  The kernel matrix will always
% have an odd number of rows/columns so that the Gaussian function
% is centred in the kernel.
%
% The kernel is always normalised such that convolving with it 
% (using conv2) preserves the magnitude of the other function
% (ie. the image).
% 
% SEE ALSO
%   conv2, smooth

% $Id: kernel.m,v 1.3 1997-10-20 18:23:23 greg Rel $
% $Name:  $

error (nargchk (1, 2, nargin));

if (nargin < 2)
   style = 'gaussian';
end;

if (strcmp (style, 'gaussian'))

   sigma = (0.72134752044448) * (fwhm/2)^2;   % N.B. magic # is 1/(2 ln 2)
   k = 6 * sqrt(sigma);
   k = ( ceil((k-1)/2) * 2)+1; 		% round to next odd integer

   % Find parameters to make the Gaussian fit the kernel: peak at k/2,
   % range -3 .. +3 std dev's from 1..k

   x = (-floor(k/2)):(floor(k/2));
   y = exp (-x.^2 / 2 / sigma);

   krn = zeros (k, k);
   for i = 1:k
      krn (i, :) = y * y (i);
   end

else
   error (['Invalid kernel type: ' style]);
end

krn = krn / sum(sum(krn));

