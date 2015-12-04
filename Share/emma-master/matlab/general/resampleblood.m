function [new_g, new_ts] = resampleblood (handle, type, samples)

%  RESAMPLEBLOOD  resample the blood activity in some new time domain
%
%  [new_g, new_ts] = resampleblood (handle, type[, samples])
%
%  reads the blood activity and sample timing data from the study
%  specified by handle, and resamples the activity data at times
%  specified by the string type.  Currently, type can be one of 'even'
%  or 'frame'.  For 'even', a new, evenly-spaced set of times will be
%  generated and used as the resampling times.  For 'frame', the mid
%  frame times will be used.  In either case, the resampled blood
%  activity is returned as new_g, and the times used are returned as
%  new_ts.
%
%  The optional argument samples specifies the number of samples
%  to take.  If it is not supplied, resampleblood will resample the
%  blood data at roughly 0.5 second intervals.

% $Id: resampleblood.m,v 1.7 1997-10-20 18:23:21 greg Rel $
% $Name:  $

if (nargin < 2) | (nargin > 3)
   help resampleblood
   error('Incorrect number of arguments');
end

if (~isstr (type))
   help resampleblood
   error('argument "type" must be a string');
end

% Get the original blood activity data, and the start/stop times for
% each sample.  The mid-sample times, ts_mid, are presumed to be the
% times at which each element of Ca is the blood activity, hence ts_mid
% is used as "old x" for any resampling.

[Ca, ts_mid] = getblooddata (handle);

% Perform a little sanity checking based on past unpleasant experiences

if (length (Ca) ~= length (ts_mid))
   error ('Blood activity data and sample times have different number of points');
end;

if (length (Ca) < 3)
   error ('Found less than three blood activity data points');
end;

if (any (ts_mid < 0))
   error ('Found blood sample times less than zero');
end;

if (all (Ca == 0) | all (isnan (Ca)) | all (isinf (Ca)))
   error ('Blood activity data points are all zero, all NaN, or all infinity');
end;

if (all (ts_mid == 0) | all (isnan (ts_mid)) | all (isinf (ts_mid)))
   error ('Blood sample times are all zero, all NaN, or all infinity');
end;

if (nargin == 2) 			% samples not supplied
   samples = ceil(2*(max(ts_mid)-min(ts_mid)));
end

if (strcmp (type, 'even'))
   new_ts = linspace (min(ts_mid), max(ts_mid), samples)';
   new_g = lookup (ts_mid, Ca, new_ts);
elseif (strcmp (type, 'frame'))
   tf_start = getimageinfo (handle, 'FrameTimes');
   tf_len = getimageinfo (handle, 'FrameLengths');
   new_ts = tf_start + (tf_len/2);
   new_g = lookup (ts_mid, Ca, new_ts);
else
   help resampleblood
   error(['Unknown sampling type: ' type]);
end
