function [points1, points2] = loadtagfile(tagfile);
% LOADTAGFILE   Load a tag file into MATLAB
% 
%    [points1, points2] = loadtagfile (tagfile);
% 
% loads an MNI tag file named by tagfile (which must be a string) into
% MATLAB.  If the tag file has points for two volumes, the two sets of
% points are returned in points1 and points2; if tags for only one
% volume are present, then points2 will be empty.
% 
% The tag points are returned as homogeneous coordinates (ie. of the
% form [x y z 1]) in columns.

% $Id: loadtagfile.m,v 1.5 2001-05-29 12:29:41 neelin Exp $
% $Name:  $

% originally by Peter Neelin; rewritten 95/3/20 Greg Ward.

error (nargchk (1, 1, nargin));

if (~isstr (tagfile))
   error ('Argument must be a string');
end

fid = fopen (tagfile, 'r');
if (fid == -1)
   error (['Could not open file ' tagfile]);
end

% The parsing works like a finite state machine, where the state just
% keeps track of where we are in the file as follows:
% 
%  1 = waiting for "MNI Tag Point File" line
%  2 = waiting for "Volumes =" line
%  3 = waiting for "Points =" line
%  4 = in list of points

% The targets array holds the string we're looking for in each state
% except state 4, which isn't looking for any particular string

targets = str2mat ('MNI Tag Point File',...
      'Volumes =',...
      'Points =',...
      'list of points');

% Initialize for the while loop below
                   
state = 1;
curline = fgetl (fid);
line_num = 1;
pts = [];

% Now loop through the input file until eof (or error condition)

while (isstr(curline))            % while not eof(fid)

   % First thing to do is strip off trailing blanks and comments

   curline = deblank (curline);
   comment = find (curline=='%');
   if (~isempty (comment))
      curline (comment:length(curline)) = '';
   end

   % Now, actually look at the line unless it's blank, 
   % 2) we're in the list of points and the line is just a semicolon
   
   if (~ isempty (curline))
    
%     fprintf (1, 'line %d (state=%d): "%s"\n', line_num, state, curline);      
      % If we're in state 1, 2, or 3, we're still looking for one
      % of the strings listed in `targets'

      if (state <= 3)

         % Test against the appropriate target string; we have to 
         % go through a few hoops to make sure we don't try to 
         % compare more characters than we have in curline!

         cur_length = length (curline);
         target_string = deblank (targets (state,:));
         target_length = length (deblank (target_string));
         min_length = min ([cur_length target_length]);

         % If we have a match, advance to the next state; otherwise
         % bomb with a hopefully informative error message
      
         if (strcmp (curline(1:min_length), target_string))
            state = state + 1;
         else
            errmsg = sprintf ('Error on line %d of %s: was expecting "%s", found "%s"',...
                  line_num, tagfile, target_string, curline);
            error (errmsg);
         end

         % If we've just entered state 3, that means we're looking at the
         % "Volumes = n" line; so, this requires some more processing
         % to parse out n and intelligently handle errors.
         
         if (state == 3)
            [num_volumes,count,err,next] = sscanf (curline, 'Volumes = %d;');
            if (count == 0)
               errmsg = sprintf ('Couldn''t find number of volumes at line %d in %s',...
                     line_num, tagfile);
               error (errmsg);
            end
            if (~isempty (err))
               errmsg = sprintf ('Error parsing line %d in %s: %s',...
                     line_num, tagfile, err);
               error (errmsg);
            end
	    expected = 3*num_volumes;
         end     % if state == 3

      % Now, if we're not in any of the lower three states, then we're
      % in the middle of the list of points.  So we parse this line 
      % into a vector, and make sure that the number of coordinates
      % given is consistent with the number of volumes found in state 3.
                    
      elseif (state == 4)
	 if (curline(1)~=';')
	    [curpts,count,err,next] = sscanf (curline, ' %f');
	    if (length (curpts) ~= expected & length(curpts) ~= expected+3)
	       errmsg = sprintf ...
   ('Bad number of points (expected %d or %d, found %d) on line %d of %s\n',...
     expected, expected+3, length (curpts), line_num, tagfile);
	       error (errmsg);
	    end
         
	    pts = [pts, curpts(:)]; 		  % put the two points in as a column
	 end     % if curline isn't ';' alone
      end     % if state == 4
   end     % if curline not empty

   % Finally, read the next line and advance the line number counter.

   curline = fgetl (fid);
   line_num = line_num + 1;
end     % while not eof


% Extract the sets of points.  Up to here, we're able to handle an
% any number of volumes in the tag file, but at this point we restrict
% to two (but that's OK, because the official definition is one or
% two volumes only).

[m,n] = size(pts);


% N.B. This check is redundant, as we check the number of coordinates
% on each line in the loop above

if (m ~= expected & m ~= expected+3)
   error('Wrong number of coordinate fields in file');
end
points1 = [pts(1:3,:); ones(1,n)];

if (num_volumes == 2) 
   points2 = [pts(4:6,:); ones(1,n)];
else
   points2 = [];
end
