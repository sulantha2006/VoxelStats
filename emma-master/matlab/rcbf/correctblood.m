function [new_ts_even, Ca_even, delta] = correctblood ...
      (A, FrameTimes, FrameLengths, g_even, ts_even, ...
       tau, delta, do_delay, progress)

% CORRECTBLOOD  perform delay and dispersion corrections on blood curve
%
%  [new_ts_even, Ca_even, delta] = correctblood (A, FrameTimes, ...
%                                     FrameLengths, g_even, ts_even, ...
%                                     tau, delta, do_delay, progress)
%
%  The required input parameters are: 
%      A - brain activity, averaged over all gray matter in a slice.  This
%          should be in units of decay / (gram-tissue * sec), and should
%          just be a vector - one value per frame.
%      FrameTimes - the start time of every frame, in seconds
%      FrameLengths - the length of every frame, in seconds
%      g_even - the (uncorrected) arterial input function, resampled at
%               some *evenly spaced* time domain.  Should be in units
%               of decay / (mL-blood * sec)
%      ts_even - the time domain at which g_even is resampled
%
%  Optional input parameters:
%      tau - the dispersion constant (default: 4 sec)
%      delta - the delay constant; only used if do_delay is 0
%      do_delay - boolean variable that controls whether to perform delay 
%                 correction (i.e. compute a value of delta) 
%                 (default: 1, to do the correction)
%      progress - 0 for total silence (except for errors)
%                 1 for minimal progress messages
%                 2 for lots of progress messages
%                 3 for lots of messages and graphical updates of the fitting
%
%  The returned variables are:
%      new_ts_even - generally the same as the old time scale,
%                    with some points missing from the end.
%      Ca_even - g_even with dispersion and delay hopefully corrected,
%                in units of decay / (mL-blood * sec).  
%      delay - the delay time (ie. shift) in seconds
%
%  A, FrameTimes, and FrameLengths must all be vectors with the same
%  number of elements (presumably the number of frames in the study).
%  g_even and ts_even must also be vectors with the same number of
%  elements, but their size should be much larger, due to the
%  resampling at half-second intervals performed by resampleblood.
%  
%  correctblood corrects for dispersion in blood activity by
%  calculating g(t) + tau * dg/dt, where tau (the dispersion time
%  constant) is taken to be 4.0 seconds.
%
%  It then attempts to correct for delay by fitting a theoretical blood
%  curve to the observed brain activity A(t).  This curve depends
%  on the parameters alpha, beta, gamma (these correspond to K1, k2,
%  and V0, although for the entire slice rather than pixel-by-pixel) and
%  delta (which is the delay time).  correctblood steps through a series
%  of delta values (currently -5 to +10 sec), and performs a three-
%  parameter fit with respect to alpha, beta, and gamma; the value of
%  delta that results in the best fit is chosen as the delay time.

% ------------------------------ MNI Header ----------------------------------
%@NAME       : correctblood
%@INPUT      : A, FrameTimes, FrameLengths, g_even, ts_even, 
%              tau, delta, do_delay, progress
%@OUTPUT     : new_ts_even, Ca_even, delta
%@RETURNS    : 
%@DESCRIPTION: Performs delay and dispersion correction of blood data.
%@METHOD     : 
%@GLOBALS    : 
%@CALLS      : deriv, lookup, delaycorrect, fit_b_curve
%@CREATED    : 93/7/21, Greg Ward
%@MODIFIED   : Lots.  See rcs log.
%@VERSION    : $Id: correctblood.m,v 1.24 1997-10-20 18:23:25 greg Rel $
%              $Name:  $
%-----------------------------------------------------------------------------


error (nargchk (5, 9, nargin));

% Set defaults for any optional arguments that weren't supplied

if (nargin < 9)                 % progress not given, assign default value
   progress = 0;
end;

if (nargin < 8)                 % do_delay not given, assign default
   do_delay = 1;
end;

if (nargin < 7)                 % delta not given
   delta = 0;
end;

if (nargin < 6)                 % tau not given
   tau = 4;
end;
   
if (~do_delay) 
   disp (['No delay-fitting will be performed; will use delta = ' ...
           int2str(delta)]);
end

% Find the mid-frame times, and select all frames in the first 60 sec
% of the study only

numframes = length(FrameTimes);
MidFTimes = FrameTimes + FrameLengths/2;
first60 = find (FrameTimes < 60);
A = A (first60);                        % chop off stuff after 60 seconds
MidFTimes = MidFTimes (first60);        % first minute again

