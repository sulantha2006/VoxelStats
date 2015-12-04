function [x,y] = getpixel(n)

% GETPIXEL replacement for MATLAB's ginput function
%
%     [x,y] = getpixel(n)
%
% MATLAB's ginput function crashes if there is no X display
% defined.  This function checks to make sure that the display
% exists before calling ginput.  The functionality of this
% function is exactly the same as MATLAB's ginput.

% $Id: getpixel.m,v 1.3 1997-10-20 18:23:19 greg Rel $
% $Name:  $

if (get(0,'ScreenSize') == [0 0 1 1])
   disp('getpixel: Unknown display, cannot get a pixel');
   return;
end

[x,y] = ginput(n);

