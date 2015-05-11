% NFRAMEINT   integrate a function across a range of intervals (frames)
%
%   integrals = nframeint (ts, y, FrameStarts, FrameLengths)
%
% calculates the integrals of a function (represented as a set of points
% in y, sampled at the time points in ts) across each of a set of frames
% which are given by their start times and lengths.  The integral is then
% normalised so that nframeint returns the average value of y (as a function
% of ts) across each frame.
%
% ts and y must be vectors of the same length, as must FrameStarts and 
% FrameLengths.  Normally, ts and y are a good deal longer than
% FrameStarts and FrameLengths in order to get reasonably accurate 
% results.  The returned variable, integrals, will be a vector of
% the same length of FrameStarts and FrameLengths, containing the 
% integral of y(ts) across each frame.
%
% Points of y to integrate for each frame are selected by finding all
% points of ts that are greater than the frame start time and less than
% the frame stop time.  If possible, y is then linearly interpolated at
% the frame start and stop times to form a closed interval.  Then, a
% trapezoidal integration across those points is calculated, and the
% integral is divided by the width of the interval across which y
% is known within the frame.  Normally, this will simply be the length
% of the frame.  However, it may be that the lowest value of ts is
% greater than the frame start or the highest value of ts is lower than
% the frame stop time.  In these cases, y is not known outside of the
% frame, and cannot be resampled at the frame endpoints; so, the integration
% will only be performed across known points, and the integral will
% be divided not by the length of the frame but by the width of the interval
% across which y is known.

% $Id: nframeint.m,v 1.3 1997-10-20 18:23:21 greg Rel $
% $Name:  $

% (NFRAMEINT is a CMEX version of frameint.m.  nframeint.c written
% by Mark Wolforth, 93/8/12; modified by Greg Ward, 93/8/12 - 93/8/13.)
