function [K1,k2,V0,delta] = rcbf2 (filename, slices, progress, ...
                                         correction, batch, tau)

% RCBF2 a two-compartment (triple-weighted integral) rCBF model.
%
%       [K1,k2,V0,delta] = rcbf2 (filename, slices ...
%                  [, progress [, correction [, batch [, tau]]]]] )
% 
% rcbf2 implements the three-weighted integral method of calculating
% k2, K1, and V0 (in that order) for a particular slice.  This
% function also returns the delay value calculated for blood
% correction.  It first reads in the brain activity for every frame of
% the slice, frame start times and lengths, plasma activity, and blood
% sample times.  Then, a simple mask is created and used to filter out
% roughly all points outside the head.
% 
% The optional arguments progress, correction, and batch control
% whether to print periodic progress reports, perform delay/dispersion
% correction, and automatically select the grey-matter mask used for
% delay/dispersion correction.  These all default to 1 (true); the
% latter two should only be set to 0 (false) in exceptional
% circumstances (i.e. never).  tau is also an optional argument
% that sets the dispersion constant; if it is not given, 4 seconds
% is assumed.
% 
% The actual calculations follow the procedure outlined in the
% document "RCBF Analysis Using MATLAB" (http://www.mni.mcgill/system/
% mni/matlab/rcbf/rcbf.html) .  Occasionally, comments in the source
% code or documentation for various functions involved in the analysis
% will refer to equations in this document.  The most relevant
% functions in this respect are rcbf2 itself, correctblood and
% findintconvos.
% 
% The starting point of the three-weighted integration method is Eq.
% 10 of the RCBF document.  The left hand side of this equation, rL,
% is calculated for every pixel.  Then, a lookup table relating a
% series of k2 values to rR (the right-hand side of Eq. 10) is
% calculated.  This lookup table should have a few hundred elements,
% as calculating rR is considerably more expensive than calculating
% rL.  Since rL and rR are equal, we use the pixel-wise values of rL
% to lookup (linearly interpolate) k2 for every pixel.
% 
% Then, the numerator of Eq. 10 is used to calculate K1.  This
% requires independently calculating the numerators of the left and
% right hand sides of the equation for every voxel, and taking their
% ratio to determine the exact value of K1 at that voxel.  However,
% since the right-hand-side is very expensive to compute, we make use
% of the fact that most of the information has already been calculated
% -- in particular, for the k2-rR lookup table.  This is then used to
% lookup values of the integrals needed, which are then combined to
% calculate the entire right hand side of Eq. 10.
% 
% Note: it is assumed that input PET data is in units of nCi/mL_tissue
% (= 37 Bq/mL_tissue = 37 Bq / 1.05 g_tissue).  This is converted to
% Bq/g_tissue for all internal calculations.  Blood data is input in
% Bq/g_blood; this is calibrated to the PET scanner (using the
% cross-calibration factor) and converted back to Bq/g_blood.  Thus,
% K1 is calculated internally as g_blood / (g_tissue * sec).  The
% final step of the rCBF analysis is to convert this to the more
% standard mL_blood / (100 g_tissue * min).  k2 and V0 are similarly 
% converted to 1/min and mL_blood / (100 g_tissue).

% $Id: rcbf2.m,v 1.36 1997-10-20 18:23:26 greg Rel $
% $Name:  $

% ----------------------------- MNI Header -----------------------------------
% @NAME       : rcbf2
% @INPUT      : 
% @OUTPUT     : 
% @RETURNS    : 
% @DESCRIPTION: 
% @METHOD     : 
% @GLOBALS    : 
% @CALLS      : 
% @CREATED    : 
% @MODIFIED   : November 22, 1993 by MW:
%                  Fixed a bug that would show up when the blood did not
%                  span the frames.  We now ignore the frames that are
%                  not spanned, and print a warning for the user.
%               May 27, 1997 by MW:
%                  Made a minor modification so that this code now works
%                  with Matlab 5.x and 4.x.
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

if (nargin < 2)
   help rcbf2
   error ('Not enough input arguments');
elseif (nargin < 3)
   progress = 1;
   correction = 1;
   batch = 1;   
   tau = 4;
elseif (nargin < 4)
   batch = 1;
   correction = 1;
   tau = 4;
elseif (nargin < 5)
   batch = 1;
   tau = 4;
elseif (nargin < 6)
   tau = 4;
elseif (nargin > 6)
   help rcbf2
   error('Incorrect number of arguments.');
end

img = openimage(filename);

