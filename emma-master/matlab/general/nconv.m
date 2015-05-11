function c = conv(a, b, spacing)
%NCONV  Convolution of two vectors with not necessarily unit spacing.
%	C = NCONV(A, B, spacing) convolves vectors A and B.  The resulting
%	vector is length LENGTH(A)+LENGTH(B)-1.
%
%       This routine is a replacement for MathWorks' conv function, 
%       which implicitly assumes that A and B are sampled with unit
%       spacing.  If you are dealing with two functions that are
%       unevenly sampled or sampled with different spacings, one or
%	both of them must be resampled to the same evenly spaced 
%	independent variable.  Then, if the spacing of the independent
%	variable is not 1, it should be passed to nconv.
%
%	See also CONV, XCORR, DECONV, CONV2, LOOKUP.

% $Id: nconv.m,v 1.2 1997-10-20 18:23:20 greg Rel $
% $Name:  $

%	J.N. Little 4-21-85
%	Revised 9-3-87 JNL
%       Added spacing argument 93-8-4 Greg Ward (at MNI)
%	Copyright (c) 1984-92 by The MathWorks, Inc.

if (nargin < 2); b = a; end;
if (nargin < 3); spacing = 1; end;

na = max(size(a));
nb = max(size(b));

% Convolution, polynomial multiplication, and FIR digital
% filtering are all the same operations.  Since FILTER
% is a fast built-in primitive, we'll use it for CONV.

% CONV(A,B) is the same as CONV(B,A), but we can make it go
% substantially faster if we swap arguments to make the first
% argument to filter the shorter of the two.
if na > nb
    if nb > 1
        a(na+nb-1) = 0;
    end
    c = filter(b, 1, a) * spacing;
else
    if na > 1
        b(na+nb-1) = 0;
    end
    c = filter(a, 1, b) * spacing;
end
