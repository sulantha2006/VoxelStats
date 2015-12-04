function xfm = loadxfmfile(xfmfile);
% LOADXFMFILE   Load an MNI linear transform file
%
%   xfm = loadxfmfile (xfmfile)
%
% opens the transform file named by xfmfile (a character string) and
% reads it in to extract the homogeneous linear transform matrix.
% Note that the transform file must contain a linear transform; other
% types (eg. thin-plate spline, displacement grid, etc.) are not
% supported.

% $Id: loadxfmfile.m,v 1.3 1997-10-20 18:23:24 greg Rel $
% $Name:  $

% by Greg Ward

error (nargchk (1, 1, nargin));

if (~isstr (xfmfile))
   error ('Argument must be a string');
end

fid = fopen (xfmfile, 'r');
if (fid == -1)
   error (['Could not open file ' xfmfile]);
end

contents = setstr (fread (fid)');
delim = find (contents == 10);
num_lines = length (delim);
delim = [0 delim];
fclose (fid);

% Meaning of state variable:
%  1 = waiting for "MNI Transform File" line
%  2 = waiting for "Transform_Type = Linear;"
%  3 = waiting for "Linear_Transform ="
%  4..6 = satisfied with format, reading the matrix (at row state-3)

waitfor = str2mat ('MNI Transform File', ...
                   'Transform_Type = Linear', ...
                   'Linear_Transform =', ...
                   'row 1 of transform matrix', ...
                   'row 2 of transform matrix', ...
                   'row 3 of transform matrix', ...
                   'uh-oh! unknown state!');

state = 1;
xfm = zeros (4, 4);

% My apologies for the flaming inelegance of the following code.  Much
% of it can be blamed on MATLAB's utterly inexcusable lack of both 
% a "continue" statement and short-circuit boolean evaluation.

i = 1;
done = 0;

while (i <= num_lines & ~done)
   curline = '';
   while (isempty(curline) & (i <= num_lines))
      curline = deblank (contents ((delim(i)+1):(delim(i+1)-1)));
      if (~isempty (curline))
         if (curline (1) == '%')
            curline = '';
         end
      end
      i = i + 1;
   end
   i = i - 1;
%   fprintf (1, 'line %d/%d (state=%d): %s\n', i, num_lines, state, curline);

   if (state == 1 & strcmp (curline, 'MNI Transform File'))
      state = 2;
   elseif (state == 2 & strcmp (curline, 'Transform_Type = Linear;'))
      state = 3;
   elseif (state == 3 & strcmp (curline, 'Linear_Transform ='))
      state = 4;
   elseif (state >= 4)      % state-2 = row number
      if (state > 6)
         error ('Too many rows in transform matrix');
      end

      if (state == 6 & curline (length (curline)) == ';')
	 curline (length (curline)) = ' ';
	 done = 1;
      end

      [currow, count, errmsg, nextindex] = sscanf (curline, '%g');
      
      if (count < 4)
         error (['Not enough columns in row ' int2str(state-3) ' of transform']);
      elseif (count > 4)
         error (['Too many columns in row ' int2str(state-3) ' of transform']);
      elseif (nextindex < length (curline))
         error (['Extraneous junk found in row ' int2str(state-3) ' of transform']);
      elseif (~isempty (errmsg))
         error (errmsg);
      end
   
      xfm (state-3, :) = currow';
      state = state + 1;
   else
      fprintf (2, 'Error in state %d (waiting for "%s")\n', ...
                  state, waitfor(state,:));
      error (['Bad transform file (died on line ' int2str(i) ')']);
   end
%   fprintf (1, 'Done processing line %d, now in state %d\n', i, state);
   i = i+1;
end

xfm (4,:) = [0 0 0 1];
