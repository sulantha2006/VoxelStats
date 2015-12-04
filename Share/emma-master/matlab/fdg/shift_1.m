function out = shift_1(in)

% SHIFT_1 Adds 0 to the 1st row and excludes the last row
%
% 	Out = shift_1(In)
%
% In can be a matrix.  The length of out is the same as the length of in.

% $Id: shift_1.m,v 1.2 1997-10-20 18:23:26 greg Rel $
% $Name:  $

s=size(in);
out=zeros(s);
out(2:s(1),:)=in(1:s(1)-1,:);
