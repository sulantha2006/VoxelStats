function [yfit, z] = deriv (nn, npts, y, dt)

% DERIV  calculate the derivative and smoothed version of a function
%
%      [yfit, deriv] = deriv (fit_points, data_points, y, dt)
%
%  This function calculates the derivative and smoothed
%  version of a function, using the method of parabolic
%  regressive filters, described in Sayers: "Inferring
%  Significance from Biological Signals."
%

% $Id: deriv.m,v 1.2 1997-10-20 18:23:19 greg Rel $
% $Name:  $

caa = 3 / (4 * nn * (nn^2 - 4));
cbb = 12 / (nn * (nn^2 - 1));
jbeg = ((nn+1)/2);
jend = npts - jbeg + 1;

yfit = zeros (npts,1);
z = zeros (npts,1);

for i = jbeg:jend
    aa=0;
    bb=0;
    cc=0;
    for j = 1:nn
        jj = j - 1;
	kk = floor(-((nn-1)/2)+jj);
	aa = aa + y(i+kk)*(3*nn^2-20*kk^2-7);
	bb = bb + y(i+kk)*kk;
    end
    yfit(i) = caa*aa;
    z(i) = cbb*bb/dt;
end
