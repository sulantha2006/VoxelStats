function mask = getmask (image)
% GETMASK returns a mask that is the same size as the passed image.
%
%     mask = getmask (image)
%
% The mask consists of 0's and 1's, and is created interactively by
% the user.  Currently, a threshold algorithm is used, based on the input
% argument image: the user selects a threshold using a slider (the default
% starting value is 1.8), and getmask selects all points in image greater
% than the mean value of the entire image multiplied by threshold the
% threshold.  It then displays image as masked by that threshold value, so
% the user can refine the threshold to his/her satisfaction.

% $Id: getmask.m,v 1.8 1997-10-20 18:23:20 greg Rel $
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


if (nargin ~= 1)
   help getmask;
   error ('Incorrect number of input arguments.');
end

img = image;                            % copy because it is made global
mu = mean(mean(img)); 			% in case it happens to be square
threshold = 1.8; 			% initial value (from Hiroto)
temp = img > threshold * mu; 		% "binary" temp - all 1's and 0's
[fh, iah] = viewimage (temp .* img); 	% returns handles: figure, image axes

pos = get (iah, 'Position');
pos (2) = pos(2) + 1.09*pos (4);	% assuming normalised units
pos (4) = .05;

tobj = text('units', 'normal', 'position', [1.05 1.12], 'string', num2str(threshold));

slider_cmd = ['global slider mu tobj temp img threshold;'...
              'threshold = get (slider, ''value'');'...
              'temp = img > threshold*mu;'...
	      'viewimage (img .* temp, 1, 0);'...
	      'tobj = text(''units'', ''normal'', ''position'', [1.05, 1.12], ''string'', num2str(threshold));'];
slider = uicontrol ('Style', 'slider', 'units', 'normal', 'Position', pos,...
      'min', 1, 'max', 3, 'value', threshold, 'CallBack', slider_cmd);

global slider mu tobj temp img threshold
drawnow;
input ('Press [Enter] when done.');
delete (slider); 
delete (tobj);
mask = temp;
clear global slider mu tobj img temp threshold