% If graphical progress: plot the caller-supplied PET activity

if (progress >= 3)
   figure;
   plot (MidFTimes, A, 'or');
   hold on
   title ('Average activity across gray matter in first minute');
   old_fig = gcf;
   drawnow;
end;

% If graphical progress: plot the uncorrected blood data

if (progress >= 3)
   figure;
   plot (ts_even, g_even, 'y:');
   title ('Blood activity: dotted=g(t), solid=g(t) + tau*dg/dt');
   drawnow
   hold on
end;

% First let's do the dispersion correction: differentiate and smooth
% g(t) by using the method of Sayers described in "Inferring
% Significance from Biological Signals."

[smooth_g_even, deriv_g] = ...
     deriv (3, length(ts_even), g_even, (ts_even(2)-ts_even(1)));
smooth_g_even(length(smooth_g_even)) = [];
deriv_g(length(deriv_g)) = [];
ts_even(length(smooth_g_even)) = [];


% Now the actual dispersion correction, using the smoothed and 
% differentiated versions of g_even

g_even = smooth_g_even + tau*deriv_g;

% Add the dispersion-corrected blood curve to the uncorrected one

if (progress >= 3)
   plot (ts_even, g_even, 'r');
   drawnow
end

% Here are the initial values of alpha, beta, and gamma, in units of:
%  alpha = (mL blood) / ((g tissue) * sec)
%   beta = 1/sec
%  gamma = (mL blood) / (g tissue)
% Note that these differ numerically from Hiroto's suggested initial
% values of [0.6, alpha/0.8, 0.03] only because of the different
% units on alpha of (mL blood) / ((100 g tissue) * min).

init = [.0001 .000125 .03];


if (do_delay)

   if (progress), fprintf ('Fitting for delay correction'), end
   if (progress >= 2), fprintf (':\n'), end

   deltas = -5:1:10;
   rss = zeros (length(deltas), 1);     % residual sum-of-squares
   params = zeros (length(deltas), 3);  % 3 parameters per fit

   for i = 1:length(deltas)
      delta = deltas (i);
      if (progress >= 2), fprintf ('delta = %.1f', delta), end

      % Get the shifted activity function, g(t - delta), by shifting g(t)
      % to the right (ie. subtract delta from its actual times, ts_even)
      % and resample at the "correct" times ts_even).  Then do the 
      % three-parameter fit to optimise the function wrt. alpha, beta,
      % and gamma.

      shifted_g_even = lookup ((ts_even-delta), g_even, ts_even);
      g_select = find (~isnan (shifted_g_even));

      final = delaycorrect (init, ...
	                    shifted_g_even(g_select), ...
                            ts_even(g_select), ...
 	                    A, FrameTimes, FrameLengths);

      params (i,:) = final;
%     rss (i) = sum (f .^ 2) ;            % if using leastsq
      rss(i) = fit_b_curve (final, ...
                            shifted_g_even(g_select), ts_even(g_select), ...
                            A, FrameTimes, FrameLengths);

      init = final;
      if (progress == 1)                % minimal progress messages
         fprintf ('.');
      elseif (progress >= 2)            % more progress messages
         fprintf ('; final = [%g %g %g]; residual = %g\n', final, rss (i));

         if (progress >= 3)             % report progress graphically
            plot (MidFTimes, ...
		  b_curve(final, ...
	                  shifted_g_even(g_select), ...
	                  ts_even(g_select), ...
                          A, FrameTimes, FrameLengths));
            drawnow;
         end      % if graphical progress
      end      % if any progress
   end      % for delta

   [err, where] = min (rss);            % find smallest residual
   delta = deltas (where);              % select delta for best fit
   
   if (progress)                        % minimal progress
      fprintf ('using delta = %.1f\n', delta);
   end

end      % if do_delay

% At this point either we have performed the delay-correction fitting to
% get delta, or the caller set do_delay to zero so that delay-correction
% was not explicitly done.  In this case, delta will have been set by
% the caller (since it's an optional input argument).  So set Ca_even to
% the g_even, shifted by delta.

Ca_even = lookup ((ts_even-delta), g_even, ts_even);

nuke = find(isnan(Ca_even));
Ca_even(nuke) = [];

% Let's assume that the NaN's occur at the beginning or end of the data
% (not in the middle), and that we can therefore modify ts_even without
% screwing up the even time spacing.

new_ts_even = ts_even;
new_ts_even(nuke) = [];
