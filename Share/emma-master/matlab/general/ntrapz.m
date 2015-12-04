%NTRAPZ Trapezoidal numerical integration.
%       Z = NTRAPZ(X,Y) computes the integral of Y with respect to X using
%       trapezoidal integration.  X and Y must be vectors of the same length,
%       or X must be a column vector and Y a matrix with as many rows as X.
%       NTRAPZ computes the integral of each column of Y separately.
%       The resulting Z is a scalar or a row vector.
%
%       Z = NTRAPZ(Y) computes the trapezoidal integral of Y assuming unit
%       spacing between the data points.  To compute the integral for
%       spacing different from one, multiply Z by the spacing increment.
%
%       This function is identical in capability to the MATLAB trapz
%       function, but since it is written C, is capable of performing its
%       operations up to two orders of magnitude faster.
%
%       See also TRAPZ, SUM, CUMSUM.

% $Id: ntrapz.m,v 1.2 1997-10-20 18:23:20 greg Rel $
% $Name:  $