total_slices = length(slices);
num_pixels = prod (getimageinfo (img, 'imagesize'));
K1 = zeros (num_pixels, total_slices);
k2 = zeros (num_pixels, total_slices);
V0 = zeros (num_pixels, total_slices);
delta = zeros(1,total_slices);

if (getimageinfo (img, 'time') == 0)
   error ('Study is non-dynamic');
end

FrameTimes = getimageinfo (img, 'FrameTimes');
FrameLengths = getimageinfo (img, 'FrameLengths');
MidFTimes = FrameTimes + (FrameLengths / 2);

% The blood data is initially in units of Bq/g_blood.  The cross-
% calibration factor, XCAL, converts this to nCi/mL_blood,
% simultaneously taking into account the unit conversions and
% equipment differences (well counter to PET scanner).  We then
% multiply by 37 (to convert nCi to Bq) and divide by 1.05 (to convert
% 1/mL_blood to 1/g_blood), thus returning to units of Bq/g_blood...
% but with equipment calibration factored in.

[g_even, orig_ts_even] = resampleblood (img, 'even');
XCAL = 0.11;
% Apply the cross-calibration factor.
rescale(g_even, (XCAL*37/1.05));        % units are decay / (g_blood * sec)

w1 = ones(length(MidFTimes), 1);
w2 = MidFTimes;
w3 = sqrt (MidFTimes);

k2_lookup = (-10:0.05:10) / 60;


