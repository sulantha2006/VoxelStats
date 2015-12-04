function [int1, int2, int3] = findintconvo (Ca_even, ts_even, k2_lookup,...
                                     midftimes, flengths, w1, w2, w3, progress)

% FINDINTCONVO   calculate tables of the integrated convolutions commonly used
%
%   [int1,int2,int3] = findintconvo (Ca_even, ts_even, k2_lookup,...
%                                    midftimes, flengths, w1[, w2[, w3]])
% 
% given a table of k2 values, generates tables of weighted integrals
% that commonly occur in RCBF analysis.  Namely, int_convo is a table
% of the same size as k2_lookup containing
%
%       int ( conv (Ca(t), exp(-k2*t)) * weight )
% 
% where the integration is carried out across frames.  weight is one
% of w1, w2, or w3, each of which will generally be some simple
% function of midftimes.  findintconvo will return int2 if and only if
% w2 is supplied, and int3 if and only if w3 is supplied.  w1 is
% required, and int1 will always be returned.  Normally, the weight
% functions should be vectors with the same number of elements as
% midftimes; however, if w1 is empty then the weighting function is
% taken to be unity.  (If w2 or w3 are empty, they are NOT assumed to
% be unity -- they are treated as though they were not even supplied.)
% 
% Note that in order to correctly calculate the convolution, Ca(t)
% must be resampled at evenly spaced time intervals, and this
% resampled blood activity should be passed as Ca_even.  The times at
% which it is sampled should be passed as ts_even.  (These can be
% calculated by resampleblood before calling findconvints.)
% 
% Then, the convolution of Ca(t) and exp(-k2*t) is integrated across
% each individual frame (a slightly more sophisticated approach than
% simply resampling at the mid-frame times) and integrated across all
% frames using flengths as dt.

% $Id: findintconvo.m,v 1.16 1997-10-20 18:23:25 greg Rel $
% $Name:  $

% ----------------------------- MNI Header -----------------------------------
% @NAME       : findintconvo
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


if ((nargin < 6) | (nargin > 9))
    help findintconvo
    error ('Incorrect number of input arguments.');
end

% Get size of various time vectors - needed for initialization below

NumEvenTimes = length(ts_even);
NumFrames = length(midftimes);
fstart = midftimes - (flengths / 2);

% Now we need to calculate the function to convolve with Ca_even
% [a/k/a Ca(t)].  A note on the variables: exp_fun and convo
% represent, respectively, the functions exp (-k2 * t) and
% conv(Ca(t), exp (-k2 * t)).  (The t here is ts_even.)  integrand 
% is just convo integrated across each individual frame (i.e. we 
% go from having several hundred elements -- the size of the ts_even
% sampling -- to having one element per frame).  Then, integrand is
% multiplied by the various weighting functions and integrated across
% all frames to give the final results (one number per weighting
% function, per value of k2).  Iterating across all values of k2 gives
% the vectors conv_int{1,2,3}.

TableSize = length (k2_lookup);
integrand = zeros (NumFrames, 1);           % this is integrated across frames

if (nargin >= 6); int1 = zeros (1, TableSize); end;
if (nargin >= 7); int2 = zeros (1, TableSize); end;
if (nargin >= 8); int3 = zeros (1, TableSize); end;
if (nargin < 9)
   progress = 1;
end

% if w1 is empty, assume that it should be all ones

if isempty (w1)
   w1 = ones (size(NumFrames));
end

[status, num_cols] = unix ('tput cols');
update_limit = ceil(TableSize/str2num(num_cols));

for i = 1:TableSize

   if (progress)

     %
     % Print some status dots if necessary
     %
    
     if (rem(i,update_limit) == 0)
       fprintf ('.');
     end
   end

   exp_fun = exp(-k2_lookup(i) * ts_even);
   convo = nconv(Ca_even, exp_fun, ts_even(2) - ts_even(1));

   integrand = nframeint (ts_even, convo(1:length(ts_even)), fstart, flengths);

   select = ~isnan(integrand);

   % w1 given?

   if (nargin >= 6)
      int1 (i) = ntrapz(midftimes(select), integrand(select), w1(select));
   end
   
   % w2 given, and not empty? then calculate the second convolution integral

   if (nargin >= 7)
      if (~isempty (w2))
         int2 (i) = ntrapz(midftimes(select), integrand(select), w2(select));
      end
   end

   % w3 given, and not empty?
   
   if (nargin >= 8)
      if (~isempty (w3))
         int3 (i) = ntrapz(midftimes(select), integrand(select), w3(select));
      end
   end
end
