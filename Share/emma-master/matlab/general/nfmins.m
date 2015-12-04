%NFMINS	Minimize a function of several variables.
%	NFMINS('F',X0) attempts to return a vector x which is a local minimizer 
%	of F(x) near the starting vector X0.  'F' is a string containing the
%	name of the objective function to be minimized.  F(x) should be a
%	scalar valued function of a vector variable.
%
%	NFMINS('F',X0,OPTIONS) uses a vector of control parameters.  If
%	OPTIONS(1) is nonzero, intermediate steps in the solution are
%	displayed; the default is OPTIONS(1) = 0.  OPTIONS(2) is the
%	termination tolerance for x; the default is 1.e-4.  OPTIONS(3) is
%	the termination tolerance for F(x); the default is 1.e-4.
%	OPTIONS(14) is the maximum number of steps; the default is
%	OPTIONS(14) = 500.  The other components of OPTIONS are not used as
%	input control parameters by NFMINS.  For more information, see
%	FOPTIONS.
%
%	NFMINS('F',X0,OPTIONS,[],P1,P2,...) provides for up to 10 additional
%	arguments which are passed to the objective function, F(X,P1,P2,...)
%
%	NFMINS uses a Simplex search method.
%
%       NFMINS is identical in use to the standard MATLAB FMINS function,
%       but with much better performance (up to two orders of magnitude
%       faster).
%
%	See also FMINS, FMIN.

% $Id: nfmins.m,v 1.2 1997-10-20 18:23:23 greg Rel $
% $Name:  $
