function yi = igrate(t,y)

% IGRATE performs a piecewise linear integration
%
%
%         yi = igrate (t,y) 
%
%
% integration of each of the columns of Y along the
% vector T.  If Y is M-by-N then T must be M. IGRATE
% returns a vector Yi containing cumulative integrals
% at each element of T.
%
% The time spacing must be even.

% $Id: igrate.m,v 1.3 1997-10-20 18:23:26 greg Rel $
% $Name:  $

if length(t) ~= length(y)
  error('t and y must have the same length.');
end;

s=size(y);
dt=(t-shift_1(t))/2; 
yi=tril(ones(length(t)))*((y+shift_1(y)).*(dt*ones(1,s(2))));
