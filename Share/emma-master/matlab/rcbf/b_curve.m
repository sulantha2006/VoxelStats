function integral = b_curve (args, shifted_g_even, ts_even, A, fstart, flengths)

% B_CURVE a two-compartment rCBF model used for delay correction
%
%     integral = b_curve (args, shifted_g_even, ts_even, A, ... 
%                         fstart, flengths)
%
% Used by blood delay correction, this function implements a
% two-compartment rCBF model used for fitting the blood
% curve data to the head curve data.

% $Id: b_curve.m,v 1.10 1997-10-20 18:23:25 greg Rel $
% $Name:  $

% ----------------------------- MNI Header -----------------------------------
% @NAME       : b_curve
% @INPUT      : 
% @OUTPUT     : 
% @RETURNS    : 
% @DESCRIPTION: 
% @METHOD     : 
% @GLOBALS    : 
% @CALLS      : 
% @CREATED    : 
% @MODIFIED   : 
% @COPYRIGHT  :
%             Copyright 1993 Mark Wolforth and Greg Ward, McConnell Brain
%             Imaging Centre, Montreal Neurological Institute, McGill
%             University.
%             Permission to use, copy, modify, and distribute this
%             software and its documentation for any purpose and without
%             fee is hereby granted, provided that the above copyright
%             notice appear in all copies.  The author and McGill University
%             make no representations about the suitability of this
%             software for any purpose.  It is provided "as is" without
%             express or implied warranty.
%
% ---------------------------------------------------------------------------- */

% N.B.: alpha = args(1)
%        beta = args(2)
%       gamma = args(3)

if (length(args) ~= 3), error ('Wrong number of fit parameters'), end;

% Now calculate exp (-beta * t) in the ts_even time domain, and perform
% the convolution with the *shifted* activity g(t-delta).

expthing = exp(-args(2)*ts_even); 	% ts_even for the convolution
c = nconv(shifted_g_even,expthing,ts_even(2)-ts_even(1));
c = c (1:length(ts_even));		% chop off points outside of the time
					% domain we're interested in

% Calculate the two main terms of the expression, alpha * (convoluted
% stuff) and gamma * (shifted activity), and sum them.

i1 = args(1)*c;				% alpha * (convolution)
i2 = args(3)*shifted_g_even;		% gamma * g(t - delta)

i = i1+i2;

% Integrate across each frame.

integral = nframeint (ts_even, i, fstart, flengths);

nuke = find (isnan (integral));
integral (nuke) = zeros (size (nuke));

integral = integral (1:length(A));
