function [ts_new, plasma_new] = getFDG_CPI(ts_plasma, plasma, eft)

% To interpolate Ca(t), integrate, and mark for end-frame times.
%
%
%       cpi = getFDG_CPI(ts_plasma, plasma, eft)
%
%
% eft  =  a column vecter of end-frame time. 

% $Id: getFDG_CPI.m,v 1.3 1997-10-20 18:23:26 greg Rel $
% $Name:  $

%  Copyright 1994 Mark Wolforth and Hiroto Kuwabara, McConnell Brain Imaging
%  Centre, Montreal Neurological Institute, McGill University.
%  Permission to use, copy, modify, and distribute this software and its
%  documentation for any purpose and without fee is hereby granted, provided
%  that the above copyright notice appear in all copies.  The authors and
%  McGill University make no representations about the suitability of this
%  software for any purpose.  It is provided "as is" without express or
%  implied warranty.


%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check the input arguments

if nargin~=3
  help getFDG_CPI
  error ('Incorrect number of input arguments');
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make eft a column vector, and use only the frames spanned
% by the plasma data

eft=eft(:);
eft=eft(find(eft<=max(ts_plasma) & eft>=min(ts_plasma))); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Our new time scale includes the plasma sample times
% and the end-frame times

aT=sort([ts_plasma; eft]);

ts_new=aT(find((aT-shift_1(aT))~=0));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Clip off any times that are beyond the end of
% the last frame

ts_new=ts_new(find(ts_new<=max(eft)));
plasma_new = lookup(ts_plasma,plasma,ts_new);
