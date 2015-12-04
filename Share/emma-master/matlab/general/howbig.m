function sizes = howbig
% HOWBIG  tell how much memory (in kbytes) current MATLAB process is using
%
%     HOWBIG
%
% returns a 2x1 vector.  The first element is the total size of the current
% MATLAB process, and the second element is the resident stack size.
% Both numbers are as parsed from 'ps -l', except multipled by 4 to
% give the sizes in kilobytes.

% $Id: howbig.m,v 1.2 1997-10-20 18:23:22 greg Rel $
% $Name:  $

[res, out] = unix ('ps -l | grep matlab | nawk ''{ split ($10, sizes, ":"); print sizes [1], sizes[2] }''');
sizes = sscanf (out, '%d %d');
sizes = sizes * 4;              % pages -> kbytes