for current_slice = 1:total_slices
  % Now start the real computation.  FrameTimes, FrameLengths, and 
  % MidFTimes should be self-explanatory.  Ca_even is the blood
  % activity resampled at some evenly-spaced time domain; ts_even
  % is the actual points of that domain.  Ca_mft is the blood activity
  % integrated frame-by-frame (ie. the average of Ca over every frame).
  
  if (progress)
    disp (['Doing slice ', int2str(slices(current_slice))]);
  end

  if (progress)
    disp ('Reading PET data for current slice');
  end
  
  ts_even = orig_ts_even;
  
  if exist('PET')
      PET = getimages (img, slices(current_slice), 1:length(FrameTimes), PET);
  else
      PET = getimages (img, slices(current_slice), 1:length(FrameTimes));
  end

  rescale (PET, (37/1.05));             % convert to decay / (g_tissue * sec)


  if (progress)
    disp ('Creating weighted integrals of the PET data');
  end

  PET_int1 = ntrapz (MidFTimes, PET, w1);
  PET_int2 = ntrapz (MidFTimes, PET, w2);
  PET_int3 = ntrapz (MidFTimes, PET, w3);

  
  % Now use PET_int1 to create a simple mask, and mask all three PET integrals.
  % This does a good job of removing the outside-of-head data for CBF studies.

  if (progress)
    disp ('Masking the weighted integrals.');
  end

  mask = PET_int1 > mean(PET_int1);
  rescale (PET_int1, mask);
  rescale (PET_int2, mask);
  rescale (PET_int3, mask);

  clear mask;
  
  % Use getmask to interactively create a threshold mask, and then perform
  % delay/dispersion correction.
  
  if (correction)
    
    if (progress)
      disp ('Performing delay/dispersion correction.');
    end

    % Since this is intended for batch mode operation,
    % we will fix the mask with a threshold of 1.8

    if (batch)
      mask = PET_int1 > (1.8*mean(PET_int1));
    else
      mask = getmask (PET_int1);
    end
       
    A = (mean (PET (find(mask),:)))';
    clear mask;
    
    % Perform the actual correction.
    
    [ts_even, Ca_even, delta(:,current_slice)] = correctblood ...
	  (A, FrameTimes, FrameLengths, g_even, ts_even, ...
	  tau, [], 1, progress);
  else
    if (progress)
      disp ('Skipping delay correction.');
    end

    Ca_even = g_even;
  end

  
  % Pick values of k2 and then calculate rR for every one.  (Ie. create
  % the lookup table).  This is done by first calculating various
  % weighted integrals (conv_int{1,2,3} and Ca_int{1,2,3}) which are
  % in turn used to calculate lots of other RCBF parameters.  Here 
  % we use them specifically to find rR.  NB. conv_int{1,2,3} are tables,
  % with one value for every k2 in k2_lookup.  However, Ca_int{1,2,3} are
  % simply scalars.
  
  
  if (progress); disp ('Generating k2/rR lookup table'); end
  [conv_int1,conv_int2,conv_int3] = findintconvo (Ca_even,ts_even,k2_lookup,...
      MidFTimes, FrameLengths, w1, w2, w3, progress);

  Ca_mft = nframeint (ts_even, Ca_even, FrameTimes, FrameLengths);      

  % NaN's will occur if the blood data does not span the frames.
  % We eliminate them here, thus ignoring the frames that are not
  % spanned by the blood data.  We print a warning message to
  % inform the user.
  
  select = ~isnan(Ca_mft);

  if (sum(select) ~= length(FrameTimes))
       disp('Warning: blood data does not span frames.');
  end
  
  Ca_int1 = ntrapz(MidFTimes(select), Ca_mft(select), w1(select));
  Ca_int2 = ntrapz(MidFTimes(select), Ca_mft(select), w2(select));
  Ca_int3 = ntrapz(MidFTimes(select), Ca_mft(select), w3(select));

  % Find the value of rL (LHS of Eq. 10) for every pixel, and the value
  % of rR (RHS of Eq. 10) for every value of k2 in k2_lookup.
  
  rL = ((Ca_int3 * PET_int1) - (Ca_int1 * PET_int3)) ./ ...
	((Ca_int3 * PET_int2) - (Ca_int2 * PET_int3));
  
  rR = ((Ca_int3 * conv_int1) - (Ca_int1 * conv_int3)) ./ ...
      ((Ca_int3 * conv_int2) - (Ca_int2 * conv_int3));

  % Now, we must have the k2/rR lookup table in order by rR; however, 
  % we also want to keep k2_lookup in the original order.  This
  % is because the first lookup uses rL as a lookup into rR to
  % find k2 (which requires that rR be monotonic, ie. sorted) whereas
  % subsequent lookups all use k2 to find conv_int{1,2,3} -- which 
  % requires that k2_lookup be monotonic.  So k2_lookup will be the
  % list of k2's in order, and k2_sorted will be the same list, but 
  % in order according to the sorted rR.
  
  [rR,sort_order] = sort (rR);
  k2_sorted = k2_lookup (sort_order);

  % Generate K1 and K2 images
  
  %=========================================================
  if (progress); disp ('Calculating k2 image (via table lookup)'); end
  k2(:,current_slice) = lookup(rR, k2_sorted, rL);
  
  
  %=========================================================
  if (progress); disp ('Calculating K1 image'); end
  
  % Note that PET_int1 = PET integrated across frames, with weighting
  % function w1 = ones.  The calculation of K1_numer is a tiny bit
  % redundant (see calculation of rR above), but the vector's involved
  % are fairly small (hundreds of elements, usually) so we don't worry
  % about it.

  K1_numer = ((Ca_int3*PET_int1) - (Ca_int1 * PET_int3));
  K1_denom = (Ca_int3 * lookup(k2_lookup,conv_int1,k2(:,current_slice))) - ...
      (Ca_int1 * lookup(k2_lookup,conv_int3,k2(:,current_slice)));
  K1(:,current_slice) = K1_numer ./ K1_denom;
  
  %=========================================================
  if (progress); disp ('Calculating V0 image'); end
  
  % Now calculate V0, using Eq. 7 (which is just Eq. 4, weighted and
  % integrated).
  
  V0(:,current_slice) = (PET_int1 - (K1(:,current_slice) .* lookup(k2_lookup,conv_int1,k2(:,current_slice)))) / Ca_int1;


  clear PET_int1 PET_int2 PET_int3
  clear k2_sorted sort_order
  clear conv_int1 conv_int2 conv_int3
  clear Ca_int1 Ca_int2 Ca_int3 Ca_mft
  clear K1_numer K1_denom
  clear rL rR
  clear ts_even Ca_even
  
end

nuke = find (isnan (K1));
K1 (nuke) = zeros (size (nuke));
nuke = find (isinf (K1));
K1 (nuke) = zeros (size (nuke));

nuke = find (isnan (V0));
V0 (nuke) = zeros (size (nuke));
nuke = find (isinf (V0));
V0 (nuke) = zeros (size (nuke));

rescale (K1, 100*60/1.05);    % convert from g_blood / (g_tissue * sec)
                              % to mL_blood / (100 g_tissue * min)
rescale (k2, 60);             % from 1/sec to 1/min
rescale (V0, 100/1.05);       % from g_blood/g_tissue to mL_b / (100 g_t)

disp('notice: rcbf2 calculates K1 in mL_blood / (100 g_tissue * min),');
disp('k2 in 1/min, and V0 in mL_blood / (100 g_tissue)');

% Cleanup

closeimage (img);
