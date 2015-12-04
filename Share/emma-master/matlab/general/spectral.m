function s = spectral(m)
%SPECTRAL Black-purple-blue-green-yellow-red-white color map.
%
%         map = spectral(num_colors)
%
% SPECTRAL(M) returns an M-by-3 matrix containing a "spectral" colormap.
% SPECTRAL, by itself, is the same length as the current colormap.
%
% For example, to reset the colormap of the current figure:
%
%           colormap(spectral)
%
% See also HSV, GRAY, PINK, HOT, COOL, BONE, COPPER, FLAG,
%          COLORMAP, RGBPLOT.

% $Id: spectral.m,v 1.5 2000-04-04 14:57:58 neelin Exp $
% $Name:  $

%         Copyright (c) 1984-92 by The MathWorks, Inc.
%         Spectral version made by Gabriel Leger, MBIC, MNI (c) 1993

if nargin < 1, m = size(get(gcf,'colormap'),1); end

n = fix(3/8*m);

base = [
 1 0.0000 0.0000 0.0000
 2 0.4667 0.0000 0.5333
 3 0.5333 0.0000 0.6000
 4 0.0000 0.0000 0.6667
 5 0.0000 0.0000 0.8667
 6 0.0000 0.4667 0.8667
 7 0.0000 0.6000 0.8667
 8 0.0000 0.6667 0.6667
 9 0.0000 0.6667 0.5333
10 0.0000 0.6000 0.0000
11 0.0000 0.7333 0.0000
12 0.0000 0.8667 0.0000
13 0.0000 1.0000 0.0000
14 0.7333 1.0000 0.0000
15 0.9333 0.9333 0.0000
16 1.0000 0.8000 0.0000
17 1.0000 0.6000 0.0000
18 1.0000 0.0000 0.0000
19 0.8667 0.0000 0.0000
20 0.8000 0.0000 0.0000
21 0.8000 0.8000 0.8000
];

n = length(base);

X0 = linspace (1, n, m);

s = emma_table(base,X0)';
