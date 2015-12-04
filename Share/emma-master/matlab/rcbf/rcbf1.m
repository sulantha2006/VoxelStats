function [K1,k2] = rcbf1 (filename, slice, progress)
% RCBF1 a one-compartment (double-weighted integral) rCBF model.
%
%        [K1,k2] = rcbf1 (filename, slice)
% 
% A one-compartment rCBF model (without V0 or blood delay and
% dispersion) implemented as a MATLAB function.  The compartmental
% equation is solved by integrating it across the entire study, and
% then weighting this integral with two different weights.  When these
% two integrals are divided by each other, K1 is eliminated, leaving
% only k2.  A lookup table is calculated, relating values of k2 to
% values of the integral.  From this, k2 can be calculated.  From k2,
% K1 is easily found by substitution into the original compartmental
% equation.  See the document "rCBF Analysis Using Matlab"
% (http://www.mni.mcgill/system/mni/matlab/rcbf/rcbf.html) for further
% details of both the compartmental equations themselves, and the
% method of solution.
% 
% Note: it is assumed that input PET data is in units of nCi/mL_tissue
% (= 37 Bq/mL_tissue = 37 Bq / 1.05 g_tissue).  This is converted to
% Bq/g_tissue for all internal calculations.  Blood data is input in
% Bq/g_blood; this is calibrated to the PET scanner (using the
% cross-calibration factor) and converted back to Bq/g_blood.  Thus,
% K1 is calculated internally as g_blood / (g_tissue * sec).  The
% final step of the rCBF analysis is to convert this to the more
% standard mL_blood / (100 g_tissue * min).  k2 is similarly converted
% to 1/min.

% $Id: rcbf1.m,v 1.25 1997-10-20 18:23:25 greg Rel $
% $Name:  $

% ----------------------------- MNI Header -----------------------------------
% @NAME       : rcbf1
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


% Input argument checking

if (nargin == 2)
    progress = 0;
elseif (nargin ~= 3)
    help rcbf1
    error('Incorrect number of arguments.');
end

if (length(slice)~=1)
    help rcbf1
    error('<Slice> must be a scalar.');
end

% Input arguments are checked, so now we can do some REAL work.

if (progress); disp ('Reading image information'); end

img = openimage(filename);
FrameTimes = getimageinfo (img, 'FrameTimes');
FrameLengths = getimageinfo (img, 'FrameLengths');
MidFTimes = FrameTimes + (FrameLengths / 2);

[g_even, ts_even] = resampleblood (img, 'even');

% Apply the cross-calibration factor to convert from Bq/g_blood to 
% nCi/mL_blood (taking into account the calibration from the well
% counter to the PET scanner).  Then convert right back to Bq/g_blood
% (but now calibrated with the scanner).

XCAL = 0.11;
g_even = g_even*XCAL*37/1.05;           % units are decay / (g_blood * sec)

Ca_even = g_even; 			% no delay/dispersion correction!!!

PET = getimages (img, slice, 1:length(FrameTimes));
rescale (PET, 37 / 1.05);               % convert to decay / (g_tissue * sec)
rescale (PET, PET > 0);                 % set all negative values to zero
ImLen = size (PET, 1);                  % num of rows = length of image

if (progress); disp ('Calculating mask and rL image'); end

PET_int1 = trapz (MidFTimes, PET')';
PET_int2 = trapz (MidFTimes, PET' .* (MidFTimes * ones(1,ImLen)))';

mask = PET_int1 > mean (PET_int1);
rescale (PET_int1, mask);
rescale (PET_int2, mask);

rL = PET_int1 ./ PET_int2;

if (progress); disp ('Calculating k2/rR lookup table'); end

k2_lookup = (0:0.02:3) / 60;
[conv_int1, conv_int2] = findintconvo (Ca_even, ts_even, k2_lookup,...
                            MidFTimes, FrameLengths, 1, MidFTimes);
rR = conv_int1 ./ conv_int2;

% Generate K1 and k2 images

if (progress); disp ('Calculating k2 image'); end
k2 = lookup(rR, k2_lookup, rL);

if (progress); disp ('Calculating K1 image'); end
k2_conv_ints = lookup (k2_lookup, conv_int1, k2);
K1 = PET_int1 ./ k2_conv_ints;

nuke = find (isnan (K1) | isinf (K1));
K1 (nuke) = zeros (size (nuke));

rescale (K1, 100*60/1.05);    % convert from g_blood / (g_tissue * sec)
                              % to mL_blood / (100 g_tissue * min)
rescale (k2, 60);             % from 1/sec to 1/min
			      
disp ('WARNING!!! rcbf1 now calculates K1 in mL_blood / (100 g_tissue * min)');

% Cleanup

closeimage (img);
