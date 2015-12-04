function fname = tempfilename

% TEMPFILENAME generate a unique temporary filename
%  
%    fname = tempfilename
%
% Requires that a directory /tmp/ exists on the current machine.

% $Id: tempfilename.m,v 1.9 2005-08-24 22:23:53 bert Exp $
% $Name:  $

if (exist('tempname') ~= 0)
   fname = tempname;
else
% Make sure that globals are automatically initialized for octave
default_global_variable_value = [];
initialize_global_variables=1;

global TempFileBase;
global TempFileCount;

% Initialize TempFileBase on first call as time (HHMMSShh, where hh is 
% hundredths of seconds)
% TempFileCount keeps track of calls to this function
now = clock;
if (isempty(TempFileBase))
   now = clock;
   TempFileBase = sprintf('%02d', fix([now(4:5) 1000*now(6)]));
   TempFileCount = 1;
else
   TempFileCount = TempFileCount + 1;
end

filename = sprintf ('/tmp/matimage_%s_%s.dat', ...
   TempFileBase, int2str (TempFileCount));
file_handle = fopen (filename,'r');

% loop until we fail to open the file, ie.
% we find one that *doesn't* exist

while (file_handle ~= -1)
   if (file_handle ~= -1)

      % if file was successfully opened, close it and try another one --
      % we keep going until we find a file that *doesn't* exist

      fclose (file_handle);
      TempFileBase = sprintf('%02d', fix([now(4:5) 1000*now(6)]));
      filename = sprintf ('/tmp/matimage_%s_%s.dat', ...
         TempFileBase, int2str (TempFileCount));
      file_handle = fopen (filename, 'r');
   end
end
fname = filename;
end
