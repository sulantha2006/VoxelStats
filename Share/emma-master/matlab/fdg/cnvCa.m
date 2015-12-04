	function cCa = cnvCa(t,Ca,b)

% To calculate cCa(t) = int_o^t Ca(u)*exp(-b(t-u))du
%
%	usage: cCa = cnvCa(t,Ca,b)
%
% t,Ca,b are column vectors.
% It is recommanded to interpolate Ca(t) with dt <= 0.1 min.
% When Ca is integral of a function (Ca'), cCa (output of this code)
% is equal to integral of convolution of Ca', if finely sampled.

% $Id: cnvCa.m,v 1.4 1997-10-20 18:23:26 greg Rel $
% $Name:  $

% Ca(:,ones(Lb,1))=Ca*ones(1,Lb) but faster.
t=t(:); b=b(:);
  Lb=length(b); Lt=length(t); q=tril(ones(Lt));
  u=Ca(:,ones(Lb,1)).*exp(t*b'); dt=(t-shift_1(t))/2; 
  cCa=(q*((u+shift_1(u)).*dt(:,ones(Lb,1)))).*exp(-t*b');
