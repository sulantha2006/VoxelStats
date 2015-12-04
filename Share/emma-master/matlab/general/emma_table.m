function [y,failures] = emma_table(tab,x0)
%TABLE Table look-up.
%
% y = emma_table(TAB,X0) 
%
%       returns a table of linearly interpolated rows from
%	table TAB, looking up X0 in the first column of TAB.

% $Id: emma_table.m,v 2.2 2000-04-04 14:57:58 neelin Exp $
% $Name:  $

%       NOTE:  TAB's 1st column is checked for monotonicity.
%       When a requested value is outside the range of the first
%       column of TAB for X0, a warning message is printed and 
%	     the value zero is returned for that lookup

%	Tomas Schoenthal 5-1-85
%  Egbert Kankeleit 1-15-87
%	Revised by L. Shure 2-3-87
%	Copyright (c) 1985, 1987 by the MathWorks, Inc.

%	Revised again by GCL 1-3-93, MBIC, MNI, McGill

if (nargin ~= 2), error('Wrong number of input arguments.'), end

[m,n]=size(tab);
k0=max(size(x0));
failures = zeros(k0,1);

% checking for monotonicity, and constructing 
% table of slopes with last row repeated

dx = tab(2:m,:) - tab(1:m-1,:);
dx = [dx;dx(m-1,:)];
sig = sign(dx(1,1));

if any(sign(dx(:,1))-sig), 
  error('First column of the table must be monotonic.')
end

y = zeros(k0,n-1);

if sig > 0, % values are monotonically increasing

  for k = 1:k0
    ii = max(find(tab(:,1) <= x0(k) ));
    if size(ii) == 0,
       failures(k) = 1;
%      fprintf(['failed at ',num2str(k),' with value %f (to low)\n'],x0(k))
    elseif x0(k) > tab(m,1),
       failures(k) = 1;
%      fprintf(['failed at ',num2str(k),' with value %f (to high)\n'],x0(k))
    else
      y(k,:) = tab(ii,2:n) + dx(ii,2:n) * (x0(k)-tab(ii,1)) / dx(ii,1);
    end
  end

else % sig < 0, values are monotonically decreasing

  for k = 1:k0
    ii = max(find(tab(:,1) >= x0(k)));
    if size(ii) == 0, 
       failures(k) = 1;
%      fprintf(['failed at ',num2str(k),' with value %f (to high)\n'],x0(k))
    elseif x0(k) < tab(m,1), 
       failures(k) = 1;
%      fprintf(['failed at ',num2str(k),' with value %f (to low)\n'],x0(k))
    else
      y(k,:) = tab(ii,2:n) + dx(ii,2:n) * (x0(k)-tab(ii,1)) / dx(ii,1);
    end
  end

end

y = y';
if nargout ~= 2, 
  if any(failures), disp([' warning: failed ',num2str(sum(failures)),' times']); end
end
