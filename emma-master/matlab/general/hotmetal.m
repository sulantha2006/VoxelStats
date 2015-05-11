function s = hotmetal(m)
%HOTMETAL a better hot metal color map.
%
%         map = hotmetal(num_colors)
%
% HOTMETAL(M) returns an M-by-3 matrix containing a "hot" colormap.
% HOTMETAL, by itself, is the same length as the current colormap.
%
% For example, to reset the colormap of the current figure:
%
%           colormap(hotmetal)
%
% See also HSV, GRAY, PINK, HOT, COOL, BONE, COPPER, FLAG,
%          COLORMAP, RGBPLOT, SPECTRAL.

% $Id: hotmetal.m,v 1.3 2000-04-04 14:57:58 neelin Exp $
% $Name:  $

%         Copyright (c) 1984-92 by The MathWorks, Inc.
%         Hotmetal version made by Mark Wolforth, MBIC, MNI (c) 1993

if nargin < 1, m = size(get(gcf,'colormap'),1); end

n = fix(3/8*m);

base = [
1 0.000000 0.000000 0.000000
2 0.100000 0.000000 0.000000
3 0.200000 0.000000 0.000000
4 0.300000 0.000000 0.000000
5 0.400000 0.000000 0.000000
6 0.500000 0.000000 0.000000
7 0.600000 0.100000 0.000000
8 0.700000 0.200000 0.000000
9 0.800000 0.300000 0.000000
10 0.900000 0.400000 0.000000
11 1.000000 0.500000 0.000000
12 1.000000 0.600000 0.100000
13 1.000000 0.700000 0.200000
14 1.000000 0.800000 0.300000
15 1.000000 0.900000 0.400000
16 1.000000 1.000000 0.500000
17 1.000000 1.000000 0.600000
18 1.000000 1.000000 0.700000
19 1.000000 1.000000 0.800000
20 1.000000 1.000000 0.900000
21 1.000000 1.000000 1.000000
];

n = length(base);

X0 = linspace (1, n, m);

s = emma_table(base,X0)';
